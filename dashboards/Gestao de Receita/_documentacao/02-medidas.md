# Gestão de Receita — Glossário de Medidas DAX

## Resumo

| Tabela | Medidas |
|--------|---------|
| `Medidas` | 45 |
| `Cenários` | 7 |
| `KPI` | 1 (dinâmica) |
| `Cenários Delta Operações` | 1 |
| `Cenários Delta Spread` | 1 |
| **Total** | **55** |

---

## Tabela: Medidas

### Métricas de Volume

---

#### ⭐ Total operações

```dax
DISTINCTCOUNT(processed_operations[id_remittance])
```

Conta o número de operações de câmbio únicas processadas no período filtrado. Usa DISTINCTCOUNT para evitar duplicação caso o mesmo `id_remittance` apareça mais de uma vez nos dados.

---

#### ⭐ Total GMV

```dax
SUM(processed_operations[gmv])
```

Soma o volume bruto movimentado (Gross Merchandise Volume) — o valor total em reais das operações de câmbio. É o denominador base para cálculo de spread e representatividade.

---

#### ⭐ Total Gross Revenue

```dax
SUM(processed_operations[gross_revenue])
```

Soma a receita bruta de spread capturada em todas as operações do período. Representa o valor que entra antes de deduzir custos.

---

#### Total clientes únicos

```dax
DISTINCTCOUNT(processed_operations[id_customer])
```

Conta quantos clientes distintos realizaram ao menos uma operação no período filtrado. Diferente de `customer` (que agrega histórico), esta medida responde ao filtro de calendário.

---

#### Operaçoes por cliente

```dax
[Total operações] / [Total clientes únicos]
```

Indica a frequência média de uso no período: quantas operações cada cliente ativo realizou em média.

---

### Métricas de Spread e Variação

---

#### ⭐ Spread

```dax
[Total Gross Revenue] / [Total GMV]
```

Spread médio ponderado pelo GMV: quanto a Remessa Online captura de receita para cada real movimentado. Mede a eficiência de precificação agregada.

---

#### Spread medio

```dax
AVERAGE(processed_operations[spread])
```

Spread médio simples por operação (não ponderado por GMV). Diferente de `Spread` que é ponderado — útil para comparar com o spread anunciado ao cliente.

---

#### Mes anterior

```dax
CALCULATE([Total Gross Revenue], PREVIOUSMONTH(dcalendar[date_month]))
```

Gross Revenue do mês calendário imediatamente anterior ao período selecionado. Usado como base de comparação para variação percentual.

---

#### % variação

```dax
DIVIDE([Total Gross Revenue] - [Mes anterior], [Total Gross Revenue], 0)
```

Variação percentual da Gross Revenue em relação ao mês anterior. Positivo = crescimento; negativo = queda.

> ⚠️ A fórmula usa `[Total Gross Revenue]` como denominador (mês atual), não `[Mes anterior]`. Isso mede a contribuição incremental relativa ao mês atual, não o crescimento relativo à base anterior.

---

#### Cor variação

```dax
SWITCH(
    TRUE(),
    [% variação] < 0, "#B22222",
    [% variação] >= 0, "00FA9A",
    "00FA9A"
)
```

Retorna um código hexadecimal de cor para uso em formatação condicional: vermelho (`#B22222`) para queda, verde (`00FA9A`) para estabilidade ou crescimento.

---

### Métricas de Rentabilidade e Lucro

---

#### ⭐ Total Receita Líquida

```dax
SUM(processed_operations[net_revenue])
```

Receita líquida total — equivale à coluna `net_revenue` de `gold.fact_operations`, que já desconta todos os custos. É o "lucro por operação" acumulado. Inclui operações com lucro negativo.

---

#### Mediana lucro

```dax
MEDIAN(processed_operations[lucro])
```

Mediana do lucro por operação individual. Mais robusta que a média para detectar o comportamento típico, pois não é afetada por outliers (operações muito grandes ou prejuízos extremos).

---

#### P25 lucro

```dax
PERCENTILE.INC(processed_operations[lucro], 0.25)
```

Percentil 25 do lucro por operação — 25% das operações têm lucro abaixo deste valor. Junto com P75 forma a caixa do boxplot de distribuição de rentabilidade.

---

#### P75 lucro

```dax
PERCENTILE.INC(processed_operations[lucro], 0.75)
```

Percentil 75 do lucro por operação — 75% das operações têm lucro abaixo deste valor.

---

#### Total Lucro absoluto

```dax
CALCULATE(SUM(processed_operations[net_revenue]), ALLSELECTED())
```

Soma do lucro de todas as operações visíveis na tela (ignora filtros de linha mas respeita filtros de página). Usado como denominador para calcular `% lucro` comparativa entre segmentos.

