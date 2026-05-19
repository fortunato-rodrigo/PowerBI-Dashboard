# Ontologia Corporativa — Mapeamento Termo → DAX → Databricks

> **Propriedade:** transversal · **Gestão:** `/pbi-ontologia`
> **Seed:** Mai 2026 a partir do dashboard Scorecard · Atualizado com Daily Sales Dashboard, Gestão de Receita, Dashboard - Recebimento, Mkt Performance e informações de domínio (datas, funil, premium)
>
> Este arquivo é a "Rosetta Stone" do time de dados + negócio:
> dado um termo de negócio, encontra a medida DAX e a coluna/tabela no Databricks.

---

## Como ler este arquivo

| Coluna | O que é |
|--------|---------|
| **Termo de negócio** | Nome usado por stakeholders e em comunicações |
| **Medida DAX** | `Tabela.NomeDaMedida` no modelo Power BI |
| **Tabela Databricks** | Camada + nome da tabela (`gold.fact_operations`) |
| **Coluna Databricks** | Coluna específica (quando aplicável) |
| **Notas** | Ressalvas, filtros, derivações |

---

## KPIs — Volume e Operações

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| GMV | `Medidas.GMV` (Scorecard) / `# Medidas.GMV` (Safras/Daily Sales) / `Medidas.Total GMV` (Gestão de Receita) | `gold.fact_operations` / `gold.funnel_event` / `gold.daily_sales` | `gmv` | Daily Sales: COALESCE(`f_daily_sales[gmv]`, `f_gold_ops[gmv]`); Scorecard: `is_intercompany=false`, `is_ops_processed=true`; Gestão de Receita: sem filtro is_intercompany na query |
| Número de operações / Operations / Ops | `Medidas.Operations` (Scorecard) / `# Medidas.Ops` (Daily Sales) / `Medidas.Total operações` (Gestão de Receita) | `gold.fact_operations` / `gold.daily_sales` | COUNT de linhas / `operations` | Daily Sales: COALESCE(`f_daily_sales`, `f_gold_ops`, `f_wallet`); Gestão de Receita: DISTINCTCOUNT(`id_remittance`) sem filtro is_ops_processed na query base |
| Clientes únicos / Customers | `Medidas.Customers` | `gold.fact_operations` | A definir (customer_id) | DISTINCTCOUNT de clientes com operação no período |
| Presignups (sem FxaaS) | `# Medidas.Presignups` | `gold.funnel_event` + `bronze.beecambio_customer` ou `silver.signup` | `id_customer` | Filtro padrão: `event_type = 'PRESIGNUP'` + `event_sequence = 1` + `email NOT LIKE '%fxaas%'`; DISTINCTCOUNT de clientes; **sempre excluir FxaaS em análises de marketing** |
| Presignups (com FxaaS — total bruto) | — | `gold.funnel_event` | `id_customer` | Sem filtro de email; inclui parceiros B2B; usar apenas para análise de volume total ou parceiros |
| Signups | `# Medidas.Signups` | `gold.funnel_event` | `id_customer` | Filtro: `event_type = 'SIGNUP'` |
| Aquisições / Primeira operação | `# Medidas.Aquisições` | `gold.funnel_event` | `id_customer` | Filtro: `event_type = 'ACQUISITION'` |
| Clientes Únicos (operantes) | `# Medidas.Clientes Únicos` | `gold.funnel_event` | `id_customer` | Filtro: `event_type IN ('OPERATION','ACQUISITION')`; mede base ativa |
| Gross Revenue (Safras) | `# Medidas.Gross Revenue` | `gold.funnel_event` | `gross_revenue` | Filtro: `event_type IN ('OPERATION','ACQUISITION')` |
| Conversão Cohortada ACQ/PSU | `# Medidas.Conversão Cohortada (ACQ/PSU)` | `gold.funnel_event` | `id_customer`, `event_type`, `Mês da Aquisição` | DIVIDE de cohortados/presignups |

---

