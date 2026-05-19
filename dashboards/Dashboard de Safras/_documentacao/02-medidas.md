# Dashboard de Safras — Glossário de Medidas DAX

Todas as medidas estão na tabela `# Medidas`, pasta `Funnel Events`.

**Convenções:**
- ⭐ KPI estratégico
- ⚠️ Medida complexa (5+ funções DAX)
- Formato dinâmico: medidas com `formatStringDefinition` adaptam o sufixo (K, M, B) conforme o valor

---

## Grupo 1 — Métricas de Volume (Funnel Base)

### Presignups ⭐

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "PRESIGNUP"
)
```

**Explicação:** Conta o número de clientes únicos que iniciaram o processo de cadastro (etapa de Presignup). É o topo do funil — todo cliente começa aqui.

---

### Signups

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "SIGNUP"
)
```

**Explicação:** Clientes que concluíram o cadastro completo. Segunda etapa do funil.

---

### Aquisições ⭐

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "ACQUISITION"
)
```

**Explicação:** Clientes que realizaram a primeira operação de câmbio — considera-se que o cliente foi "adquirido" neste momento. Métrica principal de ativação.

---

### Clientes Únicos

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "OPERATION" || f_funnel_events[event_type] = "ACQUISITION"
)
```

**Explicação:** Clientes que realizaram ao menos uma operação (inclui a primeira — aquisição — e as subsequentes). Mede a base ativa de clientes operantes.

---

### Operações

```dax
CALCULATE(
    COUNT(f_funnel_events[event_id]),
    f_funnel_events[event_type] in {"OPERATION", "ACQUISITION"}
)
```

**Explicação:** Total de transações de câmbio realizadas, incluindo a primeira (aquisição) e as subsequentes. Diferente de Clientes Únicos — um mesmo cliente pode ter N operações.

---

### Histórias Aprovadas

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[event_id]),
    f_funnel_events[event_type] = "APPROVED STORY"
)
```

**Explicação:** Quantidade de eventos de aprovação de histórico de crédito. Relevante para a jornada PJ.

---

### Eventos

```dax
DISTINCTCOUNT(f_funnel_events[event_id])
```

**Explicação:** Total de eventos únicos registrados, sem filtro de tipo. Medida genérica usada como base para visuais de funil.

---

## Grupo 2 — Métricas Financeiras

### GMV ⭐

```dax
CALCULATE(
    SUM(f_funnel_events[gmv]),
    f_funnel_events[event_type] in {"OPERATION", "ACQUISITION"}
)
```

**Explicação:** Gross Merchandise Volume — volume total em R$ de operações de câmbio realizadas. Considera aquisições e operações subsequentes.

---

### Gross Revenue

```dax
CALCULATE(
    SUM(f_funnel_events[gross_revenue]),
    f_funnel_events[event_type] in {"OPERATION", "ACQUISITION"}
)
```

**Explicação:** Receita bruta gerada pelas operações de câmbio. Diferente do GMV — representa o spread/taxa cobrado.

---

### Operações por Cliente

```dax
DIVIDE([Operações], [Clientes Únicos], BLANK())
```

**Explicação:** Frequência média de operações por cliente ativo. Indicador de engajamento e recorrência.

---

## Grupo 3 — Cohort do Presignup (PSU)

> Cohort: análise que rastreia uma "safra" (grupo de clientes do mesmo mês de origem) ao longo do tempo.

### Aquisições Cohortadas do Presignup ⭐

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "PRESIGNUP",
    f_funnel_events[Mês da Aquisição] <> BLANK()
)
```

**Explicação:** Clientes que fizeram Presignup E já converteram em Aquisição em algum momento (mesmo mês ou meses seguintes). O filtro `Mês da Aquisição <> BLANK()` garante que só conta quem chegou a converter.

---

### Aquisições Cohortadas do Presignup | Mesmo Mês

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "PRESIGNUP",
    NOT ISBLANK(f_funnel_events[Mês da Aquisição]),
    f_funnel_events[Month PSU = Month ACQ] = TRUE()
)
```

**Explicação:** Clientes do Presignup que converteram no mesmo mês em que fizeram o presignup. Indica conversão imediata.

---

### Aquisições Cohortadas do Presignup | Meses Seguintes

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "PRESIGNUP",
    f_funnel_events[Mês da Aquisição] <> BLANK(),
    f_funnel_events[Month PSU = Month ACQ] = FALSE()
)
```

**Explicação:** Clientes do Presignup que converteram em meses posteriores ao presignup. Indica conversão tardia — importante para entender o "long tail" da safra.

---

### Aquisições Cohortadas do Presignup - Acumulado ⚠️

