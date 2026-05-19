# Dashboard de Safras — Fontes de Dados

> ⚠️ **ALERTA BRONZE:** A tabela principal `f_funnel_events` utiliza JOINs com a camada `bronze` do Databricks (`bronze.beecambio_history`, `beecambio.*`). Dados bronze são brutos e sem transformação DBT — podem conter inconsistências. **Recomendação:** migrar esses JOINs para tabelas silver/gold assim que disponíveis.

> 📋 **Dataflows identificados:** 6 Dataflows documentados abaixo. Linhagem básica extraída via API do Power BI. Código M e refresh schedule pendentes — SP precisa de permissão `Dataflow.ReadWrite.All`.

---

## Resumo das Fontes

| Tabela PBI | Fonte | Camada | Confiança |
|------------|-------|--------|-----------|
| `f_funnel_events` | Databricks (gold + bronze JOINs) | 🟢 gold / ⚠️ bronze | Médio-alto |
| `d_calendar` | Dataflow `dCalendar` (`3cbe0c71`) | Dataflow / Extension | A definir via M |
| `d_canal` | Dataflow `mkt_canal` (`e4f720d3`) | Dataflow / Extension | A definir via M |
| `d_source` | Dataflow `mkt_source` (`b1d3ec0b`) | Dataflow / Extension | A definir via M |
| `d_medium` | Dataflow `mkt_medium` (`85ec54e9`) | Dataflow / Extension | A definir via M |
| `d_adgroup` | Dataflow `mkt_adgroup` (`d823fda8`) | Dataflow / Extension | A definir via M |
| `d_mkt_campaign` | Dataflow `mkt_campaign` (`b289027c`) | Dataflow / Extension | A definir via M |
| `d_last_update` | Databricks (query direta) | 🟢 Utilitário | Alto |
| `NomeSemana` | Tabela estática (M) | — | N/A |
| `d_intervalo_meses` | Tabela estática (M) | — | N/A |
| `t_Cohort` | Tabela estática (M) | — | N/A |
| Tabelas `p_*` | DAX / M estático | — | N/A |

---

## Detalhamento por Tabela

---

### f_funnel_events

**Fonte:** Databricks — `Value.NativeQuery`
**Tabela base:** `gold.funnel_event`
**Camada:** 🟢 gold (base) · ⚠️ bronze (JOINs)
**Workspace:** `beetech-prod-analytics.cloud.databricks.com`
**Modelo DBT:** A definir — executar `/extrair-dbt-metadata`

**Query SQL resumida:**
```sql
SELECT
    -- colunas de identidade do cliente
    -- colunas de evento (tipo, data, mês)
    -- colunas de classificação (Customer Type, Company Type, Onboarding Type)
    -- colunas CNAE (session, division, group, class, subclass)
    -- colunas de marketing (canal, medium, source, campaign, ad_group)
    -- colunas financeiras (gmv, gross_revenue)
    -- colunas de cohort (signup_date, acquisition_date, datas de mês, flags de mês)
    -- colunas auxiliares (full_registration, origin_platform, event_type_id)
FROM gold.funnel_event fe
LEFT JOIN gold.fact_customers fc ON fc.id_customer = fe.id_customer
LEFT JOIN silver.customers sc ON sc.id_customer = fe.id_customer
LEFT JOIN silver.requirement sr ON sr.id_customer = fe.id_customer
LEFT JOIN silver.orders so ON so.event_id = fe.event_id
LEFT JOIN gold.fact_operations fo ON fo.event_id = fe.event_id
LEFT JOIN bronze.beecambio_history bbh ON ...   -- ⚠️ BRONZE
LEFT JOIN beecambio.* ON ...                     -- ⚠️ BRONZE
LEFT JOIN google_analytics.last_click_sessions gas ON ...
WHERE fe.event_date >= '2024-01-01'
```

**Tabelas Databricks referenciadas — 18 tabelas (confirmado via `07-queries-sql.md` em 15/05/2026):**

