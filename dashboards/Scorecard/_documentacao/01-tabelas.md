# Scorecard - Business Performance — Tabelas

Catálogo de tabelas do modelo. Cada uma com descrição, granularidade, colunas tipadas e source M resumido.

> **Voltar pra:** [00 · Overview](00-overview.md) · **Próxima:** [02 · Medidas](02-medidas.md)

---

## f_operations

> Fato principal do modelo — 1 linha = 1 operação de câmbio processada. Coração do Scorecard.
> **Tipo:** Fato · **Origem:** Databricks `gold.fact_operations` via SQL nativo (beetech-prod-analytics)

### Descrição

A `f_operations` é a tabela mais rica e pesada do modelo. Traz cada operação de câmbio da Remessa Online com todos os seus atributos: dados de cliente, produto, canal de aquisição, segmento, métricas financeiras (GMV, Gross Revenue, Gross Profit, Spread, Tariff, Costs) e flags operacionais. O SELECT fonte tem mais de 200 linhas e faz join em ~10 tabelas do data lake (fact_customers, first_click_sessions, hubspot_partners, etc.), produzindo um dendrogram de atributos que permite fatiamento por praticamente qualquer dimensão de negócio.

Além das colunas de fonte, a tabela tem colunas calculadas em DAX: `Swift` (classifica distribuidores), `Event type` (Acquisition/Reactivation/Repurchase), `Dimension Total` (literal "Total"), `Ticket Range` (faixas de ticket por tipo de cliente), e o agrupamento horário `processing_hour_minute (compartimentos)`.

### Granularidade

