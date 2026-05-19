# Scorecard - Business Performance — Fontes de Dados

> **Voltar pra:** [04 · Dependências](04-dependencias.md) · **Próxima:** [06 · Glossário de Negócio](06-glossario-negocio.md)

---

> ⚠️ **Alertas ativos neste dashboard:**
> - `f_operations` inclui JOINs em **3 tabelas bronze**: `bronze.hubspot_partners`, `bronze.beecambio_qualification`, `bronze.dcalendar` — dados brutos sem transformação DBT
> - `d_business_type` usa fontes **mistas: Athena (ODBC) + Databricks** — linhagem híbrida
> - `d_faq` vem de **Google Sheets** — fonte externa não gerenciada pelo time de dados

---

## Resumo das fontes

| Tabela | Tipo de Fonte | Fonte Original | Confiança | Alerta |
|--------|--------------|----------------|-----------|--------|
| `f_operations` | Databricks SQL | `gold.fact_operations` + 9 tabelas | 🟢 Alto | 3 JOINs em bronze |
| `d_bu` | Dataflow → Databricks | `beetech-prod-analytics` | 🟢 Alto | — |
| `d_business_type` | Dataflow → Athena + Databricks | Simba Athena + `beetech-prod-analytics` | 🟡 Médio | ⚠️ Fonte mista |
| `d_calendar` | Dataflow → Databricks | `beetech-prod-analytics` | 🟢 Alto | — |
| `d_customer_type` | Dataflow | A definir | — | — |
| `d_event_type` | Dataflow | A definir | — | — |
| `d_faq` | Dataflow → Google Sheets | Planilha Google externa | 🔴 Baixo | ⚠️ Fonte externa |
| `d_segment` | Dataflow → Databricks | `beetech-prod-analytics` | 🟢 Alto | — |
| `p_timeframe` | Tabela calculada (DAX) | — | — | — |
| `p_dimension`, `p_dimension_01–04` | Tabela calculada (DAX) | — | — | — |
| `p_choose_metric` | Tabela calculada (DAX) | — | — | — |
| `t_tabela` | DATATABLE (DAX) | — | — | — |
| `Medidas` | Tabela estática | — | — | — |
| `Month over month` | Calculation Group | — | — | — |

---

## Fonte 1 — Databricks · `gold.fact_operations`

**Tabela destino:** `f_operations`
**Camada:** `gold` 🟢
**Endpoint:** `beetech-prod-analytics.cloud.databricks.com`
**Protocolo:** Native Query via `Value.NativeQuery`

### Tabelas Databricks referenciadas

Query extraída de `data_quality.tables_in_dashboards_pbix` em 15/05/2026. SQL completo em [07-queries-sql.md](07-queries-sql.md).

| Tabela | Camada | Papel |
|--------|--------|-------|
| `gold.fact_operations` | 🟢 gold | Tabela fato principal — base do SELECT e de 4 CTEs |
| `gold.fact_customers` | 🟢 gold | JOIN left — dados de cliente (canal, cidade, estado, idade) |
| `gold.funnel_event` | 🟢 gold | JOIN left — data de aquisição do cliente |
| `gold.fast_instant_analysis` | 🟢 gold | JOIN left — flag de operação instantânea |
| `silver.customers` | 🟡 silver | JOIN left — CPF/CNPJ para match com prospecção |
| `bronze.dcalendar` | ⚠️ bronze | JOIN left — flags MTD e dias úteis por data |
| `bronze.hubspot_partners` | ⚠️ bronze | CTE + JOIN left — dados de parceiros diretos (prospecção) |
| `bronze.beecambio_qualification` | ⚠️ bronze | JOIN left — tipo de operação no onboarding |
| `beecambio.beecambio_tbl_customer` | [B] beecambio | CTE `origem_psu` — provider de cadastro |
| `beecambio.beecambio_tbl_customer_login_provider` | [B] beecambio | CTE `origem_psu` — provider do signup |
| `google_analytics.first_click_sessions` | externo | JOIN left — UTMs de first click |

> ⚠️ **Atenção:** 3 tabelas bronze na query de produção:
> - `bronze.dcalendar` — dimensão de calendário sem versão DBT equivalente declarada
> - `bronze.hubspot_partners` — parceiros Hubspot; verificar se existe versão `silver` ou `gold`
> - `bronze.beecambio_qualification` — onboarding qualificação; verificar com time Beecambio

### Modelo DBT correspondente

| Campo | Valor |
|-------|-------|
| Modelo DBT | `gold.fact_operations` |
| Detalhes no repositório DBT | Ver [`dbt-metadata/gold_models.md`](../../dbt-metadata/gold_models.md) |
| Documentação DBT completa | A definir — executar `/extrair-dbt-metadata` |

---

## Fonte 2 — Power BI Dataflows · Dimensões

