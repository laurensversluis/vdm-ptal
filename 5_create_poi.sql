-- Get the POIs and corresponding network nodes
DROP SCHEMA ov_analysis CASCADE;
CREATE SCHEMA ov_analysis;

DROP TABLE IF EXISTS ov_analysis.ptal_poi CASCADE;
CREATE TABLE ov_analysis.ptal_poi2 (
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
	SELECT DISTINCT ON (grid.c28992r500) grid.c28992r500, ST_ClosestPoint(weg.geom, grid.geom),
		weg.sid, weg.length, ST_LineLocatePoint(weg.geom, grid.geom), weg.source, weg.target
	FROM (SELECT ST_Centroid(geom) geom, c28992r500
		FROM sources.cbs_vierkant500m_2017
	) AS grid, isochrone_analysis.wegen weg
	WHERE ST_DWithin(grid.geom,weg.geom,500) AND weg.disconnected = FALSE
	ORDER BY grid.c28992r500, grid.geom <-> weg.geom
;
-- remove POIs that are not reachable from any OV stop: PTAL and PTAI is 0 in those cases
WITH islands AS (
	SELECT poi.sid
	FROM ov_analysis.ptal_poi AS poi
		LEFT JOIN isochrone_analysis.isochrone_nodes AS node_1 ON node_1.node_id = poi.source_id
		LEFT JOIN isochrone_analysis.isochrone_nodes AS node_2 ON node_2.node_id = poi.target_id
	WHERE node_1.sid IS NULL AND node_2.sid IS NULL
)
DELETE FROM ov_analysis.ptal_poi
WHERE sid = ANY(SELECT * FROM islands);

-- create indices to speed up queries
CREATE INDEX ptal_poi_cell_idx ON ov_analysis.ptal_poi (cell_id);
CREATE INDEX ptal_poi_source_idx ON ov_analysis.ptal_poi (source_id);
CREATE INDEX ptal_poi_target_idx ON ov_analysis.ptal_poi (target_id);