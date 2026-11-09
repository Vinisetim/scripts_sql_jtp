Pipelines:
├── 00_Master/                   <-- Pipelines controladoras que orquestram a cadeia geral
│     └── pl_master_ingestaoGeral
├── 01_Ingestao_Lake/            <-- Cargas entre origens externas e o Data Lake
│     ├── Cittati/
│     ├── Pontotel/
│     └── Praxio/
├── 02_Carga_SQL/                <-- Movimentação do Lake para Staging/DW no Azure SQL
│     ├── CCO/
│     ├── Contratos/
│     └── Gente_e_Gestao/
└── 99_Manutencao/               <-- Tarefas utilitárias, testes e expurgo de logs
      └── pl_util_limpezaTemporarios

Datasets:
├── Data_Lake/                   <-- Datasets parametrizados do ADLS Gen2 (Parquet, Json, Csv)
└── SQL_Server/                  <-- Datasets parametrizados do banco relacional