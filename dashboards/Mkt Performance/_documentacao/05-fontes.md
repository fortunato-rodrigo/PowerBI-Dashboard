# 05 — Fontes de Dados: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`

---

> ⚠️ **ALERTA GLOBAL — CONEXÕES MISTAS:** Este dashboard conecta em múltiplas camadas e schemas não-padrão simultaneamente:
> - `f_investimento`: **BRONZE** (`bronze.paid_media_investments`) — nível de confiança baixo
> - `f_mkt_performance`: Cruza `gold`, `silver`, `stage`, `google_analytics`, `sandbox_datascience` e `prod.beecambio`
> - `f_attribution_window`: Cruza `google_analytics`, `silver` e `gold`
>
> Schemas `stage` e `sandbox_datascience` são potencialmente experimentais. Verificar estabilidade com o time de dados antes de uso em relatórios executivos.

---

## Endpoint Databricks

Todas as tabelas Databricks se conectam via:
- **Host:** `beetech-prod-analytics.cloud.databricks.com`
- **Endpoint SQL:** `/sql/1.0/endpoints/e35e97a9319a6fe7`
- **Catalog:** `prod`

---

## 1. f_mkt_performance — Fonte Principal

**Camadas envolvidas:** `gold`, `silver`, `stage`, `google_analytics`, `sandbox_datascience`, `prod.beecambio`

### Query SQL simplificada

```sql
-- CTEs auxiliares:
-- crm: gold.fact_crm_result + gold.fact_operations
-- qualification: silver.customers + prod.beecambio.* (respostas de qualificação)
-- leadscore: sandbox_datascience.leadscore_notas_pf UNION sandbox_datascience.leadscore_notas_pj

SELECT
    fe.event_id,
    fe.id_customer,
    fe.event_type,
    date(fe.event_tstamp)                AS event_date,
    -- cohort PSU→ACQ em faixas de dias
    <cohort_psu_acq>                     AS cohort_psu_acq,
    lc.channel_psu                       AS canal_lc,        -- Last Click canal
    lc.source_psu                        AS source_lc,
    lc.medium_psu                        AS medium_lc,
    lc.mkt_campaign_psu                  AS mkt_campaign_lc,
    lc.cluster_campaign_psu              AS cluster_campaign_lc,
    lc.utm_adgroup_psu                   AS ad_group_lc,
    lc.media_funnel_psu                  AS media_funnel_lc,
    fc.canal                             AS canal_fc,         -- First Click canal
    fc.mkt_campaign                      AS mkt_campaign_fc,
    lc.customer_type                     AS "Customer Type",
    po.gmv,
    po.gross_revenue,
    po.voucher_code, po.voucher_type,
    coalesce(crm.crm_status, 'Sem CRM')  AS crm_status,
    ld.score,
    current_timestamp() - interval '3' hour AS last_update
FROM gold.funnel_event AS fe
    LEFT JOIN silver.customers            AS sv ON fe.id_customer = sv.id
    LEFT JOIN gold.fact_customers         AS lc ON fe.id_customer = lc.id_customer
    LEFT JOIN silver.histories            AS fh ON fe.event_type = 'APPROVED STORY'
                                               AND fe.event_id = fh.id_history
    LEFT JOIN gold.fact_operations        AS po ON fe.event_id = po.id_remittance
                                               AND fe.event_type IN ('ACQUISITION','OPERATION')
                                               AND po.is_ops_processed
    LEFT JOIN crm                         ON fe.event_id = crm.event_id
    LEFT JOIN stage.dim_monthly_subsegmentation AS s
                                              ON fe.event_type IN ('ACQUISITION','OPERATION')
                                             AND fe.id_customer = s.id_customer
                                             AND date_trunc('month', fe.event_tstamp) = s.month
    LEFT JOIN qualification               AS q  ON fe.id_customer = q.id_customer
    LEFT JOIN google_analytics.first_click_sessions AS fc ON fc.id_customer = fe.id_customer
    LEFT JOIN leadscore                   AS ld ON fe.id_customer = ld.id_customer
WHERE date(fe.event_tstamp) >= '2024-01-01'
  AND fe.event_sequence = 1
  AND fe.event_type IN ('ACQUISITION','APPROVED STORY','CREATED STORY','PRESIGNUP','SIGNUP')
   OR fe.event_type = 'OPERATION'
```

### Tabelas Databricks referenciadas

