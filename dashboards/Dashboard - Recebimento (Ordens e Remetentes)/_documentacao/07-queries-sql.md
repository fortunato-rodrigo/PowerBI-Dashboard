# Queries SQL -- Dashboard - Recebimento (Ordens e Remetentes)
> Gerado em: 15/05/2026 14:13 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Dashboard - Recebimento (Ordens e Remetentes)
> Fonte: `data_quality.tables_in_dashboards_pbix`

> **ALERTA:** 1 tabela(s) com conexao em camada `bronze`. Dados brutos sem transformacao -- validar antes de usar em KPIs.

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `f_credito_identificado` | beecambio | 7 tabelas | -- |
| `f_etapa_drop` | gold, silver, beecambio | 4 tabelas | -- |
| `f_fonte_entrada` | beecambio | 1 tabelas | -- |
| `f_orders` | gold, silver, bronze, beecambio | 6 tabelas | ALERTA bronze |

---

## Detalhamento por tabela

### `f_credito_identificado`

**Dashboard:** Dashboard - Recebimento (Ordens e Remetentes)
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `beecambio.beecambio_tbl_customer` [B]
- `beecambio.beecambio_tbl_payment_order` [B]
- `beecambio.beecambio_tbl_payment_order_remittance` [B]
- `beecambio.beecambio_tbl_payment_order_status` [B]
- `beecambio.beecambio_tbl_remittance_operation` [B]
- `beecambio.beecambio_tbl_remittance_operation_status` [B]
- `beecambio.beecambio_tbl_sender` [B]

**SQL completo:**

```sql
select
    O.id_customer,
    'P' || D.c_type as customer_type,
    O.id as id_ordem,
    S.name as status_ordem,
    PR.remittance_operation_id,
    case when PR.remittance_operation_id is not null then true else false end as has_remittance_operation,
    R.id_history,
    os.status as status_remittance_operation,
    N.name as remetente,
    O.created_at - interval '3' hour as created_at,
    concat('https://backoffice.remessaonline.com.br/index/detalhes-ordem-pagamento/', int(O.id)) as link,
    O.currency as moeda,
    O.amount_received as quantity,
    R.total_value as total_value_remittance_operation,
    R.quantity as quantity_remittance_operation,
    current_timestamp() - interval '3' hour as updated_at
from beecambio.beecambio_tbl_payment_order as O
    inner join beecambio.beecambio_tbl_sender as N on N.id = O.id_sender
    inner join beecambio.beecambio_tbl_payment_order_status as S on O.id_status = S.id
    inner join beecambio.beecambio_tbl_customer as D on D.id = O.id_customer
    left join beecambio.beecambio_tbl_payment_order_remittance as PR on O.id = PR.payment_order_id
    left join beecambio.beecambio_tbl_remittance_operation as R on PR.remittance_operation_id = R.id
    left join beecambio.beecambio_tbl_remittance_operation_status as os on os.id = R.id_status
where 1 = 1
    and O.id_status = 3 -- 'CrÃ©dito identificado'
    and O.id_financial_institution = 3 -- TopÃ¡zio
    and date(O.created_at) >= '2024-01-01'
    and PR.remittance_operation_id is not null
    and os.status = 'Finalizada'
```

### `f_etapa_drop`

**Dashboard:** Dashboard - Recebimento (Ordens e Remetentes)
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.funnel_event` [G]
- `silver.customers` [S]
- `silver.orders` [S]
- `beecambio.beecambio_tbl_customer_bank_account` [B]

**SQL completo:**

```sql
with psu as (
  select *
  from gold.funnel_event
  where
    event_type = 'PRESIGNUP'
    and event_tstamp >= date '2022-01-01'
),
signup as (
  select *
  from gold.funnel_event
  where event_type = 'SIGNUP'
),
operou as (
  select *
  from gold.funnel_event
  where event_type in ('ACQUISITION', 'OPERATION')
),
event as (
  (select
      id_customer,
      event_type as last_event,
      event_tstamp as event_date
    from gold.funnel_event)
  union
  (select
      id_customer,
      'COMPARTILHAMENTO DE DADOS' as last_event,
      created_at as event_date
    from beecambio.beecambio_tbl_customer_bank_account )
  union
  (select
      id_customer,
      status as last_event,
      created_date as event_date
    from silver.orders)
),
funnel as (
  select
    fe.id_customer,
    p.event_tstamp as psu_date,
    s.event_tstamp as signup_date,
    fe.event_date,
    fe.last_event,
    ROW_NUMBER()
      OVER (PARTITION BY fe.id_customer ORDER BY fe.event_date desc) AS funnel_order
  from event as fe
  inner join psu as p
    on fe.id_customer = p.id_customer
  left join signup as s
    on fe.id_customer = s.id_customer
  left join operou as op
    on fe.id_customer = op.id_customer
  where
    op.id_customer is null
)
select
  f.*,
  dc.customer_type,
  dc.onboarding_type,
  lc.canal,
  ce.session_description as cnae_session,
  ce.division_description as cnae_division
