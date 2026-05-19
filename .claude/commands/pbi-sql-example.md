---
name: pbi-sql-example
description: Adiciona um novo par pergunta→SQL validado ao store sql-examples/ no formato YAML. Fluxo interativo: coleta pergunta em PT, SQL validado, gera variantes automaticamente e normaliza o SQL (remove prod., LIMIT 1000, backticks). Use para registrar queries validadas para uso pelo NL2SQL.
---

# /pbi-sql-example — Adicionar exemplo SQL validado

Invoca a skill `pbi-sql-examples` para registrar um novo par pergunta→SQL em `sql-examples/`.

## Uso

```
/pbi-sql-example
```

Ou com a pergunta como argumento:
```
/pbi-sql-example "Qual o GMV diário do mês atual por BU?"
```

## O que este command faz

Carrega e executa a skill `pbi-sql-examples`. A skill:

1. Coleta (ou usa o argumento): pergunta em PT-BR
2. Coleta o SQL validado (já testado no Databricks)
3. Gera automaticamente 3 variantes da pergunta em PT-BR
4. Extrai `tables_used` automaticamente do SQL
5. Sugere `notes` com regras de negócio obrigatórias (is_ops_processed, FxaaS, event_sequence)
6. Gera filename baseado na pergunta (lowercase, sem acentos, max 50 chars)
7. Exibe preview do YAML antes de salvar
8. Salva em `sql-examples/[nome].yaml` (estrutura **flat** — sem subdiretórios)

## Normalizações automáticas

- `prod.gold.table` → `gold.table`
- `prod.silver.table` → `silver.table`
- Remove `LIMIT 1000` (padrão Genie)
- Remove backticks desnecessários

## Formato do YAML gerado

```yaml
question_variants:
  - "[pergunta original]"
  - "[variante 1]"
  - "[variante 2]"
  - "[variante 3]"
sql: |
  [SQL normalizado]
tables_used: [gold.fact_operations, ...]
notes: "[regras de negócio, filtros obrigatórios]"
validated_by: equipe-analytics
validated_date: YYYY-MM-DD
```

## Regras de estrutura

- Arquivos sempre em `sql-examples/` (flat — sem subdiretórios)
- Sempre incluir `is_ops_processed=TRUE` e `is_intercompany=FALSE` em queries de fatos
- Para presignups: incluir FxaaS exclusion (`email NOT LIKE '%fxaas%'`)
- Para funnel_event: sempre `event_sequence=1` no primeiro evento
