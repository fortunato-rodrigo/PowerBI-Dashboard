# Queries SQL -- Dashboard de Safras
> Gerado em: 15/05/2026 14:06 | Script: tools/Extract-QueryMetadata.ps1 -Dashboard Dashboard de Safras
> Fonte: `data_quality.tables_in_dashboards_pbix`

> **ALERTA:** 1 tabela(s) com conexao em camada `bronze`. Dados brutos sem transformacao -- validar antes de usar em KPIs.

---

## Resumo de linhagem

| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |
|---|---|---|---|
| `d_intervalo_meses` |  | 0 tabelas | -- |
| `f_funnel_events` | gold, silver, bronze, beecambio | 18 tabelas | ALERTA bronze |

---

## Detalhamento por tabela

### `d_intervalo_meses`

**Dashboard:** Dashboard de Safras
**Ultima atualizacao na tabela Databricks:** 2026-05-13


**SQL completo:**

```sql
A consulta Powerâ¯Query que vocÃª forneceu nÃ£o contÃ©m nenhuma instruÃ§Ã£o SQL â ela apenas cria uma tabela a partir de dados embutidos (usando `Table.FromRows` e `Json.Document`). Portanto, nÃ£o hÃ¡ SQL a ser extraÃ­do.
```

### `f_funnel_events`

**Dashboard:** Dashboard de Safras
**Ultima atualizacao na tabela Databricks:** 2026-05-13

**Tabelas Databricks referenciadas:**

- `gold.fact_customers` [G]
- `gold.fact_operations` [G]
- `gold.funnel_event` [G]
- `silver.customers` [S]
- `silver.orders` [S]
- `silver.requirement` [S]
- `bronze.beecambio_history` [!]
- `beecambio.beecambio_company_qualification` [B]
- `beecambio.beecambio_onboarding_qualification_answers` [B]
- `beecambio.beecambio_onboarding_qualification_form_options` [B]
- `beecambio.beecambio_onboarding_qualification_form_questions` [B]
- `beecambio.beecambio_registration_form` [B]
- `beecambio.beecambio_tbl_customer` [B]
- `beecambio.beecambio_tbl_customer_address` [B]
- `beecambio.beecambio_tbl_customer_bank_account` [B]
- `beecambio.beecambio_tbl_customer_login_provider` [B]
- `beecambio.beecambio_tbl_document` [B]
- `beecambio.beecambio_tbl_remittance_operation` [B]

> **ALERTA:** Esta tabela acessa a camada `bronze` -- dado bruto, sem transformacao DBT. Verificar se e intencional.

**SQL completo:**

