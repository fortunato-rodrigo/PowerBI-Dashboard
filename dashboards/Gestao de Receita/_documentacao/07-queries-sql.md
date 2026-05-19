# Queries SQL -- Gestao de Receita
> Gerado em: 15/05/2026 14:14 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Gestao de Receita
> Fonte: `data_quality.tables_in_dashboards_pbix`

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `Parceiros` | beecambio | 2 tabelas | -- |
| `Subsegmento PF` | silver | 1 tabelas | -- |
| `customer` | gold, beecambio | 2 tabelas | -- |
| `processed_operations` | gold, beecambio | 2 tabelas | -- |

---

## Detalhamento por tabela

### `Parceiros`

**Dashboard:** GestÃ£o de Receita
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `beecambio.beecambio_maxima_partners` [B]
- `beecambio.beecambio_tbl_customer` [B]

**SQL completo:**

```sql
select
c.id as id_customer,
mp.name as partner_name
from beecambio.beecambio_tbl_customer c
inner join beecambio.beecambio_maxima_partners as mp
    on mp.partner_code = c.maxima_partner_code
where 1=1
and c.maxima_partner_code is not null
```

### `Subsegmento PF`

**Dashboard:** GestÃ£o de Receita
**Ultima atualizacao na tabela Databricks:** 2026-05-06

**Tabelas Databricks referenciadas:**

- `silver.customers` [S]

**SQL completo:**

```sql
SELECT
    s.id_customer,
    DATE(s.month) AS month_id,
    s.subsegment
FROM stage.dim_last_subsegments AS s
LEFT JOIN silver.customers AS c
    ON c.id = s.id_customer
WHERE c.customer_type = 'PF'
```

### `customer`

**Dashboard:** GestÃ£o de Receita
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_operations` [G]
- `beecambio.beecambio_tbl_office` [B]

**SQL completo:**

```sql
with comissao_afiliados as (
  select distinct
    cast(replace(replace(hc.advertiser_info, 'RM_PRODUCTION_', ''), 'RM_', '') as int) as id_remittance,
    date(hc.datetime + interval '1' hour) as operation_date,
    hc.affiliate_id,
    do.nickname as office_nickname,
    do.name as office,
    true as is_affiliate,
    sum(hc.revenue) as gross_revenue,
    sum(hc.payout) as payout
  from
    automations.integrations_hasoffer_conversion as hc
    left join beecambio.beecambio_tbl_office as do on hc.affiliate_id = do.id_affiliate_on_hasoffer
  where
    status = 'approved'
    and date(hc.datetime) >= date('2022-01-01')
    and hc.advertiser_info <> ''
  group by all
),
bank_take as (
  select
    date_trunc('month',kl.referencia) as referencia,
    kl.indicador,
    sum(kl.valor) as valor
  from finance_cube.kpi_list kl
  where 1=1
    and id = '45KPI'
  group by all
),
gmv_mensal as (
  select
    date_trunc('month',po.processed_date) mes,
    sum(po.gmv) as gmv
  from gold.fact_operations po
  where is_ops_processed is true
  group by all
),
base as (
  select
    po.*,
    gm.gmv as gmv_total_mes,
    po.gmv / gm.gmv as prop_gmv,
    -bt.valor * (po.gmv / gm.gmv) as bank_take,
    coalesce(po.real_message_cost,0) as despesa_real,
    coalesce(ca.payout,0) as payout,
    po.gross_revenue - (-bt.valor * (po.gmv / gm.gmv)) - coalesce(po.real_message_cost,0) - coalesce(ca.payout,0) as lucro
  from gold.fact_operations as po
  left join comissao_afiliados as ca
    on ca.id_remittance = po.id_remittance
  left join gmv_mensal as gm
    on date_trunc('month',po.processed_date) = gm.mes
  left join bank_take as bt
    on date_trunc('month',po.processed_date) = bt.referencia
  where 1=1
    and date_trunc('month',po.processed_date) >= date('2023-01-01')
    and date_trunc('month',po.processed_date) <= date_trunc('month',current_date) - interval '1' month
    and bt.valor is not null
    and is_ops_processed is true
)
select
  id_customer,
  count(distinct nature_operation_name) as naturezas,
  count(distinct in_or_out) as tipo_envio,
  count(distinct currency_name) as currency,
  count(distinct country) as country,
  count(distinct id_remittance) as qtde_ops,
  count(distinct case when lucro < 0 then id_remittance else null end) as ops_negativas,
  sum(lucro) as receita_liquida,
  sum(gross_revenue) as gross_revenue
from base
where 1=1
  and date_trunc('month',processed_date) >= date('2023-01-01')
group by all
```

### `processed_operations`

**Dashboard:** GestÃ£o de Receita
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_operations` [G]
- `beecambio.beecambio_tbl_remittance_operation` [B]

**SQL completo:**

```sql
with gmv_mensal as (
  select
    date_trunc('month', po.processed_date) mes,
    sum(po.gmv) as gmv
  from gold.fact_operations po
  group by all
)

select
  po.id_remittance,
  po.in_or_out,
  po.id_customer,
  po.gmv,
  po.gross_revenue,
  po.is_ops_processed,
  po.processed_date,
  po.nature_operation_name,
  po.customer_type,
  po.business_type,
  po.bu,
  po.distributor_name,
  po.is_affiliate,
  po.MID,
  po.currency_abbreviation,
  po.currency_name,
  po.has_fixed_spread,
  po.is_intercompany,
  po.applied_discount,
  po.spread,
  po.spread_original,
  po.taxes,
  po.swift_or_distributor,
  po.acquisition,
  po.country,
  po.real_message_cost,
  po.tariff,
  po.voucher_code,
  po.net_revenue,
  ro.policy_label,
  po.payout_affiliate,
  po.spread_revenue,
  po.is_efx,
  po.is_partner,
  po.is_corporate_api,
  po.is_fxaas,
  case
    when po.counterpart = 'Google' then true
    else false
  end as google,
  gm.gmv as gmv_total_mes,
  po.gmv / gm.gmv as prop_gmv,
  po.cost_bank_take as bank_take,
  coalesce(po.real_message_cost, 0) as despesa_real,
  po.payout_affiliate as payout,
  po.partner_commissioning,
  po.cost_bacen,
  po.cost_funding,
  po.net_revenue as lucro,
  coalesce(po.partner_name_from_maxima_code, po.partner_name_from_fxaas) as partner_name,
  current_timestamp() - interval '3' hour as last_update
from gold.fact_operations as po
  left join beecambio.beecambio_tbl_remittance_operation as ro on ro.id = po.id_remittance
  -- left join select * from stage.dim_monthly_messaging_cost as mm on mm.id_remittance = po.id_remittance
  left join gmv_mensal as gm on date_trunc('month', po.processed_date) = gm.mes
where 1 = 1
  and date_trunc('month', po.processed_date) >= date('2024-01-01')
  and date_trunc('month', po.processed_date) <= date_trunc('month', current_date)
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
