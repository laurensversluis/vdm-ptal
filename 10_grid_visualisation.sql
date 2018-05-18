DROP TABLE IF EXISTS ov_analysis.ptal_poi_grid;
CREATE TABLE ov_analysis.ptal_poi_grid AS (
  SELECT
    ROW_NUMBER() OVER () AS id,
    grid.c28992r500 AS cbs_cell_id,
    CASE WHEN poi.ptai IS NULL THEN 0 ELSE poi.ptai END AS ptai,
    CASE WHEN poi.ptal IS NULL THEN '0' ELSE poi.ptal END AS ptal,
    grid.geom
  FROM sources.cbs_vierkant500m_2017 AS grid LEFT JOIN ov_analysis.ptal_poi AS poi ON grid.c28992r500 = poi.cell_id
);

ALTER TABLE ov_analysis.ptal_poi_grid
    ADD PRIMARY KEY (id);

CREATE INDEX ptal_poi_grid_geom_idx ON ov_analysis.ptal_poi_grid USING GIST (geom);