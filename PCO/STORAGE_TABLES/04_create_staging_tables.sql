CREATE TABLE STG_BASE_KM(
    COD_ATENDIMENTO VARCHAR(20),
    KM_IDA DECIMAL(10,2),
    KM_VOLTA DECIMAL(10,2),
    KM_MORTO DECIMAL(10,2),
    DATA_REFERENCIA DATE,
    OPERACAO VARCHAR(50)
);

CREATE TABLE STG_CITTATI_VIAGENS(
    GARAGEM VARCHAR(50),
    [viagens.linha] VARCHAR(50),
    [viagens.codAtendimento] BIGINT,
    [viagens.nomeAtendimento] VARCHAR(100),
    [viagens.sentido]  VARCHAR(5), /*poderia ser um booleano pois o sentido ou é ida ou volta, mas para manter simples vou deixar como string*/
    [viagens.veiculo] INT, /*numero de 4 digitos para o registro do veiculo*/
    [viagens.motorista] INT, /*numero de 4 digitos para o registro do motorista*/
    [viagens.inicioProgramado]  VARCHAR(50), /*timestamp do inicio programado da viagem, precisa ser convertido para datetime*/
    [viagens.inicioRealizado]  VARCHAR(50), /*timestamp do fim programado da viagem, precisa ser convertido para datetime*/
    [viagens.fimProgramado]  VARCHAR(50), /*timestamp do fim programado da viagem, precisa ser convertido para datetime*/
    [viagens.fimRealizado] VARCHAR(50), /*timestamp do fim realizado da viagem, precisa ser convertido para datetime*/
    [viagens.data] DATE, /*data da viagem, já está em datetime*/
    [viagens.atividade] VARCHAR(100),
    [viagens.tabela] VARCHAR(5),
    [viagens.statusSaida] VARCHAR(5),
    [viagens.justificativa] VARCHAR(255),
    [retornoOK] BIT,
);

