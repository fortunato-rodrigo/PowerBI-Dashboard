# Dashboard - Recebimento — Glossário de Medidas DAX

> ⭐ = KPI estratégico · ⚠️ = medida complexa (5+ funções DAX)

---

## Volume de Ordens

### `Ordens`

```dax
CALCULATE(
    DISTINCTCOUNT(f_orders[id])
)
```

Contagem distinta de todas as ordens no período selecionado, independente do status.

---

### `Resgatadas`

```dax
CALCULATE(
    DISTINCTCOUNT(f_orders[id]),
    f_orders[status_ordem_resumo] = "Resgatado"
)
```

Ordens com status "Resgatado" — operações liquidadas/convertidas com sucesso.

---

### `Resgatadas (mesmo mês)`

```dax
CALCULATE(
    [Ordens],
    f_orders[resgate_mesmo_mes] = TRUE()
)
```

Ordens criadas e resgatadas dentro do mesmo mês calendário.

---

### `Pendentes`

```dax
CALCULATE(
    DISTINCTCOUNTNOBLANK(f_orders[id]),
    f_orders[status_ordem_resumo] = "Pendente"
)
```

Ordens aguardando processamento ou crédito. Usa `DISTINCTCOUNTNOBLANK` para excluir IDs nulos.

---

## Taxas e Conversões

### `% Resgate`

```dax
DIVIDE(
    [Resgatadas],
    [Ordens],
    BLANK()
)
```

Percentual de ordens que chegaram ao status Resgatado sobre o total de ordens.

---

### `% Resgate no mesmo mês`

```dax
DIVIDE(
    [Resgatadas (mesmo mês)],
    [Ordens],
    BLANK()
)
```

Percentual de ordens resgatadas no mesmo mês em que foram criadas.

---

## GMV (Volume Financeiro)

### ⭐ `GMV (Resgatado)`

```dax
CALCULATE(
    SUM(f_orders[gmv]),
    f_orders[status_ordem_resumo] = "Resgatado"
)
```

Soma do GMV de todas as ordens resgatadas. Usa o valor real de `f_orders[gmv]`.

---

### ⚠️ `GMV (Resgatado + Pendente)`

```dax
CALCULATE(
    SUM(f_orders[gmv_forecast]), ISBLANK(f_orders[gmv])
) 
+ 
CALCULATE(
    SUM(f_orders[gmv])
)
```

GMV total combinado: para ordens com `gmv` disponível usa o valor real; para as demais (pendentes sem GMV calculado) usa o `gmv_forecast` (cotação do dia × quantidade).

---

### `GMV Pendente (Forecast)`

```dax
CALCULATE(
    SUM(f_orders[gmv_forecast]),
    f_orders[status_ordem_resumo] = "Pendente"
)
```

Estimativa do GMV das ordens pendentes calculada como `quantity × trading_quotation` do dia atual.

---

## Receita

### ⭐ `Receita (Resgatado)`

```dax
CALCULATE(
    SUM(f_orders[gross_revenue]),
    f_orders[status_ordem_resumo] = "Resgatado"
)
```

Receita bruta real das ordens resgatadas — campo `gross_revenue` de `silver.orders`.

---

### ⚠️ `Receita Pendente (Forecast)`

```dax
CALCULATE(
    [GMV Pendente (Forecast)] * 'p_Spread (What if?)'[Valor Spread (What if?)],
    f_orders[status_ordem_resumo] = "Pendente"
)
```

Estimativa de receita das ordens pendentes aplicando o spread do simulador "What if?" ao GMV projetado.

> ⚠️ A receita projetada é totalmente dependente do spread selecionado no parâmetro. O spread padrão de 0,83% (`gross_revenue_forecast = quantity * 0.0083`) está **hardcoded** na coluna calculada — qualquer mudança de política exige edição manual.

---

## Ticket Médio

### `Ticket Médio (Resgatado)`

```dax
DIVIDE(
    [GMV (Resgatado)],
    [Resgatadas],
    BLANK()
)
```

Valor médio por ordem resgatada em BRL.

---

### `AVG Ticket (Pendente)`

```dax
DIVIDE(
    [GMV Pendente (Forecast)],
    [Pendentes],
    BLANK()
)
```

Ticket médio estimado das ordens pendentes usando o GMV projetado.

---

### `Ticket Médio (Resgatado + Pendente)`

```dax
DIVIDE(
    [GMV (Resgatado + Pendente)],
    [Ordens],
    BLANK()
)
```

Ticket médio considerando todas as ordens (resgatadas com GMV real + pendentes com forecast).

---

## Clientes

### `Clientes únicos`

```dax
CALCULATE(
    DISTINCTCOUNT(f_orders[id_customer])
)
```

Número de clientes distintos com ao menos uma ordem no período selecionado.

---

### `Ordens por cliente`

```dax
DIVIDE(
    [Ordens],
    [Clientes únicos],
    BLANK()
)
```

