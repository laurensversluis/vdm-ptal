-- STEP 1 create schema
-- STEP 2 create empty tables for all GTFS files
-- STEP 3 load GTFS files

-- STEP 1: create GTFS schema
DROP SCHEMA IF EXISTS gtfs CASCADE;
CREATE SCHEMA gtfs;

-- STEP 2: create empty tables for all GTFS files
CREATE TABLE gtfs.agency
(
	agency_id varchar,
	agency_name varchar,
	agency_url varchar,
	agency_timezone varchar,
	agency_lang varchar(2),
	agency_phone varchar
);

CREATE TABLE gtfs.stops
(
	stop_id varchar,
	stop_code varchar,
	stop_name varchar,
	stop_desc varchar,
	platform_code varchar,
	stop_lat numeric,
	stop_lon numeric,
	zone_id varchar,
	stop_url varchar,
	location_type integer,
	parent_station varchar
);

CREATE TABLE gtfs.routes
(
	route_id varchar,
	agency_id varchar,
	route_short_name varchar,
	route_long_name varchar,
	route_desc varchar,
	route_type integer,
	route_url varchar,
	route_color varchar(8),
	route_text_color varchar(8)
);

CREATE TABLE gtfs.trips
(
	route_id varchar,
	service_id varchar,
	trip_id varchar,
	trip_headsign varchar,
	direction_id integer,
	block_id varchar,
	shape_id varchar
);

CREATE TABLE gtfs.stop_times
(
	trip_id varchar,
	arrival_time varchar,
	departure_time varchar,
	stop_id varchar,
	stop_sequence integer,
	stop_headsign varchar,
	pickup_type integer,
	drop_off_type integer,
	shape_dist_traveled varchar
);

CREATE TABLE gtfs.calendar
(
	service_id varchar,
	monday boolean,
	tuesday boolean,
	wednesday boolean,
	thursday boolean,
	friday boolean,
	saturday boolean,
	sunday boolean,
	start_date date,
	end_date date
);

CREATE TABLE gtfs.calendar_dates
(
	service_id varchar,
	exception_date date,
	exception_type integer
);

CREATE TABLE gtfs.shapes
(
	shape_id varchar,
	shape_pt_lat numeric,
	shape_pt_lon numeric,
	shape_pt_sequence integer
);

CREATE TABLE gtfs.transfers
(
	from_stop_id varchar,
	to_stop_id varchar,
	transfer_type integer,
	min_transfer_time integer
);

CREATE TABLE gtfs.feed_info
(
	feed_publisher_name varchar,
	feed_publisher_url varchar,
	feed_lang varchar,
	feed_start_date date,
	feed_end_date date,
	feed_version varchar
);

-- STEP 3: write data
COPY gtfs.agency FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/agency.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.stops FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/stops.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.routes FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/routes.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.trips FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/trips.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.stop_times FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/stop_times.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.calendar_dates FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/calendar_dates.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.transfers FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/transfers.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.feed_info FROM '/Users/laurens.versluis/Documents/PTAL/Source Data/gtfs/feed_info.txt' CSV DELIMITER ',' HEADER;
COPY gtfs.shapes FROM '/Users\/laurens.versluis/Documents/PTAL/Source Data/gtfs/shapes.txt' CSV DELIMITER ',' HEADER;