| Tabela | Camada | Papel |
|--------|--------|-------|
| `gold.funnel_event` | 🟢 gold | Tabela principal de eventos de funil (PSU, Signup, Acquisition, Operation) |
| `gold.fact_customers` | 🟢 gold | Dados consolidados de clientes (canal, CNAE, onboarding) |
| `gold.fact_operations` | 🟢 gold | Operações processadas (gmv, gross_revenue, event_id) |
| `silver.customers` | 🟡 silver | Clientes normalizados (email, CPF/CNPJ, dados pessoais) |
| `silver.orders` | 🟡 silver | Pedidos (aggregate_order_status, redeemed_orders) |
| `silver.requirement` | 🟡 silver | Requisitos de compliance (KYC, documentação) |
| `bronze.beecambio_history` | ⚠️ bronze | Histórico BeeCambio — JOIN para `APPROVED STORY` |
| `beecambio.beecambio_company_qualification` | [B] beecambio | Qualificação de empresa PJ |
| `beecambio.beecambio_onboarding_qualification_answers` | [B] beecambio | Respostas de qualificação no onboarding |
| `beecambio.beecambio_onboarding_qualification_form_options` | [B] beecambio | Opções dos formulários de qualificação |
| `beecambio.beecambio_onboarding_qualification_form_questions` | [B] beecambio | Questões dos formulários de qualificação |
| `beecambio.beecambio_registration_form` | [B] beecambio | Formulário de registro (patrimônio) |
| `beecambio.beecambio_tbl_customer` | [B] beecambio | Dados brutos do cliente (telefone, endereço, email) |
| `beecambio.beecambio_tbl_customer_address` | [B] beecambio | Endereço do cliente |
| `beecambio.beecambio_tbl_customer_bank_account` | [B] beecambio | Conta bancária do cliente (banco, data cadastro) |
| `beecambio.beecambio_tbl_customer_login_provider` | [B] beecambio | Provider de login no signup (PSU origin) |
| `beecambio.beecambio_tbl_document` | [B] beecambio | Documentos enviados para KYC |
| `beecambio.beecambio_tbl_remittance_operation` | [B] beecambio | Operações de remessa (recipient, created_ops) |
| `google_analytics.last_click_sessions` | Externo | Sessões de último clique do Google Analytics |

*SQL completo com todas as CTEs disponível em [07-queries-sql.md](07-queries-sql.md).*

> ⚠️ **Ação recomendada:** Os JOINs com `bronze.beecambio_history` e 11 tabelas `beecambio.*` representam risco de qualidade de dados. Verificar com o time de dados se existem equivalentes em silver/gold para as tabelas de maior criticidade (beecambio_tbl_customer, beecambio_tbl_document).

---

### d_calendar — Dataflow `dCalendar`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | dCalendar |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| **Entidade** | `dcalendar` |
| **Tabela destino no modelo** | `d_calendar` |
| **Tipo de datasource** | Extension (conector Databricks ou M nativo) |
| **Fontes originais** | A definir — verificar no Power BI Service |
| **Código M** | Pendente — SP precisa de `Dataflow.ReadWrite.All` |
| **Frequência de atualização** | Sem agendamento configurado (404 na API) |
| **Linhagem inferida** | Databricks / M calculado → Dataflow → `d_calendar` |
| **Compartilhado com** | Dashboard Scorecard (mesmo Dataflow ID) |

Mesmo Dataflow de calendário usado no Scorecard. Fornece a tabela de datas com marcações de dia útil, MTD, YTD, mês corrente e semana configurável. A coluna `WeekStartDate` é calculada no modelo (não no Dataflow).

---

