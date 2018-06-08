-- Identify candidate SAPs from isochrone nodes
-- SAPs (Service Access Point) are entrances, groups of stops, or individual stops

-- create valid saps table
DROP TABLE IF EXISTS ov_analysis.valid_saps CASCADE;
CREATE TABLE ov_analysis.valid_saps (
	sid serial NOT NULL PRIMARY KEY,
	poi_id character varying,
	sap_id character varying,
	transport_mode character varying,
	distance_to_sap double precision
);
-- prepare some indices
DROP INDEX IF EXISTS isochrone_analysis.origin_stops_stop_idx;
CREATE INDEX origin_stops_stop_idx ON isochrone_analysis.origin_stops (stop_id);
DROP INDEX IF EXISTS isochrone_analysis.origin_stops_source_idx;
CREATE INDEX origin_stops_source_idx ON isochrone_analysis.origin_stops (source_id);
DROP INDEX IF EXISTS isochrone_analysis.origin_stops_target_idx;
CREATE INDEX origin_stops_target_idx ON isochrone_analysis.origin_stops (target_id);
DROP INDEX IF EXISTS isochrone_analysis.isochrone_nodes_origin_idx;
CREATE INDEX isochrone_nodes_origin_idx ON isochrone_analysis.isochrone_nodes (origin_id);
DROP INDEX IF EXISTS isochrone_analysis.isochrone_nodes_node_idx;
CREATE INDEX isochrone_nodes_node_idx ON isochrone_analysis.isochrone_nodes (node_id);

-- identify nodes within 3000m fiets of train stations
DROP TABLE IF EXISTS sap_isochrone_nodes CASCADE;
CREATE TEMP TABLE sap_isochrone_nodes AS
	SELECT node.*
	FROM (
		SELECT * FROM isochrone_analysis.isochrone_nodes
		WHERE travel_mode = 'fiets'
	) AS node
	WHERE (node.origin_id IN (SELECT target_id FROM isochrone_analysis.origin_stops WHERE stop_mode = 'trein')
	OR node.origin_id IN (SELECT source_id FROM isochrone_analysis.origin_stops WHERE stop_mode = 'trein'))
	AND node.node_distance <= 3000
;

-- identify pois with saps within 3000m (TAKES 48 minutes!!!)
DROP TABLE IF EXISTS saps_within_poi_nodes CASCADE;
CREATE TEMP TABLE saps_within_poi_nodes AS
	SELECT poi.cell_id, stop.stop_id, stop.stop_mode,
	CASE
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*(1-poi.weg_point_location)))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*(1-poi.weg_point_location)))
	END AS distance
	FROM (SELECT * FROM isochrone_analysis.origin_stops WHERE stop_mode = 'trein') AS stop,
	sap_isochrone_nodes AS node,
	ov_analysis.ptal_poi AS poi
	WHERE (stop.source_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*poi.weg_point_location)) <= 3000
	) OR (stop.source_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 3000
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*poi.weg_point_location)) <= 3000
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 3000
	)
;

-- get minimum distance from poi to sap
DELETE FROM ov_analysis.valid_saps WHERE transport_mode = 'trein';
INSERT INTO ov_analysis.valid_saps (poi_id, sap_id, transport_mode, distance_to_sap)
	SELECT cell_id, stop_id, stop_mode, min(distance)
	FROM saps_within_poi_nodes
	GROUP BY cell_id, stop_id, stop_mode
;

-- identify nodes within 800m walk of metro stationsDROP TABLE IF EXISTS sap_isochrone_nodes CASCADE;
CREATE TEMP TABLE sap_isochrone_nodes AS
	SELECT node.*
	FROM (
		SELECT * FROM isochrone_analysis.isochrone_nodes
		WHERE travel_mode = 'walk'
	) AS node
	WHERE (node.origin_id IN (SELECT target_id FROM isochrone_analysis.origin_stops WHERE stop_mode = 'metro')
	OR node.origin_id IN (SELECT source_id FROM isochrone_analysis.origin_stops WHERE stop_mode = 'metro'))
	AND node.node_distance <= 800
