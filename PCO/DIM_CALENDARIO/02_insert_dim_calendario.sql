DECLARE @DataAtual Date = '2024-01-01';
DECLARE @DataFinal Date = '2030-12-01';

WHILE @DataAtual <= @DataFinal
BEGIN 
    INSERT INTO dw.dim_calendario(
        id_calendario, data_completa, ano, mes, dia,
        nome_mes, nome_abrev, trimestre,dia_semana,
        nome_dia_semana,tipo_dia_padrao
    )
    VALUES(
        CAST(FORMAT(@DataAtual, 'yyyyMMdd') AS INT),
        @DataAtual,
        YEAR(@DataAtual),
        MONTH(@DataAtual),
        DAY(@DataAtual),
        UPPER(FORMAT(@DataAtual, 'MMMM', 'pt-BR')),
        UPPER(LEFT(FORMAT(@DataAtual, 'MMMM', 'pt-BR'), 3)),
        DATEPART(QUARTER, @DataAtual),
        DATEPART(WEEKDAY, @DataAtual),
        UPPER(FORMAT(@DataAtual, 'dddd', 'pt-BR')),

        CASE 
            WHEN DATEPART(WEEKDAY, @DataAtual) = 1 THEN 'DOMINGO'
            WHEN DATEPART(WEEKDAY, @DataAtual) = 7 THEN 'SÁBADO'
            ELSE 'DIA ÚTIL'
        END    
    );
    SET @DataAtual = DATEADD(DAY, 1, @DataAtual);
END;
