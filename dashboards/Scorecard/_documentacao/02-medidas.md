# Scorecard - Business Performance — Medidas

Catálogo de todas as medidas DAX do modelo, agrupadas pelos displayFolders.

> **Voltar pra:** [01 · Tabelas](01-tabelas.md) · **Próxima:** [03 · Relacionamentos](03-relacionamentos.md)

---

## Realizado\Cost

5 medidas · custos operacionais e crescimento vs período anterior

### % Total Cost

`Medidas.% Total Cost` · `0.0%;-0.0%;0.0%` · Realizado\Cost

**O que faz:**
Percentual dos custos totais sobre a Gross Revenue. Responde: "de cada R$1 de receita, quanto foi consumido em custos operacionais (mensagem + bank take + payout de afiliado)?"

**DAX:**
```dax
DIVIDE(
    [Total Cost],
    [Gross Revenue],
    BLANK()
)
```

**Como funciona:**
Simples divisão entre `[Total Cost]` e `[Gross Revenue]`. Retorna BLANK() se Gross Revenue for zero.

**Usa:** `Total Cost`, `Gross Revenue`
**É usada por:** `% Total Cost Anterior`, `% Total Cost Growth`, `% Total Cost Growth Format %`

---

### % Total Cost Anterior

`Medidas.% Total Cost Anterior` · `0.0%;-0.0%;0.0%` · Realizado\Cost

**O que faz:**
Calcula o `% Total Cost` para o período anterior (dia ou mês), de acordo com o parâmetro `p_timeframe`.

**DAX:**
```dax
DIVIDE(
    [Total Cost Anterior],
    [Gross Revenue Anterior],
    BLANK()
)
```

**Como funciona:**
Usa os valores anteriores já calculados pelas medidas correspondentes.

**Usa:** `Total Cost Anterior`, `Gross Revenue Anterior`
**É usada por:** `% Total Cost Growth`

---

### % Total Cost Growth

`Medidas.% Total Cost Growth` · `0.0%;-0.0%;0.0%` · Realizado\Cost

**O que faz:**
Variação em pontos percentuais do `% Total Cost` em relação ao período anterior.

**DAX:**
```dax
[% Total Cost] - [% Total Cost Anterior]
```

**Como funciona:**
Diferença aritmética direta em pp. Não usa DIVIDE — crescimento em p.p. se calcula por subtração.

**Usa:** `% Total Cost`, `% Total Cost Anterior`
**É usada por:** `% Total Cost Growth Format %`

---

### % Total Cost Growth Format %

`Medidas.% Total Cost Growth Format %` · Realizado\Cost

**O que faz:**
Formata o crescimento do `% Total Cost` com sinal + ou - explícito para uso em cards e tooltips.

**DAX:**
```dax
FORMAT(
    [% Total Cost Growth],
    "+0.0% pp;-0.0% pp"
)
```

**Como funciona:**
Converte a variação numérica em texto formatado com unidade "pp".

**Usa:** `% Total Cost Growth`
**É usada por:** —

---

### Total Cost

`Medidas.Total Cost` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Cost

**O que faz:**
Soma de todos os custos operacionais: custo de mensagem + bank take + payout de afiliado. É o custo variável diretamente ligado às operações.

**DAX:**
```dax
SUM ( f_operations[cost_bank_take] )
    + SUM ( f_operations[cost_mensage] )
    + SUM ( f_operations[cost_payout_affiliate] )
```

**Como funciona:**
Soma três colunas de custo da `f_operations`. Referencia colunas diretamente.

**Usa:** `f_operations[cost_bank_take]`, `f_operations[cost_mensage]`, `f_operations[cost_payout_affiliate]`
**É usada por:** `% Total Cost`, `Total Cost Anterior`, `Total Cost Growth`, `Total Cost Growth Format %`

---

### Total Cost Anterior

`Medidas.Total Cost Anterior` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Cost

**O que faz:**
Calcula `Total Cost` para o período anterior (dia ou mês), de acordo com `p_timeframe` e o filtro MTD atual.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])

VAR vPreviousMonth = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Total Cost], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), d_calendar[mtd] = TRUE()),
        CALCULATE([Total Cost], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), REMOVEFILTERS(d_calendar[mtd]))
    )

