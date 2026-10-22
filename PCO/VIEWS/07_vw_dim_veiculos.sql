CREATE VIEW VW_DIM_VEICULOS AS
SELECT
    ROW_NUMBER() OVER(ORDER BY [viagens.veiculo]) AS ID_VEICULO,
    [viagens.veiculo] AS PREFIXO_VEICULO,

    CASE
        WHEN CAST([viagens.veiculo] AS INT) >= 3157 THEN 'ROXO'
        ELSE 'AZUL'
    END AS COR_VEICULO

FROM(
    SELECT DISTINCT [viagens.veiculo]
    FROM STG_CITTATI_VIAGENS
    WHERE [viagens.veiculo] IS NOT NULL
) AS VeiculosUnicos;