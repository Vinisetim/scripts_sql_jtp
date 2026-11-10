CREATE TABLE dw.dim_feriados (
    id_feriado INT IDENTITY(1,1) PRIMARY KEY,
    data_feriado DATE NOT NULL,
    nome_feriado VARCHAR(100),
    tipo_frota VARCHAR(20),
    operacao VARCHAR(50)
);