VAR vPreviousDay = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Total Cost], DATEADD('d_calendar'[Date Key], -1, DAY), d_calendar[mtd] = TRUE()),
        CALCULATE([Total Cost], DATEADD('d_calendar'[Date Key], -1, DAY), REMOVEFILTERS(d_calendar[mtd]))
    )

RETURN
SWITCH(
    TRUE(),
    vTimeframe = "por Dia", vPreviousDay,
    vTimeframe = "por Mês", vPreviousMonth,
    BLANK()
)
```

**Como funciona:**
Padrão das medidas `Anterior` do modelo. Detecta se o filtro MTD está ativo e aplica o deslocamento temporal correto (PARALLELPERIOD para mês, DATEADD para dia), preservando ou removendo o filtro MTD conforme o contexto.

**Usa:** `Total Cost`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `% Total Cost Anterior`, `Total Cost Growth`

---

### Total Cost Growth

`Medidas.Total Cost Growth` · `0.0%;-0.0%;0.0%` · Realizado\Cost

**O que faz:**
Crescimento percentual do `Total Cost` em relação ao período anterior.

**DAX:**
```dax
DIVIDE(
    [Total Cost] - [Total Cost Anterior],
    [Total Cost Anterior],
    BLANK()
)
```

**Usa:** `Total Cost`, `Total Cost Anterior`
**É usada por:** `Total Cost Growth Format %`

---

### Total Cost Growth Format %

`Medidas.Total Cost Growth Format %` · Realizado\Cost

**O que faz:**
Formata o crescimento do Total Cost com sinal explícito para cards de tendência.

**DAX:**
```dax
FORMAT(
    [Total Cost Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Total Cost Growth`
**É usada por:** —

---

## Realizado\Customers

5 medidas · base de clientes únicos e crescimento

### Customers

`Medidas.Customers` · `#,0` · Realizado\Customers

**O que faz:**
Contagem de clientes únicos que operaram no período. É o "MAU" (Monthly Active Users) do modelo.

**DAX:**
```dax
DISTINCTCOUNT(f_operations[id_customer])
```

**Como funciona:**
DISTINCTCOUNT diretamente na coluna `id_customer` da fato. Simples e eficiente.

**Usa:** `f_operations[id_customer]`
**É usada por:** `Operations by Customer`, `ARPU (Gross Revenue / Customers)`, `Customers Anterior`, `Customers Growth`, `Customers Growth Format %`, `Color - MAUs`

---

### Customers Anterior

`Medidas.Customers Anterior` · `#,0` · Realizado\Customers

**O que faz:**
Clientes únicos no período anterior (dia ou mês), com controle de MTD.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])

VAR vPreviousMonth = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Customers], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), d_calendar[mtd] = TRUE()),
        CALCULATE([Customers], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), REMOVEFILTERS(d_calendar[mtd]))
    )

VAR vPreviousDay = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Customers], DATEADD('d_calendar'[Date Key], -1, DAY), d_calendar[mtd] = TRUE()),
        CALCULATE([Customers], DATEADD('d_calendar'[Date Key], -1, DAY), REMOVEFILTERS(d_calendar[mtd]))
    )

RETURN
SWITCH(
    TRUE(),
    vTimeframe = "por Dia", vPreviousDay,
    vTimeframe = "por Mês", vPreviousMonth,
    BLANK()
)
```

**Usa:** `Customers`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `Customers Growth`, `Operations by Customer Anterior`, `AVG Ticket GMV Anterior`

---

### Customers Growth

`Medidas.Customers Growth` · `0.0%;-0.0%;0.0%` · Realizado\Customers

**O que faz:**
Crescimento % de clientes únicos vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Customers] - [Customers Anterior],
    [Customers Anterior],
    BLANK()
)
```

**Usa:** `Customers`, `Customers Anterior`
**É usada por:** `Customers Growth Format %`

---

### Customers Growth Format %

`Medidas.Customers Growth Format %` · Realizado\Customers

