# Queries SQL -- Mkt Performance
> Gerado em: 15/05/2026 14:06 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Mkt Performance
> Fonte: `data_quality.tables_in_dashboards_pbix`

> **ALERTA:** 1 tabela(s) com conexao em camada `bronze`. Dados brutos sem transformacao -- validar antes de usar em KPIs.

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `d_blank` |  | 0 tabelas | -- |
| `d_qualificacao_1` | silver, beecambio | 4 tabelas | -- |
| `d_qualificacao_2` | silver, beecambio | 4 tabelas | -- |
| `f_attribution_window` | gold, silver | 2 tabelas | -- |
| `f_investimento` | bronze | 1 tabelas | ALERTA bronze |
| `f_mkt_performance` | gold, silver, beecambio | 9 tabelas | -- |

---

## Detalhamento por tabela

### `d_blank`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-13


**SQL completo:**

```sql
NÃ£o hÃ¡ nenhuma consulta SQL neste script de Powerâ¯Query.  
O cÃ³digo apenas cria uma tabela a partir de dados embutidos (descompactando um JSON) e altera o tipo da coluna âBlankâ para texto. Como nÃ£o hÃ¡ conexÃ£o a um banco de dados nem chamada a `Sql.Database`, `Odbc.Query`, `Value.NativeQuery` ou similar, nÃ£o existe SQL a ser extraÃ­do.
```

### `d_qualificacao_1`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `silver.customers` [S]
- `beecambio.beecambio_onboarding_qualification_answers` [B]
- `beecambio.beecambio_onboarding_qualification_form_options` [B]
- `beecambio.beecambio_onboarding_qualification_form_questions` [B]

**SQL completo:**

```sql
SELECT distinct
coalesce(o.goal, 'unknown') as primeira_pergunta
FROM silver.customers c
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_answers a
        ON c.id = a.id_customer
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_questions q
        ON q.id = a.id_question
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_options o
        ON o.id = a.id_option
```

### `d_qualificacao_2`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `silver.customers` [S]
- `beecambio.beecambio_onboarding_qualification_answers` [B]
- `beecambio.beecambio_onboarding_qualification_form_options` [B]
- `beecambio.beecambio_onboarding_qualification_form_questions` [B]

**SQL completo:**

```sql
SELECT distinct
CONCAT_WS(" | ", coalesce(o.goal, 'unknown'), o.title) as segunda_pergunta
FROM silver.customers c
  left join prod.beecambio.beecambio_onboarding_qualification_answers a on c.id = a.id_customer
  left join prod.beecambio.beecambio_onboarding_qualification_form_questions q on q.id = a.id_question
  left join prod.beecambio.beecambio_onboarding_qualification_form_options o on o.id = a.id_option
```

### `f_attribution_window`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-06

**Tabelas Databricks referenciadas:**

- `gold.fact_customers` [G]
- `silver.customers` [S]

**SQL completo:**

```sql
select distinct
  date(aw.event_date) as event_date,
  case
    when aw.mkt_campaign like '%pmax%' then 'display'
    else coalesce(aw.canal, 'unknown')
  end as canal,
  coalesce(aw.source, 'unknown') as source,
  coalesce(aw.medium, 'unknown') as medium,
  coalesce(trim(aw.mkt_campaign), 'organic/direct') as mkt_campaign,
  lower(coalesce(c.utm_adgroup_psu, 'unknown')) as ad_group_lc,
  dc.customer_type,
  count(distinct case when aw.event = 'PRESIGNUP' then aw.id_customer else null end) as presignups,
  count(distinct case when dc.customer_type = 'PF' and aw.event = 'PRESIGNUP' then aw.id_customer else null end) as presignups_pf,
  count(distinct case when dc.customer_type = 'PJ' and aw.event = 'PRESIGNUP' then aw.id_customer else null end) as presignups_pj,
  count(distinct case when aw.event = 'ACQUISITION' then aw.id_customer else null end) as acquisitions,
  count(distinct case when dc.customer_type = 'PF' and aw.event = 'ACQUISITION' then aw.id_customer else null end) as acquisitions_pf,
  count(distinct case when dc.customer_type = 'PJ' and aw.event = 'ACQUISITION' then aw.id_customer else null end) as acquisitions_pj
from google_analytics.attribution_window as aw
  inner join silver.customers as dc on aw.id_customer = dc.id
  left join google_analytics.last_click_sessions as lc on aw.session_id = lc.session_id
  left join gold.fact_customers as c on dc.id = c.id_customer
where date(aw.event_date) >= '2023-08-01'
  and lc.session_id is null
group by all
```

### `f_investimento`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-04-15

**Tabelas Databricks referenciadas:**

- `bronze.paid_media_investments` [!]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
select distinct
    pmkt.date as date_nao_usar,
    lower(ad_group) as ad_group,
    pmkt.mkt_campaign as mkt_campaign_pmkt,
    case
        when lower(pmkt.mkt_campaign) like '%pmax%' then 'display'
        else coalesce(pmkt.channel, 'unknown')
    end as channel_pmkt,
    lower(coalesce(pmkt.medium, 'unknown')) as medium_pmkt,
    lower(coalesce(pmkt.source, 'unknown')) as source_pmkt,
    case
        when lower(mkt_campaign) like '%consideracao%' then 'Consideracao'
        when lower(mkt_campaign) like '%awareness%' then 'Awareness'
        else 'Performance'
    end as media_funnel,
    'PF' as customer_type,
    sum(cost) * 0.5822 as investimento