---

#### Total prejuizo

```dax
CALCULATE(SUM(processed_operations[net_revenue]), processed_operations[Tipo Lucro] = "Negativo")
```

Soma do lucro apenas das operações com resultado negativo. Como `net_revenue` já é negativo nessas operações, o resultado é um valor negativo que representa o prejuízo total.

---

#### Total prejuizo ABS

```dax
-CALCULATE(SUM(processed_operations[net_revenue]), processed_operations[Tipo Lucro] = "Negativo")
```

Mesmo que `Total prejuizo` mas com sinal invertido — retorna o prejuízo como valor positivo para exibição em gráficos e cartões.

---

#### % lucro

```dax
DIVIDE(
    ABS([Total Receita Líquida]),
    ABS(CALCULATE(SUM(processed_operations[lucro]), ALLSELECTED()))
)
```

Participação do segmento filtrado no lucro total visível. Indica a representatividade de um grupo de operações na rentabilidade geral.

---

#### % prejuizo

```dax
ABS([Total prejuizo]) / [Total Gross Revenue]
```

Quanto do prejuízo das operações negativas representa em relação à receita bruta total. Indica a "taxa de destruição de receita" por operações ineficientes.

---

### Métricas de Custo

---

#### Total payout

```dax
SUM(processed_operations[payout_affiliate]) + SUM(processed_operations[partner_commissioning])
```

Total de pagamentos a terceiros: comissões a afiliados (`payout_affiliate`) mais comissões a parceiros (`partner_commissioning`). Representa o custo de canal de distribuição.

---

#### Total take

```dax
SUM(processed_operations[bank_take])
```

Custo cobrado pelo banco correspondente (bank take) — o valor que o banco parceiro retém na operação. É um custo direto da operação de câmbio.

---

#### Total mensageria

```dax
SUM(processed_operations[real_message_cost])
```

Custo real de mensageria (SWIFT, transferência internacional) por operação. Representa o custo de transmissão dos recursos ao beneficiário.

---

#### Total custo

```dax
VAR custo_total = ABS([Total payout]) + ABS([Total mensageria]) + ABS([Total take])
RETURN custo_total
```

Custo operacional total = payout + mensageria + bank take. Usa ABS() pois esses custos podem estar armazenados como negativos nas operações.

> **Nota:** Esta definição de custo total não inclui `cost_bacen` nem `cost_funding`, que existem em `gold.fact_operations` mas não estão neste cálculo.

---

#### % custo

```dax
VAR custo_total = [Total custo]
RETURN custo_total / [Total Gross Revenue]
```

Percentual do custo operacional total sobre a receita bruta. Quanto da receita é "consumida" por custos diretos.

---

#### % custo mensageria

```dax
VAR custo_total = ABS([Total mensageria])
RETURN custo_total / [Total Gross Revenue]
```

Representatividade do custo de mensageria sobre a receita bruta. Operações com envio Swift tendem a ter mensageria mais cara.

---

#### % custo comissão

```dax
VAR custo_total = ABS([Total payout])
RETURN custo_total / [Total Gross Revenue]
```

Representatividade dos pagamentos a afiliados e parceiros sobre a receita bruta. Indica o custo do canal de aquisição.

---

#### % custo take

```dax
VAR custo_total = ABS([Total take])
RETURN custo_total / [Total Gross Revenue]
```

Representatividade do bank take sobre a receita bruta. Operações via banco parceiro têm este custo.

---

#### Média mensageria

```dax
AVERAGE(processed_operations[despesa_real])
```

Custo médio de mensageria por operação. `despesa_real` é alias de `real_message_cost` no modelo. Útil para benchmarking por moeda ou destino.

---

#### Média Custo

```dax
AVERAGE(processed_operations[custo_total])
```

Custo total médio por operação. `custo_total` é coluna calculada (DAX) em `processed_operations` = payout + mensageria + partner_commissioning + bank_take.

---

#### Média Gross Revenue

```dax
AVERAGE(processed_operations[gross_revenue])
```

Receita bruta média por operação — ticket médio de receita. Equivalente ao GMV médio multiplicado pelo spread médio.

---

#### Média Tarifa

```dax
AVERAGE(processed_operations[tariff])
```

Tarifa média cobrada por operação. Operações sem tarifa têm valor zero.

---

### Métricas de Participação

---

#### % operações

```dax
DIVIDE(
    [Total operações],
    CALCULATE(DISTINCTCOUNT(processed_operations[id_remittance]), ALLSELECTED())
)
```

Participação do segmento filtrado no total de operações visível (ALLSELECTED respeita filtros de página mas remove filtros de linha). Usado em tabelas de decomposição.

