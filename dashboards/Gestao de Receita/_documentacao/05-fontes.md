# Gestão de Receita — Fontes de Dados

## ⚠️ Alerta Global: Múltiplos Schemas Não-Padrão

> **ATENÇÃO:** Este dashboard se conecta a **4 schemas fora da hierarquia padrão** `bronze/silver/gold/diamond`. Dados provenientes desses schemas podem ter menor garantia de estabilidade, SLA de atualização indefinido e sem cobertura de testes de qualidade do pipeline DBT padrão.

| Schema | Tabelas usadas | Impacto |
|--------|---------------|---------|
| `beecambio.*` | `beecambio_tbl_remittance_operation`, `beecambio_tbl_customer`, `beecambio_maxima_partners`, `beecambio_tbl_office` | 3 tabelas de fato/dimensão dependem deste schema |
| `automations.*` | `integrations_hasoffer_conversion` | Comissões de afiliados na tabela `customer` |
| `finance_cube.*` | `kpi_list` | Bank take alocado na tabela `customer` |
| `stage.*` | `dim_last_subsegments` | Tabela `Subsegmento PF` inteira |

> **Recomendação:** Agendar revisão com o time de dados para avaliar migração destas fontes para camadas certificadas (`gold` ou `diamond`).

---

## Resumo das fontes

| Tabela no modelo | Schema(s) | Camada | Alerta |
|-----------------|-----------|--------|--------|
| `processed_operations` | `gold` + `beecambio` | 🟢 gold + ⚠️ beecambio | JOIN com schema não-padrão |
| `customer` | `gold` + `automations` + `beecambio` + `finance_cube` | 🟢 gold + ⚠️ 3× não-padrão | 4 schemas distintos |
| `Parceiros` | `beecambio` | ⚠️ beecambio | Schema não-padrão |
| `Subsegmento PF` | `stage` + `silver` | ⚠️ stage + 🟡 silver | Stage não é camada certificada |
| `dcalendar` | Power BI Dataflow | Dataflow | Ver seção Dataflows abaixo |

---

## Fonte: processed_operations

### Visão geral

| Campo | Valor |
|-------|-------|
| Tabela destino | `processed_operations` |
| Schema principal | `gold.fact_operations` |
| Schema secundário | `beecambio.beecambio_tbl_remittance_operation` (JOIN) |
| Janela temporal | `date_trunc('month', processed_date) >= '2024-01-01'` até `date_trunc('month', current_date)` |
| Filtros na query | Nenhum filtro de `is_ops_processed` ou `is_intercompany` na query base |
| Granularidade | Uma linha por operação de câmbio |
| Endpoint Databricks | `beetech-prod-analytics.cloud.databricks.com` · `/sql/1.0/endpoints/e35e97a9319a6fe7` |

### Modelo DBT de origem

| Tabela | Modelo DBT | Status |
|--------|-----------|--------|
| `gold.fact_operations` | A definir — verificar em `dbt-metadata/gold_models.md` | A definir |

### Query SQL (simplificada)

```sql
WITH gmv_mensal AS (
  SELECT
    date_trunc('month', po.processed_date) AS mes,
    SUM(po.gmv) AS gmv
  FROM gold.fact_operations po
  GROUP BY ALL
)
SELECT
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
  ro.policy_label,              -- ← JOIN beecambio
  po.payout_affiliate,
  po.spread_revenue,
  po.is_efx,
  po.is_partner,
  po.is_corporate_api,
  po.is_fxaas,
  CASE WHEN po.counterpart = 'Google' THEN TRUE ELSE FALSE END AS google,
  gm.gmv                        AS gmv_total_mes,
  po.gmv / gm.gmv               AS prop_gmv,
  po.cost_bank_take             AS bank_take,
  COALESCE(po.real_message_cost, 0)  AS despesa_real,
  po.payout_affiliate           AS payout,
  po.partner_commissioning,
  po.cost_bacen,
  po.cost_funding,
  po.net_revenue                AS lucro,
  COALESCE(po.partner_name_from_maxima_code, po.partner_name_from_fxaas) AS partner_name,
  current_timestamp() - INTERVAL '3' HOUR AS last_update
FROM gold.fact_operations AS po
  LEFT JOIN beecambio.beecambio_tbl_remittance_operation AS ro
    ON ro.id = po.id_remittance
  LEFT JOIN gmv_mensal AS gm
    ON date_trunc('month', po.processed_date) = gm.mes
WHERE date_trunc('month', po.processed_date) >= date('2024-01-01')
  AND date_trunc('month', po.processed_date) <= date_trunc('month', current_date)
```

