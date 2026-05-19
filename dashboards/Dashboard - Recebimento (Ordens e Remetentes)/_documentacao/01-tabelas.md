# Dashboard - Recebimento — Inventário de Tabelas

## Tabelas de Fato

### `f_orders` — Ordens de Pagamento

| Campo | Valor |
|-------|-------|
| Tipo | Fato |
| Camada | 🟡 Silver |
| Fonte principal | `silver.orders` |
| Janela | `created_date >= '2024-01-01'` |
| Exclusão | `counterpart LIKE '%remessa online%'` (remove intercompany) |

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id` | string | ID da ordem |
| `id_customer` | string | ID do cliente |
| `created_date` | date | Data de criação (chave de relacionamento com `d_calendar`) |
| `status` | string | Status atual da ordem |
| `bu` | string | Unidade de negócio |
| `business_type` | string | Tipo de negócio |
| `Customer Type` | string | PF ou PJ (renomeado de `customer_type`) |
| `currency` | string | Moeda da operação |
| `quantity` | decimal | Valor em moeda estrangeira |
| `trading_quotation` | decimal | Cotação do dia |
| `gross_revenue_forecast` | decimal | ⚠️ `quantity * 0.0083` — spread 0,83% **HARDCODED** |
| `gmv_forecast` | decimal | `quantity * trading_quotation` (LOOKUPVALUE de `d_trading_quotation`) |
| `type` | string | Tipo da operação (remessa/câmbio) |
| `funil` | string | Etapa no funil (Aquisição/Recorrência) |
| `onboarding_type` | string | Tipo de onboarding |
| `company_onboarding_flow` | string | Fluxo de onboarding da empresa |
| `nature_operation_name` | string | Natureza regulatória da operação |
| `canal` / `medium` / `source` / `mkt_campaign` | string | Dimensões de marketing |
| `Remetente` | string | Contraparte original (renomeado de `original_counterpart`) |
| `Contraparte Ajustada` | string | Contraparte após normalização (renomeado de `counterpart`) |
| `Contraparte` | string | Ranking final de contraparte (`contraparte_ajustada_para_ranking_final`) |
| `Instituição Financeira` | string | Banco (`instituicao_financeira`) |
| `Prazo de Resgate` | string | Calculado: `≤ 180 dias` / `> 180 dias` |
| `Resgate no mesmo mês` | string | `Sim` / `Não` |
| `Google` | string | Calculado via JOIN com `google_analytics` |
| `Fenix` | string | Flag de operação via sistema Fênix |
| `cupom_desconto` / `desconto` | string | Dados de desconto |
| `last_bu` / `last_business_type` / `last_nature` / `last_segment` / `last_subsegment` | string | Última BU/segmento do cliente |
| `cnae_*` | string | CNAE da empresa (para PJ) |

**JOINs e fontes adicionais:**

| Fonte | Join | Finalidade |
|-------|------|------------|
| `gold.fact_operations` | LEFT JOIN por `id_remittance` | `gmv_forecast` (cotação do dia) |
| `beecambio.beecambio_tbl_customer` | LEFT JOIN por `id_customer` | Dados do cliente |
| `stage.dim_monthly_premium` | LEFT JOIN por cliente+mês | Nível premium mensal |
| `stage.dim_monthly_subsegmentation` | LEFT JOIN por cliente+mês | Subsegmento mensal |
| `google_analytics.ga4_web_event_attribution` | LEFT JOIN por `ga_session_id` | Atribuição web |
| `google_analytics.ga4_app_event_attribution` | LEFT JOIN por `ga_session_id` | Atribuição app |
| `google_analytics.last_click_sessions` | LEFT JOIN | Sessão last-click |
| `legacy.last_click_old` | LEFT JOIN | Atribuição legada |
| `bronze.dcalendar` | CROSS/FROM | Referência de calendário nas CTEs |
| `seeds.cnae_estruturado` | LEFT JOIN | Descrição de CNAE |

---

### `f_etapa_drop` — Funil de Drop-off

| Campo | Valor |
|-------|-------|
| Tipo | Fato |
| Camada | 🟢 Gold + ⚠️ Beecambio |
| Fonte | `gold.funnel_event` LEFT JOIN `beecambio.beecambio_tbl_customer_bank_account` LEFT JOIN `silver.orders` |
| Filtro | Clientes com `event_type IN ('PRESIGNUP','SIGNUP','ACQUISITION','OPERATION')` mas **sem** operação (`op.id_customer IS NULL`) |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_customer` | string | ID do cliente (DISTINCTCOUNT = `Total Users`) |
| `psu_date` | date | Data do presignup |
| `signup_date` | date | Data do signup |
| `event_date` | date | Data do evento (chave com `d_calendar`) |
| `last_event` | string | Último evento registrado no funil |
| `funnel_order` | int | Ordem numérica do estágio |
| `customer_type` | string | PF / PJ |
| `onboarding_type` | string | Tipo de onboarding |
| `canal` | string | Canal de aquisição |
| `cnae_session` / `cnae_division` | string | CNAE da empresa |

---

### `f_fonte_entrada` — Fonte de Entrada de Ordens

| Campo | Valor |
|-------|-------|
| Tipo | Fato |
| Camada | ⚠️ Beecambio + Banking Payments + Conciliation Service |
| Fonte | `beecambio.beecambio_tbl_payment_order` UNION `banking_payments.public_payment_order` UNION `conciliation_service.conciliation_payment_orders` |
| Janela | 12 meses rolling |

