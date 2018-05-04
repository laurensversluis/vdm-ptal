-- prepare network data used in analysis and calculations
DROP SCHEMA IF EXISTS networks CASCADE;
CREATE SCHEMA networks;
ALTER SCHEMA networks OWNER TO postgres;

DROP TABLE networks.t10_wegen CASCADE;
CREATE TABLE networks.t10_wegen(
	sid serial NOT NULL PRIMARY KEY,
	geom geometry(LineString,28992),
	length double precision,
	t10_id varchar,
	type_weg varchar,
	verkeer varchar,
	fysiek varchar,
	breedte varchar,
	gescheiden boolean,
	verharding varchar,
	aantal_rij integer,
	niveau integer,
	a_weg varchar,
	n_weg varchar,
	e_weg varchar,
	s_weg varchar,
	auto boolean,
	fiets boolean,
	voetganger boolean);

INSERT INTO networks.t10_wegen(geom, length, t10_id, type_weg, verkeer, fysiek, breedte, gescheiden, verharding,
	aantal_rij, niveau, a_weg, n_weg, e_weg, s_weg)
	SELECT
		weg.geom,
		ST_Length(weg.geom),
		"LOKAALID",
		"TYPEWEG",
		"HOOFDVERKEERSGEBRUIK",
		"FYSIEKVOORKOMEN",
		"VERHARDINGSBREEDTEKLASSE",
		CASE "GESCHEIDENRIJBAAN" WHEN 'ja' THEN TRUE ELSE FALSE END,
		"VERHARDINGSTYPE",
		"AANTALRIJSTROKEN",
		"HOOGTENIVEAU",
		"AWEGNUMMER_CSV",
		"NWEGNUMMER_CSV",
		"EWEGNUMMER_CSV",
		"SWEGNUMMER_CSV"
	FROM (SELECT * FROM sources.t10nl_wegdeel_hartlijn
		WHERE "EINDREGISTRATIE" IS NULL
		AND "STATUS" IN ('in gebruik', 'onbekend')
		AND "HOOFDVERKEERSGEBRUIK" NOT IN ('vliegverkeer','busverkeer')
		AND "VERHARDINGSTYPE" != 'onverhard'
		AND "TYPEWEG" NOT IN ('startbaan, landingsbaan','rolbaan, platform')
	) weg
;

-- update mode columns
UPDATE networks.t10_wegen SET auto=NULL, fiets=NULL, voetganger=NULL;
UPDATE networks.t10_wegen SET auto=True, fiets=False, voetganger=False WHERE verkeer = 'snelverkeer';
UPDATE networks.t10_wegen SET auto=False, fiets=True WHERE verkeer = 'fietsers, bromfietsers';
UPDATE networks.t10_wegen SET auto=False, voetganger=True WHERE verkeer = 'voetgangers';
UPDATE networks.t10_wegen SET auto=True, fiets=True, voetganger=True WHERE verkeer = 'gemengd verkeer';

DROP INDEX t10_wegen_geom_idx CASCADE;
CREATE INDEX t10_wegen_geom_idx ON networks.t10_wegen USING GIST (geom);