| Schema | Tabela | Camada | Papel |
|--------|--------|--------|-------|
| `gold` | `funnel_event` | Gold | Tabela base de eventos do funil |
| `gold` | `fact_customers` | Gold | Atributos do cliente + UTMs de Last Click (PSU) |
| `gold` | `fact_operations` | Gold | Dados da operação (GMV, revenue, voucher, etc.) |
| `gold` | `fact_crm_result` | Gold | Status de CRM da operação |
| `silver` | `customers` | Silver | Dados básicos do cliente (email, ID) |
| `silver` | `histories` | Silver | Histórias de Conta Global |
| `stage` | `dim_monthly_subsegmentation` | ⚠️ Stage (experimental) | Subsegmentação mensal do cliente (High/Mid/Low) |
| `google_analytics` | `first_click_sessions` | ⚠️ Schema não-padrão | Sessões de First Click (atribuição) |
| `sandbox_datascience` | `leadscore_notas_pf` | ⚠️ Sandbox (experimental) | Lead score PF (modelo ML) |
| `sandbox_datascience` | `leadscore_notas_pj` | ⚠️ Sandbox (experimental) | Lead score PJ (modelo ML) |
| `prod.beecambio` | `beecambio_onboarding_qualification_answers` | ⚠️ Transactional DB | Respostas de qualificação do onboarding |
| `prod.beecambio` | `beecambio_onboarding_qualification_form_questions` | ⚠️ Transactional DB | Perguntas do formulário de qualificação |
| `prod.beecambio` | `beecambio_onboarding_qualification_form_options` | ⚠️ Transactional DB | Opções do formulário de qualificação |

**Modelo DBT:** `gold.funnel_event`, `gold.fact_customers`, `gold.fact_operations` — verificar em `dbt-metadata/gold_models.md`.

---

## 2. f_investimento — ⚠️ BRONZE

**Camada:** `bronze.paid_media_investments`

> ⚠️ **ALERTA BRONZE:** Dado bruto de investimento em mídia paga. Não transformado pelo DBT. Validar com o time de Marketing.

### Query SQL simplificada

```sql
-- PF
SELECT DISTINCT
    pmkt.date                AS date_nao_usar,
    lower(ad_group)          AS ad_group,
    pmkt.mkt_campaign        AS mkt_campaign_pmkt,
    <canal>                  AS channel_pmkt,
    lower(pmkt.medium)       AS medium_pmkt,
    lower(pmkt.source)       AS source_pmkt,
    <media_funnel>           AS media_funnel,
    'PF'                     AS customer_type,
    SUM(cost) * 0.5822       AS investimento   -- 58,22% do custo total para PF
FROM bronze.paid_media_investments AS pmkt
WHERE year(date) >= 2023 AND date < current_date
GROUP BY ALL

UNION ALL

-- PJ (mesma estrutura, fator 0.4178)
SELECT ..., 'PJ', SUM(cost) * 0.4178 AS investimento
FROM bronze.paid_media_investments ...
```

### Tabelas Databricks referenciadas

| Schema | Tabela | Camada | Papel |
|--------|--------|--------|-------|
| `bronze` | `paid_media_investments` | ⚠️ **BRONZE** | Investimentos brutos em mídia paga |

**Modelo DBT:** Não identificado — dado bruto sem transformação DBT.

---

## 3. f_attribution_window — Attribution Window

**Camadas:** `google_analytics`, `silver`, `gold`

### Query SQL simplificada

```sql
SELECT DISTINCT
    date(aw.event_date)     AS event_date,
    <canal>                 AS canal,
    coalesce(aw.source, 'unknown')      AS source,
    coalesce(aw.medium, 'unknown')      AS medium,
    coalesce(trim(aw.mkt_campaign), 'organic/direct') AS mkt_campaign,
    lower(coalesce(c.utm_adgroup_psu, 'unknown'))     AS ad_group_lc,
    dc.customer_type,
    COUNT(DISTINCT CASE WHEN aw.event = 'PRESIGNUP'   THEN aw.id_customer END) AS presignups,
    COUNT(DISTINCT CASE WHEN aw.event = 'ACQUISITION' THEN aw.id_customer END) AS acquisitions,
    -- + segmentações PF/PJ para presignups e acquisitions
FROM google_analytics.attribution_window AS aw
    INNER JOIN silver.customers                AS dc ON aw.id_customer = dc.id
    LEFT JOIN  google_analytics.last_click_sessions AS lc ON aw.session_id = lc.session_id
    LEFT JOIN  gold.fact_customers             AS c  ON dc.id = c.id_customer
WHERE date(aw.event_date) >= '2023-08-01'
  AND lc.session_id IS NULL  -- exclui sessões capturadas pelo Last Click
GROUP BY ALL
```

