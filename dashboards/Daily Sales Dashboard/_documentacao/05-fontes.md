# Daily Sales Dashboard — Fontes de Dados

> ⚠️ **ALERTA BRONZE:** 3 tabelas utilizam a camada `bronze` do Databricks diretamente: `f_investimentos` (bronze.paid_media_investments), `f_daily_sales_psu` (JOIN com bronze.beecambio_customer) e `f_pnl_tesouraria` (JOIN com bronze.dcalendar). Dados bronze são brutos e sem transformação DBT — podem conter inconsistências.

> ❓ **LAYER NÃO-PADRÃO:** `f_wallet` usa `explore.wallet_transactions`. O schema `explore` não pertence à hierarquia padrão (bronze/silver/gold/diamond). Verificar com o time de dados o nível de confiança e plano de migração.

> 📋 **Dataflows:** 7 tabelas dimensão são alimentadas por Power BI Dataflows (Workspace `5381a7f5`). 5 Dataflows são novos (não documentados anteriormente). Executar `/pbi-fluxo-de-dados "Daily Sales Dashboard"` para linhagem completa.

---

## Resumo das Fontes

| Tabela PBI | Fonte | Camada | Confiança |
|------------|-------|--------|-----------|
| `f_daily_sales` | `gold.daily_sales` | 🟢 gold | Alto |
| `f_gold_ops` | `gold.fact_operations` | 🟢 gold | Alto |
| `f_daily_sales_psu` | `gold.daily_sales_psu` + `google_analytics.last_click_sessions` + `bronze.beecambio_customer` | 🟢 gold / ⚠️ bronze | Médio |
| `f_investimentos` | `bronze.paid_media_investments` | ⚠️ bronze | Baixo |
| `f_wallet` | `explore.wallet_transactions` | ❓ explore | A definir |
| `f_pnl_tesouraria` | `bronze.dcalendar` (calendario) + metas hardcoded | ⚠️ bronze | Baixo |
| `dcalendar` | Dataflow `dCalendar` (`3cbe0c71`) | Dataflow | A definir via M |
| `d_bu` | Dataflow A definir (`d3c2d827`) | Dataflow | A definir via M |
| `d_business_type` | Dataflow A definir (`a58daa91`) | Dataflow | A definir via M |
| `d_customer_type` | Dataflow A definir (`ee7b4dce`) | Dataflow | A definir via M |
| `d_event_type` | Dataflow A definir (`32502a54`) | Dataflow | A definir via M |
| `d_segment` | Dataflow A definir (`61b71bc0`) | Dataflow | A definir via M |
| `d_canal` | Dataflow `mkt_canal` (`e4f720d3`) | Dataflow | A definir via M |
| `f_last_update` | `gold.fact_operations` | 🟢 gold | Alto |
| `Tabela`, `Business`, `Intraday Flag` | DAX calculado | — | N/A |

---

## Detalhamento por Tabela Fato

---

### f_daily_sales

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** `gold.daily_sales`
**Workspace:** `beetech-prod-analytics.cloud.databricks.com`

**Query SQL resumida:**
```sql
SELECT
    date_key, bu, event_type, business_type,
    SUM(gross_revenue) AS gross_revenue,
    SUM(meta_gross_revenue) AS meta_gross_revenue,
    SUM(acumulado_gross_revenue) AS projecao_gross_revenue,
    SUM(gross_revenue_diario) AS gross_revenue_diario,
    SUM(operations), SUM(meta_operations), SUM(acumulado_ops) AS projecao_operations,
    SUM(ops_diaria),
    SUM(gmv), SUM(meta_gmv), SUM(acumulado_gmv) AS projecao_gmv,
    SUM(gmv_diario)
FROM gold.daily_sales AS vd
WHERE vd.date_key >= '2024-01-01'
GROUP BY ALL
```

**Observação:** Esta tabela já inclui metas e projeções computadas na camada gold — não é necessário cruzar com uma tabela de metas separada para GMV, Receita e Ops.

---

### f_gold_ops

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** `gold.fact_operations`
**Filtros:** `is_ops_processed = true`, `is_intercompany = false`, `processed_date >= '2024-01-01'`

