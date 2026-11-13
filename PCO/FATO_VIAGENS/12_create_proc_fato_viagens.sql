CREATE OR ALTER PROCEDURE dw.sp_carga_fato_viagens
    @dt_inicio DATE = NULL,
    @dt_fim    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Definição dinâmica do período de processamento
    IF @dt_inicio IS NULL
        SET @dt_inicio = CAST(DATEADD(DAY, -3, GETDATE()) AS DATE);

    IF @dt_fim IS NULL
        SET @dt_fim = CAST(GETDATE() AS DATE);

    -- 2. Limpeza pontual (idempotência)
    DELETE FROM dw.fato_viagens 
    WHERE data_operacional BETWEEN @dt_inicio AND @dt_fim;

    -- 3. CTE de tratamento com filtro antecipado de leitura no schema STG
    -- Correção: Agora apontamos para viagens_inicio_programado e viagens_data
    WITH viagens_datas_tratadas AS (
        SELECT
            *,
            TRY_CAST(viagens_inicio_programado AS DATETIME) AS dthr_inicio_prog,
            TRY_CAST(viagens_inicio_realizado AS DATETIME) AS dthr_inicio_real,
            TRY_CAST(viagens_fim_programado AS DATETIME) AS dthr_fim_prog,
            TRY_CAST(viagens_fim_realizado AS DATETIME) AS dthr_fim_real
        FROM stg.stg_cittati_viagens
        WHERE viagens_data >= DATEADD(DAY, -1, @dt_inicio)
          AND viagens_data <= DATEADD(DAY, 1, @dt_fim)
    ),

    -- 4. Aplica corte operacional da madrugada (< 03:00)
    viagens_data_operacional AS (
        SELECT
            *,
            CASE
                WHEN DATEPART(HOUR, dthr_inicio_real) < 3 
                THEN DATEADD(DAY, -1, viagens_data)
                ELSE viagens_data
            END AS data_operacional
        FROM viagens_datas_tratadas
    )

    -- 5. Inserção no schema DW
    INSERT INTO dw.fato_viagens (
        id_viagem,
        id_calendario,
        id_linha,
        id_garagem,
        id_veiculo,
        id_motorista,
        matricula_motorista,
        data_operacional,
        atividade,
        status_saida,
        justificativa,
        tabela_operacional,
        nr_tabela,
        faixa_horaria,
        faixa_horaria_1h,
        ordem_horario,
        sentido_viagem,
        retorno_ok,
        inicio_programado,
        inicio_realizado,
        fim_programado,
        fim_realizado,
        tempo_programado_min,
        tempo_realizado_min,
        partidas_dif_min,
        chegada_dif_min,
        seq_viagem_veiculo,
        seq_viagem_motorista,
        tipo_dia_operacional,
        km_realizado,
        motivo_ocorrencia
    )
    SELECT
        CAST(CONVERT(VARCHAR(8), v.data_operacional, 112) AS BIGINT) * 1000000 
            + ROW_NUMBER() OVER(PARTITION BY v.data_operacional ORDER BY v.dthr_inicio_real) AS id_viagem,

        CAST(CONVERT(VARCHAR(8), v.data_operacional, 112) AS INT) AS id_calendario,
        l.id_linha,
        g.id_garagem,
        ve.id_veiculo,
        m.id_motorista,
        m.matricula_motorista,
        v.data_operacional,
        v.viagens_atividade,
        v.viagens_status_saida,
        v.viagens_justificativa,
        v.viagens_tabela,

        -- Correção: Apontamos para v.viagens_tabela
        TRY_CAST(
            CASE 
                WHEN LEN(v.viagens_tabela) > 1 THEN LEFT(v.viagens_tabela, LEN(v.viagens_tabela) - 1)
                ELSE v.viagens_tabela
            END 
        AS INT) AS nr_tabela,

        CASE 
            WHEN (
                v.data_operacional = CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
                AND CAST(v.dthr_inicio_prog AS TIME) > CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS TIME)
            ) OR v.data_operacional > CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
            THEN NULL
            WHEN CAST(v.dthr_inicio_prog AS TIME) > '02:30:00' AND CAST(v.dthr_inicio_prog AS TIME) <= '12:00:00' THEN '1. MANHÃ'
            WHEN CAST(v.dthr_inicio_prog AS TIME) > '12:00:00' AND CAST(v.dthr_inicio_prog AS TIME) <= '18:00:00' THEN '2. TARDE'
            ELSE '3. NOITE'
        END AS faixa_horaria,

        CASE 
            WHEN (
                v.data_operacional = CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
                AND CAST(v.dthr_inicio_prog AS TIME) > CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS TIME)
            ) OR v.data_operacional > CAST(CASE WHEN v.garagem = 'PORTO VELHO' THEN DATEADD(HOUR, -4, GETDATE()) ELSE DATEADD(HOUR, -3, GETDATE()) END AS DATE)
            THEN NULL
            ELSE 
                CHAR(96 + (CASE WHEN DATEPART(HOUR, v.dthr_inicio_prog) >= 4 THEN DATEPART(HOUR, v.dthr_inicio_prog) - 3 ELSE DATEPART(HOUR, v.dthr_inicio_prog) + 21 END))
                + '. '
                + RIGHT('0' + CAST(DATEPART(HOUR, v.dthr_inicio_prog) AS VARCHAR(2)), 2) + ':00'
                + ' - '
                + RIGHT('0' + CAST((DATEPART(HOUR, v.dthr_inicio_prog) + 1) % 24 AS VARCHAR(2)), 2) + ':00'
        END AS faixa_horaria_1h,

        CASE 
            WHEN DATEPART(HOUR, v.dthr_inicio_prog) >= 4 THEN DATEPART(HOUR, v.dthr_inicio_prog) - 3
            ELSE DATEPART(HOUR, v.dthr_inicio_prog) + 21
        END AS ordem_horario,

        -- Correção: Apontamos para v.viagens_sentido
        CASE 
            WHEN v.viagens_sentido = 'I' THEN 'IDA'
            WHEN v.viagens_sentido = 'V' THEN 'VOLTA'
            ELSE v.viagens_sentido
        END AS sentido_viagem,

        v.retorno_ok,
        v.dthr_inicio_prog,
        v.dthr_inicio_real,
        v.dthr_fim_prog,
        v.dthr_fim_real,

        DATEDIFF(MINUTE, v.dthr_inicio_prog, v.dthr_fim_prog) AS tempo_programado_min,
        DATEDIFF(MINUTE, v.dthr_inicio_real, v.dthr_fim_real) AS tempo_realizado_min,
        DATEDIFF(MINUTE, v.dthr_inicio_prog, v.dthr_inicio_real) AS partidas_dif_min,
        DATEDIFF(MINUTE, v.dthr_fim_prog, v.dthr_fim_real) AS chegada_dif_min,

        -- Correção: Apontamos para v.viagens_veiculo
        ROW_NUMBER() OVER(
            PARTITION BY v.data_operacional, v.viagens_veiculo
            ORDER BY v.dthr_inicio_real ASC
        ) AS seq_viagem_veiculo,

        -- Correção: Apontamos para v.viagens_motorista
        ROW_NUMBER() OVER(
            PARTITION BY v.data_operacional, v.viagens_motorista
            ORDER BY v.dthr_inicio_real ASC
        ) AS seq_viagem_motorista,

        COALESCE(
            f.tipo_frota,
            CASE (DATEPART(WEEKDAY, v.data_operacional))
                WHEN 1 THEN 'DOMINGO'
                WHEN 7 THEN 'SÁBADO'
                ELSE 'DIA ÚTIL'
            END
        ) AS tipo_dia_operacional,

        CASE 
            WHEN v.viagens_sentido = 'I' THEN ISNULL(l.km_previsto_ida, 0.00)
            WHEN v.viagens_sentido = 'V' THEN ISNULL(l.km_previsto_volta, 0.00)
            ELSE 0
        END AS km_realizado,

        -- Correção: Apontamos para v.viagens_justificativa no regex do LIKE
        CASE 
            WHEN UPPER(v.viagens_justificativa) LIKE '%ABSENTEÍSMO%' THEN 'ABSENTEÍSMO'
            WHEN UPPER(v.viagens_justificativa) LIKE '%BLOQUEIO%' THEN 'BLOQUEIO'
            WHEN UPPER(v.viagens_justificativa) LIKE '%NATURAIS%' THEN 'FEN NATURAIS'
            WHEN UPPER(v.viagens_justificativa) LIKE '%GREVE%' THEN 'GREVE'
            WHEN UPPER(v.viagens_justificativa) LIKE '%GPS%' OR UPPER(v.viagens_justificativa) LIKE '%GPRS%' THEN 'GPS/GPRS'
            WHEN UPPER(v.viagens_justificativa) LIKE '%RA %' OR UPPER(v.viagens_justificativa) LIKE '%SOS%' OR UPPER(v.viagens_justificativa) LIKE '%FALTA DE CARRO%' THEN 'MANUTENÇÃO/QUEBRA'
            WHEN UPPER(v.viagens_justificativa) LIKE '%REMANEJAMENTO DE OPERADOR%' THEN 'REMAN OPERADOR'
            WHEN UPPER(v.viagens_justificativa) LIKE '% RO %' OR UPPER(v.viagens_justificativa) LIKE '%RO-%' OR UPPER(v.viagens_justificativa) LIKE 'RO %' THEN 'RO'
            WHEN UPPER(v.viagens_justificativa) LIKE '%SERVIÇO EXTERNO%' THEN 'SERV EXTERNO'
            WHEN UPPER(v.viagens_justificativa) LIKE '%INSUFICIENTE%' THEN 'TEMPO INSUFICIENTE'
            WHEN UPPER(v.viagens_justificativa) LIKE '%CONGESTIONADO%' THEN 'TRANS CONGEST'
            WHEN UPPER(v.viagens_justificativa) LIKE '%VISTORIA%' THEN 'VISTORIA'
            WHEN v.viagens_justificativa IS NOT NULL AND v.viagens_justificativa != '' THEN 'OUTROS'
            ELSE NULL
        END AS motivo_ocorrencia

    FROM viagens_data_operacional AS v
    -- Correção: Join de chaves naturais usando a coluna viagens_cod_atendimento
    LEFT JOIN app.vw_dim_linha AS l ON v.viagens_cod_atendimento = l.codigo_sistema
    LEFT JOIN app.vw_dim_garagem AS g ON v.garagem = g.nome_garagem
    LEFT JOIN app.vw_dim_veiculos AS ve ON v.viagens_veiculo = ve.prefixo_veiculo
    LEFT JOIN app.vw_dim_motorista AS m ON v.viagens_motorista = m.matricula_motorista
    LEFT JOIN dw.dim_feriados AS f ON v.data_operacional = f.data_feriado AND (v.garagem = f.operacao OR f.operacao = 'TODOS')
    WHERE v.data_operacional BETWEEN @dt_inicio AND @dt_fim;