**Pós-processamento M:** renomeia `nature_operation_name` → `natureza`.

### Observações

- **Sem filtro de `is_ops_processed`** na query base — operações não liquidadas são incluídas. Filtros por página aplicam `is_ops_processed = true` nos visuais que exigem.
- **JOIN beecambio** traz apenas a coluna `policy_label`. O schema `beecambio` não pertence à hierarquia gold/diamond — atualizações podem divergir.
- **`bank_take` via `cost_bank_take` direto de gold** — difere da tabela `customer`, que aloca o `bank_take` via `finance_cube.kpi_list` proporcionalmente pelo GMV.
- **Coluna `lucro` = alias de `net_revenue`** — já inclui todos os custos conforme calculado no Databricks.
- **JOIN comentado detectado em 15/05/2026:** a query contém `-- left join stage.dim_monthly_messaging_cost as mm on mm.id_remittance = po.id_remittance` — evolução planejada para usar custo de mensageria por operação do `stage`. Ainda desativado; monitorar se for ativado em próxima versão da query.

*SQL completo disponível em [07-queries-sql.md](07-queries-sql.md).*

---

## Fonte: customer

### Visão geral

| Campo | Valor |
|-------|-------|
| Tabela destino | `customer` |
| Schema principal | `gold.fact_operations` |
| Schemas adicionais | `automations.integrations_hasoffer_conversion`, `beecambio.beecambio_tbl_office`, `finance_cube.kpi_list` |
| Janela temporal | `processed_date >= '2023-01-01'` (histórico mais longo que `processed_operations`) |
| Filtros | `is_ops_processed = true` + `bt.valor IS NOT NULL` |
| Granularidade | Uma linha por `id_customer` — métricas acumuladas de todo o histórico |
| Endpoint Databricks | `beetech-prod-analytics.cloud.databricks.com` · `/sql/1.0/endpoints/e35e97a9319a6fe7` |

### CTEs da query

| CTE | Schema(s) | Objetivo |
|-----|-----------|---------|
| `comissao_afiliados` | `automations.integrations_hasoffer_conversion` + `beecambio.beecambio_tbl_office` | Comissões pagas a afiliados por operação (a partir de 2022-01-01) |
| `bank_take` | `finance_cube.kpi_list` (indicador `45KPI`) | Bank take mensal total para alocação proporcional |
| `gmv_mensal` | `gold.fact_operations` | GMV mensal para cálculo de proporção de bank take |
| `base` | JOIN dos 3 CTEs + `gold.fact_operations` | Cálculo de lucro por operação com bank take alocado |

### Fórmula de lucro na tabela customer

```
lucro = gross_revenue
        - (-bank_take_mensal × proporção_GMV_operação)
        - COALESCE(real_message_cost, 0)
        - COALESCE(payout_afiliado, 0)
```

> ⚠️ **DIVERGÊNCIA DE BANK TAKE:** O `lucro` em `customer` usa bank take alocado via `finance_cube.kpi_list` (total mensal dividido por GMV proporcional). O `lucro` em `processed_operations` usa `cost_bank_take` direto de `gold.fact_operations` por operação. Os valores podem divergir.

### Query SQL (resumida)

