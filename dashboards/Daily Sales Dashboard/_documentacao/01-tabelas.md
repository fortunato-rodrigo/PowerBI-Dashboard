# Daily Sales Dashboard — Inventário de Tabelas

## Resumo

| Categoria | Quantidade |
|-----------|-----------|
| Tabelas fato | 6 |
| Tabelas dimensão | 7 (todas via Dataflow) |
| Tabelas auxiliares/seletores | 3 |
| Tabela de medidas | 1 |
| Tabela utilitária | 1 |
| **Total** | **18** |

---

## Tabelas Fato

### f_daily_sales

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (principal) |
| **Camada** | 🟢 gold |
| **Fonte** | `gold.daily_sales` (Databricks) |
| **Granularidade** | Dia × BU × Business Type × Event Type |
| **Janela** | `date_key >= '2024-01-01'` |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_key` | Date | Data da venda |
| `bu` | String | Unidade de negócio |
| `business_type` | String | Tipo de negócio (B2C, B2B, etc.) |
| `event_type` | String | Tipo de evento |
| `gross_revenue` | Currency | Receita bruta acumulada no dia |
| `meta_gross_revenue` | Currency | Meta de receita para o dia |
| `projecao_gross_revenue` | Currency | Projeção de receita ao final do mês |
| `gross_revenue_diario` | Currency | Receita diária (não acumulada) |
| `operations` | Integer | Número de operações acumuladas |
| `meta_operations` | Double | Meta de operações para o dia |
| `projecao_operations` | Double | Projeção de operações ao final do mês |
| `ops_diaria` | Double | Operações do dia (não acumuladas) |
| `gmv` | Currency | GMV acumulado no dia |
| `meta_gmv` | Currency | Meta de GMV para o dia |
| `projecao_gmv` | Currency | Projeção de GMV ao final do mês |
| `gmv_diario` | Currency | GMV do dia (não acumulado) |

**Observação:** Esta tabela já vem com os valores de meta e projeção integrados — são calculados upstream na camada gold.

---

### f_gold_ops

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (operações em tempo real) |
| **Camada** | 🟢 gold |
| **Fonte** | `gold.fact_operations` (Databricks) |
| **Filtros** | `is_ops_processed = true`, `is_intercompany = false`, `processed_date >= '2024-01-01'` |
| **Granularidade** | Operação × BU × Business Type × Customer Type × Segment × Hora |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `customer_type` | String | Tipo de cliente (PF/PJ) |
| `operation_date` | Date | Data de processamento |
| `processing_hour` | Integer | Hora do processamento (0–23) |
| `event_type` | String | Tipo de evento (ACQUISITION / REPURCHASE) |
| `bu` | String | Unidade de negócio |
| `business_type` | String | Tipo de negócio |
| `operation_segment` | String | Segmento da operação |
| `operations` | Integer | Contagem de operações |
| `gmv` | Currency | Volume bruto |
| `gross_revenue` | Currency | Receita bruta |
| `gross_revenue_treasury` | Currency | Receita de tesouraria (base do PNL) |
| `cost_bank_take` | Currency | Custo do banco parceiro |
| `real_message_cost` | Currency | Custo de mensageria |

**Observação:** Usada para Intraday e para as medidas de PNL, Custo de Mensageria e Take do Banco. Complementa `f_daily_sales` quando há dados do dia atual.

---

### f_daily_sales_psu

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (Presignups e metas de PSU) |
| **Camada** | 🟢 gold / ⚠️ bronze |
| **Fontes** | `gold.daily_sales_psu` + `google_analytics.last_click_sessions` + `bronze.beecambio_customer` |
| **Granularidade** | Dia × Canal × Customer Type × Event Type |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_key` | Date | Data |
| `customer_type` | String | Tipo de cliente (PF/PJ) |
| `event_type` | String | Tipo de evento (PRESIGNUP) |
| `canal` | String | Canal de aquisição (UTM) |
| `goal_psu` | Double | Meta de Presignups para o dia |
| `realizado_psu` | Integer | Presignups realizados |

> ⚠️ **BRONZE:** A query usa `LEFT JOIN bronze.beecambio_customer` para obter dados de PSU. Dados bronze sem transformação DBT — verificar confiabilidade com o time de dados.

---