END;
GO

SET NOCOUNT ON;

-- 1. Janela de processamento: 15 em 15 dias para o teste de carga
DECLARE @dt_inicio_lote DATE = '2026-01-01';
DECLARE @dt_fim_total   DATE = CAST(GETDATE() AS DATE);
DECLARE @dt_fim_lote    DATE;

WHILE @dt_inicio_lote <= @dt_fim_total
BEGIN
    -- Calcula o fim do lote somando 14 dias (janela total de 15 dias)
    SET @dt_fim_lote = DATEADD(DAY, 14, @dt_inicio_lote);

    -- Trava para não ultrapassar a data atual no último ciclo
    IF @dt_fim_lote > @dt_fim_total
        SET @dt_fim_lote = @dt_fim_total;

    PRINT '------------------------------------------------------------';
    PRINT 'Executando lote: ' + CONVERT(VARCHAR(10), @dt_inicio_lote, 23) 
          + ' até ' + CONVERT(VARCHAR(10), @dt_fim_lote, 23);

    -- Executa a procedure recém-criada apontando para o schema dw
    EXEC dw.sp_carga_fato_viagens 
        @dt_inicio = @dt_inicio_lote, 
        @dt_fim    = @dt_fim_lote;

    PRINT 'Lote concluído. Pausa de 10s para alívio do log de transações...';
    WAITFOR DELAY '00:00:10';

    -- Avança o ponteiro para o próximo ciclo de 15 dias
    SET @dt_inicio_lote = DATEADD(DAY, 1, @dt_fim_lote);
END;

PRINT '------------------------------------------------------------';
PRINT 'Carga histórica completa de 2026 finalizada!';