from bronze.paid_media_investments as pmkt
where year(date) >= 2023
  and date < current_date
group by all

union all

select distinct
    pmkt.date as date_nao_usar,
    lower(ad_group) as ad_group,
    pmkt.mkt_campaign as mkt_campaign_pmkt,
    case
        when lower(pmkt.mkt_campaign) like '%pmax%' then 'display'
        else coalesce(pmkt.channel, 'unknown')
    end as channel_pmkt,
    lower(coalesce(pmkt.medium, 'unknown')) as medium_pmkt,
    lower(coalesce(pmkt.source, 'unknown')) as source_pmkt,
    case
        when lower(mkt_campaign) like '%consideracao%' then 'Consideracao'
        when lower(mkt_campaign) like '%awareness%' then 'Awareness'
        else 'Performance'
    end as media_funnel,
    'PJ' as customer_type,
    sum(cost) * 0.4178 as investimento
from bronze.paid_media_investments as pmkt
where year(date) >= 2023
  and date < current_date
group by all
```

### `f_mkt_performance`

**Dashboard:** Mkt Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_crm_result` [G]
- `gold.fact_customers` [G]
- `gold.fact_operations` [G]
- `gold.funnel_event` [G]
- `silver.customers` [S]
- `silver.histories` [S]
- `beecambio.beecambio_onboarding_qualification_answers` [B]
- `beecambio.beecambio_onboarding_qualification_form_options` [B]
- `beecambio.beecambio_onboarding_qualification_form_questions` [B]

**SQL completo:**