**Tabelas destino:** `d_bu`, `d_business_type`, `d_calendar`, `d_customer_type`, `d_event_type`, `d_faq`, `d_segment`
**Workspace ID:** `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`
**Protocolo:** `PowerPlatform.Dataflows(null)`
**Metadados extraídos em:** 09/05/2026 via `tools/Get-DataflowMetadata.ps1`

### Dataflows identificados

| Tabela Power BI | Dataflow ID | Nome do Dataflow | Fonte Original | Refresh |
|----------------|-------------|-----------------|----------------|---------|
| `d_bu` | `d3c2d827-b84c-466b-9485-ee1b0ee58b79` | `bu` | Databricks | Sem agendamento |
| `d_business_type` | `a58daa91-b31a-4f5d-9e56-f4befa9050f0` | `business_type` | ⚠️ Athena (ODBC) + Databricks | Sem agendamento |
| `d_calendar` | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` | `dCalendar` | Databricks | Sem agendamento |
| `d_customer_type` | `ee7b4dce-a733-4365-9194-bfea34031f1a` | `customer_type` | A definir | Sem agendamento |
| `d_event_type` | `32502a54-a25e-49da-96b6-b9d541c6dc0b` | `event_type` | A definir | Sem agendamento |
| `d_faq` | `42e64d90-423f-411d-8a92-c386b16a2e43` | `faq_scorecard` | ⚠️ Google Sheets | Sem agendamento |
| `d_segment` | `61b71bc0-5ab5-45b6-91eb-a941dbaa9684` | `operation_segment` | Databricks | Sem agendamento |

### Detalhamento por Dataflow

#### d_bu — `d3c2d827-b84c-466b-9485-ee1b0ee58b79`

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `bu` |
| Entidade carregada | `bu` |
| Fonte original | Databricks — `beetech-prod-analytics.cloud.databricks.com` |
| Transformação local | `Table.SelectRows` → exclui `BU = "Presignups"` |
| Colunas carregadas | `BU` (string) |
| Refresh agendado | Sem agendamento configurado |

#### d_business_type — `a58daa91-b31a-4f5d-9e56-f4befa9050f0`

> ⚠️ **Fonte mista:** este Dataflow combina dados de **Athena (ODBC via Simba)** e **Databricks**. Linhagem híbrida — verificar qual entidade vem de cada fonte.

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `business_type` |
| Entidade carregada | `business_type` |
| Fonte original | Athena (`dsn=Simba Athena`) + Databricks (`beetech-prod-analytics`) |
| Transformação local | `Table.RemoveColumns` → remove coluna `bu` |
| Colunas carregadas | `index` (int), `Business Type` (string) |
| Refresh agendado | Sem agendamento configurado |

#### d_calendar — `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef`

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `dCalendar` |
| Entidade carregada | `dcalendar` |
| Fonte original | Databricks — `beetech-prod-analytics.cloud.databricks.com` |
| Transformações locais | 1. Adiciona `Fim do Mês` = `Date.EndOfMonth([Date Key])` · 2. Adiciona `last_day` (boolean) · 3. Filtra `year >= 2022` |
| Colunas carregadas | 30+ colunas (datas, flags de período: `m0`, `m1`, `mtd`, `d0`, `is_ytd`, `is_holiday`, `workday`, `last_workday`, etc.) |
| Nota | Dimensão de tempo rica — contém flags especializados para os cálculos do Calculation Group |
| Refresh agendado | Sem agendamento configurado |

#### d_customer_type — `ee7b4dce-a733-4365-9194-bfea34031f1a`

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `customer_type` |
| Entidade carregada | `customer_type` |
| Fonte original | A definir — API não retornou datasources |
| Transformações locais | Nenhuma — carga direta |
| Colunas carregadas | `Customer Type` (string) |
| Refresh agendado | Sem agendamento configurado |

#### d_event_type — `32502a54-a25e-49da-96b6-b9d541c6dc0b`

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `event_type` |
| Entidade carregada | `event_type` |
| Fonte original | A definir — API não retornou datasources |
| Transformação local | `Table.SelectRows` → mantém apenas `ACQUISITION` e `REPURCHASE` |
| Colunas carregadas | `event_type` (string), `Evento` (string — nome em PT) |
| Nota | ⚠️ Filtro intencional: outros tipos de evento existem no Dataflow mas são excluídos neste dashboard |
| Refresh agendado | Sem agendamento configurado |

#### d_faq — `42e64d90-423f-411d-8a92-c386b16a2e43`

> ⚠️ **Fonte externa:** este Dataflow carrega dados de uma **planilha Google Sheets** fora do ecossistema de dados gerenciado. Mudanças na planilha impactam diretamente o dashboard sem rastreabilidade no DBT.

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `faq_scorecard` |
| Entidade carregada | `Results` (nome diferente da tabela Power BI) |
| Fonte original | Google Sheets — `docs.google.com/spreadsheets/d/14hMkMKQY2dAKBORFqm7KGQuw1D8u9EqHPlHKE-uQBq4` |
| Transformações locais | Nenhuma |
| Colunas carregadas | `KPI` (string), `Explicação` (string), `Conta` (string), `Tipo` (string) |
| Nota | Tabela de FAQ/glossário exibida em página dedicada do relatório |
| Refresh agendado | Sem agendamento configurado |

#### d_segment — `61b71bc0-5ab5-45b6-91eb-a941dbaa9684`

| Campo | Valor |
|-------|-------|
| Nome do Dataflow | `operation_segment` |
| Entidade carregada | `operation_segment` |
| Fonte original | Databricks — `beetech-prod-analytics.cloud.databricks.com` |
| Transformações locais | Nenhuma — carga direta |
| Colunas carregadas | `operation_segment` (string) |
| Refresh agendado | Sem agendamento configurado |

### Pendências abertas

| Dataflow | Pendência |
|---|---|
| `d_customer_type` | Fonte original não retornada pela API — verificar no Power BI Service |
| `d_event_type` | Fonte original não retornada pela API — verificar no Power BI Service |
| `d_business_type` | Confirmar qual entidade vem do Athena vs. Databricks |
| Todos | Nenhum Dataflow tem refresh agendado — confirmar se atualização é manual ou via Airflow |

---

## Fonte 3 — Tabelas calculadas (DAX)

As tabelas abaixo são definidas inteiramente em DAX dentro do modelo Power BI — sem conexão externa.

| Tabela | Tipo | Propósito |
|--------|------|-----------|
| `p_timeframe` | Parameter table | Seletor de período (Dia / Mês / Ano) — controla o `Calculation Group` |
| `p_dimension` | Parameter table | Seletor de dimensão padrão para drilldown |
| `p_dimension_01` a `p_dimension_04` | Parameter tables | Seletores de dimensão por visual específico |
| `p_choose_metric` | Parameter table | Seletor de métrica para visuais dinâmicos |
| `t_tabela` | DATATABLE | Lista de KPIs exibida em tabelas do relatório |
| `Medidas` | Tabela estática | Hospeda todas as medidas DAX do modelo (sem dados) |
| `Month over month` | Calculation Group | Define os cálculos de comparação período anterior (MoM, YoY, MTD, etc.) |

---

## Linhagem resumida

```
AWS (dados brutos)
  └─► Databricks bronze  ─────────────────────────────────────────────────────────┐
        └─► Databricks silver (DBT)                                               │ JOINs em bronze:
              └─► Databricks gold (DBT)                                           │   dcalendar (⚠️)
                    └─► f_operations (Power BI — tabela fato)  ◄──────────────────┤   hubspot_partners (⚠️)
                                                                                  └── beecambio_qualification (⚠️)