**Query SQL resumida:**
```sql
SELECT
    customer_type,
    processed_date AS operation_date,
    HOUR(processed_tstamp) AS processing_hour,
    CASE
        WHEN operation_event_type = 'Recorrência' THEN 'REPURCHASE'
        WHEN operation_event_type IN ('Aquisição', 'Ativação') THEN 'ACQUISITION'
    END AS event_type,
    bu, business_type, segment AS operation_segment,
    COUNT(id_remittance) AS operations,
    SUM(gmv), SUM(gross_revenue), SUM(gross_revenue_treasury),
    SUM(cost_bank_take), SUM(real_message_cost)
FROM gold.fact_operations
WHERE is_ops_processed IS TRUE AND is_intercompany = FALSE AND processed_date >= '2024-01-01'
GROUP BY ALL
```

**Tabelas Databricks referenciadas:**

| Tabela | Camada | Observação |
|--------|--------|-----------|
| `gold.fact_operations` | 🟢 gold | Tabela central de operações processadas |

---

### f_daily_sales_psu

**Fonte:** Databricks — `Value.NativeQuery` (query com CTE)
**Tabelas:** `gold.daily_sales_psu` + `google_analytics.last_click_sessions` + ⚠️ `bronze.beecambio_customer`

**Query SQL resumida:**
```sql
WITH lc AS (
  SELECT DATE(dc.psu_date) AS date_key, lc.canal, dc.customer_type,
    COUNT(lc.id_customer) AS realizado_psu
  FROM google_analytics.last_click_sessions AS lc
  LEFT JOIN bronze.beecambio_customer AS dc ON lc.id_customer = dc.id  -- ⚠️ BRONZE
  WHERE DATE(lc.event_date) >= '2024-01-01'
    AND dc.email NOT LIKE '%fxaas%'
  GROUP BY ALL
),
final AS (
  SELECT
    COALESCE(ds.date_key, lc.date_key) AS date_key,
    COALESCE(ds.event_type, 'PRESIGNUP') AS event_type,
    COALESCE(ds.channel, lc.canal) AS canal,
    COALESCE(ds.customer_type, lc.customer_type) AS customer_type,
    SUM(ds.goal_psu) AS goal_psu,
    COALESCE(SUM(lc.realizado_psu), SUM(ds.realizado_psu)) AS realizado_psu
  FROM gold.daily_sales_psu AS ds
  FULL OUTER JOIN lc ON lc.date_key = ds.date_key AND ...
  GROUP BY ALL
)
SELECT * FROM final
```

**Tabelas Databricks referenciadas:**

| Tabela | Camada | Observação |
|--------|--------|-----------|
| `gold.daily_sales_psu` | 🟢 gold | PSU diários e metas |
| `google_analytics.last_click_sessions` | Externo | Sessões de último clique do Google Analytics |
| `bronze.beecambio_customer` | ⚠️ bronze | Cadastro de clientes — dados brutos |

> ⚠️ **Ação recomendada:** Verificar com o time de dados se existe equivalente de `bronze.beecambio_customer` em silver/gold (`silver.customers` ou similar).

---

### f_investimentos

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** `bronze.paid_media_investments`

**Query SQL resumida:**
```sql
SELECT date AS date_key, 'PF' AS customer_type,
    SUM(cost) * 0.5822 AS investimento
FROM bronze.paid_media_investments
WHERE date >= '2024-01-01' GROUP BY ALL

UNION ALL

SELECT date AS date_key, 'PJ' AS customer_type,
    SUM(cost) * 0.4178 AS investimento
FROM bronze.paid_media_investments
WHERE date >= '2024-01-01' GROUP BY ALL
```

> ⚠️ **BRONZE:** Fonte direta de dados brutos de mídia paga. Alocação PF/PJ hardcoded (58,22% / 41,78%) — revisar periodicamente se a proporção muda.

> ⚠️ **Ação recomendada:** Verificar se existe equivalente em silver/gold para `bronze.paid_media_investments`.

---

### f_wallet

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** `explore.wallet_transactions`

**Query SQL resumida:**
```sql
SELECT
    DATE(transaction_date) AS date_key,
    'Wallet' AS bu, 'PF' AS customer_type,
    'Transações do Cartão' AS event_type,
    'Wallet EUR' AS business_type,
    'Conta Global' AS operation_segment,
    COUNT(transaction_id) AS transactions,
    SUM(gross_revenue)
FROM explore.wallet_transactions
WHERE declined_reason = 'Not declined'
  AND DATE(transaction_date) >= '2024-01-01'
GROUP BY ALL
```

