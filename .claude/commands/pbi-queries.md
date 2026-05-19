---
name: pbi-queries
description: Extrai lineage real de um dashboard Power BI consultando data_quality.tables_in_dashboards_pbix no Databricks. Gera 07-queries-sql.md em _documentacao/ com queries SQL reais, camadas de dados e alertas bronze. Rodar antes de /pbi-documentar para documentação mais precisa.
---

# /pbi-queries — Extração de lineage SQL via Databricks

Executa `tools/Extract-QueryMetadata.ps1` para consultar a tabela de lineage no Databricks e gerar `07-queries-sql.md`.

## Uso

```
/pbi-queries [NomeDoDashboard]
```

Exemplos:
```
/pbi-queries Scorecard
/pbi-queries Daily-Sales
```

## O que este command faz

Invoca:
```powershell
.\tools\Extract-QueryMetadata.ps1 -Dashboard [NomeDoDashboard]
```

O script:
1. Conecta ao Databricks usando credenciais do `.env`
2. Consulta `data_quality.tables_in_dashboards_pbix` filtrando pelo dashboard
3. Extrai queries SQL reais e linhagem de tabelas por fonte
4. Classifica cada tabela por camada: `[D]` diamond, `[G]` gold, `[S]` silver, `[!]` bronze
5. Gera `dashboards/[Dashboard]/_documentacao/07-queries-sql.md`

## Pré-requisitos

- `.env` com `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_WAREHOUSE_ID`
- Se não existir, rodar: `.\tools\Setup-Env.ps1`
- O dashboard deve estar registrado em `data_quality.tables_in_dashboards_pbix`

## Output

```
dashboards/[Dashboard]/_documentacao/
└── 07-queries-sql.md    ← queries SQL reais + lineage de tabelas
```

## Workflow recomendado

```
/pbi-queries Scorecard    ← primeiro
/pbi-documentar Scorecard     ← usa 07-queries-sql.md automaticamente
```
