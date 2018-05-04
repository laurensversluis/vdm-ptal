-- Stops
DROP TABLE IF EXISTS networks.ov_stops CASCADE;
CREATE TABLE networks.ov_stops (
	geom geometry(Point,28992),
	stop_id character varying NOT NULL PRIMARY KEY,
	stop_code character varying,
	stop_name character varying,
	stop_descr character varying,
	platform_code character varying,
	location_type integer,
	parent_station character varying,
	stop_area integer,
	tram boolean,
	metro boolean,
	trein boolean,
	bus boolean,
	veerboot boolean
);

INSERT INTO networks.ov_stops(geom, stop_id, stop_code, stop_name, stop_descr, platform_code,
		location_type, parent_station)
	SELECT gtfs.geom, gtfs.stop_id, gtfs.stop_code, gtfs.stop_name, gtfs.stop_descr,
		gtfs.platform_code, gtfs.location_type, gtfs.parent_station
	FROM (SELECT ST_Transform(ST_SetSRID(ST_Point(stop_lon,stop_lat),4326),28992) geom,
		stop_id,
		CASE WHEN stop_code='' THEN NULL
		ELSE stop_code END AS stop_code,
		CASE WHEN strpos(stop_name,',') > 0
			THEN ltrim(split_part(stop_name,',',2))
			ELSE stop_name
		END AS stop_name,
		CASE WHEN strpos(stop_name,',') > 0
			THEN split_part(stop_name,',',1)
		END AS stop_descr,
		CASE WHEN platform_code='' THEN NULL
		ELSE  platform_code END AS platform_code, location_type,
		CASE WHEN parent_station='' THEN NULL
		ELSE parent_station END AS parent_station
		FROM gtfs.stops) gtfs
;

CREATE INDEX ov_stops_geom_idx ON networks.ov_stops USING GIST (geom);

-- stop times
DROP TABLE IF EXISTS networks.ov_stop_times CASCADE;
CREATE TABLE networks.ov_stop_times (
	sid serial NOT NULL PRIMARY KEY,
	trip_id character varying,
	arrival_time character varying,
	departure_time character varying,
	stop_id character varying,
	stop_sequence integer,
	pickup_type integer,
	drop_off_type integer,
	arrival_in_secs integer,
	departure_in_secs integer,
	group_id character varying
);
INSERT INTO networks.ov_stop_times ( trip_id, arrival_time, departure_time, stop_id, stop_sequence, pickup_type, drop_off_type,
	arrival_in_secs, departure_in_secs)
	SELECT trip_id, arrival_time, departure_time,
		stop_id, stop_sequence, pickup_type, drop_off_type,
		(CAST((substring(arrival_time for 2)) as integer)*3600+
		CAST((substring(arrival_time from 4 for 2)) as integer)*60+
		CAST((substring(arrival_time from 7 for 2)) as integer)),
		(CAST((substring(departure_time for 2)) as integer)*3600+
		CAST((substring(departure_time from 4 for 2)) as integer)*60+
		CAST((substring(departure_time from 7 for 2)) as integer))
	FROM gtfs.stop_times
	WHERE stop_id IN (SELECT stop_id FROM networks.ov_stops)
;
CREATE INDEX stop_times_stopid_idx ON networks.ov_stop_times (stop_id);
CREATE INDEX stop_times_tripid_idx ON networks.ov_stop_times (trip_id);

-- trips
DROP TABLE IF EXISTS networks.ov_trips CASCADE;
CREATE TABLE networks.ov_trips(
	trip_id character varying NOT NULL PRIMARY KEY,
	trip_headsign character varying,
	direction_id integer,
	agency_name character varying,
	route_id character varying,
	route_short_name character varying,
	route_long_name character varying,
	route_desc character varying,
	route_type character varying,
	service_id character varying,
	day_of_week character varying
);

INSERT INTO networks.ov_trips (trip_id, trip_headsign, direction_id, agency_name, route_id,
	route_short_name, route_long_name, route_desc, route_type, service_id, day_of_week)
	SELECT trips.trip_id, trips.trip_headsign, trips.direction_id, agency.agency_name, routes.route_id,
		routes.route_short_name, routes.route_long_name, routes.route_desc,
		CASE
			WHEN routes.route_type = 0 THEN 'tram'
			WHEN routes.route_type = 1 THEN 'metro'
			WHEN routes.route_type = 2 THEN 'trein'
			WHEN routes.route_type = 3 THEN 'bus'
			WHEN routes.route_type = 4 THEN 'ferry'
		END, trips.service_id,
		CASE
			WHEN calendar.dow = 0 THEN 'sunday'
			WHEN calendar.dow = 1 THEN 'monday'
			WHEN calendar.dow = 2 THEN 'tuesday'
			WHEN calendar.dow = 3 THEN 'wednesday'
			WHEN calendar.dow = 4 THEN 'thursday'
			WHEN calendar.dow = 5 THEN 'friday'
			WHEN calendar.dow = 6 THEN 'saturday'
		END
	FROM (SELECT * FROM gtfs.trips
		WHERE trip_id IN (SELECT trip_id FROM networks.ov_stop_times)) trips
	LEFT JOIN gtfs.routes routes
	USING (route_id)
	LEFT JOIN gtfs.agency agency
	USING (agency_id)
	LEFT JOIN (SELECT service_id, extract(dow from min(exception_date)) dow
		FROM gtfs.calendar_dates GROUP BY service_id) calendar
	USING (service_id)
;

-- update stops mode
DROP TABLE IF EXISTS ov_stop_modes CASCADE;
CREATE TEMP TABLE ov_stop_modes AS
	SELECT a.stop_id, min(b.route_type) route_type
	FROM networks.ov_stop_times a
	JOIN networks.ov_trips b
	USING(trip_id)
	GROUP BY a.stop_id, b.route_type
	ORDER BY a.stop_id, b.route_type
;
UPDATE networks.ov_stops stp SET tram = True
	FROM (SELECT * FROM ov_stop_modes WHERE route_type='tram') mod
	WHERE stp.stop_id = mod.stop_id
;
UPDATE networks.ov_stops stp SET metro = True
	FROM (SELECT * FROM ov_stop_modes WHERE route_type='metro') mod
	WHERE stp.stop_id = mod.stop_id
;
UPDATE networks.ov_stops stp SET bus = True
	FROM (SELECT * FROM ov_stop_modes WHERE route_type='bus') mod
	WHERE stp.stop_id = mod.stop_id
;
UPDATE networks.ov_stops stp SET veerboot = True
	FROM (SELECT * FROM ov_stop_modes WHERE route_type='veerboot') mod
	WHERE stp.stop_id = mod.stop_id
;
UPDATE networks.ov_stops stp SET trein = True
	FROM (SELECT * FROM ov_stop_modes WHERE route_type='trein') mod
	WHERE stp.stop_id = mod.stop_id
;
UPDATE networks.ov_stops SET trein = TRUE WHERE location_type = 1;