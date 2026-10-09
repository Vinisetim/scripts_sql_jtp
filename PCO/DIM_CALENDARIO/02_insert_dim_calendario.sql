DECLARE @DataAtual Date = '2024-01-01';
DECLARE @DataFinal Date = '2030-12-01';

WHILE @DataAtual <= @DataFinal
BEGIN 
    INSERT INTO DIM_CALENDARIO(
        ID_CALENDARIO, DATA_COMPLETA, ANO, MES, DIA,
        NOME_MES, NOME_ABREV, TRIMESTRE,DIA_SEMANA,
        NOME_DIA_SEMANA,TIPO_DIA_PADRAO
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