> ❓ **EXPLORE:** O schema `explore` não é bronze/silver/gold/diamond. Verificar com o time de dados qual é o processo de geração e nível de confiança deste schema.

---

### f_pnl_tesouraria

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** ⚠️ `bronze.dcalendar` (usada como calendário) + metas hardcoded na query

**Query SQL resumida:**
```sql
-- Metas 2025 (hardcoded)
WITH metas_2025 AS (
    SELECT 'Plataforma' AS bu, 408000 AS meta_anual
    UNION ALL SELECT 'Processamento', 175000
),
metas_2026 AS (
    SELECT 'Premium' AS bu UNION ALL SELECT 'COMEX' UNION ALL ...
)
-- Distribuição proporcional pelo calendário
SELECT c.date_key, m.bu, m.meta_anual * c.label AS meta_pnl
FROM bronze.dcalendar AS c
CROSS JOIN metas_2025 m
WHERE YEAR(c.date_key) = 2025

UNION ALL

SELECT c.date_key, m26.bu, (141666.67 / 5) * c.label_with_all_days_month AS meta_pnl
FROM bronze.dcalendar c
CROSS JOIN metas_2026 m26
WHERE YEAR(c.date_key) = 2026
```

> ⚠️ **BRONZE + METAS HARDCODED:** Este é o pior padrão de qualidade de dado no modelo — combina dados bronze com metas embutidas na query. Qualquer mudança de meta ou de BU exige edição manual da query M.
> **Ação recomendada:** Migrar metas de PNL para uma tabela de configuração em silver/gold gerenciada pelo time de dados.

---

### f_last_update

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela:** `gold.fact_operations`

```sql
SELECT MAX(processed_tstamp) AS last_update
FROM gold.fact_operations
WHERE is_ops_processed AND is_intercompany = FALSE
```

---

## Dataflows Identificados

**Workspace PBI:** `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`
**Total:** 7 Dataflows · 2 já documentados em outros dashboards · 5 novos

| Tabela PBI | Dataflow ID | Entidade | Transformações no modelo | Status |
|-----------|-------------|----------|--------------------------|--------|
| `dcalendar` | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` | `dcalendar` | Adiciona `last_day`, seleciona colunas | ✅ Documentado |
| `d_canal` | `e4f720d3-c121-4344-a842-0c3f84f0380c` | `mkt_canal` | Nenhuma | ✅ Documentado |
| `d_bu` | `d3c2d827-b84c-466b-9485-ee1b0ee58b79` | `bu` | Nenhuma | ⏳ Fonte original pendente |
| `d_business_type` | `a58daa91-b31a-4f5d-9e56-f4befa9050f0` | `business_type` | Remove coluna `bu` | ⏳ Fonte original pendente |
| `d_customer_type` | `ee7b4dce-a733-4365-9194-bfea34031f1a` | `customer_type` | Nenhuma | ⏳ Fonte original pendente |
| `d_event_type` | `32502a54-a25e-49da-96b6-b9d541c6dc0b` | `event_type` | Nenhuma | ⏳ Fonte original pendente |
| `d_segment` | `61b71bc0-5ab5-45b6-91eb-a941dbaa9684` | `operation_segment` | Renomeia `operation_segment` → `Segmento` | ⏳ Fonte original pendente |

---

## Detalhamento por Dataflow

---

### Dataflow: dcalendar

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| **Entidade** | `dcalendar` |
| **Tabela destino** | `dcalendar` |
| **Colunas disponíveis** | `Date Key`, `date_month`, `d0`, `year`, `Filter Today`, `Current Month`, `month`, `month_number`, `month_year`, `mtd`, `is_current_date`, `last_day` |
| **Transformações no modelo** | Adiciona coluna `last_day` (`Date.EndOfMonth([Date Key])` comparado com `[Date Key]`), depois seleciona apenas as colunas acima |
| **Fonte original** | A definir via PBI Service |
| **Frequência de atualização** | A definir |
| **Status** | ✅ Mesmo Dataflow do Scorecard e Dashboard de Safras — compartilhado entre dashboards |

**Query M no modelo:**
```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    ws = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    df = ws{[dataflowId="3cbe0c71-8501-42b4-bcea-9dfb4ff7adef"]}[Data],
    dcalendar_ = df{[entity="dcalendar",version=""]}[Data],
    #"Fim do Mês" = Table.AddColumn(dcalendar_, "Fim do Mês", each Date.EndOfMonth([Date Key]), type date),
    #"last_day" = Table.AddColumn(#"Fim do Mês", "last_day", each if [Date Key] = [Fim do Mês] then true else false),
    #"Tipo" = Table.TransformColumnTypes(#"last_day",{{"last_day", type logical}}),
    result = Table.SelectColumns(#"Tipo",{"Date Key","date_month","d0","year","Filter Today",
        "Current Month","month","month_number","month_year","mtd","is_current_date","last_day"})