1 linha = 1 operação de câmbio individual (`id_remittance`), processada a partir de 2023-01-01.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `id_remittance` | string | Chave primária | Identificador único da operação |
| `id_customer` | string | Chave estrangeira | ID do cliente — base para DISTINCTCOUNT |
| `bu` | string | Chave estrangeira → d_bu | Oculta |
| `business_type` | string | Chave estrangeira → d_business_type | Oculta |
| `customer_type` | string | Chave estrangeira → d_customer_type | Oculta |
| `processing_date` | dateTime | Chave estrangeira → d_calendar | Data de processamento. Oculta |
| `event_type` | string | Chave estrangeira → d_event_type | ACQUISITION / REPURCHASE. Oculta |
| `operation_segment` | string | Chave estrangeira → d_segment | Oculta |
| `gmv` | decimal | Métrica | GMV em R$. Oculta |
| `gross_revenue` | decimal | Métrica | Receita bruta em R$. Oculta |
| `gross_profit` | decimal | Métrica | Lucro bruto em R$. Oculta |
| `quantity` | decimal | Métrica | Quantidade em moeda estrangeira (ME). Oculta |
| `spread` | double | Métrica | Spread aplicado (%). Oculta |
| `spread_original` | double | Métrica | Spread de tabela sem desconto (%). Oculta |
| `spread_dif` | double | Métrica | Diferença de spread (pp). Oculta |
| `tariff` | decimal | Métrica | Tarifa em R$. Oculta |
| `cost_mensage` | decimal | Métrica | Custo de mensagem em R$. Oculta |
| `cost_bank_take` | decimal | Métrica | Custo bank take em R$. Oculta |
| `cost_payout_affiliate` | decimal | Métrica | Custo payout de afiliado em R$. Oculta |
| `gross_revenue_original` | decimal | Métrica | Gross Revenue antes do desconto. Oculta |
| `diff_gross_revenue` | decimal | Métrica | Diferença entre GR original e atual. Oculta |
| `gmv_usd` | double | Métrica | GMV em USD. Oculta |
| `workday_processado` | int64 | Atributo | Dia útil do processamento |
| `mtd` | boolean | Atributo | Flag MTD (Month to Date). Oculta |
| `mtd_calendar_days` | boolean | Atributo | Flag MTD por dias corridos. Oculta |
| `last_update` | dateTime | Atributo | Timestamp da última atualização |
| `processing_hour` | int64 | Atributo | Hora do processamento |
| `processing_minute` | int64 | Atributo | Minuto do processamento |
| `processing_hour_minute` | dateTime | Atributo | Hora:minuto do processamento |
| `acquisition` | boolean | Atributo | Flag de aquisição. Oculta |
| `reactivation` | boolean | Atributo | Flag de reativação. Oculta |
| `in_or_out` | string | Atributo | Sending / Receiving. Oculta |
| `natureza` | string | Atributo | Natureza da operação (Serviços, Mercadorias, etc.). Oculta |
| `currency` | string | Atributo | Moeda estrangeira. Oculta |
| `country` | string | Atributo | País de destino. Oculta |
| `product` | string | Atributo | Produto (REMESSA ONLINE, etc.). Oculta |
| `canal` | string | Atributo | Canal de marketing (last click). Oculta |
| `medium` | string | Atributo | Medium de marketing (last click). Oculta |
| `source` | string | Atributo | Source de marketing (last click). Oculta |
| `mkt_campaign` | string | Atributo | Campanha de marketing (last click). Oculta |
| `canal_fc` | string | Atributo | Canal (first click). Oculta |
| `medium_fc` | string | Atributo | Medium (first click). Oculta |
| `source_fc` | string | Atributo | Source (first click). Oculta |
| `mkt_campaign_fc` | string | Atributo | Campanha (first click). Oculta |
| `office` | string | Atributo | Afiliado. Oculta |
| `is_affiliate` | string | Atributo | Yes/No. Oculta |
| `flag_affiliate` | string | Atributo | Descrição do tipo de afiliado na operação. Oculta |
| `affiliate_source` | string | Atributo | Origem do afiliado (Hasoffers, Beecambio, etc.). Oculta |
| `is_efx` | boolean | Atributo | Flag EFX. Oculta |
| `is_fxaas` | boolean | Atributo | Flag FXaaS. Oculta |
| `is_corporate_api` | boolean | Atributo | Flag Corporate API. Oculta |
| `is_partner` | boolean | Atributo | Flag parceiro. Oculta |
| `is_mid` | string | Atributo | Mid/Not Mid. Oculta |
| `high_mid_low` | string | Atributo | Subsegmento high/mid/low. Oculta |
| `segment` | string | Atributo | Segmento novo. Oculta |
| `high_pj` | boolean | Atributo | Flag High PJ |
| `is_premium_user` | string | Atributo | Status premium. Oculta |
| `is_comex` | boolean | Atributo | Flag operação Comex |
| `is_instant` | boolean | Atributo | Flag operação instantânea |
| `is_cnr` | boolean | Atributo | Flag CNR |
| `coleta_local` | boolean | Atributo | Flag coleta local. Oculta |
| `onboarding_type` | string | Atributo | Tipo de onboarding. Oculta |
| `contraparte` | string | Atributo | Contraparte da operação. Oculta |
| `nubank` | string | Atributo | Pré/Pós-tombamento Nubank. Oculta |
| `recorrente_nubank` | string | Atributo | Flag recorrência Nubank. Oculta |
| `recorrente_afiliado` | string | Atributo | Flag recorrência afiliado. Oculta |
| `acq_office` | string | Atributo | Afiliado da aquisição. Oculta |
| `partner_name` | string | Atributo | Nome do parceiro. Oculta |
| `partner_name_from_fxaas` | string | Atributo | Parceiro via FXaaS. Oculta |
| `genre` | string | Atributo | Gênero do cliente |
| `age` | string | Atributo | Faixa etária |
| `geo_city` | string | Atributo | Cidade (dataCategory: City) |
| `geo_state` | string | Atributo | Estado (dataCategory: StateOrProvince) |
| `geo_timezone` | string | Atributo | Fuso horário |
| `is_international` | string | Atributo | Flag internacional |
| `acq_rec` | string | Atributo | Aquisição / Recorrência. Oculta |
| `cnae_session` | string | Atributo | Seção CNAE. Oculta |
| `cnae_division` | string | Atributo | Divisão CNAE. Oculta |
| `cnae_group` | string | Atributo | Grupo CNAE. Oculta |
| `cnae_class` | string | Atributo | Classe CNAE. Oculta |
| `cnae_subclass` | string | Atributo | Subclasse CNAE. Oculta |
| `Swift` | Calculada | Atributo | SWITCH: "Distributor"/"Swift". Oculta |
| `Event type` | Calculada | Atributo | Acquisition/Reactivation/Repurchase. Oculta |
| `Dimension Total` | Calculada | Atributo | Sempre "Total". Oculta |
| `Ticket Range` | Calculada | Atributo | Faixas de ticket por PF/PJ. Oculta |
| `processing_hour_minute (compartimentos)` | Calculada | Atributo | Agrupamento por 30min |
| `ticket_range_v2` | string | Atributo | Faixas de ticket versão 2. Oculta |
| `ticket_range_v3` | string | Atributo | Faixas de ticket versão 3. Oculta |
| `link_backoffice` | string | Atributo | URL backoffice (dataCategory: WebUrl) |
| `acquisition_month` | dateTime | Atributo | Mês da aquisição |
| `presignup_month` | dateTime | Atributo | Mês do presignup |
| `fl_voucher` | boolean | Atributo | Flag voucher. Oculta |
| `voucher_code` | string | Atributo | Código do voucher. Oculta |
| `voucher_type` | string | Atributo | Tipo do voucher. Oculta |
| `stock_option` | boolean | Atributo | Flag stock option |
| `applied_discount` | string | Atributo | Desconto aplicado |
| `desconto` | string | Atributo | Faixa de desconto concedido. Oculta |
| `discount_category` | string | Atributo | Categoria do desconto |
| `corretora` | string | Atributo | Corretora (recipient_name) |
| `bank_name` | string | Atributo | Nome do banco |
| `customer_segment` | string | Atributo | Profissional / Empreendedor/PME |
| `is_parceiros_referral` | boolean | Atributo | Flag parceiros referral. Oculta |
| `parceiros_referral` | string | Atributo | Nome do parceiro referral. Oculta |
| `rmi` | string | Atributo | Status RMI |
| `melhor_cambio` | boolean | Atributo | Flag Melhor Câmbio. Oculta |
| `google` | boolean | Atributo | Flag contraparte Google |
| `payment_method` | string | Atributo | Método de pagamento |
| `is_automatic_operation` | string | Atributo | Flag resgate automático |
| `customer_category` | string | Atributo | Categoria do cliente. Oculta |
| `mgm_code` | string | Atributo | Código MGM |
| `mgm_operation_type` | string | Atributo | Tipo de operação MGM |
| `company_type` | string | Atributo | Tipo de empresa. Oculta |
| `company_onboarding_flow` | string | Atributo | Flow de onboarding empresa |
| `company_member_association_type` | string | Atributo | Tipo de associação de sócio |
| `company_shareholders_count` | int64 | Atributo | Número de sócios |
| `account_manager` | string | Atributo | Account Manager |
| `onb_ops_type` | string | Atributo | Tipo de operação no onboarding |
| `onb_reason` | string | Atributo | Motivo de qualificação |
| `is_potencial_premium` | boolean | Atributo | Flag potencial premium |
| `purpose_of_remittance` | string | Atributo | ID/código da finalidade da remessa. Oculta |
| `purpose_of_remittance_operation` | string | Atributo | Finalidade (novo marco) |
| `description_purpose_classification` | string | Atributo | Classificação da finalidade. Oculta |
| `indece_valor_usd` | int64 | Atributo | Índice de faixa USD. Oculta |
| `remittance_limit_approved` | double | Atributo | Limite aprovado de remessa |
| `service_description` | string | Atributo | Descrição do serviço |
| `page_url` | string | Atributo | URL da página (last click). Oculta |
| `operation_platform_beecambio` | string | Atributo | Plataforma de operação Beecambio |
| `origin_platform_psu` | string | Atributo | Plataforma de presignup. Oculta |
| `provider` | string | Atributo | Provider PSU |
| `bu_old` | string | Atributo | BU anterior |
| `business_type_old` | string | Atributo | Business Type anterior |
| `fixed_spread` | double | Atributo | Spread fixado |
| `has_fixed_spread` | boolean | Atributo | Flag spread fixado |
| `fixed_spread_equal_spread` | boolean | Atributo | Flag spread fixado = spread |
| `high_pj` | boolean | Atributo | Flag High PJ |
| `is_cnr` | boolean | Atributo | Flag CNR |
| `travel_agency_affiliate` | boolean | Atributo | Flag afiliado agência de viagem |
| `gross_profit_flag` | string | Atributo | Com/Sem Prejuízo. Oculta |
| `distributor_name_og` | string | Atributo | Nome do distribuidor original. Oculta |
| `-` | Calculada | Atributo | BLANK() — coluna vazia auxiliar. Oculta |

