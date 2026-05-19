# Daily Sales Dashboard — Glossário de Medidas DAX

> **Legenda:** ⭐ KPI estratégico · ⚠️ Medida complexa (5+ funções DAX) · 🔄 Medida dinâmica (sensível a seletor)

---

## Grupo: Receita Bruta

Medidas de Gross Revenue — o spread capturado pela Remessa Online nas operações de câmbio.

### ⭐ Receita
```dax
VAR vIntraday = SELECTEDVALUE('Intraday Flag'[Intraday])
VAR vRealizado = 
    COALESCE(
        SUM(f_gold_ops[gross_revenue]),
        SUM(f_daily_sales[gross_revenue])
    ) 
    + SUM(f_wallet[gross_revenue])
RETURN
SWITCH(
    TRUE(),
    vIntraday = FALSE(), CALCULATE(vRealizado, dcalendar[is_current_date] = FALSE()),
    vIntraday = TRUE(), vRealizado
)
```
Soma a receita bruta das operações de câmbio (`f_gold_ops` tem precedência) + receita da Wallet. Quando `Intraday = FALSE`, exclui o dia atual (visão fechamento D-1).

| Medida | Fórmula resumida | Significado |
|--------|-----------------|-------------|
| `Meta de Receita` | `SUM(f_daily_sales[meta_gross_revenue])` | Meta diária de receita |
| `Receita (MTD)` | `CALCULATE([Receita], dcalendar[mtd] = TRUE())` | Receita acumulada no mês |
| `Receita (D-1)` | `CALCULATE([Receita], dcalendar[d0] = TRUE())` | Receita do último dia fechado |
| `% Meta x Receita` | `DIVIDE([Receita] - [Meta de Receita], [Meta de Receita])` | Desvio da meta (%) |
| `% GAP de Receita` | `IF(ISBLANK([Meta de Receita]), BLANK(), [% Meta x Receita])` | GAP vs. meta (só exibe se meta existir) |
| `% Gap de Receita (D-1)` | `CALCULATE([% GAP de Receita], dcalendar[d0] = TRUE())` | GAP de receita em D-1 |
| `% Gap de Receita (MTD)` | `CALCULATE([% GAP de Receita], dcalendar[mtd] = TRUE())` | GAP de receita no acumulado do mês |
| `Projeção de Receita (Last Day)` | `CALCULATE(SUM(f_daily_sales[projecao_gross_revenue]), dcalendar[last_day] = TRUE())` | Projeção de fechamento do mês |
| `Projeção de Receita Acumulada` | Projeção dos dias ainda sem realizado | Completa o gráfico de linha até o fim do mês |

---

## Grupo: GMV

Volume bruto transacionado em câmbio.

### ⭐ GMV
```dax
COALESCE(
    SUM(f_daily_sales[gmv]),
    SUM(f_gold_ops[gmv])
)
```
Usa `f_daily_sales` (agregado) quando disponível; cai para `f_gold_ops` (granular, usado no intraday).

| Medida | Significado |
|--------|------------|
| `Meta de GMV` | Meta diária de GMV |
| `Projeção de GMV (Last Day)` | Projeção de fechamento mensal |
| `Projeção de GMV Acumulada` | Projeção para os dias ainda sem realizado |

---

## Grupo: Operações

Número de operações de câmbio processadas.

### ⭐ Ops
```dax
COALESCE(
    SUM(f_daily_sales[operations]),
    SUM(f_gold_ops[operations]),
    SUM(f_wallet[transactions])
)
```
Hierarquia de fallback: `f_daily_sales` → `f_gold_ops` → `f_wallet`.

| Medida | Significado |
|--------|------------|
| `Meta de Ops` | Meta diária de operações |
| `Projeção de Ops (Last Day)` | Projeção de fechamento mensal |
| `% Meta x Ops` | Desvio da meta de operações (%) |
| `% GAP de Ops` | GAP vs. meta (só exibe se meta existir) |
| `% Gap de Ops (D-1)` | GAP de operações em D-1 |
| `% Gap de Ops (MTD)` | GAP de operações no acumulado do mês |
| `Aquisições` | `CALCULATE([Ops], d_event_type[event_type] = "ACQUISITION")` — primeiras operações |
| `Aquisições (D-1)` | Aquisições do último dia fechado |
| `Aquisições (MTD)` | Aquisições acumuladas no mês |
| `% Gap de Aquisições (D-1)` | GAP de aquisições em D-1 |
| `% Gap de Aquisições (MTD)` | GAP de aquisições acumulado |
| `Projeção de Ops Acumulada` | Projeção para dias ainda sem realizado |