in result
```

**Linhagem inferida:**
```
Fonte original (A definir)
  └─► Dataflow dCalendar (3cbe0c71) — entidade: dcalendar
        └─► [Transformação no modelo: +last_day, seleção de colunas]
              └─► dcalendar (tabela no modelo)
                    └─► Filtros temporais de todas as medidas (MTD, D-1, YTD, last_day)
```

---

### Dataflow: d_canal

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `e4f720d3-c121-4344-a842-0c3f84f0380c` |
| **Entidade** | `mkt_canal` |
| **Tabela destino** | `d_canal` |
| **Colunas disponíveis** | `canal` |
| **Transformações no modelo** | Nenhuma — direto da entidade |
| **Fonte original** | A definir via PBI Service |
| **Status** | ✅ Mesmo Dataflow do Dashboard de Safras |

**Linhagem inferida:**
```
Fonte original (A definir — provavelmente gold.funnel_event ou configuração de canais UTM)
  └─► Dataflow mkt_canal (e4f720d3) — entidade: mkt_canal
        └─► d_canal (tabela no modelo)
              └─► f_daily_sales_psu via relacionamento d_canal.canal = f_daily_sales_psu.canal
```

---

### Dataflow: d_bu ⏳ Novo

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `d3c2d827-b84c-466b-9485-ee1b0ee58b79` |
| **Entidade** | `bu` |
| **Tabela destino** | `d_bu` |
| **Colunas disponíveis** | `BU` |
| **Transformações no modelo** | Nenhuma — direto da entidade |
| **Fonte original** | A definir via PBI Service |
| **Frequência de atualização** | A definir |
| **Linhagem inferida** | Provavelmente `gold.fact_operations.bu` ou configuração estática de BUs |

**Query M no modelo:**
```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    ws = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    df = ws{[dataflowId="d3c2d827-b84c-466b-9485-ee1b0ee58b79"]}[Data],
    bu_ = df{[entity="bu",version=""]}[Data]
in bu_
```

**Linhagem inferida:**
```
Fonte original (A definir — provável: gold.fact_operations ou lista estática de BUs)
  └─► Dataflow d3c2d827 — entidade: bu
        └─► d_bu (tabela no modelo)
              ├─► f_daily_sales via d_bu.BU = f_daily_sales.bu
              ├─► f_gold_ops via d_bu.BU = f_gold_ops.bu
              ├─► f_wallet via d_bu.BU = f_wallet.bu
              └─► f_pnl_tesouraria via d_bu.BU = f_pnl_tesouraria.bu
```

---

### Dataflow: d_business_type ⏳ Novo

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `a58daa91-b31a-4f5d-9e56-f4befa9050f0` |
| **Entidade** | `business_type` |
| **Tabela destino** | `d_business_type` |
| **Colunas disponíveis** | `Business Type`, `index` (coluna de ordenação) |
| **Transformações no modelo** | Remove coluna `bu` da entidade (a entidade original contém `bu` + `business_type` + `index`) |
| **Fonte original** | A definir via PBI Service |
| **Observação** | A coluna `index` é usada para ordenar `Business Type` no modelo — indica que o Dataflow entrega uma lista ordenada de tipos de negócio |

**Query M no modelo:**
```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    ws = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    df = ws{[dataflowId="a58daa91-b31a-4f5d-9e56-f4befa9050f0"]}[Data],
    business_type_ = df{[entity="business_type",version=""]}[Data],
    result = Table.RemoveColumns(business_type_,{"bu"})