### Tabelas Databricks referenciadas

| Schema | Tabela | Camada | Papel |
|--------|--------|--------|-------|
| `google_analytics` | `attribution_window` | ⚠️ Schema não-padrão | Janela de atribuição de eventos |
| `google_analytics` | `last_click_sessions` | ⚠️ Schema não-padrão | Sessões Last Click (para exclusão) |
| `silver` | `customers` | Silver | Customer type do cliente |
| `gold` | `fact_customers` | Gold | UTM ad group do PSU |

**Modelo DBT:** `silver.customers` — verificar em `dbt-metadata/silver_models.md`.

---

## 4. f_trading_quotation — Cotações de Moeda

**Camada:** `silver.trading_quotations`

### Query M (tabela completa via navegação)

```m
let
    Origem = Databricks.Catalogs("beetech-prod-analytics.cloud.databricks.com", ...),
    prod_Database = Origem{[Name="prod",Kind="Database"]}[Data],
    silver_Schema = prod_Database{[Name="silver",Kind="Schema"]}[Data],
    trading_quotations_Table = silver_Schema{[Name="trading_quotations",Kind="Table"]}[Data]
in
    trading_quotations_Table
```

Leitura completa da tabela `silver.trading_quotations`.

**Modelo DBT:** Verificar em `dbt-metadata/silver_models.md`.

---

## 5. Power BI Dataflows — Dimensões

Todas as dimensões abaixo pertencem ao mesmo workspace Power BI:

- **Workspace ID:** `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`

### d_calendar

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| **Entidade** | `dcalendar` |
| **Fonte original** | A definir (requer acesso ao PBI Service) |
| **Frequência de atualização** | A definir |

**Transformações M adicionais no modelo Power BI:**
```m
let
    -- 1. Lê entidade dcalendar do Dataflow
    dcalendar_ = #"3cbe0c71..."{{[entity="dcalendar",version=""]}}[Data],
    -- 2. Adiciona coluna calculada: último dia do mês
    #"Fim do Mês Inserido" = Table.AddColumn(dcalendar_, "Fim do Mês",
        each Date.EndOfMonth([Date Key]), type date),
    -- 3. Adiciona flag booleana: é o último dia do mês?
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"Fim do Mês Inserido", "last_day",
        each if [Date Key] = [Fim do Mês] then true else false),
    #"Tipo Alterado" = Table.TransformColumnTypes(...)
in
    #"Tipo Alterado"
```

**Linhagem inferida:** O Dataflow `dcalendar` provavelmente gera o calendário corporativo com feriados brasileiros, dias úteis e flags de período. Fonte original provável: tabela de datas ou cálculo interno no Dataflow.

---

### d_canal

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `e4f720d3-c121-4344-a842-0c3f84f0380c` |
| **Entidade** | `mkt_canal` |
| **Fonte original** | A definir (lista curada de canais de marketing) |

**Sem transformações M adicionais no modelo.**

**Linhagem inferida:** Lista controlada de canais de marketing (paid search, organic, display, paid social, etc.), provavelmente mantida manualmente ou derivada de `gold.fact_customers`.

---

### d_canal_fc

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `e4f720d3-c121-4344-a842-0c3f84f0380c` |
| **Entidade** | `mkt_canal` |

**Nota:** Mesma entidade que `d_canal`. Criada como tabela duplicada para suportar relacionamento com `f_mkt_performance[canal_fc]` (First Click) e `f_attribution_window[canal]` sem criar ambiguidade no modelo.

---

### d_medium

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `85ec54e9-eae3-4eaa-85e9-ef8150b1f8e8` |
| **Entidade** | `mkt_medium` |
| **Fonte original** | A definir |

**Linhagem inferida:** Lista controlada de mediums de marketing (cpc, organic, email, referral, etc.).

---

### d_source

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `b1d3ec0b-66a7-4ccd-be25-7cffbd3c9852` |
| **Entidade** | `mkt_source` |
| **Fonte original** | A definir |

**Linhagem inferida:** Lista controlada de fontes de tráfego (google, facebook, instagram, etc.).

---