## KPIs — Receita e Margem

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| Receita bruta / Gross Revenue / Receita | `Medidas.Gross Revenue` (Scorecard) / `# Medidas.Receita` (Daily Sales) / `Medidas.Total Gross Revenue` (Gestão de Receita) | `gold.fact_operations` / `gold.daily_sales` | `gross_revenue` | Daily Sales: COALESCE + toggle Intraday; Gestão de Receita: SUM direto, janela 2024-01-01 |
| Receita líquida / Net Revenue | `Medidas.Total Receita Líquida` (Gestão de Receita) | `gold.fact_operations` | `net_revenue` | Já inclui dedução de custos no Databricks; alias `lucro` no modelo |
| Lucro bruto / Gross Profit | `Medidas.Gross Profit` | `gold.fact_operations` | Calculado | `Gross Revenue − Total Cost` |
| Spread ponderado | `Medidas.Spread` (Gestão de Receita) | `gold.fact_operations` | `gross_revenue` / `gmv` | `[Total Gross Revenue] / [Total GMV]` |
| Spread médio por operação | `Medidas.Spread medio` (Gestão de Receita) | `gold.fact_operations` | `spread` | AVERAGE — não ponderado por GMV |
| Custo total / Total Cost | `Medidas.Total Cost` (Scorecard) / `Medidas.Total custo` (Gestão de Receita) | `gold.fact_operations` | Calculado | Scorecard: custo mensagem + bank take + payout; Gestão de Receita: ABS(payout) + ABS(mensageria) + ABS(bank_take) |
| % Custo sobre receita | `Medidas.% Total Cost` (Scorecard) / `Medidas.% custo` (Gestão de Receita) | — | — | `Total Cost / Gross Revenue` |
| % ops negativas | `Medidas.% ops negativas` (Gestão de Receita) | `gold.fact_operations` | `net_revenue`, `Tipo Lucro` (calculada) | `ops com lucro < 0 / total ops` |

---

## KPIs de Marketing — Daily Sales Dashboard

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| Investimento em Marketing | `# Medidas.Investimento` | `bronze.paid_media_investments` | `cost` | ⚠️ BRONZE · Alocação hardcoded: 58,22% PF / 41,78% PJ |
| CPP (Custo por Presignup) | `# Medidas.CPP` | `bronze.paid_media_investments` + `gold.daily_sales_psu` | `cost` / `realizado_psu` | `DIVIDE([Investimento], [Presignups])` |
| CPA (Custo por Aquisição) | `# Medidas.CPA` | `bronze.paid_media_investments` + `gold.fact_operations` | `cost` / COUNT de linhas ACQUISITION | `DIVIDE([Investimento], [Aquisições])` |

---

## KPIs de Tesouraria — Daily Sales Dashboard

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| PNL / Resultado de Tesouraria | `# Medidas.PNL` | `gold.fact_operations` | `gross_revenue_treasury` | Filtros: `is_ops_processed=true`, `is_intercompany=false` |
| Meta de PNL | `# Medidas.Meta de PNL` | `bronze.dcalendar` (calendário) | — | ⚠️ BRONZE + metas hardcoded na query M por BU (2025/2026) |
| Custo de Mensageria | `# Medidas.Custo de Mensageria` | `gold.fact_operations` | `real_message_cost` | — |
| Take do Banco | `# Medidas.Take do Banco` | `gold.fact_operations` | `cost_bank_take` | — |
| Presignups (Daily Sales) | `# Medidas.Presignups` | `gold.daily_sales_psu` + `google_analytics.last_click_sessions` | `realizado_psu` | ⚠️ JOIN com `bronze.beecambio_customer` para dados PSU |

---

## Custos Operacionais

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| Bank Take | Componente de `Total Cost` | `gold.fact_operations` | A definir | Custo do banco parceiro |
| Payout de afiliado | Componente de `Total Cost` | `gold.fact_operations` + `bronze.hubspot_partners` | A definir | ⚠️ JOIN em bronze — validar |
| Custo de mensagem | Componente de `Total Cost` | `gold.fact_operations` | A definir | Custo por mensagem/notificação |

---

## Dimensões

| Termo de negócio | Tabela Power BI | Tabela Databricks | Coluna Databricks | Tipo |
|-----------------|-----------------|-------------------|-------------------|------|
| Unidade de negócio / BU | `d_bu` | `gold.fact_operations` | `bu` | Dimensão |
| Tipo de negócio / Business Type | `d_business_type` | `gold.fact_operations` | `business_type` | Dimensão |
| Tipo de cliente / Customer Type (Scorecard) | `d_customer_type` | `gold.fact_operations` | `customer_type` | Dimensão |
| Tipo de cliente / Customer Type (Safras) | `f_funnel_events` | `gold.funnel_event` | `Customer Type` (PJ/PF) | Dimensão |
| Tipo de evento / Event Type | `d_event_type` | `gold.fact_operations` | `event_type` | Dimensão |
| Tipo de evento funil / Funnel Event Type | `f_funnel_events` | `gold.funnel_event` | `event_type` (PRESIGNUP/SIGNUP/ACQUISITION/OPERATION) | Dimensão |
| Segmento / Segment | `d_segment` | `gold.fact_operations` | `operation_segment` | Dimensão |
| Data de processamento | `d_calendar` | `gold.fact_operations` | `processing_date` | Dimensão temporal |
| Canal de marketing | `d_canal` | Dataflow `e4f720d3` / `gold.funnel_event` | `canal_lc` | Dimensão marketing |
| Fonte de tráfego / Source | `d_source` | Dataflow / `gold.funnel_event` | `source_lc` | Dimensão marketing |
| Meio / Medium | `d_medium` | Dataflow / `gold.funnel_event` | `medium_lc` | Dimensão marketing |
| Campanha / Campaign | `d_mkt_campaign` | Dataflow / `gold.funnel_event` | `mkt_campaign_lc` | Dimensão marketing |
| Grupo de anúncios / Ad Group | `d_adgroup` | Dataflow / `gold.funnel_event` | `ad_group_lc` | Dimensão marketing |
| CNAE (atividade econômica) | `f_funnel_events` | `gold.funnel_event` | `cnae_session/division/group/class/subclass` | Dimensão — segmentação PJ |