in result
```

**Linhagem inferida:**
```
Fonte original (A definir — entidade contém bu+business_type+index → provável tabela de configuração)
  └─► Dataflow a58daa91 — entidade: business_type
        └─► [Transformação no modelo: remove coluna "bu"]
              └─► d_business_type (tabela no modelo)
                    ├─► f_daily_sales via d_business_type.'Business Type' = f_daily_sales.business_type
                    ├─► f_gold_ops via d_business_type.'Business Type' = f_gold_ops.business_type
                    └─► f_wallet via d_business_type.'Business Type' = f_wallet.business_type
```

---

### Dataflow: d_customer_type ⏳ Novo

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `ee7b4dce-a733-4365-9194-bfea34031f1a` |
| **Entidade** | `customer_type` |
| **Tabela destino** | `d_customer_type` |
| **Colunas disponíveis** | `Customer Type` (marcada como **oculta** no modelo — usada apenas como filtro) |
| **Transformações no modelo** | Nenhuma — direto da entidade |
| **Fonte original** | A definir via PBI Service |
| **Observação** | Coluna oculta: `isHidden = true` no TMDL. É usada como dimensão de filtro mas não aparece em visuais. |

**Linhagem inferida:**
```
Fonte original (A definir — provavelmente lista estática PF/PJ ou gold.fact_operations)
  └─► Dataflow ee7b4dce — entidade: customer_type
        └─► d_customer_type (tabela no modelo — coluna oculta)
              ├─► f_daily_sales_psu via d_customer_type.'Customer Type' = f_daily_sales_psu.customer_type
              ├─► f_investimentos via d_customer_type.'Customer Type' = f_investimentos.customer_type
              ├─► f_gold_ops via d_customer_type.'Customer Type' = f_gold_ops.customer_type
              └─► f_wallet via d_customer_type.'Customer Type' = f_wallet.customer_type
```

---

### Dataflow: d_event_type ⏳ Novo

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `32502a54-a25e-49da-96b6-b9d541c6dc0b` |
| **Entidade** | `event_type` |
| **Tabela destino** | `d_event_type` |
| **Colunas disponíveis** | `event_type` (código técnico: ACQUISITION, REPURCHASE, PRESIGNUP…) + `Evento` (nome de exibição em PT-BR) |
| **Transformações no modelo** | Nenhuma — direto da entidade |
| **Fonte original** | A definir via PBI Service |
| **Observação** | Duas colunas de relacionamento distintas: `f_daily_sales` usa a coluna `Evento`; `f_gold_ops`, `f_daily_sales_psu` e `f_wallet` usam a coluna `event_type`. |

**Linhagem inferida:**
```
Fonte original (A definir — provavelmente tabela de configuração com códigos e labels PT-BR)
  └─► Dataflow 32502a54 — entidade: event_type
        └─► d_event_type (tabela no modelo)
              ├─► f_daily_sales via d_event_type.Evento = f_daily_sales.event_type
              ├─► f_gold_ops via d_event_type.event_type = f_gold_ops.event_type
              ├─► f_daily_sales_psu via d_event_type.event_type = f_daily_sales_psu.event_type
              └─► f_wallet via d_event_type.event_type = f_wallet.event_type
```

---

### Dataflow: d_segment ⏳ Novo

| Campo | Valor |
|-------|-------|
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `61b71bc0-5ab5-45b6-91eb-a941dbaa9684` |
| **Entidade** | `operation_segment` |
| **Tabela destino** | `d_segment` |
| **Colunas disponíveis** | `Segmento` |
| **Transformações no modelo** | Renomeia `operation_segment` → `Segmento` |
| **Fonte original** | A definir via PBI Service |
| **Linhagem inferida** | Provavelmente `gold.fact_operations.operation_segment` — lista de segmentos operacionais únicos |

**Query M no modelo:**
```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    ws = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    df = ws{[dataflowId="61b71bc0-5ab5-45b6-91eb-a941dbaa9684"]}[Data],
    seg_ = df{[entity="operation_segment",version=""]}[Data],
    result = Table.RenameColumns(seg_,{{"operation_segment", "Segmento"}})