```sql
--------------------------------------------------
with crm as (
  select
    op.id_remittance as event_id,
    case
        when crm.event_id is not null then 'Com CRM'
        else 'Sem CRM'
    end as crm_status
  from gold.fact_crm_result as crm
  inner join gold.fact_operations as op on op.id_remittance = crm.event_id and op.is_ops_processed and op.is_intercompany = false
  where crm.event_type in ('OPERATION','ACQUISITION')
),

qualification as (
  SELECT distinct
    c.id as id_customer,
    a.id_question,
    o.goal as primeira_pergunta,
    CONCAT_WS(" | ", coalesce(o.goal, 'unknown'), o.title) as segunda_pergunta
  FROM silver.customers c
  left join prod.beecambio.beecambio_onboarding_qualification_answers a on c.id = a.id_customer
  left join prod.beecambio.beecambio_onboarding_qualification_form_questions q on q.id = a.id_question
  left join prod.beecambio.beecambio_onboarding_qualification_form_options o on o.id = a.id_option
),

leadscore as (
  select
    id_customer,
    `Conversion Value` as score
  from sandbox_datascience.leadscore_notas_pf
  union
  select
    id_customer,
    `Conversion Value` as score
  from sandbox_datascience.leadscore_notas_pj
)

select
    fe.event_id,
    fe.id_customer,
    fe.event_type,
    date(fe.event_tstamp) as event_date,
    case
        when date(fe.event_tstamp) = po.psu_date
        then 'Acquisition Date = Presignup Date'
        else 'Acquisition Date <> Presignup Date'
    end as acq_date_equal_psu_date,
    case
        when po.psu_date is null then 'NÃ£o convertido'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 5 then '00 a 05 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 10 then '06 a 10 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 20 then '11 a 20 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 30 then '21 a 30 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 40 then '31 a 40 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 50 then '41 a 50 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 60 then '51 a 60 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 90 then '61 a 90 dias'
        when date_diff(date(fe.event_tstamp), po.psu_date) <= 120 then '91 a 120 dias'
        else '120+ dias'
    end as cohort_psu_acq,
    date(date_trunc('month', fe.event_tstamp)) as event_month,
    case
        when lc.mkt_campaign_psu like '%pmax%'
        then 'display'
        else coalesce(lc.channel_psu, 'unknown')
    end as canal_lc,
    lower(coalesce(lc.source_psu, 'unknown')) as source_lc,
    lower(coalesce(lc.medium_psu, 'unknown')) as medium_lc,
    lc.origin_platform_psu,
    lower(coalesce(lc.utm_adgroup_psu, 'unknown')) as ad_group_lc,
    COALESCE(TRIM(lc.mkt_campaign_psu), 'organic/direct') as mkt_campaign_lc,
    lc.cluster_campaign_psu as cluster_campaign_lc,
    lc.media_funnel_psu as media_funnel_lc,

    case
        when fc.mkt_campaign like '%pmax%'
        then 'display'
        else coalesce(fc.canal, 'unknown')
    end as canal_fc,
    COALESCE(TRIM(fc.mkt_campaign), 'organic/direct') as mkt_campaign_fc,

    lc.device_brand_psu,
    lc.device_browser_psu,
    lc.device_category_psu,
    lc.device_name_psu,
    lc.os_name_psu,
    lc.os_psu,
    lc.first_page_url_psu as first_page_url,
    URL_DECODE(REGEXP_EXTRACT(lc.first_page_url_psu, 'utm_term=([^&]*)', 1)) as search_term,
    lc.first_page_path_tratado_psu as first_page_path_tratado,
    lc.cluster_url_psu as cluster_url,
    case
        when sv.email like '%fxaas%' then 'fxaas'
        else 'Sem fxaas'
    end as email_fxaas,
    case
        when (lc.channel_psu = 'paid link' and fe.event_type <> 'ACQUISITION' and fe.event_type <> 'OPERATION') then 'Affiliate'
        when fe.event_type in ('ACQUISITION', 'OPERATION') and po.is_affiliate = true then 'Affiliate'
        else 'Direct'
    end as customer_subtype,
    lc.customer_type,
    lc.company_type,
    lc.nationality,
    lc.onboarding_type,
    lc.company_onboarding_flow,
    lc.session_description as cnae_session,
    lc.division_description as cnae_division,
    lc.group_description as cnae_group,
    lc.class_description as cnae_class,
    lc.subclass as cnae_subclass,
    date(lc.signup_completed_tstamp) as signup_date,
    date(lc.acquisition_tstamp) as acquisition_date,
    po.processed_date as operation_date,
    date(date_trunc('month', lc.signup_completed_tstamp)) as signup_month,
    date(date_trunc('month', lc.acquisition_tstamp)) as acquisition_month,
    date(date_trunc('month', po.processed_date)) as operation_month,
    po.psu_date,
    po.is_affiliate,
    po.in_or_out,
    po.currency_abbreviation,
    po.acquisition,
    coalesce(po.ops_symbolic_api, false) as ops_simbolica_api,
    po.voucher_code,
    po.voucher_type,
    case
        when po.voucher_code is not null
        then 'Com Voucher'
        else 'Sem Voucher'
    end as fl_voucher,
    po.nature_operation_name,
    po.country,
    po.operation_platform_beecambio,
    po.operation_platform_ga4,
    po.gmv,
    po.operation_segment,
    po.bu,
    po.business_type,
    po.gross_revenue,
    po.applied_discount_1,
    po.applied_discount_2,
    po.applied_discount_3,
    case when date(date_trunc('month', fe.event_tstamp)) = date(date_trunc('month', lc.acquisition_tstamp)) then true else false end as month_psu_equal_month_acq,
    case when date(date_trunc('month', fe.event_tstamp)) = date(date_trunc('month', lc.signup_completed_tstamp)) then true else false end as month_psu_equal_month_su,
    case when date(date_trunc('month', lc.acquisition_tstamp)) = date(date_trunc('month', lc.signup_completed_tstamp)) then true else false end as month_su_equal_month_acq,
    coalesce(crm.crm_status, 'Sem CRM') as crm_status,
    case
        when fe.event_type = 'APPROVED STORY' and fh.nature_operation_name = 'Global Account' then 'HistÃ³ria de Conta Global'
        when fe.event_type = 'APPROVED STORY' and fh.nature_operation_name <> 'Global Account' then 'NÃ£o Ã© HistÃ³ria de Conta Global'
        else 'NÃ£o Ã© event_type = APPROVED STORY'
    end as history_name,
    s.subsegment as high_mid_low,
    coalesce(q.primeira_pergunta, 'unknown') as primeira_pergunta,
    coalesce(q.segunda_pergunta, 'unknown') as segunda_pergunta,
    lc.onb_ops_type as onb_ops_type_pj,
    lc.onb_reason as onb_reason_pj,
    lc.onb_digital_platform_pj,
    lc.onb_amount_pj,
    lc.onb_forecast_pj,
    lc.has_affiliate_ops_rec,
    lc.has_affiliate_ops_acq,
    ld.score,
    current_timestamp() - interval '3' hour as last_update
from gold.funnel_event as fe
    left join silver.customers as sv on fe.id_customer = sv.id
    left join gold.fact_customers as lc on fe.id_customer = lc.id_customer
    left join silver.histories as fh on fe.event_type = 'APPROVED STORY' and fe.event_id = fh.id_history
    left join gold.fact_operations as po on fe.event_id = po.id_remittance and fe.event_type in ('ACQUISITION', 'OPERATION') and po.is_ops_processed
    left join crm on fe.event_id = crm.event_id
    left join stage.dim_monthly_subsegmentation as s on fe.event_type in ('ACQUISITION', 'OPERATION') and fe.id_customer = s.id_customer and date_trunc('month', fe.event_tstamp) = s.month
    left join qualification as q on fe.id_customer = q.id_customer
    left join google_analytics.first_click_sessions as fc on fc.id_customer = fe.id_customer
    left join leadscore as ld on fe.id_customer = ld.id_customer
where date(fe.event_tstamp) >= '2024-01-01'
    and fe.event_sequence = 1
    and fe.event_type in ('ACQUISITION', 'APPROVED STORY', 'CREATED STORY', 'PRESIGNUP', 'SIGNUP')
    or fe.event_type = 'OPERATION'
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