```sql
WITH comissao_afiliados AS (
  SELECT DISTINCT
    CAST(REPLACE(REPLACE(hc.advertiser_info, 'RM_PRODUCTION_', ''), 'RM_', '') AS INT) AS id_remittance,
    hc.affiliate_id,
    do.name AS office,
    TRUE AS is_affiliate,
    SUM(hc.revenue) AS gross_revenue,
    SUM(hc.payout) AS payout
  FROM automations.integrations_hasoffer_conversion AS hc
  LEFT JOIN beecambio.beecambio_tbl_office AS do
    ON hc.affiliate_id = do.id_affiliate_on_hasoffer
  WHERE status = 'approved'
    AND date(hc.datetime) >= date('2022-01-01')
    AND hc.advertiser_info <> ''
  GROUP BY ALL
),
bank_take AS (
  SELECT
    date_trunc('month', kl.referencia) AS referencia,
    SUM(kl.valor) AS valor
  FROM finance_cube.kpi_list kl
  WHERE id = '45KPI'
  GROUP BY ALL
),
gmv_mensal AS (
  SELECT
    date_trunc('month', po.processed_date) AS mes,
    SUM(po.gmv) AS gmv
  FROM gold.fact_operations po
  WHERE is_ops_processed IS TRUE
  GROUP BY ALL
),
base AS (
  SELECT
    po.*,
    gm.gmv                                          AS gmv_total_mes,
    po.gmv / gm.gmv                                 AS prop_gmv,
    -bt.valor * (po.gmv / gm.gmv)                  AS bank_take,
    COALESCE(po.real_message_cost, 0)               AS despesa_real,
    COALESCE(ca.payout, 0)                          AS payout,
    po.gross_revenue
      - (-bt.valor * (po.gmv / gm.gmv))
      - COALESCE(po.real_message_cost, 0)
      - COALESCE(ca.payout, 0)                      AS lucro
  FROM gold.fact_operations AS po
  LEFT JOIN comissao_afiliados AS ca ON ca.id_remittance = po.id_remittance
  LEFT JOIN gmv_mensal AS gm ON date_trunc('month', po.processed_date) = gm.mes
  LEFT JOIN bank_take AS bt ON date_trunc('month', po.processed_date) = bt.referencia
  WHERE date_trunc('month', po.processed_date) >= date('2023-01-01')
    AND date_trunc('month', po.processed_date) <= date_trunc('month', current_date) - INTERVAL '1' MONTH
    AND bt.valor IS NOT NULL
    AND is_ops_processed IS TRUE
)
SELECT
  id_customer,
  COUNT(DISTINCT nature_operation_name)              AS naturezas,
  COUNT(DISTINCT in_or_out)                          AS tipo_envio,
  COUNT(DISTINCT currency_name)                      AS currency,
  COUNT(DISTINCT country)                            AS country,
  COUNT(DISTINCT id_remittance)                      AS qtde_ops,
  COUNT(DISTINCT CASE WHEN lucro < 0 THEN id_remittance ELSE NULL END) AS ops_negativas,
  SUM(lucro)                                         AS receita_liquida,
  SUM(gross_revenue)                                 AS gross_revenue
FROM base
WHERE date_trunc('month', processed_date) >= date('2023-01-01')
GROUP BY ALL
```

---

## Fonte: Parceiros

### Visão geral

| Campo | Valor |
|-------|-------|
| Tabela destino | `Parceiros` |
| Schema | `beecambio` |
| Tabelas base | `beecambio.beecambio_tbl_customer` + `beecambio.beecambio_maxima_partners` |
| Filtro | `maxima_partner_code IS NOT NULL` |
| Granularidade | Uma linha por cliente com parceiro Maxima cadastrado |
| Endpoint Databricks | `beetech-prod-analytics.cloud.databricks.com` · `/sql/1.0/endpoints/e35e97a9319a6fe7` |

### Query SQL