**O que faz:**
Crescimento de Customers formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Customers Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Customers Growth`
**É usada por:** —

---

## Realizado\GMV

9 medidas · volume financeiro movimentado (GMV) em R$ e USD

### GMV

`Medidas.GMV` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\GMV

**O que faz:**
Gross Merchandise Volume — volume total de câmbio transacionado em R$. É a principal métrica de volume do Scorecard.

**DAX:**
```dax
SUM(f_operations[gmv])
```

**Como funciona:**
Soma simples da coluna `gmv` da fato.

**Usa:** `f_operations[gmv]`
**É usada por:** `Spread`, `AVG Ticket GMV`, `GMV Anterior`, `GMV Growth`, `GMV Growth Format %`, `Spread Anterior`, `Color - GMV`, `Color - TKM GMV`

---

### GMV Anterior

`Medidas.GMV Anterior` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\GMV

**O que faz:**
GMV do período anterior (dia ou mês), com controle de MTD.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])

VAR vPreviousMonth = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([GMV], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), d_calendar[mtd] = TRUE()),
        CALCULATE([GMV], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), REMOVEFILTERS(d_calendar[mtd]))
    )

VAR vPreviousDay = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([GMV], DATEADD('d_calendar'[Date Key], -1, DAY), d_calendar[mtd] = TRUE()),
        CALCULATE([GMV], DATEADD('d_calendar'[Date Key], -1, DAY), REMOVEFILTERS(d_calendar[mtd]))
    )

RETURN
SWITCH(
    TRUE(),
    vTimeframe = "por Dia", vPreviousDay,
    vTimeframe = "por Mês", vPreviousMonth,
    BLANK()
)
```

**Usa:** `GMV`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `GMV Growth`, `Spread Anterior`, `AVG Ticket GMV Anterior`

---

### GMV Growth

`Medidas.GMV Growth` · `0.0%;-0.0%;0.0%` · Realizado\GMV

**O que faz:**
Crescimento % do GMV vs período anterior.

**DAX:**
```dax
DIVIDE(
    [GMV] - [GMV Anterior],
    [GMV Anterior],
    BLANK()
)
```

**Usa:** `GMV`, `GMV Anterior`
**É usada por:** `GMV Growth Format %`

---

### GMV Growth Format %

`Medidas.GMV Growth Format %` · Realizado\GMV

**O que faz:**
Crescimento do GMV formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [GMV Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `GMV Growth`
**É usada por:** —

---

### GMV USD

`Medidas.GMV USD` · `$#,0;($#,0);$#,0` · Realizado\GMV

**O que faz:**
GMV total em dólares americanos.

**DAX:**
```dax
SUM(f_operations[gmv_usd])
```

**Usa:** `f_operations[gmv_usd]`
**É usada por:** —

---

### Quantity (ME)

`Medidas.Quantity (ME)` · `$#,0;($#,0);$#,0` · Realizado\GMV

**O que faz:**
Quantidade total em moeda estrangeira (ME) — o volume cambial sem conversão para BRL.

**DAX:**
```dax
SUM ( f_operations[quantity] )
```

**Usa:** `f_operations[quantity]`
**É usada por:** —

---

## Realizado\Gross

16 medidas · receita bruta, lucro bruto e variantes com comparação

### ARPU (Gross Revenue / Customers)

`Medidas.ARPU (Gross Revenue / Customers)` · `"R$"#,0;-"R$"#,0;"R$"#,0` · Realizado\Gross

**O que faz:**
Average Revenue Per User — receita bruta por cliente único. Mostra o "valor médio" que cada cliente gerou no período.

**DAX:**
```dax
DIVIDE ( [Gross Revenue], [Customers], BLANK() )
```

**Usa:** `Gross Revenue`, `Customers`
**É usada por:** —

---

### Diff Gross Revenue

`Medidas.Diff Gross Revenue` · Realizado\Gross

**O que faz:**
Diferença entre o Gross Revenue original (sem desconto) e o Gross Revenue atual — representa o volume de desconto concedido em R$.

**DAX:**
```dax
SUM ( f_operations[diff_gross_revenue] )
```

**Usa:** `f_operations[diff_gross_revenue]`
**É usada por:** `Diff Gross Revenue Anterior`, `Diff Gross Revenue Growth`

---

### Diff Gross Revenue Anterior

`Medidas.Diff Gross Revenue Anterior` · Realizado\Gross

**O que faz:**
Diff Gross Revenue do período anterior com controle de MTD/timeframe.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])
-- [mesma estrutura padrão de período anterior]
RETURN SWITCH(TRUE(), vTimeframe = "por Dia", vPreviousDay, vTimeframe = "por Mês", vPreviousMonth, BLANK())
```

**Usa:** `Diff Gross Revenue`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `Diff Gross Revenue Growth`

---

### Diff Gross Revenue Growth

`Medidas.Diff Gross Revenue Growth` · Realizado\Gross

**O que faz:**
Crescimento percentual do desconto concedido vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Diff Gross Revenue] - [Diff Gross Revenue Anterior],
    [Diff Gross Revenue Anterior],
    BLANK()
)
```

