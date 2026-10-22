CREATE VIEW VW_DIM_LINHA AS
SELECT
    ROW_NUMBER() over(ORDER BY V.[viagens.linha]) AS ID_LINHA,
    V.[viagens.codAtendimento] AS CODIGO_SISTEMA,

    MAX(V.[viagens.nomeAtendimento]) AS NOME_LINHA_NORMALIZADO,

    MAX(V.[viagens.linha]) AS NUMERO_LINHA,

    CASE 
        WHEN V.[viagens.linha] IN ('110','112','113','114', '115', '119', '120', '121', '122', '123', '125', '126', '128', '04', '118')
        THEN 'LINHA DE ROXOS'
        ELSE 'LINHA DE AZUIS'
    END AS GRUPO_LINHA,

    MAX(V.GARAGEM) AS OPERACAO_RESPONSAVEL,

    ISNULL(MAX(K.KM_IDA), 0.00) AS KM_PREVISTO_IDA,
    ISNULL(MAX(K.KM_VOLTA), 0.00) AS KM_PREVISTO_VOLTA,
    ISNULL(MAX(K.KM_IDA), 0.00) + ISNULL(MAX(K.KM_VOLTA), 0.00) + ISNULL(MAX(K.KM_MORTO), 0.00) AS KM_CICLO_PREVISTO

FROM STG_CITTATI_VIAGENS AS V

LEFT JOIN STG_BASE_KM K
    ON V.[viagens.codAtendimento] = k.COD_ATENDIMENTO

GROUP BY
    V.[viagens.codAtendimento],
    V.[viagens.linha]