from funnel as f
left join silver.customers as dc
  on f.id_customer = dc.id
left join google_analytics.last_click_sessions as lc
  on f.id_customer = lc.id_customer
left join seeds.cnae_estruturado as ce
  on ce.id_cnae = dc.company_cnae_id
```

### `f_fonte_entrada`

**Dashboard:** Dashboard - Recebimento (Ordens e Remetentes)
**Ultima atualizacao na tabela Databricks:** 2026-04-22

**Tabelas Databricks referenciadas:**

- `beecambio.beecambio_tbl_payment_order` [B]

**SQL completo:**

```sql
with
erro_conc as (
  select
    correspondent_reference,
    error_reason
  from conciliation_service.conciliation_payment_orders
  where status = 'error'
)
select
  od.id,
  date_trunc('hour', od.created_at - interval '3' hour) data_criacao,
  bpo.code,
  od.created_via_opr,
  od.type,
  cpo.error_reason,
  od.correspondent_reference,
  od.created_at - interval 3 hour as created_at,
  bpo.created_at - interval 3 hour as created_at_api,
  date_diff(minute, bpo.created_at - interval 3 hour, od.created_at - interval 3 hour) as diff_falha_api,
  case
    when bpo.code is not null and date_diff(minute, bpo.created_at - interval 3 hour, od.created_at - interval 3 hour) <= 10 then 'API'
    when bpo.code is null and od.created_via_opr is true and od.type = 'normal' and cpo.error_reason is null then 'Arquivo da OPR'
    when cpo.error_reason is not null and od.created_via_opr is true then 'Ferramenta de Emenda'
    when od.type = 'massive_children' then 'Coleta Local'
    when od.created_via_opr is false then 'Emenda Manual'
    when od.type = 'wallet' then 'Wallet/Conta Global'
    when bpo.code is not null and date_diff(minute, bpo.created_at - interval 3 hour, od.created_at - interval 3 hour) > 10 then 'Falha API'
    else null
  end fonte_entrada
from beecambio.beecambio_tbl_payment_order as od
left join banking_payments.public_payment_order as bpo on od.correspondent_reference = bpo.code
left join erro_conc as cpo on od.correspondent_reference = cpo.correspondent_reference
where date(od.created_at) >= current_date - interval '12' month
```

### `f_orders`

**Dashboard:** Dashboard - Recebimento (Ordens e Remetentes)
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_operations` [G]
- `gold.funnel_event` [G]
- `silver.orders` [S]
- `bronze.dcalendar` [!]
- `beecambio.beecambio_tbl_customer` [B]
- `beecambio.beecambio_tbl_payment_order` [B]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
with share_banking as (
    select
        *
        except(sequence, event_timestamp)
    from (
        select
            *,
            row_number() over (partition by user_id order by event_timestamp asc) as sequence
        from (
            select
                user_id,
                platform as share_banking_platform,
                label as share_banking_label,
                event_timestamp,
                date(event_timestamp) as share_banking_date
            from google_analytics.ga4_web_event_attribution
            where
                event_name = 'share_bank_details'
                and user_id is not null

            union

            select
                user_id,
                platform as share_banking_platform,
                label as share_banking_label,
                event_timestamp,
                date(event_timestamp) as share_banking_date
            from google_analytics.ga4_app_event_attribution
            where
                event_name = 'share_bank_details'
                and user_id is not null
        )
    )
    where sequence = 1
),

segmentation as (
    select
        month,
        id_customer,
        subsegment as last_subsegment,
        row_number() over (partition by id_customer order by month desc) as row_number
    from stage.dim_monthly_subsegmentation
),

