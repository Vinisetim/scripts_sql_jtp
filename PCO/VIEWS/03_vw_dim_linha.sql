CREATE VIEW app.vw_dim_linha AS
SELECT
    ROW_NUMBER() over(ORDER BY V.viagens_linha) AS id_linha,
    V.viagens_cod_atendimento AS codigo_sistema,

    MAX(V.viagens_nome_atendimento) AS nome_linha_normalizado,

    MAX(V.viagens_linha) AS numero_linha,

    CASE 
        WHEN V.viagens_linha IN ('110','112','113','114', '115', '119', '120', '121', '122', '123', '125', '126', '128', '04', '118')
        THEN 'LINHA DE ROXOS'
        ELSE 'LINHA DE AZUIS'
    END AS grupo_linha,

    MAX(V.garagem) AS operacao_responsavel,

    ISNULL(MAX(K.km_ida), 0.00) AS km_previsto_ida,
    ISNULL(MAX(K.km_volta), 0.00) AS km_previsto_volta,
    ISNULL(MAX(K.km_ida), 0.00) + ISNULL(MAX(K.km_volta), 0.00) + ISNULL(MAX(K.km_morto), 0.00) AS km_ciclo_previsto

FROM stg.stg_cittati_viagens AS V

LEFT JOIN stg.stg_base_km K
    ON V.viagens_cod_atendimento = k.cod_atendimento

GROUP BY
    V.viagens_cod_atendimento,
    V.viagens_linha