```sql
SELECT
  c.id              AS id_customer,
  mp.name           AS partner_name
FROM beecambio.beecambio_tbl_customer c
INNER JOIN beecambio.beecambio_maxima_partners AS mp
  ON mp.partner_code = c.maxima_partner_code
WHERE c.maxima_partner_code IS NOT NULL
```

### Coluna calculada (DAX)

**Escritórios:** classifica o parceiro em "Sim" (escritório legítimo) ou "Não" (parceiro específico).

Lista hardcoded de parceiros classificados como "Não":
- HIGHER - ADM GIHER SERVIÇOS FINANCEIROS
- CHINA GATE
- SPEED SOLUTIONS
- EXCHANGE SERVICOS E TECNOLOGIA LTDA
- PRICE CAMBIO (PRADAS & REBELO)
- ROYAL PARTNER
- CORPORATE API
- TriStar

> ⚠️ **MANUTENÇÃO MANUAL:** Qualquer novo parceiro que deva ser classificado como "Não" requer edição manual desta coluna calculada no modelo Power BI.

---

## Fonte: Subsegmento PF

### Visão geral

| Campo | Valor |
|-------|-------|
| Tabela destino | `Subsegmento PF` |
| Schema principal | `stage.dim_last_subsegments` |
| Schema de filtro | `silver.customers` |
| Filtro | `silver.customers.customer_type = 'PF'` |
| Granularidade | Uma linha por cliente × mês |
| Endpoint Databricks | `beetech-prod-analytics.cloud.databricks.com` · `/sql/1.0/endpoints/e35e97a9319a6fe7` |

> ⚠️ **SCHEMA STAGE:** O schema `stage` é uma camada intermediária de estágio — não é bronze/silver/gold/diamond. Verificar com o time de dados o nível de estabilidade, SLA de atualização e plano de migração para uma camada certificada.

### Query SQL

```sql
SELECT
  s.id_customer,
  date(s.month) AS month_id,
  s.subsegment
FROM stage.dim_last_subsegments AS s
LEFT JOIN silver.customers AS c
  ON c.id = s.id_customer
WHERE c.customer_type = 'PF'
```

### Observação de granularidade

A tabela tem granularidade de cliente × mês (`id_customer` + `month_id`), mas o relacionamento com `processed_operations` é feito apenas por `id_customer`. Isso significa que ao filtrar por subsegmento, todas as operações do cliente (independentemente do mês) serão incluídas. Análises temporais finas de subsegmento devem ser interpretadas com atenção.

---

## Fonte: Power BI Dataflow

### Dataflow: dcalendar

| Campo | Valor |
|-------|-------|
| Workspace ID | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| Dataflow ID | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| Entidade | `dcalendar` |
| Tabela destino | `dcalendar` |
| Transformações no modelo | Nenhuma — leitura direta da entidade, sem passos M adicionais |
| Colunas disponíveis | `Date Key`, `date_month`, `is_holiday`, `dayofweek`, `workday`, `workday_processado`, `month_days`, `workdays_month`, `last_workday`, `d0`, `m0`, `m1`, `mtd`, `workdays_quarter`, `label`, `year`, `week`, `Quarter`, `Filter Today`, `Current Month`, `month_to_date`, `last_update_calendar`, `month`, `day`, `month_number`, `month_year`, `mtd_calendar_days`, `is_ytd`, `is_current_date`, `day_of_yesterday`, `special_condition`, `total_month_days`, `Google Day`, `label_with_all_days_month` |
| Fonte original | A definir — verificar no PBI Service |
| Frequência de atualização | A definir |
| Linhagem inferida | Databricks gold (provável) → Dataflow `3cbe0c71` → `dcalendar` |

> ℹ️ **Versão expandida:** O `dcalendar` deste dashboard tem mais colunas que o do Daily Sales Dashboard — inclui flags como `is_holiday`, `workday`, `special_condition`, `Google Day`, etc. É provavelmente uma versão mais recente ou ampliada do mesmo Dataflow compartilhado (mesmo workspace ID e dataflow ID).