last_informations as (
    select
        p.id_customer,
        p.bu as last_bu,
        p.business_type as last_business_type,
        p.operation_segment as last_operation_segment,
        p.segment as last_segment,
        p.nature_operation_name as last_nature,
        p.processed_date as last_operation,
        row_number() over (partition by p.id_customer order by p.processed_tstamp desc) as row_number
    from gold.fact_operations as p
    where p.is_ops_processed
),

aquisicao as (
    select distinct
        fo.id_customer
    from gold.fact_operations as fo
    where is_ops_processed is true
)

select distinct
    do.*,
    do.aggregate_order_status as status_ordem_resumo,
    do.order_redeemed_in_the_same_month as resgate_mesmo_mes,
    date_trunc('hour', do.created_tstamp) as data_hora_criacao_ordem,
    case
        when do.customer_type = 'PF' then 'PF'
        else coalesce(b.company_onboarding_flow, 'offline')
    end as company_onboarding_flow,
    coalesce(ma.is_premium, false) as premium_status,
    do.financial_institution_number as external_financial_institution_id,
    coalesce(po.eligible_coleta_local, false) as elegivel_coleta_local,
    po.processed_date,
    po.quantity as valor_me,
    po.gmv as gmv,
    po.gross_revenue,
    coalesce(sb.share_banking_platform, 'No information') as share_banking_platform,
    coalesce(sb.share_banking_label, 'No information') as share_banking_label,
    date(do.redemption_tstamp) as redemption_date,
    sb.share_banking_date,
    date(ac.event_tstamp) as acquisition_date,
    date(ps.event_tstamp) as presignup_date,
    po.bu,
    po.voucher_code as cupom_desconto,
    case
        when po.voucher_code is null then 'Sem Cupom'
        else 'Cupom desconto'
    end as desconto,
    case
        when po.acquisition
            or a.id_customer is null then 'AquisiÃ§Ã£o'
        else 'RecorrÃªncia'
    end as funil,
    if(do.id_financial_institution = 3, 'TopÃ¡zio','Master') as instituicao_financeira,
    li.last_bu,
    li.last_business_type,
    li.last_segment,
    li.last_operation_segment,
    sg.last_subsegment,
    li.last_nature,
    li.last_operation,
    case
        when b.onboarding_type in ('instant', 'fast') then 'instant'
        else b.onboarding_type
    end as onboarding_type,
    case
        when do.counterpart is not null then do.counterpart
        else 'Outros'
    end as contraparte_ajustada_para_ranking_final,
    coalesce(lc.canal, nlc.canal) as canal,
    coalesce(lc.source, nlc.source) as source,
    coalesce(lc.medium, nlc.medium) as medium,
    coalesce(lc.mkt_campaign, nlc.mkt_campaign) as mkt_campaign,
    dc.mtd,
    dc.mtd_calendar_days,
    now() - interval '3' hour as data_atualizacao
from silver.orders as do
left join beecambio.beecambio_tbl_payment_order as od
    on do.id = od.id
left join prod.beecambio.beecambio_tbl_customer b
    on do.id_customer = b.id
left join stage.dim_monthly_premium as ma
    on do.id_customer = ma.id_customer
       and date_trunc('MONTH', ma.month) = date_trunc('MONTH', do.created_date)
left join gold.fact_operations as po
    on do.id_remittance = po.id_remittance
       and po.is_ops_processed
left join aquisicao as a
    on do.id_customer = a.id_customer
left join gold.funnel_event as ac
    on do.id_customer = ac.id_customer
       and ac.event_type = 'ACQUISITION'
left join gold.funnel_event as ps
    on do.id_customer = ps.id_customer
       and ps.event_type = 'PRESIGNUP'
left join share_banking as sb
    on do.id_customer = sb.user_id
left join last_informations as li
    on do.id_customer = li.id_customer
       and li.row_number = 1
left join segmentation as sg
    on do.id_customer = sg.id_customer
       and sg.row_number = 1
left join legacy.last_click_old as lc
    on do.id_customer = lc.id_customer
       and lc.presignup_date < '2023-08-01'
left join google_analytics.last_click_sessions as nlc
    on do.id_customer = nlc.id_customer
       and nlc.event_date >= '2023-08-01'
left join bronze.dcalendar as dc
    on date(do.created_date) = dc.date_key
where do.created_date >= '2024-01-01'
    and boolean(od.deleted) = false
    and lower(do.counterpart) not like '%remessa online%'
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
