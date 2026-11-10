CREATE VIEW app.vw_dim_garagem AS
SELECT
    ROW_NUMBER() OVER(ORDER BY garagem) AS id_garagem,
    garagem AS nome_garagem

FROM(
    SELECT DISTINCT garagem
    FROM stg.stg_cittati_viagens
    WHERE garagem IS NOT NULL
) garagensunicas;