CREATE VIEW app.vw_dim_motorista AS
SELECT 
    -- 1. ROW_NUMBER(): A Window Function que gera a nossa Chave Primária (ID) na View
    ROW_NUMBER() OVER(ORDER BY [viagens_motorista]) AS id_motorista,
    
    -- 2. A matrícula oficial do motorista
    [viagens_motorista] AS matricula_motorista
    
FROM (
    -- 3. Subquery: Filtra a base gigante antes de numerar
    SELECT DISTINCT [viagens_motorista]
    FROM stg.stg_cittati_viagens
    WHERE [viagens_motorista] IS NOT NULL
) AS motoristas_unicos;