### Source M (resumo)

```m
let
    Origem = Value.NativeQuery(
        Databricks.Catalogs("beetech-prod-analytics.cloud.databricks.com", ...){[Name="prod"]}[Data],
        "-- SQL completo em _documentacao/07-queries-sql.md
         SELECT ... FROM gold.fact_operations as op
         LEFT JOIN gold.fact_customers, google_analytics.first_click_sessions,
                   bronze.hubspot_partners (⚠️), bronze.dcalendar (⚠️),
                   bronze.beecambio_qualification (⚠️), beecambio.*, silver.customers,
                   gold.funnel_event, gold.fast_instant_analysis, ...
         WHERE op.is_intercompany = false
           AND op.is_ops_processed = true
           AND op.processed_date >= '2023-01-01'
           AND op.processed_date < current_date
         GROUP BY ALL",
        null, [EnableFolding=true]
    ),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem, {...})
in
    #"Tipo Alterado"
```
*Query nativa de ~400 linhas SQL com 6 CTEs. Filtros base: não-intercompany, processado, a partir de 2023. SQL completo: [07-queries-sql.md](07-queries-sql.md).*

---

## d_calendar

> Dimensão de tempo — 1 linha = 1 dia do calendário, com flags de MTD, dias úteis, feriados e colunas calculadas de semana.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow 3cbe0c71)