**Usa:** `Diff Gross Revenue`, `Diff Gross Revenue Anterior`
**É usada por:** `Diff Gross Revenue Growth Format %`

---

### Diff Gross Revenue Growth Format %

`Medidas.Diff Gross Revenue Growth Format %` · Realizado\Gross

**O que faz:**
Crescimento do Diff GR formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Diff Gross Revenue Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Diff Gross Revenue Growth`
**É usada por:** —

---

### Gross Profit

`Medidas.Gross Profit` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Gross

**O que faz:**
Lucro bruto total — o que sobra da receita depois dos custos de mensagem, bank take e payout de afiliado.

**DAX:**
```dax
SUM ( f_operations[gross_profit] )
```

**Usa:** `f_operations[gross_profit]`
**É usada por:** `Ticket Médio (Gross Profit)`, `Gross Profit Anterior`, `Gross Profit Growth`

---

### Gross Profit Anterior

`Medidas.Gross Profit Anterior` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Gross

**O que faz:**
Gross Profit do período anterior com controle de MTD/timeframe.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])
-- [mesma estrutura padrão de período anterior com PARALLELPERIOD/DATEADD]
RETURN SWITCH(TRUE(), vTimeframe = "por Dia", vPreviousDay, vTimeframe = "por Mês", vPreviousMonth, BLANK())
```

**Usa:** `Gross Profit`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `Gross Profit Growth`

---

### Gross Profit Growth

`Medidas.Gross Profit Growth` · `0.0%;-0.0%;0.0%` · Realizado\Gross

**O que faz:**
Crescimento % do Gross Profit vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Gross Profit] - [Gross Profit Anterior],
    [Gross Profit Anterior],
    BLANK()
)
```

**Usa:** `Gross Profit`, `Gross Profit Anterior`
**É usada por:** `Gross Profit Growth Format %`

---

### Gross Profit Growth Format %

`Medidas.Gross Profit Growth Format %` · Realizado\Gross

**O que faz:**
Crescimento do Gross Profit formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Gross Profit Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Gross Profit Growth`
**É usada por:** —

---

### Gross Revenue

`Medidas.Gross Revenue` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Gross

**O que faz:**
Receita bruta total — o revenue gerado pelas operações de câmbio. É a medida-mãe do grupo Gross.

**DAX:**
```dax
SUM ( f_operations[gross_revenue] )
```

**Usa:** `f_operations[gross_revenue]`
**É usada por:** `Spread`, `% Total Cost`, `ARPU`, `Gross Revenue Anterior`, `Gross Revenue Growth`, `AVG Ticket Gross Revenue`, `Color - Gross Revenue`

---

### Gross Revenue Anterior

`Medidas.Gross Revenue Anterior` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Gross

**O que faz:**
Gross Revenue do período anterior com controle de MTD/timeframe.

**DAX:**
```dax
VAR vTimeframe = SELECTEDVALUE(p_timeframe[SelectedValue])
VAR IsMTDSelected = SELECTEDVALUE(d_calendar[mtd])
-- [mesma estrutura padrão de período anterior]
RETURN SWITCH(TRUE(), vTimeframe = "por Dia", vPreviousDay, vTimeframe = "por Mês", vPreviousMonth, BLANK())
```

**Usa:** `Gross Revenue`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `% Total Cost Anterior`, `Spread Anterior`, `Gross Revenue Growth`, `Gross Revenue Original Anterior`

---

### Gross Revenue Growth

`Medidas.Gross Revenue Growth` · `0.0%;-0.0%;0.0%` · Realizado\Gross

**O que faz:**
Crescimento % da Gross Revenue vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Gross Revenue] - [Gross Revenue Anterior],
    [Gross Revenue Anterior],
    BLANK()
)
```

**Usa:** `Gross Revenue`, `Gross Revenue Anterior`
**É usada por:** `Gross Revenue Growth Format %`

---

### Gross Revenue Growth Format %

`Medidas.Gross Revenue Growth Format %` · Realizado\Gross

**O que faz:**
Crescimento da GR formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Gross Revenue Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Gross Revenue Growth`
**É usada por:** —

