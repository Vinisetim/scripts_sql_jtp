DROP TABLE IF EXISTS dw.fato_viagens;

CREATE TABLE dw.fato_viagens (
    id_viagem BIGINT PRIMARY KEY,
    id_calendario INT,
    id_linha INT,
    id_garagem INT,
    id_veiculo INT,
    id_motorista INT,
    matricula_motorista VARCHAR(50),
    data_operacional DATE,
    atividade VARCHAR(100),
    status_saida VARCHAR(10),
    justificativa VARCHAR(500),
    tabela_operacional VARCHAR(50),
    nr_tabela INT,
    faixa_horaria VARCHAR(20),
    faixa_horaria_1h VARCHAR(30),
    ordem_horario INT,
    sentido_viagem VARCHAR(10),
    retorno_ok BIT,
    inicio_programado DATETIME,
    inicio_realizado DATETIME,
    fim_programado DATETIME,
    fim_realizado DATETIME,
    tempo_programado_min INT,
    tempo_realizado_min INT,
    partidas_dif_min INT,
    chegada_dif_min INT,
    seq_viagem_veiculo INT,
    seq_viagem_motorista INT,
    tipo_dia_operacional VARCHAR(20),
    km_realizado DECIMAL(10,2),
    motivo_ocorrencia VARCHAR(50)
);

-- Índice para acelerar filtros de data e relatórios temporais
CREATE NONCLUSTERED INDEX ix_fato_viagens_data ON dw.fato_viagens (data_operacional);