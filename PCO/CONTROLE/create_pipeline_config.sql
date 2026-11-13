-- Criação da tabela de configuração de cargas no schema controle
CREATE TABLE controle.tb_pipeline_config (
    id_config INT IDENTITY(1,1) PRIMARY KEY,
    dominio_negocio VARCHAR(50) NOT NULL,      -- Ex: 'CCO'
    sistema_origem VARCHAR(50) NOT NULL,       -- Ex: 'cittati'
    container_lake VARCHAR(50) NOT NULL,       -- Ex: 'treated'
    caminho_lake VARCHAR(255) NOT NULL,        -- Ex: 'cittati/viagens/ano=2026/mes=11'
    nome_arquivo VARCHAR(100) NULL,            -- Opcional (NULL lê a pasta toda)
    schema_destino VARCHAR(50) NOT NULL,       -- Ex: 'stg'
    tabela_destino VARCHAR(100) NOT NULL,      -- Ex: 'stg_cittati_viagens'
    fl_truncate_antes BIT NOT NULL DEFAULT 1,  -- 1 = Limpa staging antes de carregar
    fl_ativo BIT NOT NULL DEFAULT 1,           -- 1 = Ativo no loop, 0 = Ignorado
    dthr_ultima_carga DATETIME2 NULL
);  


TRUNCATE TABLE controle.tb_pipeline_config;

-- Inserindo as parametrizações estáticas
INSERT INTO controle.tb_pipeline_config (
    dominio_negocio, 
    sistema_origem, 
    container_lake, 
    caminho_lake, 
    nome_arquivo, 
    schema_destino, 
    tabela_destino, 
    fl_truncate_antes, 
    fl_ativo
)
VALUES 
-- 1. Carga da Base KM
('CCO', 'base_km', 'treated', 'CITTATI/KM', 'km_*_', 'stg', 'stg_base_km', 1, 1),

-- 2. Carga de Viagens Cittati
('CCO', 'cittati', 'treated', 'CITTATI/VIAGENS', 'cittati_viagens_*_', 'stg', 'stg_cittati_viagens', 1, 1);