```dax
CALCULATE(
    [Aquisições Cohortadas do Presignup],
    FILTER(
        ALL(d_calendar),
        'd_calendar'[Date Key] <= MAX(f_funnel_events[event_date])
        && 'd_calendar'[date_month] = MAX('d_calendar'[date_month])
    )
)
```

**Explicação:** Total acumulado de aquisições cohortadas até a data mais recente disponível no mês atual. Usado para calcular a conversão acumulada do mês corrente.

---

### Aquisições Cohortadas do Presignup - Média Móvel Últimos 6 meses ⚠️

```dax
CALCULATE(
    [Aquisições Cohortadas do Presignup] / DISTINCTCOUNT(f_funnel_events[event_month]),
    DATESINPERIOD(
        d_calendar[Date Key],
        MAX(f_funnel_events[event_date]),
        SELECTEDVALUE('d_intervalo_meses'[Interval]),
        MONTH
    )
)
```

**Explicação:** Média mensal de aquisições cohortadas no intervalo de meses selecionado pelo usuário (via slicer `d_intervalo_meses`). Suaviza variações sazonais.

---

### Aquisições Cohortadas do Presignup | Cohort Dinâmico ⚠️

```dax
VAR DiasSelecionados = SELECTEDVALUE('p_Cohort'[SelectedValue])
RETURN
CALCULATE(
    [Aquisições Cohortadas do Presignup],
    f_funnel_events[Diferença de Dias entre Presignup e Aquisição] <= DiasSelecionados
)
```

**Explicação:** Aquisições cohortadas filtradas para clientes que converteram dentro do número de dias selecionado (ex: dentro de 30 dias do presignup). Permite análise de velocidade de conversão.

---

## Grupo 4 — Cohort do Signup (SU)

### Aquisições Cohortadas do Signup

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "SIGNUP",
    f_funnel_events[Mês da Aquisição] <> BLANK()
)
```

**Explicação:** Clientes que fizeram Signup E já converteram em Aquisição. Equivalente ao cohort de PSU, mas com origem no Signup.

---

### Aquisições Cohortadas do Signup | Mesmo Mês / Meses Seguintes

Variantes do cohort SU com filtros de `Month SU = Month ACQ`. Mesma lógica do cohort PSU, com ponto de origem no Signup.

---

### Signups Cohortados do Presignup ⭐

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "PRESIGNUP",
    f_funnel_events[signup_date] <> BLANK()
)
```

**Explicação:** Clientes do Presignup que chegaram a completar o Signup. Mede a conversão da primeira para a segunda etapa do funil.

---

## Grupo 5 — Taxas de Conversão Cohortadas

### Conversão Cohortada (ACQ/PSU) ⭐

```dax
DIVIDE(
    [Aquisições Cohortadas do Presignup],
    [Presignups],
    BLANK()
)
```

**Explicação:** Percentual de Presignups que chegaram a se tornar Aquisições (em qualquer mês). Principal KPI de conversão do funil.

---

### Conversão Cohortada (ACQ/PSU) | Mesmo Mês

```dax
DIVIDE(
    [Aquisições Cohortadas do Presignup | Mesmo Mês],
    [Presignups],
    BLANK()
)
```

**Explicação:** Taxa de conversão PSU→ACQ no mesmo mês. Indica a "conversão rápida".

---

### Conversão Cohortada (ACQ/PSU) | Meses Seguintes

Conversão de PSU para ACQ em meses posteriores — "conversão lenta".

---

### Conversão Cohortada (ACQ/SU) / (SU/PSU)

Variantes para as etapas Signup→Aquisição e Presignup→Signup. Permitem identificar em qual etapa o funil está perdendo clientes.

---

### Conversão Cohortada Acumulada (ACQ/PSU) ⚠️

```dax
DIVIDE(
    [Aquisições Cohortadas do Presignup - Acumulado],
    [Presignups (Acumulado)],
    BLANK()
)
```

**Explicação:** Taxa de conversão acumulada até o dia atual dentro do mês corrente. Compara o ritmo atual vs. meses anteriores já completos.

---

### Conversão Uncohorted (ACQ/PSU)

```dax
DIVIDE([Aquisições], [Presignups], BLANK())
```

**Explicação:** Conversão sem cohort — divide aquisições do período por presignups do mesmo período, independente de quando cada cliente iniciou. Útil como comparativo simples ao lado do cohortado.

---

## Grupo 6 — Segunda Operação

### Segunda Operação (Cohorted)

```dax
CALCULATE(
    DISTINCTCOUNT(f_funnel_events[id_customer]),
    f_funnel_events[event_type] = "OPERATION",
    NOT ISBLANK(f_funnel_events[second_operation_month])
)
```

**Explicação:** Clientes que realizaram ao menos uma segunda operação após a aquisição. Medida de retenção/recorrência.

