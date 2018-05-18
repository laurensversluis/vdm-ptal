-- STEP 0: Get the POIs and corresponding network nodes
-- STEP 1: Identify candidate SAPs from isochrone nodes
-- STEP 2: Identify candidate journeys (routes)
-- STEP 3: Identify valid routes at each SAP
-- STEP 4: Calculating Total Access Time and EDF
-- STEP 5: Calculate accessibility index
-- STEP 6: Calculate PTAI and PTAL for the POIs

DROP SCHEMA IF EXISTS ov_analysis CASCADE;
CREATE SCHEMA ov_analysis;

-- STEP 0: Get the POIs and corresponding network nodes

-- DROP TABLE ov_analysis.ptal_poi CASCADE;
CREATE TABLE ov_analysis.ptal_poi (
	sid serial NOT NULL PRIMARY KEY,
	geom geometry(Point, 28992),
	cell_id character varying,
	weg_sid integer,
	weg_length double precision,
	weg_point_location double precision,
	source_id integer,
	target_id integer
);

INSERT INTO ov_analysis.ptal_poi (cell_id, geom, weg_sid, weg_length, weg_point_location, source_id, target_id)
	SELECT DISTINCT ON (grid.c28992r100)
    grid.c28992r100,
    grid.geom,
    ST_ClosestPoint(weg.geom, grid.geom),
		weg.sid,
    weg.length,
    ST_LineLocatePoint(weg.geom, grid.geom),
    weg.source,
    weg.target
	FROM (SELECT ST_Centroid(geom) geom, c28992r100
		FROM sources.vdm_vierkant_2014_pnh_lisa
	) AS grid, isochrone_analysis.wegen weg
	WHERE ST_DWithin(grid.geom,weg.geom,100)
	ORDER BY grid.c28992r500, grid.geom <-> weg.geom
;
-- remove POIs that are not reachable from any OV stop: PTAL and PTAI is 0 in those cases
DELETE FROM ov_analysis.ptal_poi AS poi
	WHERE NOT EXISTS (SELECT 1 FROM isochrone_analysis.isochrone_nodes AS node WHERE node.node_id = poi.source_id)
	AND NOT EXISTS (SELECT 1 FROM isochrone_analysis.isochrone_nodes AS node WHERE node.node_id = poi.target_id)
;
-- create indices to speed up queries
CREATE INDEX ptal_poi_cell_idx ON ov_analysis.ptal_poi (cell_id);
CREATE INDEX ptal_poi_source_idx ON ov_analysis.ptal_poi (source_id);
CREATE INDEX ptal_poi_target_idx ON ov_analysis.ptal_poi (target_id);

INSERT INTO ov_analysis.ptal_poi (cell_id, geom, weg_sid, weg_length, weg_point_location, source_id, target_id)
  SELECT DISTINCT ON (g.c28992r500)
    g.c28992r500 AS cell_id,
    ST_Centroid(g.geom) AS geom,
    g.c28992r500 AS cell_id,
    ST_length(w.geom) AS weg_length,

  WITH
    centroids_in_water AS (
      SELECT g.id
      FROM sources.cbs_bestandbodemgebruik2012_water AS w, sources.cbs_vierkant500m_2017 AS g
      WHERE ST_within(ST_centroid(g.geom), w.geom))
SELECT *
FROM sources.cbs_vierkant500m_2017 AS g, centroids_in_water AS w
WHERE g.id != w.id