---

#### % operações (Graf)

```dax
DIVIDE(
    [Total operações],
    CALCULATE(DISTINCTCOUNT(processed_operations[id_remittance]))
)
```

Semelhante a `% operações` mas sem ALLSELECTED — usa o contexto de filtro completo. Versão para gráficos de barras empilhadas.

---

#### % ops negativas

```dax
VAR ops_negativas = CALCULATE(
    DISTINCTCOUNT(processed_operations[id_remittance]),
    processed_operations[Tipo Lucro] = "Negativo"
)
RETURN DIVIDE(ops_negativas, [Total operações], 0)
```

Percentual de operações que geraram lucro negativo no período. Indicador de qualidade da precificação — alto % indica operações abaixo do custo.

---

#### % clientes

```dax
DIVIDE(
    [Total clientes únicos],
    CALCULATE(DISTINCTCOUNT(processed_operations[id_customer]), ALLSELECTED())
)
```

Participação do segmento filtrado no total de clientes visível. Usado em tabelas de decomposição por dimensão.

---

### Métricas de Clientes (displayFolder: .Métricas clientes)

Estas medidas operam sobre a tabela `customer`, que agrega métricas históricas por cliente independentemente de filtro de calendário.

---

#### Clientes negativados

```dax
CALCULATE(
    DISTINCTCOUNT(customer[id_customer]),
    customer[receita_liquida] < 0
)
```

Clientes cujo saldo histórico acumulado de lucro é negativo — custaram mais do que geraram em receita líquida.

---

#### Clientes positivados

```dax
CALCULATE(
    DISTINCTCOUNT(customer[id_customer]),
    customer[receita_liquida] > 0, customer[ops_negativas] > 0
)
```

Clientes com saldo positivo **que também tiveram ao menos uma operação negativa** — lucrativos no total mas com histórico misto.

---

#### Clientes pelo menos 1 negativa

```dax
CALCULATE(
    DISTINCTCOUNT(customer[id_customer]),
    customer[ops_negativas] > 0
)
```

Clientes que tiveram ao menos uma operação que gerou prejuízo, independentemente do saldo total.

---

#### Clientes positivos

```dax
CALCULATE(
    DISTINCTCOUNT(customer[id_customer]),
    customer[receita_liquida] > 0
)
```

Clientes com saldo histórico positivo — geraram mais receita líquida do que custos ao longo de todo o histórico.

---

#### Clientes mais moedas

```dax
CALCULATE(
    DISTINCTCOUNT(customer[id_customer]),
    customer[currency] > 1
)
```

Clientes que operaram com mais de uma moeda ao longo do histórico. Indica diversificação de uso do produto.

---

#### # operações

```dax
SUM(customer[qtde_ops])
```

Total de operações somado a partir da tabela `customer` (histórico por cliente). Diferente de `Total operações` que conta da tabela `processed_operations` com filtro de calendário.

---

#### % Clientes mais moedas

```dax
[Clientes mais moedas] / [Total clientes únicos]
```

Percentual dos clientes ativos que operam com mais de uma moeda.

---

#### % Clientes negativados

```dax
[Clientes negativados] / [Total clientes únicos]
```

Percentual dos clientes ativos que têm saldo histórico negativo.

---

#### % Clientes pelo menos 1 negativa

```dax
[Clientes pelo menos 1 negativa] / [Total clientes únicos]
```

Percentual dos clientes ativos que tiveram ao menos uma operação com prejuízo.

---

#### % Clientes positivados

```dax
[Clientes positivados] / [Total clientes únicos]
```

Percentual dos clientes ativos que têm saldo positivo mas histórico misto (ao menos uma negativa).

---

## Tabela: Cenários

Medidas do simulador de cenários — projetam o impacto de variações hipotéticas de volume e spread na receita.

---

#### ⚠️ Total Gross Revenue - Cenário

```dax
SUMX(
    'processed_operations',
    1 * (1 + 'Cenários Delta Operações'[Valor Operações]) * processed_operations[gmv] *
    ((processed_operations[spread_revenue] / processed_operations[gmv]) * (1 + 'Cenários Delta Spread'[Valor Delta Spread])) + processed_operations[tariff]
)
```

Simula a Gross Revenue dado um delta de volume (mais/menos operações) e um delta de spread. Para cada operação: multiplica o GMV pelo fator de volume, aplica o novo spread ajustado pelo delta, e adiciona a tarifa fixa. Permite responder "se o volume crescer X% e o spread subir Y%, qual seria a receita?".

> ⚠️ Medida complexa (usa SUMX + 2 parâmetros externos + 3 colunas). Depende dos sliders `Cenários Delta Operações` e `Cenários Delta Spread`.

