CREATE VIEW VW_DIM_MOTORISTA AS
SELECT 
    -- 1. ROW_NUMBER(): A Window Function que gera a nossa Chave Primária (ID) na View
    ROW_NUMBER() OVER(ORDER BY [viagens.motorista]) AS ID_MOTORISTA,
    
    -- 2. A matrícula oficial do motorista
    [viagens.motorista] AS MATRICULA_MOTORISTA
    
FROM (
    -- 3. Subquery: Filtra a base gigante antes de numerar
    SELECT DISTINCT [viagens.motorista]
    FROM STG_CITTATI_VIAGENS
    WHERE [viagens.motorista] IS NOT NULL
) AS MotoristasUnicos;