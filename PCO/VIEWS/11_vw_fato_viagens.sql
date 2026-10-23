CREATE VIEW VW_FATO_VIAGENS AS

WITH Viagens_Datas_Tratadas AS(
SELECT
    *,
    TRY_CAST([viagens.inicioProgramado] AS DATETIME) AS INICIO_PROGRAMADO,
    TRY_CAST([viagens.inicioRealizado] AS DATETIME) AS INICIO_REALIZADO,
    TRY_CAST([viagens.fimProgramado] AS DATETIME) AS FIM_PROGRAMADO,
    TRY_CAST([viagens.fimRealizado] AS DATETIME) AS FIM_REALIZADO
FROM STG_CITTATI_VIAGENS
),

Viagens_Data_Operacional AS(
    SELECT
        *,
        CASE
            WHEN DATEPART(HOUR, INICIO_REALIZADO) < 3 
            THEN DATEADD(DAY, -1, [viagens.data])
            ELSE [viagens.data]
        END AS DATA_OPERACIONAL
    FROM Viagens_Datas_Tratadas
)

SELECT
    ROW_NUMBER() OVER(ORDER BY V.DATA_OPERACIONAL, V.INICIO_REALIZADO) AS ID_VIAGEM,

    CAST(FORMAT(V.DATA_OPERACIONAL, 'yyyyMMdd') AS INT) AS ID_CALENDARIO,
    L.ID_LINHA,
    G.ID_GARAGEM,
    VE.ID_VEICULO,
    M.MATRICULA_MOTORISTA,
    V.DATA_OPERACIONAL,
    V.[viagens.atividade],
    v.[viagens.statusSaida],
    v.[viagens.justificativa],
    v.[viagens.tabela],

    -- Regra da FAIXA HORÁRIA (Manhã: 02:30 às 12:00, Tarde: 12:00 às 18:00, Noite: resto)
    -- Simplificando para avaliar apenas a HORA inteira (ajuste se os minutos forem vitais)
    CASE 
        WHEN DATEPART(HOUR, V.INICIO_PROGRAMADO) >= 3 AND DATEPART(HOUR, V.INICIO_PROGRAMADO) < 12 THEN '1. MANHÃ'
        WHEN DATEPART(HOUR, V.INICIO_PROGRAMADO) >= 12 AND DATEPART(HOUR, V.INICIO_PROGRAMADO) < 18 THEN '2. TARDE'
        ELSE '3. NOITE'
    END AS FAIXA_HORARIA,

    -- Regra da ORDEM HORARIO (Base 4 AM)
    CASE 
        WHEN DATEPART(HOUR, V.INICIO_PROGRAMADO) >= 4 THEN DATEPART(HOUR, V.INICIO_PROGRAMADO) - 3
        ELSE DATEPART(HOUR, V.INICIO_PROGRAMADO) + 21
    END AS ORDEM_HORARIO,


    CASE
        WHEN V.[viagens.sentido] = 'I' THEN 'IDA'
        WHEN V.[viagens.sentido] = 'V' THEN 'VOLTA'
        ELSE V.[viagens.sentido]
    END AS SENTIDO_VIAGEM,

    V.retornoOK AS RETORNO_OK,

    V.INICIO_PROGRAMADO,
    V.INICIO_REALIZADO,
    V.FIM_PROGRAMADO,
    V.FIM_REALIZADO,

    DATEDIFF(MINUTE, V.INICIO_PROGRAMADO, V.FIM_PROGRAMADO) AS TEMPO_PROGRAMADO_MIN,
    DATEDIFF(MINUTE, V.INICIO_REALIZADO, V.FIM_REALIZADO) AS TEMPO_REALIZADO_MIN,
    DATEDIFF(MINUTE, V.INICIO_PROGRAMADO, V.INICIO_REALIZADO) AS PARTIDAS_DIF_MIN,
    DATEDIFF(MINUTE, V.FIM_PROGRAMADO, V.FIM_REALIZADO) AS CHEGADA_DIF_MIN,

    ROW_NUMBER() OVER(
        PARTITION BY V.DATA_OPERACIONAL, V.[viagens.veiculo]
        ORDER BY V.INICIO_REALIZADO ASC
    ) AS SEQ_VIAGEM_VEICULO,

    ROW_NUMBER() OVER(
        PARTITION BY V.DATA_OPERACIONAL, V.[viagens.motorista]
        ORDER BY V.INICIO_REALIZADO ASC
    ) AS SEQ_VIAGEM_MOTORISTA,

    COALESCE(
        F.TIPO_FROTA,
        CASE (DATEPART(WEEKDAY, V.DATA_OPERACIONAL))
            WHEN 1 THEN 'DOMINGO'
            WHEN 7 THEN 'SÁBADO'
            ELSE 'DIA ÚTIL'
        END
    ) AS TIPO_DIA_OPERACIONAL,

    CASE
        WHEN V.[viagens.sentido] = 'I' THEN ISNULL(L.KM_PREVISTO_IDA, 0.00)
        WHEN V.[viagens.sentido] = 'V' THEN ISNULL(L.KM_PREVISTO_VOLTA, 0.00)
        ELSE 0
    END AS KM_REALIZADO,

CASE 
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%ABSENTEÍSMO%' THEN 'ABSENTEÍSMO'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%BLOQUEIO%' THEN 'BLOQUEIO'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%NATURAIS%' THEN 'FEN NATURAIS'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%GREVE%' THEN 'GREVE'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%GPS%' OR UPPER(V.[viagens.justificativa]) LIKE '%GPRS%' THEN 'GPS/GPRS'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%RA %' OR UPPER(V.[viagens.justificativa]) LIKE '%SOS%' OR UPPER(V.[viagens.justificativa]) LIKE '%FALTA DE CARRO%' THEN 'MANUTENÇÃO/QUEBRA'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%REMANEJAMENTO DE OPERADOR%' THEN 'REMAN OPERADOR'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '% RO %' OR UPPER(V.[viagens.justificativa]) LIKE '%RO-%' OR UPPER(V.[viagens.justificativa]) LIKE 'RO %' THEN 'RO'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%SERVIÇO EXTERNO%' THEN 'SERV EXTERNO'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%INSUFICIENTE%' THEN 'TEMPO INSUFICIENTE'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%CONGESTIONADO%' THEN 'TRANS CONGEST'
        WHEN UPPER(V.[viagens.justificativa]) LIKE '%VISTORIA%' THEN 'VISTORIA'
        WHEN V.[viagens.justificativa] IS NOT NULL AND V.[viagens.justificativa] != '' THEN 'OUTROS'
        ELSE NULL
    END AS MOTIVO_OCORRENCIA

FROM Viagens_Data_Operacional AS V

LEFT JOIN VW_DIM_LINHA AS L
    ON V.[viagens.codAtendimento] = L.CODIGO_SISTEMA

LEFT JOIN VM_DIM_GARAGEM AS G
    ON V.GARAGEM = G.NOME_GARAGEM

LEFT JOIN VW_DIM_VEICULOS AS VE
    ON V.[viagens.veiculo] = VE.PREFIXO_VEICULO

LEFT JOIN VW_DIM_MOTORISTA AS M
    ON V.[viagens.motorista] = M.MATRICULA_MOTORISTA

LEFT JOIN DIM_FERIADOS AS F
    ON V.DATA_OPERACIONAL = F.DATA_FERIADO
    AND (V.GARAGEM = F.OPERACAO OR F.OPERACAO = 'TODOS');

