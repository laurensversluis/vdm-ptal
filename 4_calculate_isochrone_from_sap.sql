-- isochrone analysis from public transport stops along the street network
DROP SCHEMA IF EXISTS isochrone_analysis CASCADE;
CREATE SCHEMA isochrone_analysis;
ALTER SCHEMA isochrone_analysis OWNER TO postgres;

-- extract network for pedestrians and cyclists
DROP TABLE isochrone_analysis.wegen CASCADE;
CREATE TABLE isochrone_analysis.wegen AS
	SELECT *
	FROM networks.t10_wegen
	WHERE fiets = TRUE OR fiets IS NULL
	OR voetganger = TRUE OR voetganger IS NULL
;

-- prepare topology
ALTER TABLE isochrone_analysis.wegen DROP COLUMN source, DROP COLUMN target;
ALTER TABLE isochrone_analysis.wegen ADD COLUMN source integer, ADD COLUMN target integer;

-- build the network topology (takes about an hour)
SELECT pgr_createTopology('isochrone_analysis.wegen', 0.01, 'geom', 'sid');

-- indexing the wegen link and vertex tables
CREATE INDEX wegen_geom_idx ON isochrone_analysis.wegen USING GIST (geom);
CREATE INDEX wegen_vertices_geom_idx ON isochrone_analysis.wegen_vertices_pgr USING GIST (the_geom);

-- link stations to 2 nearest (non connected) streets
DROP TABLE IF EXISTS isochrone_analysis.origin_stops CASCADE;
CREATE TABLE isochrone_analysis.origin_stops (
	sid serial NOT NULL PRIMARY KEY,
	geom geometry(Point,28992),
	stop_id character varying,
	stop_name character varying,
	stop_mode character varying,
	weg_sid integer,
	weg_dist double precision,
	weg_length double precision,
	weg_point_location double precision,
	source_id integer,
	target_id integer
);
-- add closest weg
INSERT INTO isochrone_analysis.origin_stops (stop_id, geom, stop_name, stop_mode,
	weg_sid, weg_length, weg_dist, weg_point_location, source_id, target_id)
	SELECT DISTINCT ON(stops.stop_id) stops.stop_id,
		ST_ClosestPoint(weg.geom, stops.geom), stops.stop_name,
		CASE
			WHEN trein = TRUE THEN 'trein'
			WHEN metro = TRUE THEN 'metro'
			WHEN tram = TRUE THEN 'tram'
			WHEN bus = TRUE THEN 'bus'
		END,
		weg.sid, weg.length,
		ST_Distance(stops.geom, weg.geom) dist,
		ST_LineLocatePoint(weg.geom, ST_GeometryN(stops.geom, 1)),
		weg.source, weg.target
	FROM (
		SELECT * FROM networks.ov_stops
		WHERE parent_station IS NULL
	) stops, isochrone_analysis.wegen weg
	WHERE ST_DWithin(stops.geom, weg.geom, 200)
	ORDER BY stops.stop_id, dist ASC
;

CREATE INDEX origins_stops_idx ON isochrone_analysis.origin_stops (stop_id);
CREATE INDEX origins_weg_idx ON isochrone_analysis.origin_stops (weg_sid);
CREATE INDEX origins_source_idx ON isochrone_analysis.origin_stops (source_id);
CREATE INDEX origins_target_idx ON isochrone_analysis.origin_stops (target_id);

----- CALCULATE street network distances to every stop
-- this is neded for walk, cycling, ov isochrones and for PTAL
-- stations - 800m walking, 3000m cycling
-- metro - 800m walking
-- bus and tram - 400m walking

-- cycling for 3000m
DO $$
DECLARE
  origins integer[];
	origin integer;
	counter integer := 1;