---

### Gross Revenue Original

`Medidas.Gross Revenue Original` · Realizado\Gross

**O que faz:**
Gross Revenue sem descontos — receita "cheia" de tabela antes da concessão de descontos de spread.

**DAX:**
```dax
SUM ( f_operations[gross_revenue_original] )
```

**Usa:** `f_operations[gross_revenue_original]`
**É usada por:** `Gross Revenue Original Anterior`, `Gross Revenue Original Growth`

---

### Gross Revenue Original Anterior

`Medidas.Gross Revenue Original Anterior` · Realizado\Gross

**O que faz:**
Gross Revenue Original do período anterior com controle de MTD/timeframe.

**DAX:**
```dax
-- [mesma estrutura padrão de período anterior]
```

**Usa:** `Gross Revenue Original`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `Gross Revenue Original Growth`

---

### Gross Revenue Original Growth

`Medidas.Gross Revenue Original Growth` · Realizado\Gross

**O que faz:**
Crescimento % da GR Original vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Gross Revenue Original] - [Gross Revenue Original Anterior],
    [Gross Revenue Original Anterior],
    BLANK()
)
```

**Usa:** `Gross Revenue Original`, `Gross Revenue Original Anterior`
**É usada por:** `Gross Revenue Original Growth Format %`

---

### Gross Revenue Original Growth Format %

`Medidas.Gross Revenue Original Growth Format %` · Realizado\Gross

**O que faz:**
Crescimento da GR Original formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Gross Revenue Original Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Gross Revenue Original Growth`
**É usada por:** —

---

## Realizado\Operations

8 medidas · volume de operações e operações por cliente

### Operations

`Medidas.Operations` · `#,0` · Realizado\Operations

**O que faz:**
Contagem total de operações processadas no período. É a medida de volume transacional do modelo.

**DAX:**
```dax
COUNT ( f_operations[id_remittance] )
```

**Usa:** `f_operations[id_remittance]`
**É usada por:** `AVG Ticket GMV`, `AVG Ticket Gross Revenue`, `Operations by Customer`, `Ticket Médio (Gross Profit)`, `Operations Anterior`, `Operations Growth`, `Color - Operations`

---

### Operations Anterior

`Medidas.Operations Anterior` · `#,0` · Realizado\Operations

**O que faz:**
Operations do período anterior com controle de MTD/timeframe.

**DAX:**
```dax
-- [mesma estrutura padrão de período anterior]
```

**Usa:** `Operations`, `p_timeframe[SelectedValue]`, `d_calendar[mtd]`
**É usada por:** `Operations Growth`, `Operations by Customer Anterior`, `AVG Ticket GMV Anterior`

---

### Operations Growth

`Medidas.Operations Growth` · `0.0%;-0.0%;0.0%` · Realizado\Operations

**O que faz:**
Crescimento % das operações vs período anterior.

**DAX:**
```dax
DIVIDE(
    [Operations] - [Operations Anterior],
    [Operations Anterior],
    BLANK()
)
```

**Usa:** `Operations`, `Operations Anterior`
**É usada por:** `Operations Growth Format %`

---

### Operations Growth Format %

`Medidas.Operations Growth Format %` · Realizado\Operations

**O que faz:**
Crescimento de Operations formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Operations Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `Operations Growth`
**É usada por:** —

---

### Operations by Customer

`Medidas.Operations by Customer` · `0.00` · Realizado\Operations

**O que faz:**
Número médio de operações por cliente — indicador de recorrência.

**DAX:**
```dax
DIVIDE ( [Operations], [Customers], BLANK() )
```

**Usa:** `Operations`, `Customers`
**É usada por:** `Operations by Customer Anterior`, `Operations by Customer Growth`, `Color - Ops by Customer`

---

### Operations by Customer Anterior

`Medidas.Operations by Customer Anterior` · `#,0.00` · Realizado\Operations

**O que faz:**
Operações por cliente do período anterior.

**DAX:**
```dax
DIVIDE(
    [Operations Anterior],
    [Customers Anterior],
    BLANK()
)
```

**Usa:** `Operations Anterior`, `Customers Anterior`
**É usada por:** `Operations by Customer Growth`

---

### Operations by Customer Growth