---

## Flags de Filtro

| Termo de negócio | Flag Databricks | Valor padrão nos dashboards | Significado |
|-----------------|-----------------|----------------------------|-------------|
| Excluir intercompany | `is_intercompany` | `= false` | Remove transações entre empresas do grupo |
| Apenas operações processadas | `is_ops_processed` | `= true` | Considera apenas operações liquidadas |
| Janela de dados | `processed_date` | `>= '2023-01-01'` | Limite histórico do Scorecard |

---

## Flags e Controles — Daily Sales Dashboard

| Termo de negócio | Mecanismo Power BI | Databricks | Notas |
|-----------------|-------------------|------------|-------|
| Intraday / Modo ao vivo | `Intraday Flag` (DAX DATATABLE) + `SELECTEDVALUE` | — | Toggle TRUE/FALSE; controla se o dia atual é incluído nas medidas |
| Seletor de KPI | `Tabela` (DAX DATATABLE, 8 KPIs) + `SELECTEDVALUE` | — | Medidas `Realizado`, `Meta`, `Projeção`, `% GAP` são dinâmicas |
| Controle de atualização | `# Medidas.Last Update` | `gold.fact_operations.processed_tstamp` | `MAX(processed_tstamp)` com filtros operações processadas |

---

## Custos Operacionais — Gestão de Receita

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| Bank Take (por operação) | `Medidas.Total take` | `gold.fact_operations` | `cost_bank_take` | Custo direto por operação |
| Bank Take (alocado — `customer`) | Calculado no CTE | `finance_cube.kpi_list` (indicador `45KPI`) | `valor` | ⚠️ Schema não-padrão — alocado proporcionalmente pelo GMV mensal |
| Mensageria | `Medidas.Total mensageria` | `gold.fact_operations` | `real_message_cost` | Custo de SWIFT/transferência internacional |
| Payout + Comissão parceiro | `Medidas.Total payout` | `gold.fact_operations` | `payout_affiliate` + `partner_commissioning` | Inclui afiliados e parceiros Maxima |
| Comissão afiliados (histórico) | CTE `comissao_afiliados` | `automations.integrations_hasoffer_conversion` | `payout` | ⚠️ Schema não-padrão |

## Dimensões — Gestão de Receita

| Termo de negócio | Tabela Power BI | Tabela Databricks | Coluna Databricks | Tipo |
|-----------------|-----------------|-------------------|-------------------|------|
| Natureza da operação | `processed_operations[natureza]` | `gold.fact_operations` | `nature_operation_name` | Dimensão regulatória |
| Política de Preço | `processed_operations[policy_label]` | `beecambio.beecambio_tbl_remittance_operation` | `policy_label` | ⚠️ Schema não-padrão |
| Parceiro Maxima | `Parceiros[partner_name]` | `beecambio.beecambio_maxima_partners` | `name` | ⚠️ Schema não-padrão |
| Escritórios (classificação) | `Parceiros[Escritórios]` | — | Lista hardcoded DAX | "Sim"/"Não" — 8 parceiros hardcoded |
| Subsegmento PF | `Subsegmento PF[subsegment]` | `stage.dim_last_subsegments` | `subsegment` | ⚠️ Schema stage — verificar estabilidade |
| Tipo de Lucro | `processed_operations[Tipo Lucro]` | — | `net_revenue < 0` (DAX) | Positivo / Negativo |
| Ticket Range | `processed_operations[Ticket Range]` | — | `gmv` (DAX — 8 faixas) | Faixa de GMV por operação |
| Faixa Spread | `processed_operations[Faixa Spread]` | — | `spread` (DAX — 9 faixas) | Faixas de margem |

---

## A definir (identificados mas sem mapeamento completo)

| Termo de negócio | Status | Ação necessária |
|-----------------|--------|-----------------|
| Colunas específicas de GMV, Gross Revenue | A definir | Confirmar com time de dados quais colunas compõem cada métrica em `gold.fact_operations` |
| Colunas de Customers (customer_id) | A definir | Identificar campo de ID único de cliente |
| Dataflow IDs das dimensões | A definir | Executar `/pbi-fluxo-de-dados Scorecard` |
| `finance_cube.kpi_list` indicador `45KPI` | A definir | Confirmar com time Financeiro a definição e metodologia de alocação do bank take |
| `stage.dim_last_subsegments` | A definir | Confirmar com time de dados estabilidade e plano de migração |

