# Scorecard - Business Performance — Overview

> **Modelo operacional de câmbio com análise de performance de negócio — GMV, Gross Revenue, Gross Profit, Operations, Spread e Customers com comparação período anterior (dia/mês/ano) via Calculation Group.**
> Documentação gerada por Claude Code + `/pbi-doc` em 08 mai 2026

**Arquivo:** `Scorecard - Business Performance.pbip`

---

## Métricas

| Métrica | Valor |
|---|---|
| Tabelas reais | **18** (excluindo auto-date geradas) |
| Medidas | **110** (aprox., distribuídas em Medidas + Month over month) |
| Relacionamentos | **6** |
| Colunas totais | **~210** |
| Tamanho .pbip | **~2.8 MB** (estimado pela soma dos .tmdl) |

---

## Inventário de tabelas

| Tabela | Tipo | Colunas | Medidas | Source |
|---|---|---|---|---|
| `f_operations` | Fato | ~85 | 0 | Databricks (gold.fact_operations via Native Query SQL) |
| `d_calendar` | Dimensão | 31 | 1 (`Last Working Day`) | Power Platform Dataflows (Workspace 5381...) |
| `d_bu` | Dimensão | 1 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `d_business_type` | Dimensão | 2 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `d_customer_type` | Dimensão | 1 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `d_event_type` | Dimensão | 2 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `d_segment` | Dimensão | 1 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `d_faq` | Dimensão | 4 | 0 | Power Platform Dataflows (Workspace 5381...) |
| `Medidas` | Tabela de medidas | 1 | ~85 medidas | Tabela estática (`"Medidas"`) |
| `Month over month` | Tabela de medidas | 2 | ~10 medidas | Calculation Group (calculada) |
| `p_timeframe` | Auxiliar | 4 | 0 | Tabela calculada (parameter table) |
| `p_dimension` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `p_dimension_01` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `p_dimension_02` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `p_dimension_03` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `p_dimension_04` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `p_choose_metric` | Auxiliar | 3 | 0 | Tabela calculada (parameter table) |
| `t_tabela` | Auxiliar | 3 | 0 | DATATABLE calculada (lista KPIs) |

> **Tipo:** Fato (1+ por modelo) · Dimensão (descreve fato) · Medidas (só hospeda DAX) · Aux (parameter table, calculated, etc.)

---

## Fontes de dados

- **Power Platform Dataflows** (workspace `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`) — todas as dimensões (d_bu, d_business_type, d_calendar, d_customer_type, d_event_type, d_faq, d_segment) são carregadas via `PowerPlatform.Dataflows(null)`. Os dataflow IDs são específicos por entidade.

- **Databricks** (`beetech-prod-analytics.cloud.databricks.com`) — a tabela fato `f_operations` é carregada via SQL nativo (`Value.NativeQuery`) direto no Databricks, consultando `gold.fact_operations` com um SELECT extenso que inclui joins em `gold.fact_customers`, `google_analytics.first_click_sessions`, `bronze.hubspot_partners`, `beecambio.*` e outras tabelas do data lake. Filtro base: `is_intercompany = false`, `is_ops_processed = true`, `processed_date >= '2023-01-01'`.

- **Tabelas calculadas / DATATABLE** — `p_timeframe`, `p_dimension`, `p_dimension_01` a `p_dimension_04`, `p_choose_metric` e `t_tabela` são definidas em DAX como tabelas calculadas (parameter tables), sem conexão externa.

> **Nota:** descrição inferida a partir de naming, colunas e fonte — não há `description:` declarado nas tabelas TMDL.

---

## Configurações relevantes do modelo

| Configuração | Valor |
|---|---|
| Culture | `pt-BR` |
| Source Query Culture | `pt-BR` |
| Auto Date/Time | **Desligado** (`__PBI_TimeIntelligenceEnabled = 0`) |
| Default PBI Datasource Version | `powerBI_V3` |
| Fast Combine | Habilitado |
| Legacy Redirects | Habilitado |
| Return Error Values as Null | Habilitado |
| Ferramentas de desenvolvimento ativas | CalcGroup, DaxQueryView_Desktop, DevMode |
| Compatibility Level | powerBI_V3 (nível padrão recente) |

---

## Próximas seções

- [01 · Tabelas](01-tabelas.md) — descrição + colunas tipadas + source M de cada tabela
- [02 · Medidas](02-medidas.md) — DAX completo + explicação PT de cada medida
- [03 · Relacionamentos](03-relacionamentos.md) — mapa visual + tabela detalhada
- [04 · Dependências](04-dependencias.md) — quem depende de quem entre as medidas

---

*XPERIUN · O Sistema Operacional dos Incomparáveis · `/pbi-doc`*