### Descrição

Dimensão de tempo enriquecida. Além das colunas básicas de data, traz um conjunto completo de flags usados para filtrar o período correto nas medidas: `mtd` (Month to Date), `m0` e `m1` (meses atual e anterior), `Filter Today`, `last_day`, `is_ytd`, além de contadores de dias úteis (`workday`, `workdays_month`, `workdays_quarter`, `workday_processado`). Tem também uma medida hospedada (`Last Working Day`) e colunas calculadas em DAX (`Qua` para início de quarter, `weekFriday` para agrupar por semana com âncora na sexta).

### Granularidade

1 linha = 1 dia do calendário, filtrado para `year >= 2022`.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `Date Key` | dateTime | Chave primária | Chave de relacionamento com f_operations. Oculta |
| `date_month` | dateTime | Atributo | Mês/Ano (formato mmm/yyyy). Oculta |
| `month_year` | string | Atributo | Mês/Ano textual, sortByColumn: date_month. Oculta |
| `Current Month` | string | Atributo | Mês atual formatado, sortByColumn: date_month. Oculta |
| `month` | string | Atributo | Nome do mês |
| `month_number` | int64 | Atributo | Número do mês |
| `month_days` | int64 | Atributo | Total de dias no mês |
| `total_month_days` | int64 | Atributo | Dias totais do mês |
| `day` | string | Atributo | Dia |
| `year` | int64 | Atributo | Ano. Oculta |
| `Quarter` | string | Atributo | Quarter. Oculta |
| `week` | dateTime | Atributo | Semana (âncora segunda). Oculta |
| `Fim do Mês` | dateTime | Atributo | Último dia do mês |
| `m0` | boolean | Atributo | Flag mês atual. Oculta |
| `m1` | boolean | Atributo | Flag mês anterior. Oculta |
| `mtd` | boolean | Atributo | Flag MTD. Oculta |
| `mtd_calendar_days` | boolean | Atributo | Flag MTD por dias corridos. Oculta |
| `month_to_date` | boolean | Atributo | Flag MTD alternativo |
| `Filter Today` | boolean | Atributo | Flag para o dia atual. Oculta |
| `last_day` | boolean | Atributo | Flag último dia do mês |
| `is_ytd` | boolean | Atributo | Flag Year to Date |
| `d0` | boolean | Atributo | Flag dia atual |
| `special_condition` | boolean | Atributo | Condição especial |
| `is_holiday` | boolean | Atributo | Flag feriado |
| `dayofweek` | int64 | Atributo | Dia da semana (1=Dom) |
| `day_of_yesterday` | int64 | Atributo | Dia de ontem |
| `is_current_date` | boolean | Atributo | Flag data atual |
| `Google Day` | boolean | Atributo | Flag dia Google |
| `workday` | int64 | Atributo | Dia útil do mês |
| `workdays_month` | int64 | Atributo | Total dias úteis no mês |
| `workdays_quarter` | int64 | Atributo | Total dias úteis no quarter |
| `last_workday` | int64 | Atributo | Último dia útil |
| `workday_processado` | int64 | Atributo | Dia útil do processamento |
| `last_update_calendar` | dateTime | Atributo | Timestamp de atualização |
| `label` | double | Atributo | Label numérica auxiliar |
| `label_with_all_days_month` | double | Atributo | Label com total de dias |
| `Qua` | Calculada | Atributo | Início do quarter via `STARTOFQUARTER`. Oculta |
| `weekFriday` | Calculada | Atributo | Semana com âncora na sexta-feira (DAX) |

