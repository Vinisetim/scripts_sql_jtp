CREATE VIEW app.vw_dim_veiculos AS
SELECT
    ROW_NUMBER() OVER(ORDER BY viagens_veiculo) AS id_veiculo,
    viagens_veiculo AS prefixo_veiculo,

    CASE
        WHEN CAST(viagens_veiculo AS INT) >= 3157 THEN 'ROXO'
        ELSE 'AZUL'
    END AS COR_VEICULO

FROM(
    SELECT DISTINCT viagens_veiculo
    FROM stg.stg_cittati_viagens
    WHERE viagens_veiculo IS NOT NULL
) AS veiculos_unicos;