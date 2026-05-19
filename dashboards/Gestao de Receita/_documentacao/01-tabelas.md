# Gestão de Receita — Inventário de Tabelas

## Resumo

| Categoria | Quantidade |
|-----------|-----------|
| Tabelas fato (Databricks) | 4 (`processed_operations`, `customer`, `Parceiros`, `Subsegmento PF`) |
| Tabelas dimensão (Dataflow) | 1 (`dcalendar`) |
| Tabelas calculadas / seletores (DAX) | 9 |
| Tabelas de parâmetro (cenários) | 2 |
| Tabelas de medidas | 2 |
| **Total** | **18** |

---

## Tabelas Fato / Dados

### processed_operations

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato principal (operações individuais) |
| **Camada** | 🟢 gold + ⚠️ beecambio (JOIN) |
| **Fonte** | `gold.fact_operations` + `beecambio.beecambio_tbl_remittance_operation` |
| **Granularidade** | Uma linha por operação de câmbio processada |
| **Janela** | `date_trunc('month', processed_date) >= '2024-01-01'` e `<= date_trunc('month', current_date)` |
| **Filtro** | Sem filtro de `is_intercompany` ou `is_ops_processed` na query (filtros aplicados por página via `is_ops_processed = true`) |

> ⚠️ **JOIN BEECAMBIO:** A query faz `LEFT JOIN beecambio.beecambio_tbl_remittance_operation` para obter `policy_label`. O schema `beecambio` não pertence à hierarquia padrão — dados podem divergir de gold.

**Colunas da fonte (gold.fact_operations):**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_remittance` | Integer | ID único da operação |
| `id_customer` | String | ID do cliente |
| `in_or_out` | String | Direção da remessa (entrada/saída) |
| `gmv` | Double | Volume bruto da operação |
| `gross_revenue` | Double | Receita bruta capturada |
| `spread` | Double | Spread percentual da operação |
| `spread_original` | Double | Spread original antes de ajustes |
| `spread_revenue` | Double | Receita de spread |
| `net_revenue` | Double | Receita líquida (lucro) após todos os custos |
| `processed_date` | Date | Data de processamento |
| `customer_type` | String | PF ou PJ |
| `business_type` | String | Tipo de negócio |
| `bu` | String | Unidade de negócio |
| `acquisition` | Boolean | TRUE se for primeira operação do cliente |
| `is_affiliate` | Boolean | TRUE se veio por afiliado |
| `is_intercompany` | Boolean | TRUE se for transação intragrupo |
| `is_ops_processed` | Boolean | TRUE se operação foi liquidada |
| `is_efx` | Boolean | Flag EFX |
| `is_partner` | Boolean | Flag parceiro |
| `is_corporate_api` | Boolean | Flag Corporate API |
| `is_fxaas` | Boolean | Flag FXaaS |
| `MID` | Boolean | Flag MID |
| `country` | String | País de destino |
| `currency_name` | String | Nome da moeda (ex: Dólar Americano) |
| `currency_abbreviation` | String | Código ISO (ex: USD) |
| `applied_discount` | String | Desconto aplicado |
| `voucher_code` | String | Código do voucher (se aplicável) |
| `tariff` | Double | Tarifa cobrada |
| `taxes` | Double | Impostos |
| `real_message_cost` | Double | Custo de mensageria |
| `cost_bank_take` | Double | Custo cobrado pelo banco (bank take) |
| `payout_affiliate` | Double | Payout a afiliados |
| `partner_commissioning` | Double | Comissão de parceiro |
| `cost_bacen` | Double | Custo BACEN |
| `cost_funding` | Double | Custo de funding |
| `swift_or_distributor` | String | Via Swift ou Remessadora |
| `distributor_name` | String | Nome da remessadora |
| `partner_name` | String | Nome do parceiro |
| `has_fixed_spread` | Boolean | Spread fixo |
| `google` | Boolean | TRUE se contraparte = Google |
| `gmv_total_mes` | Double | GMV total do mês (CTE gmv_mensal) |
| `prop_gmv` | Double | Proporção do GMV desta operação no mês |
| `despesa_real` | Double | Mesmo que real_message_cost (alias) |
| `payout` | Double | Mesmo que payout_affiliate (alias) |
| `lucro` | Double | Mesmo que net_revenue (alias) |
| `last_update` | DateTime | Timestamp de atualização (`current_timestamp() - 3h`) |

**Coluna via JOIN beecambio:**

| Coluna | Tipo | Fonte |
|--------|------|-------|
| `policy_label` | String | `beecambio.beecambio_tbl_remittance_operation.policy_label` |

**Colunas calculadas (DAX):**

| Coluna | Lógica |
|--------|--------|
| `Tipo Lucro` | `IF(lucro < 0, "Negativo", "Positivo")` |
| `is_cupom` | `IF(voucher_code = BLANK(), "S/ cupom", "C/ cupom")` |
| `Ticket Range` | SWITCH por faixas de GMV (8 faixas de 0 a +30.000) |
| `swift_remessadora` | `IF(swift_or_distributor = BLANK(), "Swift", "Remessadora")` |
| `aquisicao_recorrencia` | `IF(acquisition, "Aquisição", "Recorrência")` |
| `Moedas` | Agrupa moedas principais (USD/EUR/GBP/CLP/ARS); demais = "Moeda exótica" |
| `Tarifa aplicada` | `IF(tariff = 0, "S/ tarifa", "C/ tarifa")` |
| `Desconto aplicado` | Classifica: Sem desconto / Produccine / Nubank / Com desconto / Vazio |
| `Faixa Spread` | SWITCH em 9 faixas de spread (Negativo → Acima de 1,2%) |
| `Faixa perc_mensageria` | SWITCH em 7 faixas de % mensageria/receita (0% → Acima 90%) |
| `spread_calculado` | `gross_revenue / gmv` |
| `Class Spread Real` | Compara `spread` vs `spread_calculado` |
| `perc_mensageria` | `real_message_cost / gross_revenue` |
| `custo_total` | `ABS(payout) + ABS(real_message_cost) + ABS(partner_commissioning) + ABS(bank_take)` |
| `bank_take_abs` | `-bank_take` (valor positivo) |

---

### customer

| Campo | Valor |
|-------|-------|
| **Tipo** | Fato (métricas agregadas por cliente) |
| **Camada** | 🟢 gold + ⚠️ automations + ⚠️ beecambio + ⚠️ finance_cube |
| **Fonte** | `gold.fact_operations` + `automations.integrations_hasoffer_conversion` + `beecambio.beecambio_tbl_office` + `finance_cube.kpi_list` |
| **Granularidade** | Uma linha por `id_customer` — métricas acumuladas de todo o histórico |
| **Janela** | `processed_date >= '2023-01-01'` (um ano mais longo que `processed_operations`) |
| **Filtro** | `is_ops_processed = true` + `bt.valor IS NOT NULL` (exige bank_take calculável) |

> ⚠️ **SCHEMAS NÃO-PADRÃO:** Esta tabela usa 3 schemas fora da hierarquia padrão para calcular bank_take alocado (finance_cube), comissões de afiliados (automations) e nomes de escritórios (beecambio).

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_customer` | Integer | ID do cliente |
| `naturezas` | Integer | Número de naturezas de operação distintas |
| `tipo_envio` | Integer | Número de tipos de envio distintos |
| `currency` | Integer | Número de moedas distintas |
| `country` | Integer | Número de países distintos |
| `qtde_ops` | Integer | Total de operações |
| `ops_negativas` | Integer | Operações com lucro negativo |
| `receita_liquida` | Double | Soma do lucro (net_revenue) |
| `gross_revenue` | Double | Soma da receita bruta |