---

## Grupo: Presignups

Clientes que iniciaram o cadastro na plataforma (topo do funil).

### Presignups
```dax
SUM(f_daily_sales_psu[realizado_psu])
```
Soma os presignups realizados conforme registrado na tabela `f_daily_sales_psu` (que combina `gold.daily_sales_psu` com dados de Google Analytics).

| Medida | Significado |
|--------|------------|
| `Presignups (D-1)` | PSU do último dia fechado |
| `Presignups (MTD)` | PSU acumulados no mês |
| `Presignups (PMTD)` | PSU acumulados no mesmo período do mês anterior |
| `Presignups % MOM (MTD)` | Variação % de PSU vs. mês anterior (mesmo período) |

---

## Grupo: Investimento em Marketing

Gasto com mídia paga (fonte: `bronze.paid_media_investments`).

### Investimento
```dax
SUM(f_investimentos[investimento])
```
Soma o investimento em mídia paga, já alocado proporcionalmente entre PF e PJ.

| Medida | Significado |
|--------|------------|
| `Investimento (D-1)` | Investimento do último dia |
| `Investimento (MTD)` | Investimento acumulado no mês |
| `Investimento (PMTD)` | Investimento no mesmo período do mês anterior |
| `Investimento % MOM (MTD)` | Variação % do investimento vs. mês anterior |
| `Investimento Sem Filtro de Ano` | `CALCULATE([Investimento], REMOVEFILTERS(dcalendar[year]))` — remove filtro de ano para análises históricas |

---

## Grupo: Eficiência de Marketing (CPP e CPA)

Métricas de custo-eficiência do investimento em marketing.

### CPP (Custo por Presignup)
```dax
DIVIDE([Investimento], [Presignups], BLANK())
```
Quanto a Remessa Online gasta em marketing para cada novo presignup. Menor = mais eficiente.

### CPA (Custo por Aquisição)
```dax
DIVIDE([Investimento], [Aquisições], BLANK())
```
Quanto a Remessa Online gasta em marketing para cada nova aquisição (primeiro câmbio). Menor = mais eficiente.

| Medida | Significado |
|--------|------------|
| `CPP (D-1)` | CPP do último dia |
| `CPP (MTD)` | CPP acumulado no mês |
| `CPP (PMTD)` | CPP no mesmo período do mês anterior |
| `CPP # MOM (MTD)` | Variação absoluta do CPP vs. mês anterior |
| `CPA (D-1)` | CPA do último dia |
| `CPA (MTD)` | CPA acumulado no mês |
| `CPA (PMTD)` | CPA no mesmo período do mês anterior |
| `CPA # MOM (MTD)` | Variação absoluta do CPA vs. mês anterior |
| `CPA Acumulado` | CPA calculado sobre todos os dias até o último com dados de investimento |

---

## Grupo: PNL (Tesouraria)

Resultado de tesouraria — receita específica de operações de tesouraria.

### PNL
```dax
SUM(f_gold_ops[gross_revenue_treasury])
```
Soma a receita de tesouraria das operações, registrada na coluna `gross_revenue_treasury` de `gold.fact_operations`.

### Meta de PNL
```dax
SUM(f_pnl_tesouraria[meta_pnl])
```
Meta de PNL distribuída diariamente conforme proporção de dias úteis (hardcoded por BU para 2025 e 2026).

---

## Grupo: Custos Operacionais

### Custo de Mensageria
```dax
SUM(f_gold_ops[real_message_cost])
```
Custo total de mensagens/notificações enviadas nas operações processadas.

### Take do Banco
```dax
SUM(f_gold_ops[cost_bank_take])
```
Custo cobrado pelo banco parceiro para processar as operações de câmbio.

---

## ⚠️ Grupo: Medidas Dinâmicas (# Oficial)

Estas medidas são **sensíveis ao seletor `Tabela[KPI]`** e ao **toggle `Intraday Flag`**. Retornam valores diferentes conforme a combinação selecionada. São as medidas usadas nos visuais principais do dashboard.

### ⚠️ 🔄 Realizado
```dax
VAR vIntraday = SELECTEDVALUE('Intraday Flag'[Intraday])
VAR vKPI = SELECTEDVALUE(Tabela[KPI])
RETURN
SWITCH(
    TRUE(),
    vKPI = "GMV" && vIntraday = FALSE(), CALCULATE([GMV], dcalendar[is_current_date] = FALSE()),
    vKPI = "Receita" && vIntraday = FALSE(), CALCULATE([Receita], dcalendar[is_current_date] = FALSE()),
    -- [e mais 6 combinações...]
    vKPI = "GMV" && vIntraday = TRUE(), [GMV],
    -- [e mais 6 combinações...]
)
```
Retorna o KPI selecionado na `Tabela`, com ou sem dados do dia atual conforme o `Intraday Flag`.