;
-- identify pois with saps within 800m
DROP TABLE saps_within_poi_nodes CASCADE;
CREATE TEMP TABLE saps_within_poi_nodes AS
	SELECT poi.cell_id, stop.stop_id, stop.stop_mode,
	CASE
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*(1-poi.weg_point_location)))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*(1-poi.weg_point_location)))
	END AS distance
	FROM (SELECT * FROM isochrone_analysis.origin_stops WHERE stop_mode = 'metro') AS stop,
	sap_isochrone_nodes AS node,
	ov_analysis.ptal_poi AS poi
	WHERE (stop.source_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*poi.weg_point_location)) <= 800
	) OR (stop.source_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 800
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*poi.weg_point_location)) <= 800
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 800
	)
;
-- get minimum distance from poi to sap
DELETE FROM ov_analysis.valid_saps WHERE transport_mode = 'metro';
INSERT INTO ov_analysis.valid_saps (poi_id, sap_id, transport_mode, distance_to_sap)
	SELECT cell_id, stop_id, stop_mode, min(distance)
	FROM saps_within_poi_nodes
	GROUP BY cell_id, stop_id, stop_mode
;


-- identify nodes within 400m walk of tram and bus stops
DROP TABLE IF EXISTS sap_isochrone_nodes CASCADE;
CREATE TEMP TABLE sap_isochrone_nodes AS
	SELECT node.*
	FROM (
		SELECT * FROM isochrone_analysis.isochrone_nodes
		WHERE travel_mode = 'walk'
	) AS node
	WHERE (node.origin_id IN (SELECT target_id FROM isochrone_analysis.origin_stops WHERE stop_mode IN ('tram','bus'))
	OR node.origin_id IN (SELECT source_id FROM isochrone_analysis.origin_stops WHERE stop_mode IN ('tram','bus')))
	AND node.node_distance <= 400
;
-- identify pois with saps within 800m
DROP TABLE IF EXISTS saps_within_poi_nodes CASCADE;
CREATE TEMP TABLE saps_within_poi_nodes AS
	SELECT poi.cell_id, stop.stop_id, stop.stop_mode,
	CASE
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.source_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*stop.weg_point_location) + (poi.weg_length*(1-poi.weg_point_location)))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.source_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*poi.weg_point_location))
	WHEN stop.target_id = node.origin_id AND node.node_id = poi.target_id
	THEN (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) + (poi.weg_length*(1-poi.weg_point_location)))
	END AS distance
	FROM (SELECT * FROM isochrone_analysis.origin_stops WHERE stop_mode IN ('tram','bus')) AS stop,
	sap_isochrone_nodes AS node,
	ov_analysis.ptal_poi AS poi
	WHERE (stop.source_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*poi.weg_point_location)) <= 400
	) OR (stop.source_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*stop.weg_point_location) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 400
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.source_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*poi.weg_point_location)) <= 400
	) OR (stop.target_id = node.origin_id AND node.node_id = poi.target_id
		AND (node.node_distance + (stop.weg_length*(1-stop.weg_point_location)) +
		(poi.weg_length*(1-poi.weg_point_location))) <= 400
	)
;
-- get minimum distance from poi to sap
DELETE FROM ov_analysis.valid_saps WHERE transport_mode IN ('tram','bus');
INSERT INTO ov_analysis.valid_saps (poi_id, sap_id, transport_mode, distance_to_sap)
	SELECT cell_id, stop_id, stop_mode, min(distance)
	FROM saps_within_poi_nodes
	GROUP BY cell_id, stop_id, stop_mode
;
-- add indices for faster querying
DROP INDEX IF EXISTS ov_analysis.valid_saps_idx;
CREATE INDEX IF NOT EXISTS valid_saps_idx ON ov_analysis.valid_saps (sap_id);
