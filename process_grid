WITH
    centroids_in_water AS (
      SELECT g.id
      FROM sources.cbs_bestandbodemgebruik2012_water AS w, sources.cbs_vierkant500m_2017 AS g
      WHERE ST_within(ST_centroid(g.geom), w.geom))
SELECT *
FROM sources.cbs_vierkant500m_2017 AS g, centroids_in_water AS w
WHERE g.id != w.id