### Medidas hospedadas

- `Last Working Day` — `MAX(d_calendar[workday_processado])`. Oculta.

### Source M (resumo)

```m
let
    Fonte = PowerPlatform.Dataflows(null),
    -- navega até dataflow 3cbe0c71 no workspace 5381...
    dcalendar_ = ...{[entity="dcalendar",version=""]}[Data],
    #"Fim do Mês Inserido" = Table.AddColumn(dcalendar_, "Fim do Mês", each Date.EndOfMonth([Date Key])),
    #"Coluna Condicional Adicionada" = Table.AddColumn(..., "last_day", each [Date Key] = [Fim do Mês]),
    #"Linhas Filtradas" = Table.SelectRows(..., each [year] >= 2022)
in
    #"Linhas Filtradas"
```

---

## d_bu

> Dimensão de BU (Business Unit) — 1 linha = 1 unidade de negócio, excluindo "Presignups".
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow d3c2d827)

### Descrição

Tabela dimensional simples com a lista de Business Units da empresa. Carregada via Dataflow com filtro exclusivo de "Presignups". Tem apenas 1 coluna visível (`BU`).

### Granularidade

1 linha = 1 Business Unit.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `BU` | string | Chave primária | Valor da BU. Oculta |

### Source M (resumo)

```m
let
    -- dataflow d3c2d827, entity "bu"
    #"Linhas Filtradas" = Table.SelectRows(bu_, each ([BU] <> "Presignups"))
in
    #"Linhas Filtradas"
```

---

## d_business_type

> Dimensão de tipo de negócio — 1 linha = 1 Business Type com ordem de exibição.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow a58daa91)

### Descrição

Dimensão que classifica o tipo de negócio (PF, PJ, tipos de produto, etc.). A coluna `index` é usada para ordenação da coluna `Business Type` no relatório.

### Granularidade

1 linha = 1 Business Type.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `index` | int64 | Atributo | Ordem de exibição. Oculta |
| `Business Type` | string | Chave primária | sortByColumn: index. Oculta |

### Source M (resumo)

```m
let
    -- dataflow a58daa91, entity "business_type"
    #"Colunas Removidas" = Table.RemoveColumns(business_type_, {"bu"})
in
    #"Colunas Removidas"
```

---

## d_customer_type

> Dimensão de tipo de cliente — PF / PJ.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow ee7b4dce)

### Descrição

Dimensão simples com os tipos de cliente. Provavelmente 2 linhas: PF (pessoa física) e PJ (pessoa jurídica).

### Granularidade

1 linha = 1 tipo de cliente.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `Customer Type` | string | Chave primária | PF ou PJ. Oculta |

---

## d_event_type

> Dimensão de tipo de evento — ACQUISITION / REPURCHASE.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow 32502a54)

### Descrição

