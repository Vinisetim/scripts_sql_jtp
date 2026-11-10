
CREATE TABLE dw.dim_calendario(
    id_calendario INT PRIMARY KEY,
    data_completa DATE,
    ano INT,
    mes INT,
    dia INT,
    nome_mes VARCHAR(20),
    nome_abrev VARCHAR(5),
    trimestre INT,
    dia_semana INT, 
    nome_dia_semana VARCHAR(20),
    tipo_dia_padrao VARCHAR(15)
);

CREATE VIEW app.vw_dim_calendario AS
SELECT 
    id_calendario,
    data_completa,
    ano,
    mes,
    dia,
    nome_mes,
    nome_abrev,
    trimestre,
    dia_semana,
    nome_dia_semana,
    tipo_dia_padrao,
    CASE 
        WHEN data_completa <= CAST(DATEADD(HOUR, -3, GETDATE()) AS DATE) THEN 1 
        ELSE 0 
    END AS flg_passado
FROM dw.dim_calendario;