### d_mkt_campaign

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `b289027c-da70-4578-8627-0c05c1471ac3` |
| **Entidade** | `mkt_campaign` |
| **Fonte original** | A definir |

**Linhagem inferida:** Dimensão enriquecida de campanhas, com metadados como `cluster_campaign`, `investment_type`, `media_funnel`, `paid_search_restructuring`, `awareness_2024`. Provavelmente mantida manualmente pelo time de Marketing.

---

### d_mkt_campaign_fc

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `b289027c-da70-4578-8627-0c05c1471ac3` |
| **Entidade** | `mkt_campaign` |

**Nota:** Mesma entidade que `d_mkt_campaign`. Criada como tabela duplicada para relacionamento com First Click.

---

### d_adgroup

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `d823fda8-e56a-4fdb-a243-e10604f3ff69` |
| **Entidade** | `mkt_adgroup` |
| **Fonte original** | A definir |

**Linhagem inferida:** Lista de ad groups de campanhas pagas.

---

### d_customer_type

| Atributo | Valor |
|----------|-------|
| **Dataflow ID** | `ee7b4dce-a733-4365-9194-bfea34031f1a` |
| **Entidade** | `customer_type` |
| **Fonte original** | A definir |

**Linhagem inferida:** Tabela simples com valores PF e PJ para filtro de tipo de cliente.

---

## 6. d_qualificacao_1 e d_qualificacao_2 — Databricks direto

**Camadas:** `silver` / `prod.beecambio`

### d_qualificacao_1
```sql
SELECT DISTINCT coalesce(o.goal, 'unknown') AS primeira_pergunta
FROM silver.customers c
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_answers    a ON c.id = a.id_customer
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_questions q ON q.id = a.id_question
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_options   o ON o.id = a.id_option
```

### d_qualificacao_2
```sql
SELECT DISTINCT
    CONCAT_WS(' | ', coalesce(o.goal, 'unknown'), o.title) AS segunda_pergunta
FROM silver.customers c
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_answers    a ON c.id = a.id_customer
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_questions q ON q.id = a.id_question
    LEFT JOIN prod.beecambio.beecambio_onboarding_qualification_form_options   o ON o.id = a.id_option
```

---

## Linhagem Estendida

```
[Fontes de Origem]
        │
        ├── Google Analytics → google_analytics.attribution_window
        │                      google_analytics.first_click_sessions
        │                      google_analytics.last_click_sessions
        │
        ├── Plataformas de mídia (Google Ads, Meta, etc.)
        │   → bronze.paid_media_investments ⚠️
        │
        ├── Databricks / DBT Transformações
        │   ├── gold.funnel_event           (eventos do funil)
        │   ├── gold.fact_customers         (atributos + UTMs)
        │   ├── gold.fact_operations        (operações processadas)
        │   ├── gold.fact_crm_result        (dados de CRM)
        │   ├── silver.customers            (dados do cliente)
        │   ├── silver.histories            (histórias conta global)
        │   └── silver.trading_quotations   (cotações de câmbio)
        │
        ├── Fontes experimentais / staging
        │   ├── stage.dim_monthly_subsegmentation ⚠️
        │   ├── sandbox_datascience.leadscore_notas_pf ⚠️
        │   └── sandbox_datascience.leadscore_notas_pj ⚠️
        │
        └── Banco transacional
            └── prod.beecambio.beecambio_onboarding_* ⚠️
                        │
                        ↓
[Power BI Dataflows — Workspace 5381a7f5-5b4c-4fa7-96d6-48992d85d88e]
        │
        ├── d_calendar       (Dataflow: 3cbe0c71)
        ├── d_canal          (Dataflow: e4f720d3)
        ├── d_medium         (Dataflow: 85ec54e9)
        ├── d_source         (Dataflow: b1d3ec0b)
        ├── d_mkt_campaign   (Dataflow: b289027c)
        ├── d_adgroup        (Dataflow: d823fda8)
        └── d_customer_type  (Dataflow: ee7b4dce)
                        │
                        ↓
[Power BI Semantic Model — Mkt Performance]
        │
        ├── f_mkt_performance     (fato principal — gold+silver+stage+ga+sandbox)
        ├── f_investimento        (investimento — BRONZE ⚠️)
        ├── f_attribution_window  (janela de atribuição — ga+silver+gold)
        ├── f_trading_quotation   (cotações — silver)
        └── [Dimensões Dataflow + Databricks]
                        │
                        ↓
[Dashboard Mkt Performance — Power BI Report]
```