BEGIN
  -- Create temporary isochrone node table
	DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes_3000 CASCADE;
	CREATE TABLE isochrone_analysis.isochrone_nodes_3000(
		sid bigserial NOT NULL PRIMARY KEY,
		origin_id integer,
		travel_mode varchar,
		node_id integer,
		node_distance double precision
	);
	-- Select network
	DROP TABLE IF EXISTS wegen_fiets CASCADE;
  CREATE TEMP TABLE wegen_fiets AS (
		SELECT sid AS id, source, target, length AS cost FROM isochrone_analysis.wegen WHERE fiets IS NULL OR fiets = True);
	CREATE INDEX wegen_fiets_idx ON wegen_fiets (id);
	CREATE INDEX wegen_fiets_source_idx ON wegen_fiets (source);
	CREATE INDEX wegen_fiets_target_idx ON wegen_fiets (target);
	-- Select train stations
	origins := ARRAY(
		SELECT id FROM isochrone_analysis.wegen_vertices_pgr v
		WHERE EXISTS (
			SELECT 1 FROM wegen_fiets WHERE source=v.id OR target=v.id)
			AND EXISTS (
				SELECT 1 FROM isochrone_analysis.origin_stops
				WHERE stop_mode = 'trein' AND (source_id=v.id OR target_id=v.id)));
	-- Generate catchments
	FOREACH origin IN ARRAY origins LOOP
		RAISE NOTICE '%', counter;
		INSERT INTO isochrone_analysis.isochrone_nodes_3000 (origin_id, travel_mode, node_id, node_distance)
		SELECT origin, 'fiets', catchment.id1, catchment.cost
		FROM pgr_drivingDistance(
				'SELECT  id, source, target, cost FROM wegen_fiets',
				origin, 2900, false, false) AS catchment;
		counter := counter + 1;
	END LOOP;
	DROP TABLE IF EXISTS wegen_fiets;
END; $$ LANGUAGE plpgsql;

-- walking for 800m
DO $$
DECLARE
  origins integer[];
	origin integer;
	counter integer := 1;
BEGIN
	DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes_800 CASCADE;
	CREATE TABLE isochrone_analysis.isochrone_nodes_800(
		sid bigserial NOT NULL PRIMARY KEY,
		origin_id integer,
		travel_mode varchar,
		node_id integer,
		node_distance double precision
	);
	-- Select network
	DROP TABLE IF EXISTS wegen_walk CASCADE;
  CREATE TEMP TABLE wegen_walk AS (
		SELECT sid AS id, source, target, length AS cost FROM isochrone_analysis.wegen WHERE voetganger IS NULL OR voetganger = True);
	CREATE INDEX wegen_walk_idx ON wegen_walk (id);
	CREATE INDEX wegen_walk_source_idx ON wegen_walk (source);
	CREATE INDEX wegen_walk_target_idx ON wegen_walk (target);
	-- Select train stations
	origins := ARRAY(
		SELECT id FROM isochrone_analysis.wegen_vertices_pgr v
		WHERE EXISTS (
			SELECT 1 FROM wegen_walk WHERE source=v.id OR target=v.id)
			AND EXISTS (
				SELECT 1 FROM isochrone_analysis.origin_stops
				WHERE stop_mode IN ('trein', 'metro') AND (source_id=v.id OR target_id=v.id)));
	-- Generate catchments
	FOREACH origin IN ARRAY origins LOOP
		RAISE NOTICE '%', counter;
		INSERT INTO isochrone_analysis.isochrone_nodes_800 (origin_id, travel_mode, node_id, node_distance)
		SELECT origin, 'walk', catchment.id1, catchment.cost
		FROM pgr_drivingDistance(
				'SELECT  id, source, target, cost FROM wegen_walk',
				origin, 700, false, false) AS catchment;
		counter := counter + 1;
	END LOOP;
	DROP TABLE IF EXISTS wegen_walk;
END; $$ LANGUAGE plpgsql;

-- walking for 400m part 1
DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes_400_1 CASCADE;
CREATE TABLE isochrone_analysis.isochrone_nodes_400_1(
	sid bigserial NOT NULL PRIMARY KEY,
	origin_id integer,
	travel_mode varchar,
	node_id integer,
	node_distance double precision
);

DO $$
DECLARE
  origins integer[];
	origin integer;
	counter integer := 1;
BEGIN
  -- Select network
	DROP TABLE IF EXISTS wegen_walk CASCADE;
  CREATE TEMP TABLE wegen_walk AS (
		SELECT sid AS id, source, target, length AS cost FROM isochrone_analysis.wegen WHERE voetganger IS NULL OR voetganger = True);
	CREATE INDEX wegen_walk_idx ON wegen_walk (id);
	CREATE INDEX wegen_walk_source_idx ON wegen_walk (source);
	CREATE INDEX wegen_walk_target_idx ON wegen_walk (target);
	-- Select train stations
	origins := ARRAY(
		SELECT id FROM isochrone_analysis.wegen_vertices_pgr v
		WHERE EXISTS (
			SELECT 1 FROM wegen_walk WHERE source=v.id OR target=v.id)
			AND EXISTS (
				SELECT 1 FROM isochrone_analysis.origin_stops
				WHERE stop_mode IN ('tram', 'bus') AND (source_id=v.id OR target_id=v.id))
			ORDER BY id ASC LIMIT 25000);
	-- Generate catchments
	FOREACH origin IN ARRAY origins LOOP
		RAISE NOTICE '%', counter;
		INSERT INTO isochrone_analysis.isochrone_nodes_400_1 (origin_id, travel_mode, node_id, node_distance)
		SELECT origin, 'walk', catchment.id1, catchment.cost
		FROM pgr_drivingDistance(
				'SELECT  id, source, target, cost FROM wegen_walk',
				origin, 300, false, false) AS catchment;
		counter := counter + 1;
	END LOOP;
	DROP TABLE IF EXISTS wegen_walk;