### d_canal — Dataflow `mkt_canal`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | mkt_canal |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `e4f720d3-c121-4344-a842-0c3f84f0380c` |
| **Entidade** | `mkt_canal` |
| **Tabela destino no modelo** | `d_canal` |
| **Coluna exposta** | `canal` (string) |
| **Tipo de datasource** | Extension (2 fontes identificadas via API) |
| **Fontes originais** | A definir — provavelmente Databricks gold/silver ou tabela de mapeamento manual |
| **Código M** | Pendente — SP precisa de `Dataflow.ReadWrite.All` |
| **Frequência de atualização** | Sem agendamento configurado |
| **Linhagem inferida** | [Fonte mkt] → Dataflow `mkt_canal` → `d_canal` → `f_funnel_events.canal_lc` |

Dimensão de canais de marketing. Provável conteúdo: organic, paid, referral, direct, etc.

---

### d_source — Dataflow `mkt_source`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | mkt_source |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `b1d3ec0b-66a7-4ccd-be25-7cffbd3c9852` |
| **Entidade** | `mkt_source` |
| **Tabela destino no modelo** | `d_source` |
| **Coluna exposta** | `source` (string, oculta no modelo) |
| **Tipo de datasource** | Extension (2 fontes via API) |
| **Fontes originais** | A definir |
| **Frequência de atualização** | Sem agendamento configurado |
| **Linhagem inferida** | [Fonte mkt] → Dataflow `mkt_source` → `d_source` → `f_funnel_events.source_lc` |

Dimensão de fontes de tráfego UTM (ex: google, facebook, direct).

---

### d_medium — Dataflow `mkt_medium`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | mkt_medium |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `85ec54e9-eae3-4eaa-85e9-ef8150b1f8e8` |
| **Entidade** | `mkt_medium` |
| **Tabela destino no modelo** | `d_medium` |
| **Coluna exposta** | `medium` (string) |
| **Tipo de datasource** | Extension (2 fontes via API) |
| **Fontes originais** | A definir |
| **Frequência de atualização** | Sem agendamento configurado |
| **Linhagem inferida** | [Fonte mkt] → Dataflow `mkt_medium` → `d_medium` → `f_funnel_events.medium_lc` |

Dimensão de meios UTM (ex: cpc, email, organic, display).

---

### d_adgroup — Dataflow `mkt_adgroup`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | mkt_adgroup |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `d823fda8-e56a-4fdb-a243-e10604f3ff69` |
| **Entidade** | `mkt_adgroup` |
| **Tabela destino no modelo** | `d_adgroup` |
| **Coluna exposta** | `ad_group` (string) |
| **Tipo de datasource** | Extension (2 fontes via API) |
| **Fontes originais** | A definir |
| **Frequência de atualização** | Sem agendamento configurado |
| **Linhagem inferida** | [Fonte mkt] → Dataflow `mkt_adgroup` → `d_adgroup` → `f_funnel_events.ad_group_lc` |

Dimensão de grupos de anúncios de campanhas pagas.

---

### d_mkt_campaign — Dataflow `mkt_campaign`

| Campo | Valor |
|-------|-------|
| **Nome no Dataflow** | mkt_campaign |
| **Workspace ID** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Dataflow ID** | `b289027c-da70-4578-8627-0c05c1471ac3` |
| **Entidade** | `mkt_campaign` |
| **Tabela destino no modelo** | `d_mkt_campaign` |
| **Colunas expostas** | `Campaign`, `cluster_campaign`, `investment_type`, `media_funnel`, `paid_search_restructuring`, `awareness_2024` |
| **Tipo de datasource** | Extension (2 fontes via API) |
| **Fontes originais** | A definir — provável origem em ferramenta de gestão de mídia ou planilha |
| **Frequência de atualização** | Sem agendamento configurado |
| **Linhagem inferida** | [Ferramenta de mídia / Planilha] → Dataflow `mkt_campaign` → `d_mkt_campaign` → `f_funnel_events.mkt_campaign_lc` |

Esta é a dimensão de marketing mais rica — além do nome da campanha, inclui metadados de classificação como `cluster_campaign`, `investment_type`, `media_funnel` e flags booleanas (`paid_search_restructuring`, `awareness_2024`). Essas colunas sugerem uso para segmentação e análise de efetividade de campanhas.

