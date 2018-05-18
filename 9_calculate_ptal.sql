-- update weight
UPDATE ov_analysis.valid_routes SET weight = 1.0
	WHERE sid IN (
		SELECT DISTINCT ON (poi_id, transport_mode) sid
		FROM ov_analysis.valid_routes
		ORDER BY poi_id, transport_mode, edf DESC
	)
;
UPDATE ov_analysis.valid_routes SET weight = 0.5 WHERE weight IS NULL;

-- update accessibility index
UPDATE ov_analysis.valid_routes SET accessibility_index = weight * edf;

-- create index
CREATE INDEX IF NOT EXISTS valid_routes_idx ON ov_analysis.valid_routes (poi_id);

-- Calculate PTAI and PTAL for the POIs
ALTER TABLE ov_analysis.ptal_poi
	ADD COLUMN IF NOT EXISTS ptai double precision,
	ADD COLUMN IF NOT EXISTS ptal character varying
;
-- PTAI: accessibility index
UPDATE ov_analysis.ptal_poi AS poi
	SET ptai = routes.accessibility_index
	FROM (
		SELECT poi_id, round(sum(accessibility_index)::numeric,2) accessibility_index
		FROM ov_analysis.valid_routes
		GROUP BY poi_id
	) AS routes
	WHERE poi.cell_id = routes.poi_id
;
-- PTAL
UPDATE ov_analysis.ptal_poi SET ptai = 0 WHERE ptai IS NULL;
UPDATE ov_analysis.ptal_poi SET ptal = CASE
	--WHEN ptai = 0 THEN '0'
	WHEN ptai > 0 AND ptai <= 2.5 THEN '1a'
	WHEN ptai > 2.5 AND ptai <= 5 THEN '1b'
	WHEN ptai > 5 AND ptai <= 10 THEN '2'
	WHEN ptai > 10 AND ptai <= 15 THEN '3'
	WHEN ptai > 15 AND ptai <= 20 THEN '4'
	WHEN ptai > 20 AND ptai <= 25 THEN '5'
	WHEN ptai > 25 AND ptai <= 40 THEN '6a'
	WHEN ptai > 40 THEN '6b'
	END
	WHERE ptai IS NOT NULL
;