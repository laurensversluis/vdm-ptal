-- Identify candidate routes
--
-- candidate links with start and stop within the analysis region: networks.ov_links
-- if we have a Netherlands map and wanted to study a region, we would have to filter

-- create candidate routes temp table:
-- only those at weekday afternoon afternoon peak time, that one can board, and have valid link
-- peak time is 17.00 to 18.00 to have a 1 hour period as in London. Otherwise we have to adjust the method.
DROP TABLE IF EXISTS temp_candidate_routes CASCADE;
CREATE TEMP TABLE temp_candidate_routes (
	sid serial NOT NULL PRIMARY KEY,
	sap_id character varying,
	route_name character varying,
	trip_headsign character varying,
	direction integer,
	transport_mode character varying,
	frequency integer
);
INSERT INTO temp_candidate_routes (sap_id, route_name, trip_headsign, direction, transport_mode, frequency)
	SELECT routes.sap_id, routes.route_name, routes.trip_headsign,
		routes.direction_id, routes.route_type, count(*)
	FROM (
		SELECT stops.sap_id,
			CASE WHEN patterns.route_short_name IS NULL THEN patterns.route_long_name
			ELSE patterns.route_short_name END AS route_name,
			patterns.trip_headsign, patterns.direction_id,
			patterns.route_type
		FROM (
			SELECT sap_id FROM ov_analysis.valid_saps
			GROUP BY sap_id
		) AS stops
		JOIN (
			SELECT * FROM networks.ov_links link
			WHERE (start_stop_time >= EXTRACT(EPOCH FROM INTERVAL '17:00:00')
			AND start_stop_time <= EXTRACT(EPOCH FROM INTERVAL '18:00:00'))
			AND trip_id IN (
				SELECT trip_id FROM networks.ov_trips
				WHERE day_of_week not in ('saturday','sunday')
			)
		) AS times
		ON(stops.sap_id=times.start_stop_id)
		JOIN networks.ov_trips AS patterns
		USING(trip_id)
	) routes
	GROUP BY routes.sap_id, routes.route_name, routes.trip_headsign,
		routes.direction_id, routes.route_type
;
CREATE INDEX temp_candidate_routes_idx ON temp_candidate_routes (sap_id);

-- eliminate bi-directional routes, selecting highest frequency
DELETE FROM temp_candidate_routes WHERE sid IN (
		SELECT DISTINCT ON(a.sap_id, a.route_name, a.transport_mode) a.sid
		FROM temp_candidate_routes a, temp_candidate_routes b
		WHERE a.sap_id=b.sap_id
		AND a.route_name=b.route_name
		--AND a.trip_headsign=b.trip_headsign
		AND a.transport_mode=b.transport_mode
		AND (a.direction!=b.direction)
		ORDER BY a.sap_id, a.route_name, a.transport_mode, a.frequency ASC
	)
;
-- Identify valid routes at each SAP
DROP TABLE IF EXISTS ov_analysis.valid_routes CASCADE;
CREATE TABLE ov_analysis.valid_routes(
	sid serial NOT NULL PRIMARY KEY,
	poi_id character varying,
	sap_id character varying,
	transport_mode character varying,
	distance_to_sap double precision,
	pattern_id integer,
	pattern_frequency integer
);
INSERT INTO ov_analysis.valid_routes
	(poi_id, sap_id, transport_mode, distance_to_sap, pattern_id, pattern_frequency)
	SELECT
		DISTINCT ON (saps.poi_id, routes.sid)
		saps.poi_id,
		saps.sap_id,
		saps.transport_mode,
		saps.distance_to_sap,
		routes.sid,
		routes.frequency AS pattern_frequency
	FROM ov_analysis.valid_saps AS saps
	JOIN temp_candidate_routes AS routes
	USING (sap_id)
	ORDER BY saps.poi_id, routes.sid, saps.distance_to_sap ASC
;