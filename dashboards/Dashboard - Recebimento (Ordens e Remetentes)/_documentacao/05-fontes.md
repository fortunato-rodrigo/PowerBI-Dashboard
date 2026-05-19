# Dashboard - Recebimento — Fontes de Dados

> ⚠️ **ALERTA GLOBAL — Schemas não-padrão:**
> Este dashboard conecta em múltiplos schemas fora do padrão `gold`/`silver`:
> - `beecambio.*` — sistema legado da Remessa Online (7+ tabelas)
> - `banking_payments.*` — serviço de pagamentos
> - `conciliation_service.*` — serviço de conciliação
> - `stage.*` — dados em fase de transição (instáveis)
> - `google_analytics.*` — dados de atribuição de marketing
> - `legacy.*` — dados legados de atribuição
> - `bronze.*` — dados brutos sem transformação
>
> Conexões mistas com schemas fora do padrão elevam o risco de inconsistência e criam dependências implícitas com outros times. Qualquer breaking change nessas tabelas afeta diretamente este dashboard.

---

## Fonte 1: `f_orders` — silver.orders

| Campo | Valor |
|-------|-------|
| Tabela destino | `f_orders` |
| Camada principal | 🟡 Silver |
| Schema | `silver.orders` |
| Janela | `created_date >= '2024-01-01'` |
| Exclusão | `counterpart LIKE '%remessa online%'` |

**Query (simplificada):**

```sql
SELECT
    o.*,
    fo.gmv AS gmv_forecast,    -- cotação do dia via f_gold_ops
    c.*,                        -- dados do cliente (beecambio)
    pm.premium_level,          -- nível premium (stage)
    ms.subsegment,             -- subsegmento mensal (stage)
    ga_web.*,                  -- atribuição web GA4
    ga_app.*,                  -- atribuição app GA4
    lc.canal_lc,               -- last-click sessions
    leg.canal_lc_old,          -- atribuição legada
    bc.date AS calendar_ref,   -- referência de datas (bronze.dcalendar nas CTEs)
    cnae.*                     -- CNAE estruturado (seeds)
FROM silver.orders o
LEFT JOIN gold.fact_operations fo ON o.id_remittance = fo.id_remittance
LEFT JOIN beecambio.beecambio_tbl_customer c ON o.id_customer = c.id_customer
LEFT JOIN stage.dim_monthly_premium pm ON o.id_customer = pm.id_customer AND month(o.created_date) = pm.month
LEFT JOIN stage.dim_monthly_subsegmentation ms ON o.id_customer = ms.id_customer AND month(o.created_date) = ms.month
LEFT JOIN google_analytics.ga4_web_event_attribution ga_web ON o.ga_session_id = ga_web.ga_session_id
LEFT JOIN google_analytics.ga4_app_event_attribution ga_app ON o.ga_session_id = ga_app.ga_session_id
LEFT JOIN google_analytics.last_click_sessions lc ON ...
LEFT JOIN legacy.last_click_old leg ON ...
LEFT JOIN seeds.cnae_estruturado cnae ON o.cnae = cnae.cnae_code
WHERE created_date >= '2024-01-01'
  AND counterpart NOT LIKE '%remessa online%'
```

**Colunas calculadas no modelo M:**

| Coluna calculada | Lógica |
|-----------------|--------|
| `gmv_forecast` | `quantity * LOOKUPVALUE(d_trading_quotation[trading_quotation], ...)` |
| `gross_revenue_forecast` | ⚠️ `quantity * 0.0083` — spread 0,83% **HARDCODED** |
| `Prazo de Resgate` | `≤ 180 dias` / `> 180 dias` baseado em dias entre criação e resgate |
| `Resgate no mesmo mês` | `Sim` / `Não` |
| `Google` | Calculado a partir do JOIN com google_analytics |
| `Fenix` | Flag de sistema (Fênix vs. plataforma principal) |
| `Customer Type` | Renomeado de `customer_type` |
| `Remetente` | Renomeado de `original_counterpart` |
| `Contraparte Ajustada` | Renomeado de `counterpart` |
| `Contraparte` | Renomeado de `contraparte_ajustada_para_ranking_final` |
| `Instituição Financeira` | Renomeado de `instituicao_financeira` |

---

## Fonte 2: `f_etapa_drop` — Funil de Drop-off