### f_investimentos

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (investimento em mídia paga) |
| **Camada** | ⚠️ bronze |
| **Fonte** | `bronze.paid_media_investments` |
| **Granularidade** | Dia × Customer Type (alocação proporcional 58,22% PF / 41,78% PJ) |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_key` | Date | Data |
| `customer_type` | String | PF ou PJ (alocação artificial) |
| `investimento` | Currency | Custo de mídia paga em R$ |

> ⚠️ **BRONZE:** Fonte direta de `bronze.paid_media_investments`. Dados brutos de custos de mídia. A divisão 58,22% PF / 41,78% PJ é hardcoded na query — pode desatualizar.

---

### f_wallet

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (transações da Conta Global/Wallet) |
| **Camada** | ❓ explore (não-padrão) |
| **Fonte** | `explore.wallet_transactions` |
| **Filtro** | `declined_reason = 'Not declined'` |
| **Granularidade** | Dia × (BU=Wallet, customer_type=PF, business_type=Wallet EUR, segment=Conta Global) |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_key` | Date | Data da transação |
| `bu` | String | Fixo: "Wallet" |
| `customer_type` | String | Fixo: "PF" |
| `event_type` | String | Fixo: "Transações do Cartão" |
| `business_type` | String | Fixo: "Wallet EUR" |
| `operation_segment` | String | Fixo: "Conta Global" |
| `transactions` | Integer | Número de transações |
| `gross_revenue` | Currency | Receita bruta da Wallet |

> ❓ **LAYER NÃO-PADRÃO:** O schema `explore` não faz parte da hierarquia padrão bronze/silver/gold/diamond. Verificar com o time de dados qual é o nível de confiança e se existirá equivalente em gold.

---

### f_pnl_tesouraria

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (metas de PNL por BU) |
| **Camada** | ⚠️ bronze |
| **Fonte** | `bronze.dcalendar` (CROSS JOIN com metas hardcoded) |
| **Granularidade** | Dia × BU |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_key` | Date | Data |
| `bu` | String | Unidade de negócio |
| `meta_pnl` | Currency | Meta de PNL alocada proporcionalmente ao dia |

> ⚠️ **BRONZE:** Usa `bronze.dcalendar` apenas como tabela de calendário para distribuição proporcional das metas. As metas em si são hardcoded na query (ex: Plataforma=408k/ano 2025, Premium+COMEX+...=141.666,67/5 por mês 2026). Qualquer mudança de meta exige edição da query M.

---

## Tabelas Dimensão (todas via Dataflow)

Todas as dimensões abaixo são alimentadas por Power BI Dataflows do workspace `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`.

| Tabela PBI | Nome do Dataflow | Dataflow ID | Entidade | Coluna principal |
|-----------|-----------------|-------------|----------|-----------------|
| `dcalendar` | dCalendar | `3cbe0c71` | `dcalendar` | `Date Key` |
| `d_bu` | A definir | `d3c2d827` | `bu` | `BU` |
| `d_business_type` | A definir | `a58daa91` | `business_type` | `Business Type` |
| `d_customer_type` | A definir | `ee7b4dce` | `customer_type` | `Customer Type` |
| `d_event_type` | A definir | `32502a54` | `event_type` | `event_type`, `Evento` |
| `d_segment` | A definir | `61b71bc0` | `operation_segment` | `Segmento` |
| `d_canal` | mkt_canal | `e4f720d3` | `mkt_canal` | `canal` |

> 📋 **Linhagem pendente:** Os Dataflows `d3c2d827`, `a58daa91`, `ee7b4dce`, `32502a54` e `61b71bc0` são novos (não documentados anteriormente). Executar `/pbi-fluxo-de-dados "Daily Sales Dashboard"` para mapear fontes originais e código M.

> ℹ️ `dcalendar` e `d_canal` já foram documentados no Dashboard de Safras — mesmos IDs de Dataflow.

---

## Tabelas Auxiliares

### Tabela (Seletor de KPI)

Tabela calculada via DAX (`DATATABLE`) com os KPIs disponíveis no seletor principal do dashboard:

| Id | KPI |
|----|-----|
| 1 | GMV |
| 2 | Receita |
| 3 | Operações |
| 4 | Presignups |
| 5 | Investimento |
| 6 | CPP |
| 7 | CPA |
| 8 | PNL |

As medidas `Realizado`, `Meta`, `Projeção` e `% GAP` são dinâmicas — usam `SELECTEDVALUE(Tabela[KPI])` para retornar o KPI correto conforme seleção.

### Business (Seletor de Dimensão)

Tabela calculada via DAX com as dimensões disponíveis para decomposição:

| Business | Dimensão referenciada |
|----------|----------------------|
| BU | `d_bu[BU]` |
| Evento | `d_event_type[Evento]` |
| Business Type | `d_business_type[Business Type]` |
| Canal | `d_canal[canal]` |

### Intraday Flag (Toggle Intraday)

Tabela calculada via DAX com dois valores booleanos:

| Intraday | Comportamento |
|----------|--------------|
| TRUE | Inclui dados do dia corrente (em andamento) |
| FALSE | Exclui hoje — exibe apenas dias com fechamento completo (D-1) |

---

## Tabela Utilitária

### f_last_update

| Campo | Valor |
|-------|-------|
| **Tipo** | Utilitário |
| **Camada** | 🟢 gold |
| **Fonte** | `gold.fact_operations` |
| **Query** | `SELECT MAX(processed_tstamp) WHERE is_ops_processed AND is_intercompany = false` |

Alimenta a medida `Last Update`, exibida no título do dashboard.