```sql
with recipient_name as (
select
  id_customer,
  max(id_recipient) as id_recipient
from beecambio.beecambio_tbl_remittance_operation
where id_recipient IS NOT NULL
group by all
),

orders as (
SELECT
  id_customer,
  count(id) as orders,
  count(case when aggregate_order_status = 'Resgatado' then id else null end) as redeemed_orders
FROM silver.orders
GROUP BY 1
),

created_ops as (
  select
    id_customer,
    count(id) as created_ops
  from beecambio.beecambio_tbl_remittance_operation
  group by all
),

bank_name as (
select
  ba.id_customer,
  ba.bank_name,
  ba.created_at,
  row_number() over (partition by ba.id_customer order by ba.created_at desc) as rn
from beecambio.beecambio_tbl_customer_bank_account as ba
qualify rn = 1
),

documentos_validos AS (
  SELECT
    id_customer,
    created_at,
    doc_status,
    ROW_NUMBER() OVER (PARTITION BY id_customer ORDER BY created_at) AS tentativa_envio
  FROM beecambio.beecambio_tbl_document
  WHERE id_doc_type = 2
    AND deleted = 'false'
    AND created_at >= '2024-01-01'
),

primeira_aprovacao AS (
  SELECT *
  FROM documentos_validos
  WHERE doc_status = 3 -- Aprovado
),

tentativas_doc_aprovado AS (
  SELECT
    id_customer,
    MIN(tentativa_envio) AS tentativa_documento_aprovado
  FROM primeira_aprovacao
  GROUP BY id_customer
),

ops AS (
  SELECT
    id_customer,
    COUNT(id_remittance) as operations
  FROM gold.fact_operations
  WHERE is_ops_processed
    AND is_intercompany = FALSE
    AND processed_date >= '2024-01-01'
  GROUP BY id_customer
),

patrimony as (
SELECT
  RF.customer_id,
  RF.patrimony,
  ROW_NUMBER() OVER (PARTITION BY RF.customer_id ORDER BY RF.created_at DESC) seq
FROM beecambio.beecambio_registration_form RF
WHERE deleted = false
),

qualification as (
  SELECT distinct
    c.id as id_customer,
    a.id_question,
    coalesce(o.goal, 'unknown') as primeira_pergunta,
    CONCAT_WS(" | ", coalesce(o.goal, 'unknown'), o.title) as segunda_pergunta
  FROM silver.customers c
  left join prod.beecambio.beecambio_onboarding_qualification_answers a on c.id = a.id_customer
  left join prod.beecambio.beecambio_onboarding_qualification_form_questions q on q.id = a.id_question
  left join prod.beecambio.beecambio_onboarding_qualification_form_options o on o.id = a.id_option
),

origem_psu as (
    SELECT
      clp.customer_id,
      clp.provider
    FROM beecambio.beecambio_tbl_customer_login_provider clp
    JOIN beecambio.beecambio_tbl_customer c
      ON c.id = clp.customer_id
    WHERE clp.deleted_at IS NULL
      AND clp.linked_at_signup = TRUE
      AND clp.created_at >= '2026-04-01 00:00:00'
      AND c.deleted = FALSE
    QUALIFY ROW_NUMBER() OVER(PARTITION BY clp.customer_id ORDER BY clp.created_at DESC) = 1
),

final as (
SELECT
    fe.* except(fe.event_tstamp, fe.requirement_type, fe.ocr),
    DATE(fe.event_tstamp) as event_date,
    DATE_TRUNC('month', fe.event_tstamp) AS event_month,
    CASE fe.event_type
        WHEN 'PRESIGNUP' THEN 1
        WHEN 'SIGNUP' THEN 2
        WHEN 'CREATED STORY' THEN 3
        WHEN 'APPROVED STORY' THEN 4
        WHEN 'ACQUISITION' THEN 5
        WHEN 'OPERATION' THEN 6
    END AS event_type_id,
    dc.channel_psu as canal_lc,
    LOWER(COALESCE(dc.source_psu, 'unknown')) AS source_lc,
    LOWER(COALESCE(dc.medium_psu, 'unknown')) AS medium_lc,
    dc.origin_platform_psu,
    dc.os_psu as os,
    dc.os_name_psu as os_name,
    dc.device_brand_psu as device_brand,
    dc.device_name_psu as device_name,
    dc.device_category_psu as device_category,
    dc.device_browser_psu as device_browser,
    dc.mkt_campaign_psu as mkt_campaign_lc,
    dc.cluster_campaign_psu AS cluster_campaign_lc,
    dc.media_funnel_psu as media_funnel_lc,
    dc.utm_adgroup_psu as ad_group_lc,
    dc.first_page_url_psu AS first_page_url,
    dc.first_page_path_tratado_psu,
    lc.first_page_cluster_url AS cluster_url,
    lc.last_page_path_tratado AS last_page_path_tratado,
    dc.company_type,
    dc.age,
    dc.nationality,
    dc.state,
    dc.city,
    CASE
        WHEN sv.email LIKE '%fxaas%' THEN 'Email fxaas'
        ELSE 'Default - Sem fxaas'
    END AS email_fxaas,
    CASE
      WHEN dc.signup_completed_tstamp IS NOT NULL THEN TRUE
      ELSE FALSE
    END AS full_registration,
    sv.company_member_association_type,
    sv.company_shareholders_count,
    sv.company_shareholders_with_document,
    dc.session_description AS cnae_session,
    dc.division_description AS cnae_division,
    dc.group_description AS cnae_group,
    dc.class_description AS cnae_class,
    dc.subclass AS cnae_subclass,
    DATE(dc.psu_tstamp) AS presignup_date,
    DATE(dc.signup_completed_tstamp) AS signup_date,
    DATE(hc.event_tstamp) AS created_history_date,
    DATE(hi.event_tstamp) AS approved_history_date,
    DATE(dc.acquisition_tstamp) AS acquisition_date,
    EXTRACT(YEAR FROM DATE(dc.acquisition_tstamp)) AS acquisition_year,
    DATE(so.event_tstamp) AS second_operation_date,
    po.processed_date as operation_date,
    DATE_TRUNC('month', dc.psu_tstamp) AS presignup_month,
    DATE_TRUNC('month', dc.signup_completed_tstamp) AS signup_month,
    DATE_TRUNC('month', hi.event_tstamp) AS approved_history_month,
    DATE_TRUNC('month', dc.acquisition_tstamp) AS acquisition_month,
    DATE_TRUNC('month', so.event_tstamp) AS second_operation_month,
    DATE_TRUNC('month', po.processed_date) AS operation_month,
    DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(dc.signup_completed_tstamp)) AS diff_days_psu_to_su,
    DATEDIFF(DAY, DATE(dc.signup_completed_tstamp), DATE(dc.acquisition_tstamp)) AS diff_days_su_to_acq,
    dc.days_to_conversion as diff_days_psu_to_acq,
    DATEDIFF(DAY, DATE(dc.acquisition_tstamp), DATE(so.event_tstamp)) AS diff_days_acq_to_sec,
    DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(hc.event_tstamp)) AS diff_days_psu_to_created_history,
    DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(hi.event_tstamp)) AS diff_days_psu_to_approved_history,
    CASE
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 0 THEN '  D0'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 1 THEN '  D1'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 2 THEN '  D2'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 3 THEN '  D3'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 4 THEN '  D4'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 5 THEN '  D5'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 6 THEN '  D6'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 7 THEN '  D7'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 8 AND 10 THEN ' 08-10'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 11 AND 14 THEN ' 11-14'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 15 AND 30 THEN ' 15-30'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 31 AND 60 THEN ' 31-60'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 61 AND 90 THEN ' 61-90'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 91 AND 100 THEN ' 91-100'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 101 AND 110 THEN '101-110'
      WHEN DATEDIFF(DAY, DATE(dc.psu_tstamp), DATE(po.processed_date)) BETWEEN 111 AND 120 THEN '111-120'
      ELSE '121+'
      END AS diff_days_psu_to_acq_category,
    CASE
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 0 THEN '   MÃªs 0'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 1 THEN '   MÃªs 1'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 2 THEN '   MÃªs 2'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 3 THEN '   MÃªs 3'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 4 THEN '   MÃªs 4'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 5 THEN '   MÃªs 5'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 6 THEN '   MÃªs 6'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 7 THEN '   MÃªs 7'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 8 THEN '   MÃªs 8'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 9 THEN '   MÃªs 9'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 10 THEN '  MÃªs 10'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 11 THEN '  MÃªs 11'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 12 THEN '  MÃªs 12'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 13 THEN '  MÃªs 13'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 14 THEN '  MÃªs 14'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) = 15 THEN '  MÃªs 15'
      WHEN DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) > 15 THEN 'Acima 15m'
      ELSE 'Excluir'
    END AS diff_months_psu_to_acq_cat,
    DATEDIFF(MONTH, DATE(dc.psu_tstamp), DATE(po.processed_date)) AS diff_months_psu_to_acq,
    DATEDIFF(MONTH, DATE(dc.acquisition_tstamp), DATE(so.event_tstamp)) AS diff_months_acq_to_sec,
    DATEDIFF(MONTH, DATE(dc.acquisition_tstamp), DATE_TRUNC('month', fe.event_tstamp)) AS month_diff_operation,
    DATEDIFF(MONTH, DATE(fe.event_tstamp), DATE(so.event_tstamp)) AS month_diff_second_operation,
    DATEDIFF(MONTH, DATE_TRUNC('month', fe.event_tstamp), DATE(dc.acquisition_tstamp)) AS month_diff_presignup,
    CASE WHEN DATEDIFF(MONTH, DATE_TRUNC('month', dc.signup_completed_tstamp), DATE(dc.acquisition_tstamp)) < 0 THEN 0
         ELSE DATEDIFF(MONTH, DATE_TRUNC('month', dc.signup_completed_tstamp), DATE(dc.acquisition_tstamp))
    END AS month_diff_signup,
    CASE WHEN LOWER(COALESCE(dc.source_psu, '')) = 'nubank' THEN 'Nubank' ELSE 'NÃ£o Nubank' END AS is_presignup_nubank,
    po.premium_status as is_premium_user,
    CASE
        WHEN fe.event_type = 'APPROVED STORY' AND fh.nature_operation_name = 'Global Account' THEN 'HistÃ³ria de Conta Global'
        WHEN fe.event_type = 'APPROVED STORY' AND fh.nature_operation_name <> 'Global Account' THEN 'NÃ£o Ã© HistÃ³ria de Conta Global'
        ELSE 'NÃ£o Ã© event_type = APPROVED STORY'
    END AS history_name,
    po.is_affiliate,
    po.in_or_out,
    po.currency_abbreviation as currency,
    po.acquisition,
    po.institution_fin_id as instituicao_fin,
    po.voucher_code,
    po.voucher_type,
    CASE
        WHEN po.voucher_code IS NOT NULL THEN 'Com Voucher'
        ELSE 'Sem Voucher'
    END AS fl_voucher,
    po.distributor_name as remessadora,
    po.nature_operation_name as natureza,
    po.country,
    po.operation_platform_beecambio as origin_platform_acq,
    po.gmv,
    po.segment,
    po.bu,
    po.business_type,
    po.gross_revenue,
    DATE_TRUNC('month', fe.event_tstamp) = DATE_TRUNC('month', dc.acquisition_tstamp) AS month_psu_equal_month_acq,
    DATE_TRUNC('month', fe.event_tstamp) = DATE_TRUNC('month', dc.signup_completed_tstamp) AS month_psu_equal_month_su,
    DATE_TRUNC('month', dc.acquisition_tstamp) = DATE_TRUNC('month', dc.signup_completed_tstamp) AS month_su_equal_month_acq,
    DATE_TRUNC('month', dc.acquisition_tstamp) = DATE_TRUNC('month', so.event_tstamp) AS month_acq_equal_month_second_operation,
    dc.has_shared_bank_details,
    dc.shared_bank_details_platform,
    dc.shared_bank_details_label,
    dc.shared_bank_details_tstamp,
    co.requeriment_actual_status as requirement_status,
    co.requirement_type,
    co.institution_financial,
    co.has_uploaded_identification,
    co.identification_document_type_name,
    co.doc_identification_status_name,
    co.ocr,
    co.ocr_doc_type,
    co.ocr_analysis_reference_status,
    co.ocr_validated,
    co.ocr_analyzed_document,
    co.compliance_lock,
    co.compliance_veredict,
    co.is_active_requirement,
    CASE
      WHEN ops.operations BETWEEN 0 AND 1 THEN ' 01'
      WHEN ops.operations = 2 THEN ' 02'
      WHEN ops.operations = 3 THEN ' 03'
      WHEN ops.operations = 4 THEN ' 04'
      WHEN ops.operations BETWEEN 5 AND 6 THEN ' 05 a 06'
      WHEN ops.operations BETWEEN 7 AND 10 THEN ' 07 a 10'
      WHEN ops.operations BETWEEN 11 AND 20 THEN ' 11 a 20'
      WHEN ops.operations BETWEEN 21 AND 50 THEN ' 21 a 50'
      WHEN ops.operations > 50 THEN '+50'
      ELSE 'Sem operaÃ§Ã£o'
    END AS operations,

---------------------------------------------------------

PJ:

-- Filtro de Clientes FxaaS
CASE
    WHEN sv.email LIKE '%fxaas%' THEN TRUE
    ELSE FALSE
END AS pj_fxaas,

CASE
  WHEN cq.id_qualification_outbound IS NOT NULL THEN 'Outbound'
  WHEN cq.id_qualification_inbound IS NOT NULL THEN 'Inbound'
  ELSE 'Sem QualificaÃ§Ã£o'
END AS qualification_type,

-- ClassificaÃ§Ã£o do fluxo
CASE
  WHEN fe.customer_type = 'PF' THEN 'PF Normal'
  WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound is not null then 'PJ Instant Outbound'
  WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound  is not null then 'PJ Instant Inbound'
  WHEN fe.onboarding_type = 'express' and cq.id_qualification_outbound is not null then 'PJ Express Outbound'
  WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound  is not null then 'PJ Express Inbound'
  ELSE 'PJ Offline'
END AS pj_fluxo,

-- Etapa 1 - Presignup (email, CNPJ, ddi, telefone e senha)
CASE WHEN sv.email IS NOT NULL AND sv.cnpj_cpf_client IS NOT NULL AND O.country_code IS NOT NULL AND O.phone IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen1_psu,

-- Etapa 2 - QualificaÃ§Ã£o
CASE WHEN cq.id_customer IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen2_qualification,

-- Etapa 3:
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND dc.has_shared_bank_details THEN TRUE ELSE FALSE END AS pj_screen3_shared_bank_details_instant_inbound, -- Instant Inbound compartilhar dados
CASE WHEN fe.onboarding_type = 'express' and dc.signup_completed_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen3_signup_completed_express, -- Express - Signup
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound IS NOT NULL AND rn.id_recipient IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen3_recipient_instant_outbound, -- Instant Outbound - BeneficiÃ¡rio

-- Etapa 4
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND od.orders > 0 THEN TRUE ELSE FALSE END AS pj_screen4_orders_instant_inbound, -- Instant Inbound - Recebimento da Ordem
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound IS NOT NULL AND hc.event_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen4_created_story_instant_outbound, -- Instant Outbound - Criar HistÃ³ria
CASE WHEN fe.onboarding_type = 'express' and sv.company_shareholders_with_document > 0 THEN TRUE ELSE FALSE END AS pj_screen4_documents_express, -- Express - Envio do Documento

-- Etapa 5
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND hc.event_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen5_created_story_instant_inbound, -- Instant Inbound Criar HistÃ³ria
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound IS NOT NULL AND dc.signup_completed_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen5_signup_completed_instant_outbound, -- Instant Outbound - Signup
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound IS NOT NULL AND dc.has_shared_bank_details THEN TRUE ELSE FALSE END AS pj_screen5_shared_bank_details_express_inbound, -- Express Inbound compartilhar dados
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_outbound IS NOT NULL AND rn.id_recipient IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen5_recipient_express_outbound, -- Instant Outbound - BeneficiÃ¡rio

-- Etapa 6
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND dc.signup_completed_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen6_signup_completed_instant_inbound, -- Instant Inbound - Signup
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound IS NOT NULL AND sv.company_shareholders_with_document > 0 THEN TRUE ELSE FALSE END AS pj_screen6_documents_instant_outbound, -- Instant Outbound - Envio do Documento
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound IS NOT NULL AND od.orders > 0 THEN TRUE ELSE FALSE END AS pj_screen6_orders_express_inbound, -- Express Inbound - Recebimento da Ordem
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_outbound IS NOT NULL AND hc.event_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen6_created_story_express_outbound, -- Express Outbound - Criar HistÃ³ria

-- Etapa 7
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND sv.company_shareholders_with_document > 0 THEN TRUE ELSE FALSE END AS pj_screen7_documents_instant_inbound, -- Instant Inbound - Envio do Documento
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_outbound IS NOT NULL AND cr.created_ops > 0 THEN TRUE ELSE FALSE END AS pj_screen7_created_ops_instant_outbound, -- Instant Outbound - Criar OperaÃ§Ã£o ETAPA FINAL
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound IS NOT NULL AND hc.event_tstamp IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen7_created_story_express_inbound, -- Express Inbound - Criar HistÃ³ria
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_outbound IS NOT NULL AND cr.created_ops > 0 THEN TRUE ELSE FALSE END AS pj_screen7_created_ops_express_outbound, -- Express Outbound - Criar OperaÃ§Ã£o ETAPA FINAL

-- Etapa 8
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND bk.bank_name IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen8_bank_name_instant_inbound, -- Instant Inbound - Conta PJ
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound IS NOT NULL AND bk.bank_name IS NOT NULL THEN TRUE ELSE FALSE END AS pj_screen8_bank_name_express_inbound, -- Express Inbound - Conta PJ

-- Etapa 9
CASE WHEN fe.onboarding_type = 'instant' and cq.id_qualification_inbound IS NOT NULL AND od.redeemed_orders > 0 THEN TRUE ELSE FALSE END AS pj_screen9_redeemed_order_instant_inbound, -- Instant Inbound - Conta PJ -- Etapa Final
CASE WHEN fe.onboarding_type = 'express' and cq.id_qualification_inbound IS NOT NULL AND od.redeemed_orders > 0 THEN TRUE ELSE FALSE END AS pj_screen9_redeemed_order_express_inbound, -- Express Inbound - Conta PJ -- Etapa Final

---------------------------------------------------------

PF:

-- Etapa 1 - Presignup (name, cpf_cnpj, email)
CASE WHEN sv.customer_name IS NOT NULL AND sv.cnpj_cpf_client IS NOT NULL AND sv.email IS NOT NULL THEN TRUE ELSE FALSE END AS pf_app_screen1_filled,
-- Etapa 2 - Dados Pessoais
CASE WHEN sv.customer_name IS NOT NULL AND sv.doc_number IS NOT NULL AND sv.birthday_date IS NOT NULL AND sv.nationality IS NOT NULL AND sv.genre IS NOT NULL AND sv.mother_name IS NOT NULL
AND O.country_code IS NOT NULL AND sv.mobile_phone IS NOT NULL THEN TRUE ELSE FALSE END AS pf_app_screen4_personal_data_filled,
-- Etapa 3: EndereÃ§o
CASE WHEN sv.address IS NOT NULL AND A.str_number IS NOT NULL AND A.neighbor IS NOT NULL AND A.city IS NOT NULL AND A.state IS NOT NULL THEN TRUE ELSE FALSE END AS pf_app_screen5_address_filled,
-- Etapa 4: Renda e residÃªncia fiscal
CASE WHEN dc.monthly_income IS NOT NULL AND RF.patrimony IS NOT NULL AND sv.american_fiscal_resident IS NOT NULL THEN TRUE ELSE FALSE END AS pf_app_screen6_income_tax_residency_filled,
-- Etapa 5: Documento de identificaÃ§Ã£o
co.has_uploaded_identification AS pf_app_screens7_to_9_document_filled,

q.primeira_pergunta as qualification_1,
q.segunda_pergunta as qualification_2,
dc.onb_ops_type as onb_ops_type_pj,
dc.onb_reason as onb_reason_pj,
dc.onb_digital_platform_pj,
dc.onb_amount_pj,
dc.onb_forecast_pj,
dc.has_affiliate_ops_rec,
dc.has_affiliate_ops_acq,
coalesce(ps.provider,'no provider') as provider

FROM gold.funnel_event AS fe
LEFT JOIN gold.fact_customers as dc ON fe.id_customer = dc.id_customer
LEFT JOIN silver.customers AS sv ON fe.id_customer = sv.id
LEFT JOIN patrimony AS RF ON fe.id_customer = RF.customer_id AND RF.seq = 1
  LEFT JOIN recipient_name as rn ON fe.id_customer = rn.id_customer
  LEFT JOIN orders AS od ON fe.id_customer = od.id_customer
  LEFT JOIN created_ops AS cr ON fe.id_customer = cr.id_customer
  LEFT JOIN bank_name AS bk ON fe.id_customer = bk.id_customer
LEFT JOIN beecambio.beecambio_company_qualification AS cq ON fe.id_customer = cq.id_customer
  LEFT JOIN beecambio.beecambio_tbl_customer AS O ON fe.id_customer = O.id
LEFT JOIN beecambio.beecambio_tbl_customer_address AS A ON O.id = A.id_customer
LEFT JOIN gold.funnel_event AS hc ON fe.id_customer = hc.id_customer AND hc.event_type = 'CREATED STORY' AND hc.event_sequence = 1
LEFT JOIN gold.funnel_event AS hi ON fe.id_customer = hi.id_customer AND hi.event_type = 'APPROVED STORY' AND hi.event_sequence = 1
LEFT JOIN gold.funnel_event AS so ON fe.id_customer = so.id_customer AND so.event_type = 'OPERATION' AND so.event_sequence = 2
LEFT JOIN gold.fact_operations AS po ON fe.event_id = po.id_remittance AND fe.event_type IN ('ACQUISITION', 'OPERATION')
LEFT JOIN bronze.beecambio_history as fh ON fe.event_id = fh.id AND fe.event_type = 'APPROVED STORY'
LEFT JOIN google_analytics.last_click_sessions AS lc ON lc.id_customer = fe.id_customer
LEFT JOIN ops ON fe.id_customer = ops.id_customer AND fe.event_type = 'ACQUISITION'
LEFT JOIN silver.requirement AS co ON fe.id_customer = co.id_customer
  AND co.institution_financial = 'TopÃ¡zio'
  AND co.requeriment_date >= '2024-01-01'
  AND (
    (co.customer_type = 'PF' AND co.requirement_type IN ('Simples', 'Completo'))
    OR
    (co.customer_type = 'PJ' AND co.requirement_type = 'Completo')
  )
LEFT JOIN qualification as q on fe.id_customer = q.id_customer
LEFT JOIN origem_psu as ps on fe.id_customer = ps.customer_id
WHERE DATE(fe.event_tstamp) >= '2024-01-01'
  AND (
        (fe.event_sequence = 1 AND fe.event_type IN ('ACQUISITION', 'PRESIGNUP', 'SIGNUP', 'APPROVED STORY', 'CREATED STORY'))
        OR
        (fe.event_type = 'OPERATION')
      )
)

SELECT DISTINCT
  f.*,
  case
    when f.pf_app_screens7_to_9_document_filled = false then 'NÃ£o Enviado'
    when f.pf_app_screens7_to_9_document_filled and t.tentativa_documento_aprovado is null then 'NÃ£o Aprovado'
    when t.tentativa_documento_aprovado = 1 then 'Aprovado na 1Âª tentativa'
    when t.tentativa_documento_aprovado = 2 then 'Aprovado na 2Âª tentativa'
    else 'Mais de +3Âª tentativa'
  end as tentativa_documento_aprovado,

------------------------------------ PF:
  CASE
    WHEN customer_type = 'PJ' THEN 'PJ nÃ£o se aplica'
    WHEN pf_app_screens7_to_9_document_filled = TRUE THEN 'Etapa 5 - Envio Documento'
    WHEN pf_app_screen6_income_tax_residency_filled = TRUE THEN 'Etapa 4 - Renda e ResidÃªncia'
    WHEN pf_app_screen5_address_filled = TRUE THEN 'Etapa 3 - EndereÃ§o'
    WHEN pf_app_screen4_personal_data_filled = TRUE THEN 'Etapa 2 - Dados Pessoais'
    WHEN pf_app_screen1_filled = TRUE THEN 'Etapa 1 - Presignup'
  END AS pf_app_journey_stage,

------------------------------------ PJ:

CASE
  WHEN customer_type = 'PF' THEN 'PF nÃ£o se aplica'
  WHEN pj_screen9_redeemed_order_instant_inbound THEN 'Etapa 9 - Ordem Resgatada'
  WHEN pj_screen8_bank_name_instant_inbound THEN 'Etapa 8 - Conta PJ Cadastrada'
  WHEN pj_screen7_documents_instant_inbound THEN 'Etapa 7 - Enviou Documentos'
  WHEN pj_screen6_signup_completed_instant_inbound THEN 'Etapa 6 - Finalizou Cadastro'
  WHEN pj_screen5_created_story_instant_inbound THEN 'Etapa 5 - Criou HistÃ³ria'
  WHEN pj_screen4_orders_instant_inbound THEN 'Etapa 4 - Recebeu Ordem'
  WHEN pj_screen3_shared_bank_details_instant_inbound THEN 'Etapa 3 - Compartilhou Dados BancÃ¡rios'
  WHEN pj_screen2_qualification THEN 'Etapa 2 - QualificaÃ§Ã£o'
  WHEN pj_screen1_psu THEN 'Etapa 1 - Presignup'
  ELSE 'Desconhecido'
END AS pj_journey_stage_instant_inbound,

CASE
  WHEN customer_type = 'PF' THEN 'PF nÃ£o se aplica'
  WHEN pj_screen7_created_ops_instant_outbound THEN 'Etapa 7 - Criou OperaÃ§Ã£o'
  WHEN pj_screen6_documents_instant_outbound THEN 'Etapa 6 - Enviou Documentos'
  WHEN pj_screen5_signup_completed_instant_outbound THEN 'Etapa 5 - Finalizou Cadastro'
  WHEN pj_screen4_created_story_instant_outbound THEN 'Etapa 4 - Criou HistÃ³ria'
  WHEN pj_screen3_recipient_instant_outbound THEN 'Etapa 3 - Indicou BeneficiÃ¡rio'
  WHEN pj_screen2_qualification THEN 'Etapa 2 - QualificaÃ§Ã£o'
  WHEN pj_screen1_psu THEN 'Etapa 1 - Presignup'
  ELSE 'Desconhecido'
END AS pj_journey_stage_instant_outbound,

CASE
  WHEN customer_type = 'PF' THEN 'PF nÃ£o se aplica'
  WHEN pj_screen9_redeemed_order_express_inbound THEN 'Etapa 9 - Ordem Resgatada'
  WHEN pj_screen8_bank_name_express_inbound THEN 'Etapa 8 - Conta PJ Cadastrada'
  WHEN pj_screen7_created_story_express_inbound THEN 'Etapa 7 - Criou HistÃ³ria'
  WHEN pj_screen6_orders_express_inbound THEN 'Etapa 6 - Recebeu Ordem'
  WHEN pj_screen5_shared_bank_details_express_inbound THEN 'Etapa 5 - Compartilhou Dados BancÃ¡rios'
  WHEN pj_screen4_documents_express THEN 'Etapa 4 - Enviou Documentos'
  WHEN pj_screen3_signup_completed_express THEN 'Etapa 3 - Finalizou Cadastro'
  WHEN pj_screen2_qualification THEN 'Etapa 2 - QualificaÃ§Ã£o'
  WHEN pj_screen1_psu THEN 'Etapa 1 - Presignup'
  ELSE 'Desconhecido'
END AS pj_journey_stage_express_inbound,

CASE
  WHEN customer_type = 'PF' THEN 'PF nÃ£o se aplica'
  WHEN pj_screen7_created_ops_express_outbound THEN 'Etapa 7 - Criou OperaÃ§Ã£o'
  WHEN pj_screen6_created_story_express_outbound THEN 'Etapa 6 - Criou HistÃ³ria'
  WHEN pj_screen5_recipient_express_outbound THEN 'Etapa 5 - Indicou BeneficiÃ¡rio'
  WHEN pj_screen4_documents_express THEN 'Etapa 4 - Enviou Documentos'
  WHEN pj_screen3_signup_completed_express THEN 'Etapa 3 - Finalizou Cadastro'
  WHEN pj_screen2_qualification THEN 'Etapa 2 - QualificaÃ§Ã£o'
  WHEN pj_screen1_psu THEN 'Etapa 1 - Presignup'
  ELSE 'Desconhecido'
END AS pj_journey_stage_express_outbound

FROM final f
LEFT JOIN tentativas_doc_aprovado t ON f.id_customer = t.id_customer
```

---
*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*