Frequência média de ordens por cliente no período.

---

## Moeda Estrangeira (ME)

### `ME (Resgatado)`

```dax
CALCULATE(
    SUM(f_orders[quantity]),
    f_orders[status_ordem_resumo] = "Resgatado"
)
```

Soma da quantidade em moeda estrangeira das ordens resgatadas.

---

### `ME (Pendente)`

```dax
CALCULATE(
    SUM(f_orders[quantity]),
    f_orders[status_ordem_resumo] = "Pendente"
)
```

Soma da quantidade em moeda estrangeira das ordens pendentes.

---

### `ME`

```dax
SUM(f_orders[quantity])
```

Total de moeda estrangeira de todas as ordens (sem filtro de status).

---

## Comparação Temporal

### ⚠️ `Ordens Anterior`

```dax
VAR vTimeframe = SELECTEDVALUE(p_Timeframe[SelectedValue])
VAR IsMTDSelected  = SELECTEDVALUE(f_orders[mtd])
VAR IsMTDCalendarSelected = SELECTEDVALUE(f_orders[mtd_calendar_days])

VAR vPreviousMonth = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Ordens], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), d_calendar[mtd] = TRUE()),
        CALCULATE([Ordens], PARALLELPERIOD('d_calendar'[Date Key], -1, MONTH), REMOVEFILTERS(d_calendar[mtd]))
    )

VAR vPreviousDay = 
    IF(
        IsMTDSelected = TRUE(),
        CALCULATE([Ordens], DATEADD('d_calendar'[Date Key], -1, DAY), d_calendar[mtd] = TRUE()),
        CALCULATE([Ordens], DATEADD('d_calendar'[Date Key], -1, DAY), REMOVEFILTERS(d_calendar[mtd]))
    )

VAR vPreviousMonthMTDCalendar = ...
VAR vPreviousDayMTDCalendar = ...

RETURN
SWITCH(
    TRUE() && NOT ISBLANK([Ordens]),
    vTimeframe = "Date" && IsMTDSelected = TRUE(), vPreviousDay,
    vTimeframe = "Month" && IsMTDSelected = TRUE(), vPreviousMonth,
    vTimeframe = "Date" && IsMTDCalendarSelected = TRUE(), vPreviousDayMTDCalendar,
    vTimeframe = "Month" && IsMTDCalendarSelected = TRUE(), vPreviousMonthMTDCalendar,
    vTimeframe = "Date", vPreviousDay,
    vTimeframe = "Month", vPreviousMonth,
    BLANK()
)
```

Retorna o valor de `Ordens` no período anterior de acordo com a granularidade selecionada (`p_Timeframe`) e o modo MTD (dias úteis ou calendário). Suporta comparação dia anterior e mês anterior, tanto para MTD quanto para período completo.

---

### `PercentualCrescimento`

```dax
VAR OrdensAtual = [Ordens]
VAR OrdensAnterior = [Ordens Anterior]
RETURN
IF(
    NOT ISBLANK(OrdensAnterior) && NOT ISBLANK(OrdensAtual),
    (OrdensAtual - OrdensAnterior) / OrdensAnterior,
    BLANK()
)
```

Variação percentual de ordens em relação ao período anterior. Retorna BLANK quando não há dado anterior.

---

## Cotações FX

### `Max`

```dax
CALCULATE(MAX(d_trading_quotation[trading_quotation]))
```

Maior cotação FX no período selecionado.

---

### `Min`

```dax
CALCULATE(MIN(d_trading_quotation[trading_quotation]))
```

Menor cotação FX no período selecionado.

---

### `Median`

```dax
CALCULATE(MEDIAN(d_trading_quotation[trading_quotation]))
```

Cotação mediana FX no período selecionado.

---

## Auxiliares de Calendário

### `Última Data`

```dax
CALCULATE(
    MAX(d_calendar[Date Key]),
    d_calendar[mtd] = TRUE()
)
```

Última data dentro do MTD (dias úteis).

---

### `Último dia útil`

```dax
CALCULATE(
    MAX(d_calendar[workday]),
    d_calendar[mtd] = TRUE()
)
```

Número do último dia útil dentro do MTD.

---

### `Refresh Date`

```dax
MAX(d_last_update[last_update])
```

Timestamp da última atualização dos dados (current_timestamp − 3 horas).

---

## Funil de Drop-off

### `Total Users` *(tabela: `f_etapa_drop`)*

```dax
DISTINCTCOUNT(f_etapa_drop[id_customer])
```

Clientes únicos que passaram pelo funil mas não chegaram a realizar uma operação.

---

## Simulador de Spread

### `Valor Spread (What if?)` *(tabela: `p_Spread (What if?)`)*

```dax
SELECTEDVALUE('p_Spread (What if?)'[Spread (What if?)])
```

Retorna o spread selecionado no slider "What if?" (0% a 2%). Usado como multiplicador em `Receita Pendente (Forecast)`.