| Campo | Valor |
|-------|-------|
| Tabela destino | `f_etapa_drop` |
| Camada | 🟢 Gold + ⚠️ Beecambio |
| Schemas | `gold.funnel_event`, `beecambio.beecambio_tbl_customer_bank_account`, `silver.orders` |
| Filtro | Clientes com eventos PSU/SU/ACQ/OPR mas **sem** operação (anti-join) |

**Query (simplificada):**

```sql
SELECT
    fe.id_customer,
    fe.event_date,
    fe.event_type AS last_event,
    fe.psu_date,
    fe.signup_date,
    fe.funnel_order,
    fe.customer_type,
    fe.onboarding_type,
    fe.canal,
    fe.cnae_session,
    fe.cnae_division
FROM gold.funnel_event fe
LEFT JOIN beecambio.beecambio_tbl_customer_bank_account ba ON fe.id_customer = ba.id_customer
LEFT JOIN silver.orders op ON fe.id_customer = op.id_customer
WHERE fe.event_type IN ('PRESIGNUP', 'SIGNUP', 'ACQUISITION', 'OPERATION')
  AND op.id_customer IS NULL  -- clientes que NUNCA fizeram uma ordem
```

---

## Fonte 3: `f_fonte_entrada` — Fonte de Entrada de Ordens

| Campo | Valor |
|-------|-------|
| Tabela destino | `f_fonte_entrada` |
| Camada | ⚠️ Beecambio + Banking Payments + Conciliation Service |
| Schemas | `beecambio.beecambio_tbl_payment_order`, `banking_payments.public_payment_order`, `conciliation_service.conciliation_payment_orders` |
| Janela | 12 meses rolling (últimos 12 meses) |

**Query real (extraída de `data_quality.tables_in_dashboards_pbix` em 15/05/2026):**

```sql
with erro_conc as (
    select correspondent_reference, error_reason
    from conciliation_service.conciliation_payment_orders
    where status = 'error'
)
select
    od.id,
    date_trunc('hour', od.created_at - interval '3' hour) as data_criacao,
    bpo.code,
    od.created_via_opr,
    od.type,
    cpo.error_reason,
    od.correspondent_reference,
    od.created_at - interval 3 hour as created_at,
    bpo.created_at - interval 3 hour as created_at_api,
    date_diff(minute, bpo.created_at - interval 3 hour, od.created_at - interval 3 hour) as diff_falha_api,
    case
        when bpo.code is not null and date_diff(minute, ...) <= 10 then 'API'
        when bpo.code is null and od.created_via_opr is true and od.type = 'normal'
             and cpo.error_reason is null then 'Arquivo da OPR'
        when cpo.error_reason is not null and od.created_via_opr is true then 'Ferramenta de Emenda'
        when od.type = 'massive_children' then 'Coleta Local'
        when od.created_via_opr is false then 'Emenda Manual'
        when od.type = 'wallet' then 'Wallet/Conta Global'
        when bpo.code is not null and date_diff(minute, ...) > 10 then 'Falha API'
        else null
    end as fonte_entrada
from beecambio.beecambio_tbl_payment_order as od
left join banking_payments.public_payment_order as bpo
    on od.correspondent_reference = bpo.code
left join erro_conc as cpo
    on od.correspondent_reference = cpo.correspondent_reference
where date(od.created_at) >= current_date - interval '12' month
```

*SQL completo disponível em [07-queries-sql.md](07-queries-sql.md).*

**Tipos de fonte mapeados:**

| Fonte de Entrada | Descrição |
|-----------------|-----------|
| API | Ordem criada via integração API |
| Arquivo da OPR | Arquivo de ordens de pagamento enviado pelo cliente |
| Ferramenta de Emenda | Ordens corrigidas manualmente via ferramenta |
| Coleta Local | ⚠️ Pagamento coletado presencialmente |
| Emenda Manual | Emenda feita manualmente pelo backoffice |
| Wallet / Conta Global | Ordem originada da carteira digital do cliente |
| Falha API | Tentativa de criação via API que falhou |
| N/A | Tipo não classificado |

---

## Fonte 4: `f_credito_identificado` — Crédito Identificado (Topázio)

| Campo | Valor |
|-------|-------|
| Tabela destino | `f_credito_identificado` |
| Camada | ⚠️ Beecambio exclusivamente |
| Schemas | `beecambio.*` (7 tabelas) |
| Filtros | `id_status = 3` (Crédito identificado) + `id_financial_institution = 3` (Topázio) + `date >= 2024-01-01` |
| Relacionamento | Sem join com `d_calendar` |