END; $$ LANGUAGE plpgsql;

-- walking for 400m part 2
DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes_400_2 CASCADE;
CREATE TABLE isochrone_analysis.isochrone_nodes_400_2(
	sid bigserial NOT NULL PRIMARY KEY,
	origin_id integer,
	travel_mode varchar,
	node_id integer,
	node_distance double precision
);

DO $$
DECLARE
  origins integer[];
	origin integer;
	counter integer := 1;
BEGIN
  -- Select network
	DROP TABLE IF EXISTS wegen_walk CASCADE;
  CREATE TEMP TABLE wegen_walk AS (
		SELECT sid AS id, source, target, length AS cost FROM isochrone_analysis.wegen WHERE voetganger IS NULL OR voetganger = True);
	CREATE INDEX wegen_walk_idx ON wegen_walk (id);
	CREATE INDEX wegen_walk_source_idx ON wegen_walk (source);
	CREATE INDEX wegen_walk_target_idx ON wegen_walk (target);
	-- Select train stations
	origins := ARRAY(
		SELECT id FROM isochrone_analysis.wegen_vertices_pgr v
		WHERE EXISTS (
			SELECT 1 FROM wegen_walk WHERE source=v.id OR target=v.id)
			AND EXISTS (
				SELECT 1 FROM isochrone_analysis.origin_stops
				WHERE stop_mode IN ('tram', 'bus') AND (source_id=v.id OR target_id=v.id))
			AND NOT id IN (
		SELECT id FROM isochrone_analysis.wegen_vertices_pgr v
		WHERE EXISTS (
			SELECT 1 FROM wegen_walk WHERE source=v.id OR target=v.id)
			AND EXISTS (
				SELECT 1 FROM isochrone_analysis.origin_stops
				WHERE stop_mode IN ('tram', 'bus') AND (source_id=v.id OR target_id=v.id)) ORDER BY id ASC LIMIT 25000));
	-- Generate catchments
	FOREACH origin IN ARRAY origins LOOP
		RAISE NOTICE '%', counter;
		INSERT INTO isochrone_analysis.isochrone_nodes_400_2 (origin_id, travel_mode, node_id, node_distance)
		SELECT origin, 'walk', catchment.id1, catchment.cost
		FROM pgr_drivingDistance(
				'SELECT  id, source, target, cost FROM wegen_walk',
				origin, 300, false, false) AS catchment;
		counter := counter + 1;
	END LOOP;
	DROP TABLE IF EXISTS wegen_walk;
END; $$ LANGUAGE plpgsql;

-- Merging walking 400m isochrone tables
DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes_400;
CREATE TABLE isochrone_analysis.isochrone_nodes_400 AS (
SELECT * FROM isochrone_analysis.isochrone_nodes_400_1
UNION
SELECT * FROM isochrone_analysis.isochrone_nodes_400_2);

-- Merging different isochrone tables
DROP TABLE IF EXISTS isochrone_analysis.isochrone_nodes CASCADE;
CREATE TABLE isochrone_analysis.isochrone_nodes(
	sid bigserial NOT NULL PRIMARY KEY,
	origin_id integer,
	travel_mode varchar,
	node_id integer,
	node_distance double precision
);
INSERT INTO isochrone_analysis.isochrone_nodes (origin_id, travel_mode, node_id, node_distance)
SELECT origin_id, travel_mode, node_id, node_distance FROM isochrone_analysis.isochrone_nodes_3000;

INSERT INTO isochrone_analysis.isochrone_nodes (origin_id, travel_mode, node_id, node_distance)
SELECT origin_id, travel_mode, node_id, node_distance FROM isochrone_analysis.isochrone_nodes_800;

INSERT INTO isochrone_analysis.isochrone_nodes (origin_id, travel_mode, node_id, node_distance)
SELECT origin_id, travel_mode, node_id, node_distance FROM isochrone_analysis.isochrone_nodes_400;









