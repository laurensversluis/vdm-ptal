ALTER TABLE ov_analysis.valid_routes
	ADD COLUMN travel_time double precision,
	ADD COLUMN swt double precision,
	ADD COLUMN access_time double precision,
	ADD COLUMN edf double precision,
	ADD COLUMN weight double precision,
	ADD COLUMN accessibility_index double precision
;
-- update travel time in minutes based on walk speed of 80m/minute
UPDATE ov_analysis.valid_routes
	SET travel_time = distance_to_sap/80.0
	WHERE transport_mode IN ('metro','tram','bus')
;
-- update travel time in minutes based on cycle speed of 300m/minute
UPDATE ov_analysis.valid_routes
	SET travel_time = distance_to_sap/300.0
	WHERE transport_mode IN ('trein')
;
-- update wait time (with added 2 minute delay for most modes, and 0.75 minute delay for rail)
UPDATE ov_analysis.valid_routes
	SET swt = CASE
		WHEN transport_mode IN ('trein','metro')
			THEN (0.5*(60.0/pattern_frequency::double precision)) + 0.75
		ELSE (0.5*(60.0/pattern_frequency::double precision)) + 2.0
	END
;
-- calculate access time
UPDATE ov_analysis.valid_routes SET access_time = travel_time + swt;

-- calculate edf
UPDATE ov_analysis.valid_routes SET edf = 30.0/access_time;