---

## KPIs — Dashboard - Recebimento

| Termo de negócio | Medida DAX | Tabela Databricks | Coluna Databricks | Notas |
|-----------------|------------|-------------------|-------------------|-------|
| Ordens de pagamento | `# Medidas.Ordens` | `silver.orders` | COUNT `id` | Todas as ordens criadas — sem filtro de status |
| Ordens resgatadas | `# Medidas.Resgatadas` | `silver.orders` | `status_ordem_resumo = 'Resgatado'` | Ordens liquidadas |
| GMV (Resgatado) | `# Medidas.GMV (Resgatado)` | `silver.orders` | `gmv`, filtro status Resgatado | Valor real liquidado |
| GMV Pendente (Forecast) | `# Medidas.GMV Pendente (Forecast)` | `silver.orders` + `silver.trading_quotations` | `quantity × trading_quotation` | Estimativa — cotação varia até o resgate |
| Receita (Resgatado) | `# Medidas.Receita (Resgatado)` | `silver.orders` | `gross_revenue`, filtro status Resgatado | Receita real |
| Receita Pendente (Forecast) | `# Medidas.Receita Pendente (Forecast)` | — | `GMV Pendente × spread (What if?)` | ⚠️ spread base 0,83% hardcoded |
| % Resgate | `# Medidas.% Resgate` | `silver.orders` | `status_ordem_resumo` | Resgatadas / Total |
| Clientes únicos (Recebimento) | `# Medidas.Clientes únicos` | `silver.orders` | `id_customer` | DISTINCTCOUNT |
| Total Users (Drop-off) | `# Medidas.Total Users` | `gold.funnel_event` | `id_customer` | Anti-join com silver.orders — clientes sem ordem |

---

## Datas e Chave Temporal — gold.fact_operations / gold.fact_customers

| Termo de negócio | Coluna Databricks | Tabela | Notas |
|-----------------|-------------------|--------|-------|
| Data da operação | `processed_date` | `gold.fact_operations` | Chave temporal — usada para join com `d_calendar` |
| Data de aquisição | `first_processed_operation` | `gold.fact_customers` | Data da 1ª operação processada do cliente |
| Direção Inbound | `in_or_out = 'Receiving'` | `gold.fact_operations` | Recebimento — cliente recebe do exterior |
| Direção Outbound | `in_or_out = 'Sending'` | `gold.fact_operations` | Envio — cliente envia para o exterior |
| Dias Úteis | `workday` | `d_calendar` (Dataflow) | Boolean — identifica dias úteis no calendário |
| Month to Date (MTD) | `mtd` | `d_calendar` (Dataflow) | Boolean — identifica dias do MTD corrente |

---

## Segmentação de Clientes — gold.fact_customers

| Conceito | Coluna / Regra | Notas |
|----------|---------------|-------|
| Novos | `acquisition = true` | Clientes na 1ª operação |
| Recorrentes | 2+ operações processadas | Sem flag direta — calculado |
| Ativos | `data_última_operação >= today - 120 dias` | Janela de 120 dias |
| Churn | `data_última_operação < today - 120 dias` | Janela de 120 dias |
| 1ª Data de Churn | `first_date_churn_lifetime` | Data em que o cliente entrou em churn pela 1ª vez |
| Sequência do funil | `sequence` | Ordena eventos em `gold.funnel_event` / `gold.fact_customers` |

**Ordem dos eventos de funil (coluna `sequence`):**
`PRESIGNUP (PSU)` → `SIGNUP (SU)` → `CREATED STORY` → `APPROVED STORY` → `ACQUISITION (ACQ)` → `OPERATION (REC)`

---

## Regras Premium — gold.fact_operations / gold.fact_customers

| Conceito | Filtro | Tabela | ⚠️ Atenção |
|----------|--------|--------|-----------|
| Operação Premium | `business_type IN ('Premium PF', 'Pjtão')` | `gold.fact_operations` | NUNCA usar `is_premium` — campo legado |
| Operação Potencial Premium | `is_potencial_premium = TRUE` | `gold.fact_operations` | — |
| Cliente Premium (status atual) | `premium_status = 'Premium'` | `gold.fact_customers` | — |
| Cliente Potencial Premium (status atual) | `premium_status = 'Potencial Premium'` | `gold.fact_customers` | — |

---

*Gerenciado via `/pbi-ontologia` · Remessa Online · Mai 2026 — inclui Scorecard, Safras, Daily Sales, Gestão de Receita, Dashboard - Recebimento, Mkt Performance*
