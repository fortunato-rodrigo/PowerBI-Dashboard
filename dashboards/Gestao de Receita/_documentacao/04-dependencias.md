# Gestão de Receita — Mapa de Dependências

## Árvore de dependências das medidas principais

```
Total Gross Revenue
└── SUM(processed_operations[gross_revenue])
    └── gold.fact_operations.gross_revenue

Total GMV
└── SUM(processed_operations[gmv])
    └── gold.fact_operations.gmv

Total operações
└── DISTINCTCOUNT(processed_operations[id_remittance])
    └── gold.fact_operations.id_remittance

Total clientes únicos
└── DISTINCTCOUNT(processed_operations[id_customer])
    └── gold.fact_operations.id_customer

Total Receita Líquida
└── SUM(processed_operations[net_revenue])
    └── gold.fact_operations.net_revenue

Spread
├── [Total Gross Revenue]
└── [Total GMV]

Operaçoes por cliente
├── [Total operações]
└── [Total clientes únicos]

Mes anterior
├── [Total Gross Revenue]
└── dcalendar[date_month]   (via relacionamento)

% variação
├── [Total Gross Revenue]
└── [Mes anterior]

Cor variação
└── [% variação]

Total custo
├── [Total payout]
│   └── SUM(processed_operations[payout_affiliate]) + SUM(processed_operations[partner_commissioning])
├── [Total mensageria]
│   └── SUM(processed_operations[real_message_cost])
└── [Total take]
    └── SUM(processed_operations[bank_take])

% custo
├── [Total custo]
└── [Total Gross Revenue]

% custo mensageria
├── [Total mensageria]
└── [Total Gross Revenue]

% custo comissão
├── [Total payout]
└── [Total Gross Revenue]

% custo take
├── [Total take]
└── [Total Gross Revenue]

% ops negativas
├── CALCULATE(..., processed_operations[Tipo Lucro] = "Negativo")
│   └── processed_operations[Tipo Lucro]  (coluna calculada DAX)
│       └── processed_operations[lucro]   (coluna alias = net_revenue)
└── [Total operações]

Total prejuizo
└── CALCULATE(SUM(net_revenue), processed_operations[Tipo Lucro] = "Negativo")
    └── processed_operations[Tipo Lucro]

Total prejuizo ABS
└── -[Total prejuizo]

% prejuizo
├── [Total prejuizo]
└── [Total Gross Revenue]

Total Lucro absoluto
└── CALCULATE(SUM(processed_operations[net_revenue]), ALLSELECTED())

% lucro
├── [Total Receita Líquida]
└── [Total Lucro absoluto]

% operações
├── [Total operações]
└── CALCULATE(DISTINCTCOUNT, ALLSELECTED())

% clientes
├── [Total clientes únicos]
└── CALCULATE(DISTINCTCOUNT, ALLSELECTED())

Clientes negativados
└── CALCULATE(DISTINCTCOUNT(customer[id_customer]), customer[receita_liquida] < 0)
    └── customer[receita_liquida]   (sem relacionamento com calendário)

Clientes positivados
└── CALCULATE(DISTINCTCOUNT, receita_liquida > 0, ops_negativas > 0)
    └── customer[receita_liquida], customer[ops_negativas]

Clientes pelo menos 1 negativa
└── CALCULATE(DISTINCTCOUNT, customer[ops_negativas] > 0)

Clientes positivos
└── CALCULATE(DISTINCTCOUNT, customer[receita_liquida] > 0)

Clientes mais moedas
└── CALCULATE(DISTINCTCOUNT, customer[currency] > 1)

% Clientes negativados
├── [Clientes negativados]
└── [Total clientes únicos]

% Clientes positivados
├── [Clientes positivados]
└── [Total clientes únicos]

% Clientes pelo menos 1 negativa
├── [Clientes pelo menos 1 negativa]
└── [Total clientes únicos]

% Clientes mais moedas
├── [Clientes mais moedas]
└── [Total clientes únicos]

# operações
└── SUM(customer[qtde_ops])

Metricas de operações  (medida dinâmica)
├── SELECTEDVALUE('KPI'[KPI])
├── [Total GMV]
├── [Total Gross Revenue]
├── [Total operações]
├── [Total clientes únicos]
└── [Operaçoes por cliente]
```

---

## Medidas dos Cenários

