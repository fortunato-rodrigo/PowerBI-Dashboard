# Queries SQL -- Scorecard
> Gerado em: 15/05/2026 14:13 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Scorecard
> Fonte: `data_quality.tables_in_dashboards_pbix`

> **ALERTA:** 1 tabela(s) com conexao em camada `bronze`. Dados brutos sem transformacao -- validar antes de usar em KPIs.

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `f_operations` | gold, silver, bronze, beecambio | 10 tabelas | ALERTA bronze |

---

## Detalhamento por tabela

### `f_operations`

**Dashboard:** Scorecard - Business Performance
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_customers` [G]
- `gold.fact_operations` [G]
- `gold.fast_instant_analysis` [G]
- `gold.funnel_event` [G]
- `silver.customers` [S]
- `bronze.beecambio_qualification` [!]
- `bronze.dcalendar` [!]
- `bronze.hubspot_partners` [!]
- `beecambio.beecambio_tbl_customer` [B]
- `beecambio.beecambio_tbl_customer_login_provider` [B]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
with acq_afiliado as (
    select id_customer,
           office_name_affiliate as acq_office
    from gold.fact_operations
    where acquisition = true
      and is_ops_processed
      and office_name_affiliate is not null
      and is_intercompany = false
),
recorrente_nubank as (
    select distinct id_customer,
           'Cliente Recorrente Nubank' as recorrente_nubank
    from gold.fact_operations
    where acquisition = false
      and is_intercompany = false
      and is_ops_processed
      and office_name_affiliate = 'Nubank'
),
recorrente_afiliado as (
    select distinct id_customer,
           'Cliente Recorrente Afiliado (Sem Nubank)' as recorrente_afiliado
    from gold.fact_operations
    where acquisition = false
      and is_intercompany = false
      and is_ops_processed
      and is_affiliate = true
      and office_name_affiliate <> 'Nubank'
),
monthly_payers AS (
    SELECT id_customer,
           month,
           count(distinct contraparte_ajustada) as unique_payers
    FROM (
        SELECT DISTINCT
               op.id_customer,
               DATE_TRUNC('month', op.processed_date) as month,
               CASE
                   WHEN op.counterpart = 'Outros' then op.original_counterpart
                   ELSE op.counterpart
               END as contraparte_ajustada
        FROM gold.fact_operations as op
        WHERE op.in_or_out = 'Receiving'
          AND op.counterpart is not null
          AND is_ops_processed
          AND is_intercompany = false
    )
    GROUP BY ALL
),
high_pj_servicos as (
    with temp as (
        select distinct id_customer,
               count(distinct case when nature_operation_name = 'ServiÃ§os' then nature_operation_name else null end) as natureza_servicos,
               count(distinct case when nature_operation_name in (
                   'Aluguel de imÃ³vel',
                   'Aporte',
                   'Compra de imÃ³vel',
                   'EmprÃ©stimo',
                   'Ganho de capital',
                   'Mercadorias',
                   'Pagamento de dÃ­vidas',
                   'Pagamento de locaÃ§Ã£o',
                   'Sociedade Empresarial',
                   'Venda de imÃ³vel'
               ) then nature_operation_name else null end) as natureza_not_servicos
        from gold.fact_operations
        where is_intercompany = false
          and customer_type = 'PJ'
          and is_ops_processed
        group by id_customer
    )
    select distinct id_customer,
           case when natureza_servicos = 1 and natureza_not_servicos >= 1 then true else false end as high_pj_servicos
    from temp
),
clientes_diretos_hubspot as (
    select partner_name,
           owner_name,
           partnership_details,
           id_office,
           case
               when partnership_details = 'Diretos - PJ'
               then lpad(regexp_replace(cast(cnpj AS STRING), '[^0-9]', ''), 14, '0')
               when partnership_details = 'Diretos - PF'
               then lpad(regexp_replace(cast(cnpj AS STRING), '[^0-9]', ''), 11, '0')
           end AS cnpj_formatado,
           creation_date__remap,
           partnership_details
    from bronze.hubspot_partners
    where partnership_details like 'Diretos%'
    qualify row_number() over (partition by cnpj_formatado order by creation_date__remap desc) = 1
),
origem_psu as (
    SELECT clp.customer_id,
           clp.provider
    FROM beecambio.beecambio_tbl_customer_login_provider clp
    JOIN beecambio.beecambio_tbl_customer c
      ON c.id = clp.customer_id
    WHERE clp.deleted_at IS NULL
      AND clp.linked_at_signup = TRUE
      AND clp.created_at >= '2026-04-01 00:00:00'
      AND c.deleted = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY clp.customer_id ORDER BY clp.created_at DESC) = 1
)
select
    op.id_remittance,
    op.link_backoffice,
    op.id_customer,
    op.bu,
    op.business_type,
    op.bu_old,
    op.business_type_old,
    op.customer_type,
    op.processed_date as processing_date,
    date_trunc('month', date(ac.event_tstamp)) as acquisition_month,
    date_trunc('month', date(op.psu_date)) as presignup_month,
    hour(op.processed_tstamp) as processing_hour,
    minute(op.processed_tstamp) as processing_minute,
    date_format(op.processed_tstamp, 'HH:mm:00') as processing_hour_minute,
    op.account_manager,
    op.is_efx,
    op.operation_platform_beecambio,
    op.is_fxaas,
    op.is_corporate_api,
    op.is_automatic_operation,
    op.company_type,
    sc.company_member_association_type,
    sc.company_shareholders_count,
    sc.company_shareholders_with_document,
    op.acquisition,
    op.is_partner,
    coalesce(op.product_from_fxaas, 'REMESSA ONLINE') as product,
    op.coleta_local,
    op.country,
    op.customer_category,
    op.ops_symbolic_api as ops_simbolicas_api,
    op.quantity,
    op.tariff,
    op.gmv,
    op.gross_revenue,
    op.gross_revenue_original,
    op.diff_gross_revenue,
    op.gross_profit,
    case
        when op.customer_type = 'PF' and op.gmv <= 5000 then '0-5k'
        when op.customer_type = 'PF' and op.gmv <= 10000 then '5k-10k'
        when op.customer_type = 'PF' and op.gmv <= 20000 then '10k-20k'
        when op.customer_type = 'PF' and op.gmv <= 40000 then '20k-40k'
        when op.customer_type = 'PF' and op.gmv <= 75000 then '40k-75k'
        when op.customer_type = 'PF' and op.gmv <= 200000 then '75k-200k'
        when op.customer_type = 'PF' and op.gmv > 200000 then '+200k'
        when op.customer_type = 'PJ' and op.gmv <= 250000 then '0-250k'
        when op.customer_type = 'PJ' and op.gmv <= 500000 then '250k-500k'
        when op.customer_type = 'PJ' and op.gmv <= 1000000 then '500k-1MM'
        when op.customer_type = 'PJ' and op.gmv > 1000000 then '+1MM'
    end as ticket_range_v2,
    case
        when op.customer_type = 'PF' and op.gmv <= 5000     then '0-5k'
        when op.customer_type = 'PF' and op.gmv <= 10000    then '5k-10k'
        when op.customer_type = 'PF' and op.gmv <= 25000    then '10k-25k'
        when op.customer_type = 'PF' and op.gmv <= 50000    then '25k-50k'
        when op.customer_type = 'PF' and op.gmv <= 130000   then '50k-130k'
        when op.customer_type = 'PF' and op.gmv <= 270000   then '130k-270k'
        when op.customer_type = 'PF' and op.gmv <= 500000   then '270k-500k'
        when op.customer_type = 'PF' and op.gmv <= 1000000  then '500k-1M'
        when op.customer_type = 'PF' and op.gmv <= 2500000  then '1M-2.5M'
        when op.customer_type = 'PF' and op.gmv > 2500000   then '+2.5M'
        when op.customer_type = 'PJ' and op.gmv <= 10000    then '0-10k'
        when op.customer_type = 'PJ' and op.gmv <= 25000    then ' 10k-25k'
        when op.customer_type = 'PJ' and op.gmv <= 50000    then ' 25k-50k'
        when op.customer_type = 'PJ' and op.gmv <= 100000   then '50k-100k'
        when op.customer_type = 'PJ' and op.gmv <= 200000   then '100k-200k'
        when op.customer_type = 'PJ' and op.gmv <= 400000   then '200k-400k'
        when op.customer_type = 'PJ' and op.gmv <= 600000   then '400k-600k'
        when op.customer_type = 'PJ' and op.gmv <= 800000   then '600k-800k'
        when op.customer_type = 'PJ' and op.gmv <= 1000000  then '800k-1M'
        when op.customer_type = 'PJ' and op.gmv <= 2500000  then '1M-2.5M'
        else 'Other'
    end as ticket_range_v3,
    case
        when op.gross_profit < 0 then 'Com PrejuÃ­zo'
        else 'Sem PrejuÃ­zo'
    end as gross_profit_flag,
    op.real_message_cost as cost_mensage,
    op.cost_bank_take as cost_bank_take,
    op.payout_affiliate as cost_payout_affiliate,
    op.spread,
    op.fixed_spread = op.spread as fixed_spread_equal_spread,
    op.spread_original,
    op.fixed_spread,
    op.has_fixed_spread,
    (op.spread_original - op.spread) * 100 as spread_dif,
    CASE
        WHEN (op.spread_original - op.spread) * 100 <= 0 THEN ' Sem Desconto'
        WHEN (op.spread_original - op.spread) * 100 <= 0.05 THEN 'Desconto atÃ© 5%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.10 THEN 'Desconto entre 5% e 10%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.15 THEN 'Desconto entre 10% e 15%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.20 THEN 'Desconto entre 15% e 20%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.25 THEN 'Desconto entre 20% e 25%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.30 THEN 'Desconto entre 25% e 30%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.35 THEN 'Desconto entre 30% e 35%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.40 THEN 'Desconto entre 35% e 40%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.45 THEN 'Desconto entre 40% e 45%'
        WHEN (op.spread_original - op.spread) * 100 <= 0.50 THEN 'Desconto entre 45% e 50%'
        ELSE 'Desconto maior de 50%'
    END as desconto,
    op.in_or_out,
    op.segment,
    op.operation_segment,
    op.subsegment as high_mid_low,
    op.nature_operation_name as natureza,
    op.currency_abbreviation as currency,
    op.operation_event_type as event_type_ops,
    op.premium_status as is_premium_user,
    op.id_purpose_of_remittance as purpose_of_remittance,
    op.is_comex,
    op.service_description,
    op.description_purpose_of_remittance as description_purpose_classification,
    op.office_name_affiliate as office,
    op.travel_agency_affiliate,
    case
        when op.office_name_affiliate = 'Nubank' and op.processed_date <= '2024-05-18' then 'Nubank PrÃ©-tombamento'
        when op.office_name_affiliate = 'Nubank' and op.processed_date > '2024-05-18' then 'Nubank PÃ³s-tombamento'
        else null
    end as nubank,
    nu.recorrente_nubank,
    rf.recorrente_afiliado,
    af.acq_office,
    case
        when op.acquisition = true then 'AquisiÃ§Ã£o'
        when op.office_name_affiliate = af.acq_office then 'Com Match - RecorrÃªncia de Afiliado e a AquisiÃ§Ã£o foi do mesmo Afiliado'
        when op.office_name_affiliate is not null and af.acq_office is not null then 'Sem Match - RecorrÃªncia de Afiliado, mas a AquisiÃ§Ã£o foi de outro Afiliado'
        when op.office_name_affiliate is null and af.acq_office is not null then 'RecorrÃªncia Sem Afiliado e AquisiÃ§Ã£o foi via Afiliado'
        when op.office_name_affiliate is not null and af.acq_office is null then 'RecorrÃªncia de Afiliado e AquisiÃ§Ã£o Sem Afiliado'
        else 'RecorrÃªncia e AquisiÃ§Ã£o Sem Afiliado'
    end as flag_affiliate,
    op.reactivation,
    case
        when op.customer_type = 'PF'
         and op.in_or_out = 'Receiving'
         and op.id_purpose_of_remittance = 67005
         and op.nature_operation_name = 'Ganho em aÃ§Ãµes'
        then true
        else false
    end as stock_option,
    case
        when op.acquisition then 'ACQUISITION'
        else 'REPURCHASE'
    end as event_type,
    case
        when op.acquisition then 'AquisiÃ§Ã£o'
        else 'RecorrÃªncia'
    end as acq_rec,
    case
        when op.mid then 'Mid'
        else 'Not Mid'
    end as is_mid,
    case
        when op.is_affiliate = true then 'Yes'
        else 'No'
    end as is_affiliate,
    case
        when op.affiliate_source = '1_hasoffers' then 'OperaÃ§Ã£o de Afiliado - Hasoffers'
        when op.affiliate_source = '2_applied_discount' then 'OperaÃ§Ã£o de Afiliado - Beecambio'
        when op.affiliate_source = '3_nubankers' then 'OperaÃ§Ã£o de Afiliado - Ex-Nubank'
        else 'OperaÃ§Ã£o Sem Afiliado'
    end as affiliate_source,
    case
        when op.voucher_code is not null then true
        else false
    end as fl_voucher,
    op.genre,
    op.voucher_code,
    op.swift_or_distributor,
    op.distributor_name as distributor_name_og,
    case
        when op.office_name_affiliate in ('Nubank', 'Vivo Empresas', 'Flash', 'Claro Clube Empresas', 'Banco Linker', 'Strider Inc', 'NinjaTrader') then true
        else false
    end as is_parceiros_referral,
    case
        op.office_name_affiliate
        when 'Nubank' then 'Nubank'
        when 'Vivo Empresas' then 'Vivo'
        when 'Flash' then 'Flash'
        when 'Claro Clube Empresas' then 'Claro Clube Empresas'
        when 'Banco Linker' then 'Banco Linker'
        when 'Strider Inc' then 'Strider Inc'
        when 'NinjaTrader' then 'NinjaTrader'
        else 'Not referral'
    end as parceiros_referral,
    case
        when op.gmv_usd <= 1000 then 1000
        when op.gmv_usd <= 10000 then 10000
        when op.gmv_usd <= 100000 then 100000
        else 1000000
    end as indece_valor_usd,
    op.applied_discount,
    op.applied_discount_1,
    op.applied_discount_2,
    op.applied_discount_3,
    op.mgm_code,
    op.mgm_operation_type,
    op.voucher_type,
    sc.channel_psu as canal,
    sc.medium_psu as medium,
    sc.source_psu as source,
    sc.mkt_campaign_psu as mkt_campaign,
    sc.first_page_url_psu as page_url,
    sc.origin_platform_psu,
    nfc.canal as canal_fc,
    nfc.medium as medium_fc,
    nfc.source as source_fc,
    coalesce(nfc.mkt_campaign, 'organic/direct') as mkt_campaign_fc,
    op.cnae_subclass as cnae_subclass,
    op.cnae_session_description as cnae_session,
    op.cnae_division_description as cnae_division,
    op.cnae_group_description as cnae_group,
    op.cnae_class_description as cnae_class,
    op.company_onboarding_flow,
    op.onboarding_type,
    op.remittance_limit_approved,
    CASE
        WHEN op.counterpart = 'Outros' then op.original_counterpart
        ELSE op.counterpart
    END as contraparte,
    CASE
        WHEN op.counterpart = 'Google' then TRUE
        ELSE FALSE
    END AS google,
    CASE
        WHEN unique_payers = 1 THEN 'Profissional'
        WHEN unique_payers > 1 THEN 'Empreendedor/PME'
    END as customer_segment,
    c.mtd,
    c.workday_processado,
    c.mtd_calendar_days,
    op.partner_name_from_maxima_code as partner_name,
    op.partner_name_from_fxaas,
    CASE
        WHEN op.customer_type = 'PJ' THEN
            CASE
                WHEN op.nature_operation_name IN ('ServiÃ§os de veiculaÃ§Ã£o digital', 'Facilitadora', 'Crypto') THEN false
                WHEN op.remittance_limit_approved >= 2000000 and any_value(sv.high_pj_servicos) = true THEN true
                WHEN SUM(op.gmv) >= 2000000 AND op.processed_date >= current_date - INTERVAL '12' MONTH THEN true
                WHEN op.gmv >= 260000 THEN true
                WHEN op.remittance_limit_approved >= 2000000 THEN true
                WHEN op.operation_segment = 'Capital' AND op.nature_operation_name <> 'Disponibilidade' THEN true
                WHEN op.nature_operation_name = 'Mercadorias' AND op.gmv >= 3000 THEN true
                WHEN op.nature_operation_name IN ('EmprÃ©stimo', 'Conta investimento', 'Retorno de investimento') THEN true
                ELSE false
            END
        ELSE false
    END AS high_pj,
    op.payment_type as payment_method,
    op.melhor_cambio,
    sc.city as geo_city,
    sc.timezone as geo_timezone,
    upper(sc.state) as geo_state,
    sc.is_international,
    case
        when sc.age < 18 then ' <18'
        when sc.age between 18 and 24 then ' 18-24'
        when sc.age between 25 and 34 then ' 25-34'
        when sc.age between 35 and 44 then ' 35-44'
        when sc.age between 45 and 54 then ' 45-54'
        when sc.age between 55 and 64 then ' 55-64'
        when sc.age > 64 then ' 65+'
        else 'No info'
    end as age,
    op.discount_category,
    op.recipient_name as corretora,
    op.bank_name_recipient as bank_name,
    op.rmi_status as rmi,
    ia.is_instant,
    if(csh.cnpj_formatado is not null, true, false) as cliente_prospeccao,
    op.gmv_usd,
    op.is_cnr,
    op.purpose_of_remittance_operation,
    ps.provider,
    op.is_potencial_premium,
    coalesce(bq.onb_ops_type,'S/ resposta') as onb_ops_type,
    coalesce(bq.onb_reason,'S/ resposta') as onb_reason,
    current_timestamp() - interval '3' hour as last_update
from gold.fact_operations as op
    left join gold.fact_customers as sc on op.id_customer = sc.id_customer
    left join google_analytics.first_click_sessions as nfc on op.id_customer = nfc.id_customer
    left join high_pj_servicos as sv on op.id_customer = sv.id_customer
    left join acq_afiliado as af on op.id_customer = af.id_customer
    left join recorrente_nubank as nu on op.id_customer = nu.id_customer
    left join recorrente_afiliado as rf on op.id_customer = rf.id_customer
    left join monthly_payers as mp on op.id_customer = mp.id_customer and date_trunc('month', op.processed_date) = mp.month
    left join gold.funnel_event as ac on op.id_customer = ac.id_customer and ac.event_type = 'ACQUISITION'
    left join bronze.dcalendar as c on c.date_key = op.processed_date
    left join prod.gold.fast_instant_analysis as ia on op.id_remittance = ia.id_remittance
    left join silver.customers as c on c.id = sc.id_customer
    left join clientes_diretos_hubspot as csh on c.cnpj_cpf_client = csh.cnpj_formatado
    left join origem_psu as ps on op.id_customer = ps.customer_id
    left join bronze.beecambio_qualification as bq on bq.id_customer = op.id_customer
where op.is_intercompany = false
  and op.is_ops_processed = true
  and op.processed_date >= '2023-01-01'
  and op.processed_date < current_date
group by all
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