---

### d_last_update

**Fonte:** Databricks — query direta
**Camada:** 🟢 Utilitário (não Databricks layer formal)
**Query:**
```sql
SELECT CURRENT_TIMESTAMP - INTERVAL '3' HOUR AS last_update
```

Retorna o timestamp do momento da última atualização, ajustado para UTC-3 (fuso horário de Brasília). Alimenta a medida `Refresh Date`.

---

### NomeSemana, d_intervalo_meses, t_Cohort

**Fonte:** Tabelas estáticas criadas via M (Power Query)
**Camada:** N/A — não dependem de sistemas externos
**Conteúdo:** Listas de valores fixos para slicers de configuração do usuário

---

### Tabelas p_*

**Fonte:** DAX calculado ou M estático
**Camada:** N/A
**Uso:** Parâmetros de seleção para visuais (matrizes cohort, modo de exibição, seleção de medida, etc.)

---

## Agendamento de Atualização

| Tabela | Agendamento | Observação |
|--------|------------|-----------|
| `f_funnel_events` | A definir | Atualização via Power BI Service |
| Todos os Dataflows | Sem agendamento configurado | API retornou 404 para refreshSchedule |
| `d_last_update` | A cada atualização | Query ao vivo — sempre retorna o momento atual |
| Tabelas estáticas / `p_*` | Nunca | Não mudam sem edição no modelo |

---

## Linhagem Estendida (com Dataflows)

```
Jornada do cliente (f_funnel_events)
├── gold.funnel_event          (Databricks 🟢)
│   ├── gold.fact_customers    (Databricks 🟢)
│   ├── silver.customers       (Databricks 🟡)
│   ├── silver.requirement     (Databricks 🟡)
│   ├── silver.orders          (Databricks 🟡)
│   ├── gold.fact_operations   (Databricks 🟢)
│   ├── bronze.beecambio_history  ⚠️ BRONZE
│   ├── beecambio.*               ⚠️ BRONZE
│   └── google_analytics.last_click_sessions
│         └─► f_funnel_events (tabela fato)
│               └─► Visuais: Cohort, Funil, Conversão, PJ, Aquisições

Calendário (d_calendar)
├── [Fonte externa — Extension]
│     └─► Dataflow: dCalendar (3cbe0c71)
│               └─► d_calendar
│                     └─► Relacionamento com f_funnel_events.event_date

Marketing UTM (todas as dimensões de marketing)
├── [Fonte externa — Extension]  (provável: Databricks gold/silver ou planilha)
│     ├─► Dataflow: mkt_canal    (e4f720d3) → d_canal    → f_funnel_events.canal_lc
│     ├─► Dataflow: mkt_source   (b1d3ec0b) → d_source   → f_funnel_events.source_lc
│     ├─► Dataflow: mkt_medium   (85ec54e9) → d_medium   → f_funnel_events.medium_lc
│     ├─► Dataflow: mkt_adgroup  (d823fda8) → d_adgroup  → f_funnel_events.ad_group_lc
│     └─► Dataflow: mkt_campaign (b289027c) → d_mkt_campaign → f_funnel_events.mkt_campaign_lc

Controle de atualização (d_last_update)
└── Databricks CURRENT_TIMESTAMP() → d_last_update → medida Refresh Date
```

---

## Pendências de Linhagem

| Pendência | Ação necessária |
|-----------|----------------|
| Código M dos 5 Dataflows mkt_* | Admin conceder `Dataflow.ReadWrite.All` ao SP `6531f15d` no workspace `5381a7f5` |
| Código M do Dataflow dCalendar | Mesma ação acima |
| Fonte original dos Dataflows mkt_* | Verificar no Power BI Service: workspace → Dataflow → Edit → Power Query Editor |
| Agendamento de atualização | Verificar no Power BI Service: workspace → Dataflow → Settings |
| JOINs bronze em f_funnel_events | Verificar com time de dados se existem equivalentes em silver/gold para `bronze.beecambio_history` |