`Medidas.Operations by Customer Growth` · `#,0.00` · Realizado\Operations

**O que faz:**
Variação absoluta de operações por cliente vs período anterior (não é percentual — é diferença aritmética).

**DAX:**
```dax
[Operations by Customer] - [Operations by Customer Anterior]
```

**Usa:** `Operations by Customer`, `Operations by Customer Anterior`
**É usada por:** `Operations by Customer Growth Format %`

---

### Operations by Customer Growth Format %

`Medidas.Operations by Customer Growth Format %` · Realizado\Operations

**O que faz:**
Variação de Ops by Customer formatada com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Operations by Customer Growth],
    "+0.00;-0.00"
)
```

**Usa:** `Operations by Customer Growth`
**É usada por:** —

---

## Realizado\Spread

9 medidas · análise de spread (taxa de câmbio aplicada)

### Spread

`Medidas.Spread` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Spread médio ponderado pelo volume — calculado como Gross Revenue / GMV. Representa a "margem de câmbio" em percentual.

**DAX:**
```dax
DIVIDE ( [Gross Revenue], [GMV], BLANK() )
```

**Usa:** `Gross Revenue`, `GMV`
**É usada por:** `Spread Anterior`, `Spread Growth`, `Color - Spread`

---

### Spread Anterior

`Medidas.Spread Anterior` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Spread (Gross Revenue / GMV) do período anterior.

**DAX:**
```dax
DIVIDE(
    [Gross Revenue Anterior],
    [GMV Anterior],
    BLANK()
)
```

**Usa:** `Gross Revenue Anterior`, `GMV Anterior`
**É usada por:** `Spread Growth`

---

### Spread Growth

`Medidas.Spread Growth` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Variação em pontos percentuais do Spread vs período anterior.

**DAX:**
```dax
[Spread] - [Spread Anterior]
```

**Usa:** `Spread`, `Spread Anterior`
**É usada por:** `Spread Growth Format %`

---

### Spread Growth Format %

`Medidas.Spread Growth Format %` · Realizado\Spread

**O que faz:**
Variação de Spread formatada em pp com sinal explícito.

**DAX:**
```dax
FORMAT(
    [Spread Growth],
    "+0.00% pp;-0.00% pp"
)
```

**Usa:** `Spread Growth`
**É usada por:** —

---

### Spread AVGX

`Medidas.Spread AVGX` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Spread médio simples por linha (AVERAGEX), em vez da média ponderada por volume. Mostra a média aritmética do spread aplicado em cada operação.

**DAX:**
```dax
AVERAGEX ( f_operations, f_operations[spread] )
```

**Usa:** `f_operations[spread]`
**É usada por:** `Color - Spread AVGX`

---

### Spread Original (AVGX)

`Medidas.Spread Original (AVGX)` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Média do spread de tabela (sem desconto) linha a linha. Comparar com `Spread AVGX` revela o desconto médio concedido.

**DAX:**
```dax
AVERAGEX ( f_operations, f_operations[spread_original] )
```

**Usa:** `f_operations[spread_original]`
**É usada por:** `Color - Spread Original AVGX`

---

### Spread Dif

`Medidas.Spread Dif` · `0.00%;-0.00%;0.00%` · Realizado\Spread

**O que faz:**
Média da diferença de spread (spread original - spread aplicado) linha a linha — representa o desconto médio de spread concedido por operação.

**DAX:**
```dax
AVERAGEX ( f_operations, f_operations[spread_dif] )
```

**Usa:** `f_operations[spread_dif]`
**É usada por:** —

---

## Realizado\Tariff

2 medidas · tarifas cobradas nas operações

### Tariff

`Medidas.Tariff` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Tariff

**O que faz:**
Total de tarifas cobradas — componente de receita adicional ao spread.

**DAX:**
```dax
sum(f_operations[tariff])
```

**Usa:** `f_operations[tariff]`
**É usada por:** —

---

### Tariff AVGX

`Medidas.Tariff AVGX` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\Tariff

**O que faz:**
Tarifa média por operação (AVERAGEX).

**DAX:**
```dax
AVERAGEX(f_operations, f_operations[tariff])
```

**Usa:** `f_operations[tariff]`
**É usada por:** —

---

## Realizado\TKM

7 medidas · ticket médio (por GMV e por Gross Revenue)

### AVG Ticket GMV

`Medidas.AVG Ticket GMV` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\TKM

**O que faz:**
Ticket médio em GMV — volume médio por operação em R$.

**DAX:**
```dax
DIVIDE ( [GMV], [Operations], BLANK() )
```

**Usa:** `GMV`, `Operations`
**É usada por:** `AVG Ticket GMV Anterior`, `AVG Ticket GMV Growth`, `Color - TKM GMV`, `f_operations[Ticket Range]` (calculada)

---

### AVG Ticket GMV Anterior

`Medidas.AVG Ticket GMV Anterior` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\TKM

**O que faz:**
Ticket médio GMV do período anterior.

**DAX:**
```dax
DIVIDE(
    [GMV Anterior],
    [Operations Anterior],
    BLANK()
)
```

**Usa:** `GMV Anterior`, `Operations Anterior`
**É usada por:** `AVG Ticket GMV Growth`

---

### AVG Ticket GMV Growth

`Medidas.AVG Ticket GMV Growth` · `0.0%;-0.0%;0.0%` · Realizado\TKM

**O que faz:**
Crescimento % do ticket médio GMV vs período anterior.

**DAX:**
```dax
DIVIDE(
    ([AVG Ticket GMV] - [AVG Ticket GMV Anterior]),
    [AVG Ticket GMV Anterior],
    BLANK()
)
```

**Usa:** `AVG Ticket GMV`, `AVG Ticket GMV Anterior`
**É usada por:** `AVG Ticket GMV Growth Format %`

---

### AVG Ticket GMV Growth Format %

`Medidas.AVG Ticket GMV Growth Format %` · Realizado\TKM

**O que faz:**
Crescimento do ticket médio GMV formatado com sinal explícito.

**DAX:**
```dax
FORMAT(
    [AVG Ticket GMV Growth],
    "+0.0%;-0.0%"
)
```

**Usa:** `AVG Ticket GMV Growth`
**É usada por:** —

---

### AVG Ticket Gross Revenue

`Medidas.AVG Ticket Gross Revenue` · `"R$" #,0.00;-"R$" #,0.00;"R$" #,0.00` · Realizado\TKM