**Query M no modelo:**

```m
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    #"5381a7f5-5b4c-4fa7-96d6-48992d85d88e" = Workspaces{[workspaceId="5381a7f5-5b4c-4fa7-96d6-48992d85d88e"]}[Data],
    #"3cbe0c71-8501-42b4-bcea-9dfb4ff7adef" = #"5381a7f5-5b4c-4fa7-96d6-48992d85d88e"{[dataflowId="3cbe0c71-8501-42b4-bcea-9dfb4ff7adef"]}[Data],
    dcalendar_ = #"3cbe0c71-8501-42b4-bcea-9dfb4ff7adef"{[entity="dcalendar",version=""]}[Data]
in
    dcalendar_
```

**Linhagem inferida:**

```
Databricks (gold.dcalendar — provável)
  └─► Power BI Dataflow 3cbe0c71 (Workspace 5381a7f5)
        └─► dcalendar (tabela dimensão no modelo)
              └─► processed_operations (via relacionamento Date Key → processed_date)
                    └─► Medidas de série temporal (Mes anterior, % variação, etc.)
                          └─► Visuais de gráfico de linha e barras por período
```

---

## Linhagem Estendida

```
FONTES EXTERNAS → DATABRICKS → [DATAFLOW] → MODELO POWER BI → MEDIDAS → VISUAIS
                                                                               
gold.fact_operations ──────────────────────────────► processed_operations
                                                          ├── Total GMV ⭐
                                                          ├── Total Gross Revenue ⭐
                                                          ├── Total operações ⭐
                                                          ├── Total Receita Líquida
                                                          ├── Total custo
                                                          └── [+40 medidas]

beecambio.beecambio_tbl_remittance_operation ──► processed_operations[policy_label]

gold.fact_operations ──────────────────────────────► customer
automations.integrations_hasoffer_conversion ──────► customer (comissões afiliados)
beecambio.beecambio_tbl_office ────────────────────► customer (escritórios afiliados)
finance_cube.kpi_list (45KPI) ─────────────────────► customer (bank take alocado)
                                                          ├── Clientes negativados
                                                          ├── Clientes positivos
                                                          └── # operações

beecambio.beecambio_tbl_customer ──────────────────► Parceiros
beecambio.beecambio_maxima_partners ───────────────► Parceiros

stage.dim_last_subsegments ────────────────────────► Subsegmento PF
silver.customers (filtro PF) ──────────────────────► Subsegmento PF

Databricks gold (provável)
  └─► Dataflow 3cbe0c71 ──────────────────────────► dcalendar
                                                          └─► Mes anterior
                                                          └─► % variação
                                                          └─► Filtros de calendário
```

---

## Tabela de Pendências

| Fonte | Informação pendente | Como obter | Prioridade |
|-------|--------------------|-----------|----|
| `dcalendar` (Dataflow) | Fonte original do Dataflow | PBI Service → Workspace 5381a7f5 → Dataflow 3cbe0c71 → Edit | Média |
| `dcalendar` (Dataflow) | Transformações M internas | PBI Service → Dataflow → Edit Queries | Baixa |
| `dcalendar` (Dataflow) | Frequência de atualização | PBI Service → Dataflow → Settings | Média |
| `gold.fact_operations` | Modelo DBT de origem | `dbt-metadata/gold_models.md` ou `/extrair-dbt-metadata` | Baixa |
| `beecambio.*` | Plano de migração para gold/diamond | Time de dados | Alta |
| `automations.*` | Plano de migração para gold/diamond | Time de dados | Alta |
| `finance_cube.kpi_list` | Definição do indicador `45KPI` e metodologia de alocação | Time Financeiro | Alta |
| `stage.dim_last_subsegments` | Estabilidade e plano de certificação | Time de dados | Alta |
| `Parceiros` | Revisar lista hardcoded de 8 parceiros classificados como "Não" | Time Revenue | Média |