---

## Grupo 7 — Medidas Dinâmicas

### Aquisições Dinâmicas - Diferença de Meses ⚠️

```dax
VAR ExibicaoSelecionada = SELECTEDVALUE('p_Modo de Exibição'[Exibição], "#")
VAR TotalLinha = CALCULATE([Aquisições], ALL('f_funnel_events'[Diferença de Meses]))
VAR ValorFinal = SWITCH(TRUE(),
    ExibicaoSelecionada = "%", DIVIDE([Aquisições], TotalLinha, 0),
    [Aquisições])
RETURN SWITCH(ExibicaoSelecionada,
    "%", FORMAT(ValorFinal, "0.0%"),
    FORMAT(ValorFinal, "#,##0"))
```

**Explicação:** Exibe aquisições agrupadas por diferença de meses entre PSU e ACQ, podendo alternar entre valor absoluto (#) e percentual (%). Controlado pelo slicer `p_Modo de Exibição`.

---

### Aquisições Dinâmicas - Diferença de Dias

Mesma lógica, agrupando por `diff_days_psu_to_acq_category` em vez de meses.

---

## Grupo 8 — Proporções (% do Total)

Padrão: `DIVIDE([Medida Base], CALCULATE([Medida Base], ALLSELECTED(dimensão)), BLANK())`

| Medida | Base | Dimensão ALLSELECTED |
|--------|------|---------------------|
| % do Total de Presignups | Presignups | Mês do Presignup |
| % do Total de Aquisições (PSU - Cohorted) | Aquisições Cohortadas PSU | Mês do Presignup |
| % do Total de Aquisições (SU - Cohorted) | Aquisições Cohortadas SU | Mês do Signup |
| % do Total de Clientes Únicos | Clientes Únicos | Mês da Operação |
| % do Total de Operações | Operações | Mês da Operação |
| % do Total de GMV | GMV | Mês da Operação |
| % do Total de Gross Revenue | Gross Revenue | Mês da Operação |

**Explicação:** Todas calculam a participação percentual de uma linha (ex: mês específico) sobre o total selecionado. Usadas em matrizes cohort para mostrar distribuição relativa.

---

## Grupo 9 — KPIs de Tendência ⚠️

### Total de Presignups - KPI Limpo ⚠️

```dax
SWITCH(TRUE(),
    ISBLANK([Presignups]) ||
    [Total de Presignups - KPI] < 0 ||
    [Total de Presignups - KPI] = 1 ||
    min(f_funnel_events[Mês do Presignup]) < 0, BLANK(),
    min(f_funnel_events[Mês do Presignup]) = 0, 0.05,
    [Total de Presignups - KPI]
)
```

**Explicação:** Normaliza o valor de Presignups numa escala 0-1 (mínimo-máximo histórico), com filtros para remover valores extremos. Usado em visuais de KPI sparkline ou heatmap.

---

## Grupo 10 — Auxiliares e Visuais

| Medida | Descrição |
|--------|-----------|
| `Refresh Date` | `MAX(d_last_update[last_update])` — exibe data/hora da última atualização |
| `LineColor` | Retorna cor (#hex) baseada em Current Month / Previous Month / Outros |
| `Texto Conversão PSU` | Retorna a string `"CR PSU"` (rótulo estático para visuais) |
| `Cohort Dinâmico Selecionado` | Texto concatenado: "Cohort Dinâmico Selecionado: X dias" |
| `Cadastro 100% Preenchido` | % de presignups com cadastro completamente preenchido |
| `Eventos - Desloc Barra %` | Texto formatado para exibição de % no visual de funil |
| `Eventos - Desloc Barra Anterior %` | % vs. etapa anterior do funil (usando OFFSET) |
| `Aquisições (Current Month)` | Aquisições filtradas para "Current Month" via d_calendar |
| `Aquisições Previous Month` | Aquisições do "Previous Month" |
| `Histórias Aprovadas Cohortadas` | Aquisições cohortadas a partir de Histórias Aprovadas |
| `Conversão (ACQ/APPROVED STORY)` | Taxa de conversão de Histórias Aprovadas para Aquisição |

---

## Divisões de Segmentação Cohort

Medidas de divisão (percentual dentro de cada coorte):

| Medida | Descrição |
|--------|-----------|
| `Divisão das Aquisições - Mesmo mês do PSU` | % das aquisições cohortadas que converteram no mesmo mês |
| `Divisão das Aquisições - Meses Seguintes do PSU` | % que converteram em meses seguintes |
| `Divisão dos Signups - Mesmo Mês do PSU` | % dos signups cohortados que ocorreram no mesmo mês do PSU |
| `Divisão dos Signups - Meses Seguintes do PSU` | % dos signups em meses seguintes |
