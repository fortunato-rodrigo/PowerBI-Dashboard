# Queries SQL -- Daily Sales Dashboard
> Gerado em: 15/05/2026 14:06 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Daily Sales Dashboard
> Fonte: `data_quality.tables_in_dashboards_pbix`

> **ALERTA:** 3 tabela(s) com conexao em camada `bronze`. Dados brutos sem transformacao -- validar antes de usar em KPIs.

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `f_daily_sales` | gold | 1 tabelas | -- |
| `f_daily_sales_psu` | gold, bronze | 2 tabelas | ALERTA bronze |
| `f_gold_ops` | gold | 1 tabelas | -- |
| `f_investimentos` | bronze | 1 tabelas | ALERTA bronze |
| `f_last_update` | gold | 1 tabelas | -- |
| `f_pnl_tesouraria` | bronze | 1 tabelas | ALERTA bronze |
| `f_wallet` |  | 0 tabelas | -- |

---

## Detalhamento por tabela

### `f_daily_sales`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-04-29

**Tabelas Databricks referenciadas:**

- `gold.daily_sales` [G]

**SQL completo:**

```sql
SELECT
    vd.date_key,
    vd.bu,
    vd.event_type,
    vd.business_type,
    SUM(vd.gross_revenue) AS gross_revenue,
    SUM(vd.meta_gross_revenue) AS meta_gross_revenue,
    SUM(vd.acumulado_gross_revenue) AS projecao_gross_revenue,
    SUM(vd.gross_revenue_diario) AS gross_revenue_diario,
    SUM(vd.operations) AS operations,
    SUM(vd.meta_operations) AS meta_operations,
    SUM(vd.acumulado_ops) AS projecao_operations,
    SUM(vd.ops_diaria) AS ops_diaria,
    SUM(vd.gmv) AS gmv,
    SUM(vd.meta_gmv) AS meta_gmv,
    SUM(vd.acumulado_gmv) AS projecao_gmv,
    SUM(vd.gmv_diario) AS gmv_diario
FROM gold.daily_sales AS vd
WHERE vd.date_key >= '2024-01-01'
GROUP BY ALL;
```

### `f_daily_sales_psu`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.daily_sales_psu` [G]
- `bronze.beecambio_customer` [!]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
WITH lc AS (
    SELECT
        DATE(dc.psu_date) AS date_key,
        lc.canal,
        dc.customer_type,
        COUNT(lc.id_customer) AS realizado_psu
    FROM google_analytics.last_click_sessions AS lc
    LEFT JOIN bronze.beecambio_customer AS dc
        ON lc.id_customer = dc.id
    WHERE DATE(lc.event_date) >= '2024-01-01'
      AND dc.email NOT LIKE '%fxaas%'
    GROUP BY ALL
), final AS (
    SELECT
        COALESCE(ds.date_key, lc.date_key) AS date_key,
        COALESCE(ds.event_type, 'PRESIGNUP') AS event_type,
        COALESCE(ds.channel, lc.canal) AS canal,
        COALESCE(ds.customer_type, lc.customer_type) AS customer_type,
        SUM(ds.goal_psu) AS goal_psu,
        COALESCE(COALESCE(SUM(lc.realizado_psu), 0), COALESCE(SUM(ds.realizado_psu), 0)) AS realizado_psu
    FROM gold.daily_sales_psu AS ds
    FULL OUTER JOIN lc
        ON lc.date_key = ds.date_key
       AND lc.canal = ds.channel
       AND lc.customer_type = ds.customer_type
    GROUP BY ALL
)

SELECT * FROM final;
```

### `f_gold_ops`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_operations` [G]

**SQL completo:**

```sql
SELECT
  customer_type,
  processed_date AS operation_date,
  hour(processed_tstamp) AS processing_hour,
  --minute(processed_tstamp) AS processing_minute,
  --date_format(processed_tstamp, 'HH:mm:00') AS processing_hour_minute,
  CASE
    WHEN operation_event_type = 'RecorrÃªncia' THEN 'REPURCHASE'
    WHEN operation_event_type IN ('AquisiÃ§Ã£o', 'AtivaÃ§Ã£o') THEN 'ACQUISITION'
  END AS event_type,
  bu,
  business_type,
  segment AS operation_segment,
  COUNT(id_remittance) AS operations,
  SUM(gmv) AS gmv,
  SUM(gross_revenue) AS gross_revenue,
  SUM(gross_revenue_treasury) AS gross_revenue_treasury,
  SUM(cost_bank_take) AS cost_bank_take,
  SUM(real_message_cost) AS real_message_cost
FROM gold.fact_operations
WHERE is_ops_processed IS TRUE
  AND is_intercompany = FALSE
  AND processed_date >= '2024-01-01'
GROUP BY ALL;
```

### `f_investimentos`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `bronze.paid_media_investments` [!]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
select date as date_key,
       'PF' as customer_type,
       sum(cost) * 0.5822 as investimento
from bronze.paid_media_investments
where date >= '2024-01-01'
group by all

union all

select date as date_key,
       'PJ' as customer_type,
       sum(cost) * 0.4178 as investimento
from bronze.paid_media_investments
where date >= '2024-01-01'
group by all
```

### `f_last_update`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-04-29

**Tabelas Databricks referenciadas:**

- `gold.fact_operations` [G]

**SQL completo:**

```sql
select
max(processed_tstamp) as last_update
from gold.fact_operations
where is_ops_processed
and is_intercompany = false
```

### `f_pnl_tesouraria`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `bronze.dcalendar` [!]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
WITH metas_2025 AS (
    SELECT 'Plataforma'    AS bu, 408000 AS meta_anual
    UNION ALL
    SELECT 'Processamento' AS bu, 175000 AS meta_anual
),

metas_2026 AS (
    SELECT 'Premium'       AS bu
    UNION ALL SELECT 'COMEX'
    UNION ALL SELECT 'Processamento'
    UNION ALL SELECT 'Plataforma'
    UNION ALL SELECT 'Afiliados'
)

-- 2025
SELECT
    c.date_key,
    m.bu,
    m.meta_anual * c.label AS meta_pnl
FROM bronze.dcalendar AS c
CROSS JOIN metas_2025 m
WHERE YEAR(c.date_key) = 2025

UNION ALL

-- 2026
SELECT
    c.date_key,
    m26.bu,
    (141666.67 / 5) * c.label_with_all_days_month AS meta_pnl
FROM bronze.dcalendar c
CROSS JOIN metas_2026 m26
WHERE YEAR(c.date_key) = 2026
```

### `f_wallet`

**Dashboard:** Daily Sales Dashboard
**Ultima atualizacao na tabela Databricks:** 2025-12-24


**SQL completo:**

```sql
select
    date(transaction_date) as date_key,
    'Wallet' as bu,
    'PF' as customer_type,
    'TransaÃ§Ãµes do CartÃ£o' as event_type,
    'Wallet EUR' as business_type,
    'Conta Global' as operation_segment,
    count(transaction_id) as transactions,
    sum(gross_revenue) as gross_revenue
from explore.wallet_transactions
where declined_reason = 'Not declined'
and date(transaction_date) >= '2024-01-01'
group by all
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