**Tabelas beecambio referenciadas (7 tabelas — confirmado via `07-queries-sql.md` em 15/05/2026):**

| Tabela | Papel |
|--------|-------|
| `beecambio.beecambio_tbl_payment_order` | Tabela principal (ordens de pagamento) — FROM |
| `beecambio.beecambio_tbl_sender` | Nome do remetente (N.name) |
| `beecambio.beecambio_tbl_payment_order_status` | Status da ordem (S.name) |
| `beecambio.beecambio_tbl_customer` | Tipo de cliente (D.c_type → PF/PJ) |
| `beecambio.beecambio_tbl_payment_order_remittance` | Vinculação ordem ↔ remessa |
| `beecambio.beecambio_tbl_remittance_operation` | Dados da operação de remessa (valor, quantidade) |
| `beecambio.beecambio_tbl_remittance_operation_status` | Status da operação de remessa |

**Query (simplificada — SQL completo em [07-queries-sql.md](07-queries-sql.md)):**

```sql
SELECT O.id_customer, 'P' || D.c_type AS customer_type,
       O.id AS id_ordem, S.name AS status_ordem,
       PR.remittance_operation_id,
       R.total_value AS total_value_remittance_operation,
       ...
FROM beecambio.beecambio_tbl_payment_order AS O
    INNER JOIN beecambio.beecambio_tbl_sender AS N ON N.id = O.id_sender
    INNER JOIN beecambio.beecambio_tbl_payment_order_status AS S ON O.id_status = S.id
    INNER JOIN beecambio.beecambio_tbl_customer AS D ON D.id = O.id_customer
    LEFT JOIN beecambio.beecambio_tbl_payment_order_remittance AS PR ON O.id = PR.payment_order_id
    LEFT JOIN beecambio.beecambio_tbl_remittance_operation AS R ON PR.remittance_operation_id = R.id
    LEFT JOIN beecambio.beecambio_tbl_remittance_operation_status AS os ON os.id = R.id_status
WHERE O.id_status = 3              -- Crédito identificado
  AND O.id_financial_institution = 3   -- Topázio
  AND date(O.created_at) >= '2024-01-01'
  AND PR.remittance_operation_id IS NOT NULL
  AND os.status = 'Finalizada'
```

> ℹ️ Esta tabela exibe apenas ordens da **instituição Topázio** (id=3). Outras instituições financeiras (ex: Master) não aparecem nesta view. Se a Remessa Online usar outra instituição, o filtro `id_financial_institution = 3` precisará ser atualizado.

---

## Fonte 5: `d_trading_quotation` — Cotações FX

| Campo | Valor |
|-------|-------|
| Tabela destino | `d_trading_quotation` |
| Camada | 🟡 Silver |
| Schema | `silver.trading_quotations` |
| Janela | `date > 2024-01-01` |
| Cardinalidade | Uma cotação por moeda por dia |

```sql
SELECT currency_abbrev, date, trading_quotation
FROM silver.trading_quotations
WHERE date > '2024-01-01'
```

---

## Fonte 6: `d_calendar` — Calendário (Power BI Dataflow)

### Dataflow: dcalendar

| Campo | Valor |
|-------|-------|
| Workspace ID | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| Dataflow ID | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| Entidade | `dcalendar` |
| Tabela destino | `d_calendar` |
| Janela | `year >= 2023` (filtro M no modelo) |
| Fonte original | A definir — verificar no Power BI Service |
| Frequência de atualização | A definir |

**Transformações M no modelo (após leitura da entidade):**

1. Adiciona coluna `Fim do Mês` = `Date.EndOfMonth([Date Key])`
2. Adiciona coluna `last_day` = `[Date Key] = [Fim do Mês]` (booleano)
3. Filtra: `year >= 2023`

**Query M completa:**