Dimensão de eventos de operação. Filtrada para apenas dois valores: ACQUISITION e REPURCHASE. A coluna `Evento` traz o label em português.

### Granularidade

1 linha = 1 tipo de evento.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `event_type` | string | Chave primária | ACQUISITION / REPURCHASE. Oculta |
| `Evento` | string | Atributo | Label PT. Oculta |

### Source M (resumo)

```m
#"Linhas Filtradas" = Table.SelectRows(event_type_, each ([event_type] = "ACQUISITION" or [event_type] = "REPURCHASE"))
```

---

## d_segment

> Dimensão de segmento de operação — 1 linha = 1 segmento.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow 61b71bc0)

### Descrição

Dimensão simples com os segmentos de operação (ex: Serviços, Mercadorias, Capital, etc.).

### Granularidade

1 linha = 1 segmento de operação.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `operation_segment` | string | Chave primária | Segmento. Oculta |

---

## d_faq

> Dimensão auxiliar de FAQ — tabela de definições e explicações dos KPIs do Scorecard.
> **Tipo:** Dimensão · **Origem:** Power Platform Dataflows (workspace 5381..., dataflow 42e64d90, entity "Results")

### Descrição

Tabela de FAQ com a definição de cada KPI exibido no Scorecard. Tem KPI, Explicação, Conta (como calcular) e Tipo. Útil para tooltips ou seções de ajuda no relatório.

### Granularidade

1 linha = 1 KPI/definição documentada.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `KPI` | string | Chave primária | Nome do KPI |
| `Explicação` | string | Atributo | Descrição do KPI |
| `Conta` | string | Atributo | Fórmula/como calcular |
| `Tipo` | string | Atributo | Tipo do KPI |

---

## Medidas

> Tabela de medidas principal — hospeda ~85 medidas DAX do modelo.
> **Tipo:** Tabela de medidas · **Origem:** Tabela estática (literal `"Medidas"`)

### Descrição

Tabela-repositório de todas as medidas do Scorecard. Tem apenas 1 coluna visível (`Medidas`, texto, oculta) que serve de âncora. Todas as medidas estão organizadas em displayFolders sob `Realizado\` (GMV, Gross, Spread, Operations, Customers, TKM, Cost, Tariff) e `Aux`.

### Medidas hospedadas

Ver [02 · Medidas](02-medidas.md) para o catálogo completo. Grupos:
- **Realizado\GMV** — GMV, GMV Anterior, GMV Growth, GMV USD, GMV Growth Format %
- **Realizado\Gross** — Gross Revenue, Gross Revenue Anterior, Gross Revenue Growth, Gross Profit, Gross Profit Anterior, Gross Profit Growth, ARPU, Gross Revenue Original, Diff Gross Revenue e variantes
- **Realizado\Spread** — Spread, Spread AVGX, Spread Original (AVGX), Spread Dif, Spread Anterior, Spread Growth, Spread Growth Format %
- **Realizado\Operations** — Operations, Operations Anterior, Operations Growth, Operations by Customer e variantes
- **Realizado\Customers** — Customers, Customers Anterior, Customers Growth e variantes
- **Realizado\TKM** — AVG Ticket GMV, AVG Ticket Gross Revenue, Ticket Médio (Gross Profit) e variantes
- **Realizado\Cost** — Total Cost, % Total Cost, Total Cost Anterior, Total Cost Growth e variantes
- **Realizado\Tariff** — Tariff, Tariff AVGX
- **Aux** — medidas de título, MTD, Last Working Day, Refresh, etc.

---

## Month over month

> Tabela de Calculation Group — aplica lógica de período anterior e crescimento em qualquer medida selecionada.
> **Tipo:** Tabela de medidas · **Origem:** Tabela calculada (calculationGroup)

### Descrição

Essa é a tabela de Calculation Group do modelo. Ela tem os calculation items que modificam o contexto de filtro de qualquer medida: `Realizado` (valor atual), `Período Anterior` (DATEADD -1 período), `Growth #` (diferença absoluta), `Growth %` (crescimento relativo). O período (dia/mês/ano/quarter) é controlado pelo parâmetro `p_timeframe`. Também hospeda as medidas de `Color - {KPI}` que ativam formatação condicional quando o item "Growth" está selecionado.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `Coluna do grupo de cálculo` | string | Atributo | Nome do calculation item. sortByColumn: Ordinal |
| `Ordinal` | int64 | Atributo | Ordem dos calculation items |