---

#### Total operações - Cenário

```dax
SUMX(
    'processed_operations',
    1 * (1 + 'Cenários Delta Operações'[Valor Operações])
)
```

Número simulado de operações dado o delta de volume. Para cada linha existente, aplica o fator multiplicador. Delta = 0 retorna o número atual; delta = 0.10 simula +10% de volume.

---

#### % spread

```dax
SUMX(processed_operations, processed_operations[spread_revenue]) /
SUMX(processed_operations, processed_operations[gmv]) * (1 + 'Cenários Delta Spread'[Valor Delta Spread])
```

Spread percentual ajustado pelo delta de spread do cenário. Mostra o spread projetado após a variação simulada.

---

#### Mes anterior - Cenário

```dax
CALCULATE([Total Gross Revenue - Cenário], PREVIOUSMONTH(dcalendar[date_month]))
```

Gross Revenue do cenário simulado para o mês anterior. Usado para calcular a variação percentual no contexto do cenário.

---

#### % variação - Cenário

```dax
DIVIDE([Total Gross Revenue - Cenário] - [Mes anterior], [Total Gross Revenue - Cenário], 0)
```

Variação percentual da receita no cenário simulado em relação ao mês anterior.

---

#### Cor variação - Cenário

```dax
SWITCH(
    TRUE(),
    [% variação - Cenário] < 0, "#B22222",
    [% variação - Cenário] >= 0, "00FA9A",
    "00FA9A"
)
```

Cor condicional para o card de variação do cenário. Mesma lógica que `Cor variação` da tabela Medidas.

---

#### Last Update

```dax
MAX(processed_operations[last_update])
```

Data e hora da última atualização dos dados de operações. A coluna `last_update` em `processed_operations` é calculada como `current_timestamp() - 3h` no momento da carga no Databricks.

---

## Tabela: KPI

---

#### ⚠️ Metricas de operações

```dax
SWITCH(
    SELECTEDVALUE('KPI'[KPI]),
    "GMV", [Total GMV],
    "Gross Revenue", [Total Gross Revenue],
    "Operações", [Total operações],
    "Clientes únicos", [Total clientes únicos],
    "Operações por clientes", [Operaçoes por cliente],
    BLANK()
)
```

Medida dinâmica que retorna a métrica correspondente ao item selecionado no seletor KPI. Permite que um único visual exiba 5 métricas diferentes conforme a escolha do usuário. Retorna BLANK() quando nenhuma opção está selecionada.

---

## Tabela: Cenários Delta Operações

---

#### Valor Operações

```dax
SELECTEDVALUE('Cenários Delta Operações'[Operações], 0)
```

Retorna o valor selecionado no slider de delta de operações (entre -1 e +1, em passos de 0.01). Default = 0 (sem alteração). Alimenta `Total Gross Revenue - Cenário` e `Total operações - Cenário`.

---

## Tabela: Cenários Delta Spread

> A medida `Valor Delta Spread` é análoga a `Valor Operações` — retorna o valor do slider de delta de spread. Alimenta `Total Gross Revenue - Cenário` e `% spread`.

---

## Índice por tema

| Tema | Medidas |
|------|---------|
| **Volume** | Total operações, Total GMV, Total clientes únicos, Operaçoes por cliente |
| **Receita** | ⭐ Total Gross Revenue, ⭐ Total Receita Líquida, Média Gross Revenue |
| **Spread** | ⭐ Spread, Spread medio, % spread (Cenário) |
| **Variação MoM** | Mes anterior, % variação, Cor variação |
| **Distribuição lucro** | Mediana lucro, P25 lucro, P75 lucro |
| **Prejuízo** | Total prejuizo, Total prejuizo ABS, % prejuizo, % ops negativas |
| **Custos** | Total payout, Total take, Total mensageria, Total custo, Média Custo, Média mensageria, Média Tarifa |
| **% de custo** | % custo, % custo mensageria, % custo comissão, % custo take |
| **Participação** | % operações, % operações (Graf), % lucro, % clientes |
| **Clientes (histórico)** | Clientes negativados, Clientes positivados, Clientes positivos, Clientes pelo menos 1 negativa, Clientes mais moedas, # operações |
| **% clientes** | % Clientes negativados, % Clientes positivados, % Clientes pelo menos 1 negativa, % Clientes mais moedas |
| **Cenários** | Total Gross Revenue - Cenário, Total operações - Cenário, % spread, Mes anterior - Cenário, % variação - Cenário, Cor variação - Cenário |
| **Meta / Controle** | Last Update, Valor Operações, Metricas de operações |