```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    #"5381a7f5-5b4c-4fa7-96d6-48992d85d88e" = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    #"3cbe0c71-8501-42b4-bcea-9dfb4ff7adef" = #"5381a7f5-5b4c-4fa7-96d6-48992d85d88e"{[dataflowId="3cbe0c71-8501-42b4-bcea-9dfb4ff7adef"]}[Data],
    dcalendar_ = #"3cbe0c71-8501-42b4-bcea-9dfb4ff7adef"{[entity="dcalendar",version=""]}[Data],
    #"Fim do Mês Inserido" = Table.AddColumn(dcalendar_, "Fim do Mês", each Date.EndOfMonth([Date Key]), type date),
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"Fim do Mês Inserido", "last_day", each if [Date Key] = [Fim do Mês] then true else false),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Coluna Condicional Adicionada",{{"last_day", type logical}}),
    #"Linhas Filtradas" = Table.SelectRows(#"Tipo Alterado", each [year] >= 2023)
in
    #"Linhas Filtradas"
```

**Linhagem inferida:**

```
[Fonte original — A definir no PBI Service]
  └─► Dataflow 3cbe0c71 (entidade dcalendar)
        └─► Modelo: + Fim do Mês + last_day, filtro year >= 2023
              └─► d_calendar [hub temporal]
                    ├─► f_orders (created_date)
                    ├─► f_etapa_drop (event_date)
                    ├─► f_fonte_entrada (data_criacao_data)
                    └─► d_trading_quotation (date)
```

> ℹ️ **Mesmo Dataflow** usado no Scorecard, Daily Sales Dashboard e Gestão de Receita. O Dataflow `dcalendar` é transversal a todos os dashboards da Remessa Online.

---

## Fonte 7: `d_last_update` — Timestamp

| Campo | Valor |
|-------|-------|
| Camada | Sem camada Databricks |
| Query | `SELECT current_timestamp() - interval '3' hour AS last_update` |

Compensa o UTC-3 para exibir o horário de Brasília.

---

## Linhagem Estendida

```
FONTES EXTERNAS → CAMADAS → TABELAS DO MODELO → MEDIDAS → VISUAIS

silver.orders ──────────────────────────────────────► f_orders
  + gold.fact_operations (gmv_forecast)                 ├── Ordens, Resgatadas, Pendentes
  + beecambio.beecambio_tbl_customer                    ├── GMV (Resgatado), Receita (Resgatado)
  + stage.dim_monthly_premium                           ├── GMV Pendente (Forecast)
  + stage.dim_monthly_subsegmentation                   ├── Receita Pendente (Forecast)
  + google_analytics.ga4_*_event_attribution            ├── Ticket Médio, ME, Clientes únicos
  + legacy.last_click_old                               └── PercentualCrescimento
  + bronze.dcalendar (CTEs)
  + seeds.cnae_estruturado

gold.funnel_event ──────────────────────────────────► f_etapa_drop ── Total Users
  + beecambio.beecambio_tbl_customer_bank_account
  + silver.orders (anti-join)

beecambio.beecambio_tbl_payment_order ──────────────► f_fonte_entrada
  + banking_payments.public_payment_order
  + conciliation_service.conciliation_payment_orders

beecambio.* (7 tabelas) ────────────────────────────► f_credito_identificado
  Topázio only (id_financial_institution=3)

silver.trading_quotations ──────────────────────────► d_trading_quotation ── Max, Min, Median

Dataflow 3cbe0c71 (dcalendar) ──────────────────────► d_calendar [hub temporal]
  + Fim do Mês, last_day (transformações M)

current_timestamp() - 3h ───────────────────────────► d_last_update ── Refresh Date

p_Spread (What if?) ─────────────────────────────────────────────────────────────────
  GENERATESERIES(0, 0.02, 0.0001) ──────────────────────────────── Receita Pendente (Forecast)
```

---

## Pendências

| Tabela | Campo pendente | Ação necessária |
|--------|---------------|-----------------|
| `d_calendar` (Dataflow) | Fonte original do Dataflow | Acessar PBI Service → workspace `5381a7f5` → Dataflows |
| `d_calendar` (Dataflow) | Frequência de atualização | Idem |
| `f_orders` | Campos exatos do `stage.dim_monthly_premium` | Confirmar com time de dados |
| `f_orders` | Campos exatos do `stage.dim_monthly_subsegmentation` | Confirmar com time de dados |
| Geral | `gross_revenue_forecast = quantity * 0.0083` | Confirmar se 0,83% ainda é o spread vigente. **Se não for, atualizar a coluna calculada.** |

> ✅ **Resolvido em 15/05/2026 via `Extract-QueryMetadata.ps1`:** lista das 7 tabelas de `f_credito_identificado` e query exata de `f_fonte_entrada` (CASE WHEN, não UNION) — ver [07-queries-sql.md](07-queries-sql.md).