```
Total Gross Revenue - Cenário  ⚠️
├── SUMX(processed_operations, ...)
│   ├── processed_operations[gmv]
│   ├── processed_operations[spread_revenue]
│   ├── processed_operations[tariff]
│   ├── 'Cenários Delta Operações'[Valor Operações]  (parâmetro)
│   └── 'Cenários Delta Spread'[Valor Delta Spread]  (parâmetro)
└── (iteração linha a linha)

Total operações - Cenário
├── SUMX(processed_operations, ...)
└── 'Cenários Delta Operações'[Valor Operações]

% spread
├── SUMX(processed_operations[spread_revenue])
├── SUMX(processed_operations[gmv])
└── 'Cenários Delta Spread'[Valor Delta Spread]

Mes anterior - Cenário
├── [Total Gross Revenue - Cenário]
└── dcalendar[date_month]

% variação - Cenário
├── [Total Gross Revenue - Cenário]
└── [Mes anterior]   ← usa Mes anterior da tabela Medidas (não o de Cenário)

Cor variação - Cenário
└── [% variação - Cenário]

Valor Operações  (Cenários Delta Operações)
└── SELECTEDVALUE('Cenários Delta Operações'[Operações], 0)
```

---

## Referência reversa — quais medidas dependem de cada coluna-chave

| Coluna de origem | Medidas dependentes |
|-----------------|---------------------|
| `processed_operations[gross_revenue]` | Total Gross Revenue, Spread, % variação, % custo, % prejuizo, Média Gross Revenue, Total Lucro absoluto (indireta) |
| `processed_operations[gmv]` | Total GMV, Spread, Total Gross Revenue - Cenário, % spread |
| `processed_operations[net_revenue]` | Total Receita Líquida, Total prejuizo, Total prejuizo ABS, % lucro |
| `processed_operations[lucro]` | Mediana lucro, P25 lucro, P75 lucro, Total Lucro absoluto (alias de net_revenue) |
| `processed_operations[id_remittance]` | Total operações, % operações, % operações (Graf), % ops negativas |
| `processed_operations[id_customer]` | Total clientes únicos, % clientes |
| `processed_operations[real_message_cost]` | Total mensageria, % custo mensageria, Média mensageria |
| `processed_operations[bank_take]` | Total take, % custo take |
| `processed_operations[payout_affiliate]` | Total payout, % custo comissão |
| `processed_operations[partner_commissioning]` | Total payout, % custo comissão |
| `processed_operations[Tipo Lucro]` | % ops negativas, Total prejuizo, Total prejuizo ABS |
| `processed_operations[custo_total]` | Média Custo |
| `processed_operations[spread_revenue]` | Total Gross Revenue - Cenário, % spread |
| `processed_operations[tariff]` | Total Gross Revenue - Cenário, Média Tarifa |
| `processed_operations[spread]` | Spread medio |
| `processed_operations[last_update]` | Last Update |
| `customer[receita_liquida]` | Clientes negativados, Clientes positivados, Clientes positivos |
| `customer[ops_negativas]` | Clientes pelo menos 1 negativa, Clientes positivados |
| `customer[currency]` | Clientes mais moedas |
| `customer[qtde_ops]` | # operações |
| `dcalendar[date_month]` | Mes anterior, Mes anterior - Cenário |
| `'Cenários Delta Operações'[Valor Operações]` | Total Gross Revenue - Cenário, Total operações - Cenário |
| `'Cenários Delta Spread'[Valor Delta Spread]` | Total Gross Revenue - Cenário, % spread |
| `'KPI'[KPI]` | Metricas de operações |

---

## Medidas isoladas (sem dependência de outras medidas)

Estas medidas são atômicas — dependem apenas de colunas de tabelas fonte:

| Medida | Coluna(s) fonte |
|--------|----------------|
| Total operações | `processed_operations[id_remittance]` |
| Total GMV | `processed_operations[gmv]` |
| Total Gross Revenue | `processed_operations[gross_revenue]` |
| Total clientes únicos | `processed_operations[id_customer]` |
| Total Receita Líquida | `processed_operations[net_revenue]` |
| Total mensageria | `processed_operations[real_message_cost]` |
| Total take | `processed_operations[bank_take]` |
| Mediana lucro | `processed_operations[lucro]` |
| P25 lucro | `processed_operations[lucro]` |
| P75 lucro | `processed_operations[lucro]` |
| Spread medio | `processed_operations[spread]` |
| Média mensageria | `processed_operations[despesa_real]` |
| Média Custo | `processed_operations[custo_total]` |
| Média Gross Revenue | `processed_operations[gross_revenue]` |
| Média Tarifa | `processed_operations[tariff]` |
| # operações | `customer[qtde_ops]` |
| Last Update | `processed_operations[last_update]` |
| Clientes negativados | `customer[receita_liquida]` |
| Clientes positivos | `customer[receita_liquida]` |
| Clientes mais moedas | `customer[currency]` |
| Clientes pelo menos 1 negativa | `customer[ops_negativas]` |

---

## Medidas órfãs

Não foram identificadas medidas órfãs — todas as medidas do modelo estão referenciadas em pelo menos um visual ou são dependência de outra medida ativa.

> **Observação:** `Total Lucro absoluto` só é usada internamente por `% lucro`. Se `% lucro` for removida, `Total Lucro absoluto` ficaria órfã.