**Coluna calculada (DAX):**

| Coluna | Lógica |
|--------|--------|
| `currency type` | `IF(currency = 1, "1", "Mais de 2 moedas")` |

**CTEs usados na query:**

| CTE | Fonte | Objetivo |
|-----|-------|----------|
| `comissao_afiliados` | `automations.integrations_hasoffer_conversion` + `beecambio.beecambio_tbl_office` | Comissões pagas a afiliados por operação |
| `bank_take` | `finance_cube.kpi_list` (indicador `45KPI`) | Bank take mensal total para alocação proporcional |
| `gmv_mensal` | `gold.fact_operations` | GMV mensal para cálculo de proporção |
| `base` | JOIN dos 3 CTEs acima | Cálculo de lucro = GR − bank_take − mensageria − payout |

---

### Parceiros

| Campo | Valor |
|-------|-------|
| **Tipo** | Dimensão (mapeamento cliente → parceiro) |
| **Camada** | ⚠️ beecambio |
| **Fonte** | `beecambio.beecambio_tbl_customer` + `beecambio.beecambio_maxima_partners` |
| **Granularidade** | Uma linha por cliente que tem `maxima_partner_code` |
| **Filtro** | `maxima_partner_code IS NOT NULL` |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_customer` | Integer | ID do cliente |
| `partner_name` | String | Nome do parceiro Maxima |
| `Escritórios` (calculada) | String | "Sim" se escritório legítimo, "Não" se parceiro específico (lista hardcoded de 8 nomes) |

> ⚠️ **LISTA HARDCODED:** A classificação `Escritórios = "Não"` usa lista fixada de 8 parceiros. Mudanças nos parceiros exigem edição manual da coluna calculada DAX.

---

### Subsegmento PF

| Campo | Valor |
|-------|-------|
| **Tipo** | Dimensão de segmentação (subsegmento de clientes PF) |
| **Camada** | ⚠️ stage + 🟡 silver |
| **Fonte** | `stage.dim_last_subsegments` + `silver.customers` |
| **Filtro** | `silver.customers.customer_type = 'PF'` |
| **Granularidade** | Uma linha por cliente × mês |

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_customer` | Integer | ID do cliente |
| `month_id` | Date | Mês de referência do subsegmento |
| `subsegment` | String | Nome do subsegmento PF |