Databricks gold (adicionais)
  gold.fact_customers ──────────────────────────────────────────────────────────────► f_operations (JOIN)
  gold.funnel_event ────────────────────────────────────────────────────────────────► f_operations (JOIN — data aquisição)
  gold.fast_instant_analysis ───────────────────────────────────────────────────────► f_operations (JOIN — flag instant)

Databricks silver
  silver.customers ─────────────────────────────────────────────────────────────────► f_operations (JOIN — CPF/CNPJ)

Beecambio (banco de dados próprio)
  beecambio_tbl_customer + beecambio_tbl_customer_login_provider ──────────────────► f_operations (CTE origem_psu)

Google Analytics
  first_click_sessions ────────────────────────────────────────────────────────────► f_operations (JOIN — UTMs first click)

Databricks (beetech-prod-analytics)
  └─► Power BI Dataflow (Workspace 5381a7f5...)
        ├─► d_bu          (bu · filtra Presignups)
        ├─► d_calendar    (dCalendar · +cols calculadas, year>=2022)
        └─► d_segment     (operation_segment)

Athena (Simba ODBC) + Databricks  ⚠️ fonte mista
  └─► Power BI Dataflow
        └─► d_business_type (business_type · remove col bu)

Google Sheets (externo)  ⚠️ fonte não gerenciada
  └─► Power BI Dataflow
        └─► d_faq         (faq_scorecard · entidade: Results)

Fonte A definir
  └─► Power BI Dataflow
        ├─► d_customer_type (customer_type)
        └─► d_event_type  (event_type · filtra ACQUISITION/REPURCHASE)

DAX / Tabelas calculadas (sem fonte externa)
  └─► p_timeframe, p_dimension, p_dimension_01–04, p_choose_metric
      t_tabela, Medidas, Month over month
```

---

*Documentado por Claude Code + `/pbi-documentacao` · Dataflows: 09/05/2026 · SQL real (Extract-QueryMetadata.ps1): 15/05/2026*