in result
```

**Linhagem inferida:**
```
Fonte original (A definir — provável: gold.fact_operations.operation_segment DISTINCT)
  └─► Dataflow 61b71bc0 — entidade: operation_segment
        └─► [Transformação no modelo: renomeia para "Segmento"]
              └─► d_segment (tabela no modelo)
                    ├─► f_gold_ops via d_segment.Segmento = f_gold_ops.operation_segment
                    └─► f_wallet via d_segment.Segmento = f_wallet.operation_segment
```

---

## Linhagem Estendida (com Dataflows)

```
┌─────────────────────────────────────────────────────────┐
│  FONTES EXTERNAS (Databricks + Google Analytics)        │
└─────────────────────────────────────────────────────────┘

gold.daily_sales ──────────────────────────────► f_daily_sales
gold.fact_operations ──────────────────────────► f_gold_ops
gold.fact_operations MAX(tstamp) ──────────────► f_last_update
gold.daily_sales_psu ─┐
google_analytics ─────┼──────────────────────► f_daily_sales_psu
bronze.beecambio ─────┘  ⚠️
bronze.paid_media ─────────────────────────────► f_investimentos  ⚠️
explore.wallet ────────────────────────────────► f_wallet  ❓
bronze.dcalendar + hardcoded ──────────────────► f_pnl_tesouraria  ⚠️

┌─────────────────────────────────────────────────────────┐
│  POWER BI DATAFLOWS (workspace 5381a7f5)               │
└─────────────────────────────────────────────────────────┘

Fonte (A definir) → Dataflow 3cbe0c71 (dCalendar)
  └─► [+last_day, seleção colunas] ──────────► dcalendar

Fonte (A definir) → Dataflow e4f720d3 (mkt_canal)
  └─► [direto] ──────────────────────────────► d_canal

Fonte (A definir) → Dataflow d3c2d827
  └─► [direto] ──────────────────────────────► d_bu

Fonte (A definir) → Dataflow a58daa91
  └─► [-coluna bu] ──────────────────────────► d_business_type

Fonte (A definir) → Dataflow ee7b4dce
  └─► [direto, coluna oculta] ───────────────► d_customer_type

Fonte (A definir) → Dataflow 32502a54
  └─► [direto, 2 colunas: code + label PT] ──► d_event_type

Fonte (A definir) → Dataflow 61b71bc0
  └─► [renomeia operation_segment→Segmento] ──► d_segment

┌─────────────────────────────────────────────────────────┐
│  MODELO POWER BI (Daily Sales Dashboard)                │
└─────────────────────────────────────────────────────────┘

Fatos: f_daily_sales, f_gold_ops, f_daily_sales_psu,
       f_investimentos, f_wallet, f_pnl_tesouraria, f_last_update
Dims:  dcalendar, d_bu, d_business_type, d_customer_type,
       d_event_type, d_segment, d_canal
  └─► Medidas DAX (Realizado, Meta, Projeção, % GAP, CPP, CPA, PNL…)
        └─► Visuais e páginas do dashboard
```

---

## Pendências de Linhagem

| Pendência | Ação necessária | Prioridade |
|-----------|----------------|-----------|
| Fonte original dos 5 Dataflows novos (d_bu, d_business_type, d_customer_type, d_event_type, d_segment) | PBI Service → workspace `5381a7f5` → Dataflow → Edit → Power Query | Alta |
| Fonte original dos 2 Dataflows existentes (dCalendar, mkt_canal) | Já documentado em outros dashboards — verificar se há mudanças | Baixa |
| `explore.wallet_transactions` — nível de confiança | Verificar com time de dados o processo de geração e plano de migração | Alta |
| `bronze.beecambio_customer` — migrar para silver | Verificar se `silver.customers` ou equivalente cobre o mesmo dado | Média |
| `bronze.paid_media_investments` — migrar para silver/gold | Verificar com time de dados o plano de migração | Média |
| Metas de PNL hardcoded em `f_pnl_tesouraria` | Migrar para tabela de configuração gerenciada em silver/gold | Média |
| Frequência de atualização dos Dataflows novos | Verificar no PBI Service → Dataflow → Settings → Schedule | Baixa |