**O que faz:**
Receita média por operação.

**DAX:**
```dax
DIVIDE ( [Gross Revenue], [Operations], BLANK() )
```

**Usa:** `Gross Revenue`, `Operations`
**É usada por:** `Color - TKM Receita`

---

### Ticket Médio (Gross Profit)

`Medidas.Ticket Médio (Gross Profit)` · `"R$" #,0;-"R$" #,0;"R$" #,0` · Realizado\TKM

**O que faz:**
Lucro bruto médio por operação — mede a rentabilidade unitária.

**DAX:**
```dax
DIVIDE ( [Gross Profit], [Operations], BLANK() )
```

**Usa:** `Gross Profit`, `Operations`
**É usada por:** —

---

## Aux

17 medidas · suporte a títulos dinâmicos, MTD e controle de data

### Last Working Day

`d_calendar.Last Working Day` · `0` · Aux

**O que faz:**
Retorna o número do último dia útil processado no calendário (com filtro MTD ativo).

**DAX:**
```dax
MAX ( d_calendar[workday_processado] )
```

**Usa:** `d_calendar[workday_processado]`
**É usada por:** —

---

### MTD

`Medidas.MTD` · Aux

**O que faz:**
Retorna o texto "MTD" se o filtro MTD estiver ativo, senão "Total".

**DAX:**
```dax
SWITCH ( TRUE (), SELECTEDVALUE ( 'd_calendar'[mtd] ) = TRUE (), "MTD", "Total" )
```

**Usa:** `d_calendar[mtd]`
**É usada por:** —

---

### MTD:

`Medidas.MTD:` · Aux

**O que faz:**
Texto descritivo do MTD atual: "Até o Nº dia útil".

**DAX:**
```dax
"Até o "
    & CALCULATE (
        MAX ( 'd_calendar'[workday_processado] ),
        'd_calendar'[Filter Today] = TRUE ()
    ) & "º dia útil"
```

**Usa:** `d_calendar[workday_processado]`, `d_calendar[Filter Today]`
**É usada por:** —

---

### Refresh

`Medidas.Refresh` · Aux

**O que faz:**
Mostra a data/hora do último refresh dos dados, no formato dd/MM/yy hh:mm.

