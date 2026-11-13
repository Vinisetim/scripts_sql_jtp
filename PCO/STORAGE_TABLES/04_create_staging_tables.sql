CREATE TABLE stg.stg_base_km(
    cod_atendimento VARCHAR(20),
    km_ida DECIMAL(10,2),
    km_volta DECIMAL(10,2),
    km_morto DECIMAL(10,2),
    data_referencia DATE,
    operacao VARCHAR(50)
);


CREATE TABLE stg.stg_cittati_viagens(
    garagem VARCHAR(50),
    viagens_linha VARCHAR(50),
    viagens_cod_atendimento BIGINT,
    viagens_nome_atendimento VARCHAR(100),
    viagens_sentido VARCHAR(5), /*poderia ser um booleano pois o sentido ou é ida ou volta, mas para manter simples vou deixar como string*/
    viagens_veiculo INT, /*numero de 4 digitos para o registro do veiculo*/
    viagens_motorista INT, /*numero de 4 digitos para o registro do motorista*/
    viagens_inicio_programado  VARCHAR(50), /*timestamp do inicio programado da viagem, precisa ser convertido para datetime*/
    viagens_inicio_realizado  VARCHAR(50), /*timestamp do fim programado da viagem, precisa ser convertido para datetime*/
    viagens_fim_programado  VARCHAR(50), /*timestamp do fim programado da viagem, precisa ser convertido para datetime*/
    viagens_fim_realizado VARCHAR(50), /*timestamp do fim realizado da viagem, precisa ser convertido para datetime*/
    viagens_data DATE, /*data da viagem, já está em datetime*/
    viagens_atividade VARCHAR(100),
    viagens_tabela VARCHAR(5),
    viagens_status_saida VARCHAR(5),
    viagens_justificativa VARCHAR(255),
    retorno_ok BIT,
);