**Colunas:**

| Coluna | Descrição |
|--------|-----------|
| `id_payment_order` | ID da ordem de pagamento |
| `data_criacao_data` | Data de criação (chave com `d_calendar`) |
| `fonte_entrada` | Classificação: API / Arquivo da OPR / Ferramenta de Emenda / Coleta Local / Emenda Manual / Wallet/Conta Global / Falha API / N/A |

---

### `f_credito_identificado` — Crédito Identificado

| Campo | Valor |
|-------|-------|
| Tipo | Fato |
| Camada | ⚠️ Beecambio (todos os 7 JOINs) |
| Fonte | `beecambio.beecambio_tbl_payment_order` + 6 tabelas beecambio |
| Filtro | `id_status = 3` (Crédito identificado) + `id_financial_institution = 3` (Topázio) + `date >= 2024-01-01` |
| Relacionamento | **Nenhum** — não se relaciona com `d_calendar` |

**Colunas:**

| Coluna | Descrição |
|--------|-----------|
| `id` | ID da ordem |
| `id_customer` | ID do cliente |
| `name` | Nome do cliente |
| `amount` | Valor identificado |
| `currency` | Moeda |
| `date` | Data da identificação |
| `backoffice_link` | URL dinâmica: `https://backoffice.remessaonline.com.br/index/detalhes-ordem-pagamento/{id}` |

---

## Tabela de Dimensão

### `d_trading_quotation` — Cotações FX

| Campo | Valor |
|-------|-------|
| Tipo | Dimensão |
| Camada | 🟡 Silver |
| Fonte | `silver.trading_quotations` |
| Janela | `date > 2024-01-01` |

**Colunas:** `currency_abbrev`, `date` (chave com `d_calendar`), `trading_quotation`, `currency_key` (calculada, oculta)

---

### `d_calendar` — Calendário

| Campo | Valor |
|-------|-------|
| Tipo | Dimensão temporal |
| Camada | Dataflow (transversal) |
| Fonte | Power BI Dataflow `3cbe0c71` · Entidade `dcalendar` |
| Workspace | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| Janela | `year >= 2023` |

**Transformações M no modelo:** adiciona `Fim do Mês` (Date.EndOfMonth) e `last_day` (booleano).

**Colunas:** `Date Key`, `date_month`, `year`, `month`, `month_number`, `month_year`, `month_to_date`, `quarter`, `week`, `workday`, `workdays_month`, `workday_processado`, `workdays_quarter`, `last_workday`, `d0`, `m0`, `m1`, `mtd`, `mtd_calendar_days`, `is_holiday`, `dayofweek`, `is_ytd`, `is_current_date`, `day_of_yesterday`, `Filter Today`, `Current Month`, `Google Day`, `last_update_calendar`, `Fim do Mês`, `last_day`, `label`, `label_with_all_days_month`, `total_month_days`, `special_condition`

---

### `d_last_update` — Atualização

| Campo | Valor |
|-------|-------|
| Tipo | Auxiliar |
| Fonte | `SELECT current_timestamp() - interval '3' hour as last_update` |

---

## Tabelas de Seleção (Parâmetros DAX)

### `p_Medida` — Seletor de Métrica (16 opções)

Controla qual KPI é exibido nos visuais dinâmicos.

| Opção | Medida associada |
|-------|-----------------|
| Ordens | Ordens |
| Resgatadas | Resgatadas |
| GMV (Resgatado) | GMV (Resgatado) |
| GMV Pendente (Forecast) | GMV Pendente (Forecast) |
| Receita (Resgatado) | Receita (Resgatado) |
| Receita Pendente (Forecast) | Receita Pendente (Forecast) |
| ... | ... (16 total) |

---

### `p_Dimension 1`, `p_Dimension 2`, `p_Dimension 3` — Seletores de Dimensão (28 opções cada)

Permitem decompor as métricas por até 3 dimensões simultâneas. Opções:

`BU`, `Onboarding Flow`, `Contraparte Ajustada`, `Contraparte`, `Cupom`, `Currency`, `Customer Type`, `Desconto`, `Fenix`, `Funil`, `Filtrar Google`, `ID Customer`, `ID da Ordem`, `Instituição Financeira`, `Onboarding Type`, `Prazo de Resgate`, `Remittance Nature`, `Resgate no mesmo mês`, `Type`, `Canal`, `Medium`, `Source`, `Mkt Campaign`, `Última BU`, `Última Business Type`, `Última Natureza`, `Último Segmento`, `Último Subsegmento`

---

### `p_Spread (What if?)` — Simulador de Spread

| Campo | Valor |
|-------|-------|
| Range | 0% a 2% em passos de 0,01% |
| Geração | `GENERATESERIES(0, 0.02, 0.0001)` |
| Medida | `Valor Spread (What if?) = SELECTEDVALUE(...)` |

Permite simular cenários de receita com diferentes spreads.

---

### `p_Timeframe` — Granularidade Temporal

| Opção | Coluna `d_calendar` |
|-------|---------------------|
| Year | `d_calendar[year]` |
| Quarter | `d_calendar[Quarter]` |
| Month | `d_calendar[date_month]` |
| Week | `d_calendar[week]` |
| Date | `d_calendar[Date Key]` |