> ⚠️ **STAGE:** O schema `stage` não é bronze/silver/gold/diamond — é uma camada de estágio intermediário. Verificar com o time de dados o nível de estabilidade e plano de migração.

---

## Tabela Dimensão (Dataflow)

### dcalendar

| Campo | Valor |
|-------|-------|
| **Tipo** | Dimensão temporal |
| **Camada** | Dataflow |
| **Dataflow ID** | `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| **Workspace** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Entidade** | `dcalendar` |
| **Transformações no modelo** | Nenhuma — direto da entidade (diferente do Daily Sales que adiciona `last_day`) |
| **Status** | ✅ Mesmo Dataflow do Scorecard, Daily Sales e Safras |

> ℹ️ **Versão mais completa:** O `dcalendar` deste dashboard tem mais colunas que o do Daily Sales — inclui `is_holiday`, `dayofweek`, `workday`, `workday_processado`, `label`, `Google Day`, `special_condition`, entre outros. Provavelmente é uma versão mais recente ou ampliada do mesmo Dataflow.

**Colunas adicionais em relação ao Daily Sales:**

`is_holiday`, `dayofweek`, `workday`, `workday_processado`, `month_days`, `workdays_month`, `last_workday`, `m0`, `m1`, `workdays_quarter`, `label`, `week`, `Quarter`, `month_to_date`, `last_update_calendar`, `day`, `month_number`, `mtd_calendar_days`, `is_ytd`, `day_of_yesterday`, `special_condition`, `total_month_days`, `Google Day`, `label_with_all_days_month`

---

## Tabelas Calculadas — Seletores e Parâmetros

### KPI (Seletor de métrica)

Tabela calculada DAX (`DATATABLE`) com as métricas disponíveis no seletor principal:

| KPI | Medida associada |
|-----|-----------------|
| GMV | `Total GMV` |
| Gross Revenue | `Total Gross Revenue` |
| Operações | `Total operações` |
| Clientes únicos | `Total clientes únicos` |
| Operações por clientes | `Operaçoes por cliente` |

A medida `Metricas de operações` é dinâmica — usa `SELECTEDVALUE('KPI'[KPI])` para retornar a métrica correta.

### Dimensão 1, Dimensão 2, Dimensão 3, Dimensão 4, Dimensão 5

Cinco tabelas calculadas idênticas, cada uma listando as **18 dimensões disponíveis** para decomposição nos gráficos de barras e tabelas. Permitem ao usuário escolher independentemente até 5 dimensões simultâneas.

| Opção | Coluna de origem |
|-------|-----------------|
| swift_remessadora | `processed_operations[swift_or_distributor]` |
| Tipo Lucro | `processed_operations[Tipo Lucro]` |
| in_or_out | `processed_operations[in_or_out]` |
| acquisition | `processed_operations[aquisicao_recorrencia]` |
| country | `processed_operations[country]` |
| customer_type | `processed_operations[customer_type]` |
| natureza | `processed_operations[natureza]` |
| Moedas | `processed_operations[Moedas]` |
| Ticket Range | `processed_operations[Ticket Range]` |
| Tarifa | `processed_operations[Tarifa aplicada]` |
| Desconto aplicado | `processed_operations[Desconto aplicado]` |
| Faixa Spread | `processed_operations[Faixa Spread]` |
| MID | `processed_operations[MID]` |
| Representatividade Mensagem | `processed_operations[Faixa perc_mensageria]` |
| Parceiro | `processed_operations[partner_name]` |
| Cod. Moeda | `processed_operations[currency_abbreviation]` |
| Remessadora | `processed_operations[distributor_name]` |
| Política de Preço | `processed_operations[policy_label]` |

### Escolha a métrica

Seletor de 4 métricas para o visual de análise de clientes:

| Opção | Medida |
|-------|--------|
| # operações | `Medidas[Total operações]` |
| % ops negativas | `Medidas[% ops negativas]` |
| # prejuizo | `Medidas[Total prejuizo]` |
| # Receita Líquida | `Medidas[Total Receita Líquida]` |

### Timeframe

Seletor de granularidade temporal com 4 opções: Date Key (dia), week (semana), month (mês), year (ano). Controla a granularidade dos gráficos de linha e barras de série temporal.

### Cenários Delta Operações

Parâmetro de cenário — `GENERATESERIES(-1, 1, 0.01)` — slider de -100% a +100% em passos de 1%. Simula variação no volume de operações para projetar impacto na receita.

### Cenários Delta Spread

Parâmetro de cenário — `GENERATESERIES(-1, 1, 0.01)` — slider de -100% a +100% em passos de 1%. Simula variação no spread médio para projetar impacto na receita.

---

## Tabelas de Medidas

### Medidas

Tabela principal de medidas DAX. Ver [02-medidas.md](02-medidas.md) para detalhes.

### Cenários

Tabela de medidas para o simulador de cenários. Ver [02-medidas.md](02-medidas.md).
