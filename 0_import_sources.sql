-- prepare network data used in analysis and calculations
DROP SCHEMA IF EXISTS sources CASCADE;
CREATE SCHEMA sources;
ALTER SCHEMA sources OWNER TO postgres;

-- Top10 Wegdeel hartlijn
-- CBS Bestand Bodemgebruik 2012_water
-- CBS Vierkant 500m 2017
-- CBS Vierkant 100m 2010
-- 9292.nl GTFS

-- 'https://geodata.nationaalgeoregister.nl/inspireadressen/wfs?' version='auto' table=""
-- sql=SELECT * FROM inspireadressen WHERE woonplaats = 'Utrecht'
-- 'https://geodata.nationaalgeoregister.nl/bestuurlijkegrenzen/wfs?' version='auto' table=""
-- sql=SELECT * FROM provincies WHERE provincies.provincienaam = 'Noord-Brabant'

-- Clip 100m grid to province (takes 5 minutes)
DROP TABLE IF EXISTS sources.cbs_vierkant100m_2017_full_noord_brabant CASCADE;
CREATE TABLE sources.cbs_vierkant100m_2017_full_noord_brabant AS (
  SELECT a.*
  FROM sources.cbs_vierkant100m_2017_full AS a, sources.provincie_noord_brabant AS b
  WHERE a.geom && b.geom AND st_contains(b.geom, a.geom)
);

ALTER TABLE sources.cbs_vierkant100m_2017_full_noord_brabant
    ADD PRIMARY KEY (id);
CREATE INDEX cbs_vierkant100m_2017_full_noord_brabant_geom_idx ON sources.cbs_vierkant100m_2017_full_noord_brabant USING GIST (geom);