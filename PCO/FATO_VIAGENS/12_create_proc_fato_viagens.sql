CREATE OR ALTER PROCEDURE PRC_CARGA_FATO_VIAGENS
    @DATA_INICIO DATE = NULL, -- Se omitido, assume (Hoje - 3 dias)
    @DATA_FIM    DATE = NULL  -- Se omitido, assume Hoje
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Definição dinâmica do período de processamento
    -- Se os parâmetros forem nulos (rotina diária do ADF), processa a janela deslizante de 3 dias
    IF @DATA_INICIO IS NULL
        SET @DATA_INICIO = CAST(DATEADD(DAY, -3, GETDATE()) AS DATE);

    IF @DATA_FIM IS NULL
        SET @DATA_FIM = CAST(GETDATE() AS DATE);

    -- 2. Limpeza pontual apenas do intervalo informado (compatível com Ledger, sem derrubar a DTU)
    DELETE FROM FATO_VIAGENS 
    WHERE DATA_OPERACIONAL BETWEEN @DATA_INICIO AND @DATA_FIM;

    -- 3. CTE de tratamento com filtro antecipado de leitura
    WITH Viagens_Datas_Tratadas AS (
        SELECT
            *,
            TRY_CAST([viagens.inicioProgramado] AS DATETIME) AS INICIO_PROGRAMADO,
            TRY_CAST([viagens.inicioRealizado] AS DATETIME) AS INICIO_REALIZADO,
            TRY_CAST([viagens.fimProgramado] AS DATETIME) AS FIM_PROGRAMADO,
            TRY_CAST([viagens.fimRealizado] AS DATETIME) AS FIM_REALIZADO
        FROM STG_CITTATI_VIAGENS
        -- Lê da staging apenas a faixa necessária (-1 dia e +1 dia para cobrir as viagens da madrugada)
        WHERE [viagens.data] >= DATEADD(DAY, -1, @DATA_INICIO)
          AND [viagens.data] <= DATEADD(DAY, 1, @DATA_FIM)
    ),

    -- 4. Aplica corte operacional da madrugada (< 03:00)
    Viagens_Data_Operacional AS (
        SELECT
            *,
            CASE
                WHEN DATEPART(HOUR, INICIO_REALIZADO) < 3 
                THEN DATEADD(DAY, -1, [viagens.data])
                ELSE [viagens.data]
            END AS DATA_OPERACIONAL
        FROM Viagens_Datas_Tratadas
    )

    -- 5. Inserção controlada em lote do período selecionado
    INSERT INTO FATO_VIAGENS (
        ID_VIAGEM,
        ID_CALENDARIO,
        ID_LINHA,
        ID_GARAGEM,
        ID_VEICULO,
        ID_MOTORISTA,
        MATRICULA_MOTORISTA,
        DATA_OPERACIONAL,
        ATIVIDADE,
        STATUS_SAIDA,
        JUSTIFICATIVA,
        TABELA_OPERACIONAL,
        NR_TABELA,
        FAIXA_HORARIA,
        FAIXA_HORARIA_1H,
        ORDEM_HORARIO,
        SENTIDO_VIAGEM,
        RETORNO_OK,
        INICIO_PROGRAMADO,
        INICIO_REALIZADO,
        FIM_PROGRAMADO,
        FIM_REALIZADO,
        TEMPO_PROGRAMADO_MIN,
        TEMPO_REALIZADO_MIN,
        PARTIDAS_DIF_MIN,
        CHEGADA_DIF_MIN,
        SEQ_VIAGEM_VEICULO,
        SEQ_VIAGEM_MOTORISTA,
        TIPO_DIA_OPERACIONAL,
        KM_REALIZADO,
        MOTIVO_OCORRENCIA
    )
    SELECT
        -- CONVERT(..., 112) substitui FORMAT() para reduzir consumo de CPU/DTU
        CAST(CONVERT(VARCHAR(8), V.DATA_OPERACIONAL, 112) AS BIGINT) * 1000000 
            + ROW_NUMBER() OVER(PARTITION BY V.DATA_OPERACIONAL ORDER BY V.INICIO_REALIZADO) AS ID_VIAGEM,

        CAST(CONVERT(VARCHAR(8), V.DATA_OPERACIONAL, 112) AS INT) AS ID_CALENDARIO,
        L.ID_LINHA,
        G.ID_GARAGEM,
        VE.ID_VEICULO,
        M.ID_MOTORISTA,
        M.MATRICULA_MOTORISTA,
        V.DATA_OPERACIONAL,
        V.[viagens.atividade] AS ATIVIDADE,
        V.[viagens.statusSaida] AS STATUS_SAIDA,
        V.[viagens.justificativa] AS JUSTIFICATIVA,
        V.[viagens.tabela] AS TABELA_OPERACIONAL,

        TRY_CAST(
            CASE 
                WHEN LEN(V.[viagens.tabela]) > 1 THEN LEFT(V.[viagens.tabela], LEN(V.[viagens.tabela]) - 1)
                ELSE V.[viagens.tabela]
            END 
        AS INT) AS NR_TABELA,

        -- Faixa horária ampla com corte de viagens futuras e fusos (Porto Velho UTC-4 vs Demais UTC-3)
        CASE 
            WHEN (
                V.DATA_OPERACIONAL = CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
                AND CAST(V.INICIO_PROGRAMADO AS TIME) > CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS TIME)
            ) OR V.DATA_OPERACIONAL > CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
            THEN NULL
            WHEN CAST(V.INICIO_PROGRAMADO AS TIME) > '02:30:00' AND CAST(V.INICIO_PROGRAMADO AS TIME) <= '12:00:00' THEN '1. MANHÃ'
            WHEN CAST(V.INICIO_PROGRAMADO AS TIME) > '12:00:00' AND CAST(V.INICIO_PROGRAMADO AS TIME) <= '18:00:00' THEN '2. TARDE'
            ELSE '3. NOITE'
        END AS FAIXA_HORARIA,

        -- Faixa horária de 1 hora com ordenação alfabética iniciando às 04h
        CASE 
            WHEN (
                V.DATA_OPERACIONAL = CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
                AND CAST(V.INICIO_PROGRAMADO AS TIME) > CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS TIME)
            ) OR V.DATA_OPERACIONAL > CAST(CASE WHEN V.GARAGEM = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
            THEN NULL
            ELSE 
                CHAR(96 + (CASE WHEN DATEPART(HOUR, V.INICIO_PROGRAMADO) >= 4 THEN DATEPART(HOUR, V.INICIO_PROGRAMADO) - 3 ELSE DATEPART(HOUR, V.INICIO_PROGRAMADO) + 21 END))
                + '. '
                + RIGHT('0' + CAST(DATEPART(HOUR, V.INICIO_PROGRAMADO) AS VARCHAR(2)), 2) + ':00'
                + ' - '
                + RIGHT('0' + CAST((DATEPART(HOUR, V.INICIO_PROGRAMADO) + 1) % 24 AS VARCHAR(2)), 2) + ':00'
        END AS FAIXA_HORARIA_1H,

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
    LEFT JOIN VW_DIM_LINHA AS L ON V.[viagens.codAtendimento] = L.CODIGO_SISTEMA
    LEFT JOIN VM_DIM_GARAGEM AS G ON V.GARAGEM = G.NOME_GARAGEM
    LEFT JOIN VW_DIM_VEICULOS AS VE ON V.[viagens.veiculo] = VE.PREFIXO_VEICULO
    LEFT JOIN VW_DIM_MOTORISTA AS M ON V.[viagens.motorista] = M.MATRICULA_MOTORISTA
    LEFT JOIN DIM_FERIADOS AS F ON V.DATA_OPERACIONAL = F.DATA_FERIADO AND (V.GARAGEM = F.OPERACAO OR F.OPERACAO = 'TODOS')
    WHERE V.DATA_OPERACIONAL BETWEEN @DATA_INICIO AND @DATA_FIM;
END;
GO -- SEPARADOR OBRIGATÓRIO: Garante que a procedure termine aqui e os blocos abaixo rodem como script separado


SET NOCOUNT ON;

-- 1. Janela de processamento: 15 em 15 dias
DECLARE @DataInicioLote DATE = '2026-01-01';
DECLARE @DataFimTotal   DATE = CAST(GETDATE() AS DATE);
DECLARE @DataFimLote    DATE;

WHILE @DataInicioLote <= @DataFimTotal
BEGIN
    -- Calcula o fim do lote somando 14 dias (janela total de 15 dias)
    SET @DataFimLote = DATEADD(DAY, 14, @DataInicioLote);

    -- Trava para não ultrapassar a data atual no último ciclo
    IF @DataFimLote > @DataFimTotal
        SET @DataFimLote = @DataFimTotal;

    PRINT '------------------------------------------------------------';
    PRINT 'Executando lote: ' + CONVERT(VARCHAR(10), @DataInicioLote, 23) 
          + ' até ' + CONVERT(VARCHAR(10), @DataFimLote, 23);

    -- Executa a procedure no lote leve de 15 dias
    EXEC PRC_CARGA_FATO_VIAGENS 
        @DATA_INICIO = @DataInicioLote, 
        @DATA_FIM    = @DataFimLote;

    PRINT 'Lote concluído. Pausa de 10s para alívio do log de transações...';
    WAITFOR DELAY '00:00:10';

    -- Avança o ponteiro para o próximo ciclo de 15 dias
    SET @DataInicioLote = DATEADD(DAY, 1, @DataFimLote);
END;

PRINT '------------------------------------------------------------';
PRINT 'Carga histórica completa de 2026 finalizada!';