### Calculation Items

| Item | Lógica |
|---|---|
| `Realizado` | `SELECTEDMEASURE()` — valor atual sem modificação |
| `Período Anterior` | `CALCULATE(SELECTEDMEASURE(), DATEADD(..., -1, {DAY\|MONTH\|YEAR\|QUARTER}))` |
| `Growth #` | `current_value - previous_value` |
| `Growth %` | `DIVIDE(current - previous, previous, BLANK())` |
| `Conditional - Gross Revenue` | Filtra para Growth # apenas |

---

## p_timeframe

> Parameter table de granularidade temporal — controla se o Scorecard mostra por dia, mês, semana, quarter ou ano.
> **Tipo:** Auxiliar · **Origem:** Tabela calculada (parameter table)

### Descrição

Slicer dinâmico de período. O usuário seleciona um valor (Hora, Dia, Semana, Mês, Quarter, Ano) e as medidas reagem via `SELECTEDVALUE(p_timeframe[SelectedValue])`. A coluna calculada `SelectedValue` retorna a forma formatada ("por Dia", "por Mês", etc.) usada nos títulos dinâmicos.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `Timeframe` | string | Atributo | Label do período (Hora, Dia, ...) |
| `Timeframe Campos` | string | Atributo | NAMEOF da coluna correspondente |
| `Timeframe Pedido` | int64 | Atributo | Ordem de exibição |
| `SelectedValue` | Calculada | Atributo | "por Dia", "por Mês", etc. |

---

## p_dimension

> Parameter table de dimensão principal — controla o eixo de quebra do Scorecard (simples, ~19 opções).
> **Tipo:** Auxiliar · **Origem:** Tabela calculada (parameter table)

### Descrição

Slicer de dimensão para o visual principal. Tem ~19 opções de dimensão (Event type, BU, Customer Type, Business Type, Genre, etc.). Versão reduzida do p_dimension_01.

---

## p_dimension_01 / p_dimension_02 / p_dimension_03 / p_dimension_04

> Parameter tables de dimensão completa — controlam os 4 eixos de quebra do visual de detalhamento (~100 opções cada).
> **Tipo:** Auxiliar · **Origem:** Tabelas calculadas (parameter tables)

### Descrição

As quatro tabelas de dimensão expandida têm exatamente as mesmas ~100 opções (são espelhos umas das outras), permitindo 4 eixos independentes de análise. Cobrem virtualmente toda a `f_operations`: atributos de afiliado, BU, Business Type, CNAE, customer, desconto, geo, marketing (first/last click), segmento, spread, ticket range, voucher, etc.

---

## p_choose_metric

> Parameter table de seleção de métrica — controla qual KPI é exibido no visual dinâmico (20 opções).
> **Tipo:** Auxiliar · **Origem:** Tabela calculada (parameter table)

### Descrição

Slicer de métrica. O usuário escolhe o KPI que quer analisar: GMV, Gross Revenue, Gross Profit, Spread, Operations, Customers, AVG Ticket, etc. 20 opções mapeadas via `NAMEOF()` para as medidas da tabela `Medidas`.

---

## t_tabela

> Tabela auxiliar de KPIs — lista de 6 KPIs com ID, nome e formato para geração de tabela scorecard.
> **Tipo:** Auxiliar · **Origem:** DATATABLE calculada

### Descrição

Tabela estática com 6 KPIs (GMV, Receita, Operações, Spread, Ticket Médio, DAUs) e seus formatos de número. Usada provavelmente em algum visual de tabela dinâmica no relatório.

### Colunas

| Coluna | Tipo | Papel | Notas |
|---|---|---|---|
| `Id` | int64 | Chave primária | Ordem dos KPIs |
| `KPI` | string | Atributo | Nome do KPI |
| `Format` | string | Atributo | String de formato |

---

*XPERIUN · `/pbi-doc`*