**DAX:**
```dax
FORMAT(MAX(f_operations[last_update]), "dd/MM/yy hh:mm")
```

**Usa:** `f_operations[last_update]`
**É usada por:** —

---

### Título M0

`Medidas.Título M0` · Aux

**O que faz:**
Título dinâmico para o período atual: "Até {data de hoje}".

**DAX:**
```dax
"Até " & CALCULATE ( MAX ( 'd_calendar'[Date Key] ), 'd_calendar'[Filter Today] = TRUE () )
```

**Usa:** `d_calendar[Date Key]`, `d_calendar[Filter Today]`
**É usada por:** `Título SC`

---

### Título Results

`Medidas.Título Results` · Aux

**O que faz:**
Texto de rodapé com o intervalo de datas dos dados: "Dados de {min} até {max}".

**DAX:**
```dax
"Dados de " &
min(f_operations[processing_date]) &
" até " &
max(f_operations[processing_date])
```

**Usa:** `f_operations[processing_date]`
**É usada por:** —

---

### Título SC

`Medidas.Título SC` · Aux

**O que faz:**
Título completo do Scorecard unindo MTD, dia útil e data atual em uma string.

**DAX:**
```dax
VAR vMTD = SWITCH(TRUE(), SELECTEDVALUE(f_operations[mtd]) = TRUE(), "MTD", "Mês Cheio")
VAR vMTD2 = "Até o " & CALCULATE(MAX(f_operations[workday_processado]), f_operations[mtd] = TRUE()) & "º dia útil"
RETURN
vMTD & "  |  " & vMTD2 & "  |  " & [Título M0]
```

**Usa:** `f_operations[mtd]`, `f_operations[workday_processado]`, `Título M0`
**É usada por:** —

---

### Título SC Topo - AVG Ticket GMV / Customers / GMV / Gross Profit / Gross Revenue / Operations / Ops by Customer / Spread / Total Cost # / Total Cost %

`Medidas.Título SC Topo - *` · Aux

**O que faz:**
Série de medidas de título que geram o rótulo dinâmico do topo do Scorecard para cada KPI, concatenando o nome do KPI com o período selecionado em `p_timeframe`.

**DAX (exemplo — Título SC Topo - GMV):**
```dax
"GMV " & SELECTEDVALUE(p_timeframe[SelectedValue])
```

**Usa:** `p_timeframe[SelectedValue]`
**É usada por:** —

---

### Última Data

`Medidas.Última Data` · `Short Date` · Aux

**O que faz:**
Retorna a data máxima no calendário com filtro MTD ativo.

**DAX:**
```dax
CALCULATE ( MAX ( d_calendar[Date Key] ), d_calendar[mtd] = TRUE () )
```

**Usa:** `d_calendar[Date Key]`, `d_calendar[mtd]`
**É usada por:** —

---

### Última Operação

`Medidas.Última Operação` · Aux

**O que faz:**
Data da última operação processada na fato.

**DAX:**
```dax
MAX(f_operations[processing_date])
```

**Usa:** `f_operations[processing_date]`
**É usada por:** —

---

### Último dia útil

`Medidas.Último dia útil` · `#,0` · Aux

**O que faz:**
Número do último dia útil com operações processadas.

**DAX:**
```dax
max(f_operations[workday_processado])
```

**Usa:** `f_operations[workday_processado]`
**É usada por:** —

---

## Month over month (Calculation Group)

10 medidas de cor (Color - *) + 5 calculation items

### Color - GMV / Gross Revenue / MAUs / Operations / Ops by Customer / Spread / Spread AVGX / Spread Original AVGX / TKM GMV / TKM Receita

Série de medidas de formatação condicional. Cada uma retorna o valor da medida base se o Calculation Item selecionado for "Growth #" ou "Growth %", caso contrário retorna BLANK(). Usadas para aplicar cor condicional (positivo/negativo) nos visuais de crescimento.

**Exemplo — Color - GMV:**
```dax
IF (
    SELECTEDVALUE('Month over month'[Coluna do grupo de cálculo]) IN {"Growth #", "Growth %"},
    [GMV],
    BLANK ()
)
```

**Usa:** `Month over month[Coluna do grupo de cálculo]`, medida base correspondente
**É usada por:** —

---

*XPERIUN · `/pbi-doc`*