| Medida | Fórmula resumida |
|--------|-----------------|
| `Realizado (D-1)` | `CALCULATE([Realizado], dcalendar[d0] = TRUE())` |
| `Realizado (M-1)` | `CALCULATE([Realizado], DATEADD(dcalendar[Date Key], -1, MONTH))` |
| `Realizado (MTD)` | `CALCULATE([Realizado], dcalendar[mtd] = TRUE())` com ajuste Intraday |
| `Realizado (PMTD)` | `CALCULATE([Realizado], DATEADD(-1, MONTH), dcalendar[mtd] = TRUE())` |
| `Realizado YTD` | `TOTALYTD([Realizado], dcalendar[Date Key])` |
| `AVG -3M (D-1)` | Média dos últimos 90 dias usando `DATESINPERIOD` |

### 🔄 Meta, Meta (D-1), Meta (MTD), Meta Acumulada, Meta YTD, Meta FY, Meta (D0), Gauge Meta 0

Equivalentes de meta para cada período — também dinâmicas via `SELECTEDVALUE(Tabela[KPI])`.

### 🔄 Projeção, Projeção Acumulada, Projeção x M-1 (#), Projeção x Meta (#)

Projeção de fechamento do mês — retorna BLANK quando já há realizado (exibe apenas para dias futuros).

### Métricas de GAP e Growth

| Medida | Fórmula resumida | Significado |
|--------|-----------------|-------------|
| `% GAP` | `IF(ISBLANK([Meta]), BLANK(), [% Meta x Realizado])` | Percentual atingido da meta |
| `% Meta x Realizado` | `DIVIDE([Realizado], [Meta])` | Realizado ÷ Meta |
| `% GAP (D-1)` | GAP em D-1 | |
| `% GAP (MTD)` | GAP acumulado no mês | |
| `% GAP (YTD)` | GAP acumulado no ano | |
| `# GAP` | `[Realizado] - [Meta]` | Diferença absoluta |
| `# GAP (D-1)` | GAP absoluto em D-1 | |
| `# GAP (MTD)` | GAP absoluto no mês | |
| `# GAP (YTD)` | GAP absoluto no ano | |
| `% MOM (MTD)` | `DIVIDE([Realizado (MTD)] - [Realizado (PMTD)], [Realizado (PMTD)])` | Crescimento vs. mês anterior |
| `% MOM` | `DIVIDE([Realizado (MTD)] - [Realizado (M-1)], [Realizado (M-1)])` | Crescimento vs. mês anterior completo |
| `# MOM (MTD)` | `[Realizado (MTD)] - [Realizado (PMTD)]` | Variação absoluta vs. mês anterior |
| `% Meta x Realizado - Acumulado` | `DIVIDE([Acumulado], [Meta Acumulada])` | GAP acumulado do mês |
| `Gauge - GAP YTD` | Texto formatado com valor e ícone | Exibição em gauge visual |

---

## Grupo: Auxiliares

| Medida | Fórmula resumida | Uso |
|--------|-----------------|-----|
| `Last Update` | `MAX(f_last_update[last_update])` | Timestamp da última atualização |
| `MaxData` | `MAX(dcalendar[Date Key])` | Data máxima do calendário com dados |
| `Current Month Processed` | Texto estático "Resultado Diário Acumulado" | Label do visual |
| `Título Report Diário` | `"Report Diário - " & FORMAT([Last Update], "DD/mm/YYYY")` | Título dinâmico |
| `Mês Anterior` | `FORMAT(EDATE(MAX(dcalendar[Date Key]), -1), "MMM/YYYY")` | Texto do mês anterior para comparação |

---

## Grupo: HTML Narrativo

Medidas que geram texto HTML para visualização em visual de Texto/HTML.

### Bom Dia Dream Makers
```dax
"<div style='...'><h2>Hey, time Remessa!</h2>
Segue o resumo dos resultados registrados no último fechamento (D-1) e o desempenho 
acumulado no mês de <b>" & MAX(dcalendar[month_year]) & "</b>.</div>"
```
Cabeçalho narrativo personalizado para o dia.

### ⚠️ Resumo Dashboard
Medida HTML complexa que concatena valores de Investimento, Presignups, CPP, Aquisições, CPA e Receita Bruta em cards formatados com indicação de cor (verde/vermelho conforme performance vs. meta). Usada para exportação ou visão narrativa em uma única célula.
