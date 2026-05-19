# Scorecard - Business Performance — Dependências

Grafo de dependências entre medidas. Útil pra entender o impacto de mudanças e priorizar refator.

> **Voltar pra:** [03 · Relacionamentos](03-relacionamentos.md)

---

## Árvores por medida-raiz

Medidas-raiz são as que não são usadas por nenhuma outra. Mostram a árvore descendente até chegar nas colunas-folha.

### Medidas de crescimento formatado (raízes — nenhuma outra medida depende delas)

```
GMV Growth Format %
└─ GMV Growth
   ├─ GMV
   │  └─ f_operations[gmv]
   └─ GMV Anterior
      └─ GMV  (já mapeada)
      └─ p_timeframe[SelectedValue]
      └─ d_calendar[mtd]

Gross Revenue Growth Format %
└─ Gross Revenue Growth
   ├─ Gross Revenue
   │  └─ f_operations[gross_revenue]
   └─ Gross Revenue Anterior
      └─ Gross Revenue  (já mapeada)

Gross Profit Growth Format %
└─ Gross Profit Growth
   ├─ Gross Profit
   │  └─ f_operations[gross_profit]
   └─ Gross Profit Anterior
      └─ Gross Profit  (já mapeada)

Operations Growth Format %
└─ Operations Growth
   ├─ Operations
   │  └─ f_operations[id_remittance]
   └─ Operations Anterior
      └─ Operations  (já mapeada)

Customers Growth Format %
└─ Customers Growth
   ├─ Customers
   │  └─ f_operations[id_customer]
   └─ Customers Anterior
      └─ Customers  (já mapeada)

AVG Ticket GMV Growth Format %
└─ AVG Ticket GMV Growth
   ├─ AVG Ticket GMV
   │  ├─ GMV  (já mapeada)
   │  └─ Operations  (já mapeada)
   └─ AVG Ticket GMV Anterior
      ├─ GMV Anterior  (já mapeada)
      └─ Operations Anterior  (já mapeada)

Operations by Customer Growth Format %
└─ Operations by Customer Growth
   ├─ Operations by Customer
   │  ├─ Operations  (já mapeada)
   │  └─ Customers  (já mapeada)
   └─ Operations by Customer Anterior
      ├─ Operations Anterior  (já mapeada)
      └─ Customers Anterior  (já mapeada)

Spread Growth Format %
└─ Spread Growth
   ├─ Spread
   │  ├─ Gross Revenue  (já mapeada)
   │  └─ GMV  (já mapeada)
   └─ Spread Anterior
      ├─ Gross Revenue Anterior  (já mapeada)
      └─ GMV Anterior  (já mapeada)

% Total Cost Growth Format %
└─ % Total Cost Growth
   ├─ % Total Cost
   │  ├─ Total Cost
   │  │  └─ f_operations[cost_bank_take]
   │  │  └─ f_operations[cost_mensage]
   │  │  └─ f_operations[cost_payout_affiliate]
   │  └─ Gross Revenue  (já mapeada)
   └─ % Total Cost Anterior
      ├─ Total Cost Anterior
      │  └─ Total Cost  (já mapeada)
      └─ Gross Revenue Anterior  (já mapeada)

Total Cost Growth Format %
└─ Total Cost Growth
   ├─ Total Cost  (já mapeada)
   └─ Total Cost Anterior  (já mapeada)

Título SC
└─ Título M0
   └─ d_calendar[Date Key]
   └─ d_calendar[Filter Today]
└─ f_operations[mtd]
└─ f_operations[workday_processado]

Gross Revenue Original Growth Format %
└─ Gross Revenue Original Growth
   ├─ Gross Revenue Original
   │  └─ f_operations[gross_revenue_original]
   └─ Gross Revenue Original Anterior
      └─ Gross Revenue Original  (já mapeada)

Diff Gross Revenue Growth Format %
└─ Diff Gross Revenue Growth
   ├─ Diff Gross Revenue
   │  └─ f_operations[diff_gross_revenue]
   └─ Diff Gross Revenue Anterior
      └─ Diff Gross Revenue  (já mapeada)
```

---

## Reverse — quem depende das medidas-base

Medidas-base são as mais reusadas no modelo. Mexer nelas afeta várias outras a jusante.

### GMV (base)

**Usada por:**
- `Spread`
- `AVG Ticket GMV`
- `GMV Anterior`
- `GMV Growth`
- `GMV Growth Format %`
- `Spread Anterior`
- `Color - GMV`
- `Color - TKM GMV`

**Implicação:** mudar `GMV` afeta 8 medidas diretamente — inclui Spread, AVG Ticket, Spread Anterior e medidas de cor. Cuidado em refator.

---

### Gross Revenue (base)

**Usada por:**
- `Spread`
- `% Total Cost`
- `ARPU (Gross Revenue / Customers)`
- `AVG Ticket Gross Revenue`
- `Gross Revenue Anterior`
- `Gross Revenue Growth`
- `Gross Revenue Growth Format %`
- `Color - Gross Revenue`

**Implicação:** mudar `Gross Revenue` afeta 8 medidas diretamente, incluindo todas as variantes de crescimento e ARPU.

---

### Operations (base)

**Usada por:**
- `AVG Ticket GMV`
- `AVG Ticket Gross Revenue`
- `Operations by Customer`
- `Ticket Médio (Gross Profit)`
- `Operations Anterior`
- `Operations Growth`
- `Operations Growth Format %`
- `Color - Operations`

**Implicação:** mudar `Operations` afeta 8 medidas diretamente — todos os tickets médios dependem dela.

---

### Customers (base)

**Usada por:**
- `Operations by Customer`
- `ARPU (Gross Revenue / Customers)`
- `Customers Anterior`
- `Customers Growth`
- `Customers Growth Format %`
- `Color - MAUs`

**Implicação:** mudar `Customers` afeta 6 medidas.

---

### Gross Profit (base)

**Usada por:**
- `Ticket Médio (Gross Profit)`
- `Gross Profit Anterior`
- `Gross Profit Growth`
- `Gross Profit Growth Format %`

**Implicação:** mudar `Gross Profit` afeta 4 medidas.

---

### Total Cost (base)

**Usada por:**
- `% Total Cost`
- `Total Cost Anterior`
- `Total Cost Growth`
- `Total Cost Growth Format %`

**Implicação:** mudar `Total Cost` afeta 4 medidas.

---

### GMV Anterior (base intermediária)

**Usada por:**
- `GMV Growth`
- `Spread Anterior`
- `AVG Ticket GMV Anterior`

**Implicação:** é produzida por `GMV` e `p_timeframe`/`d_calendar[mtd]` — se a lógica de período mudar, 3 medidas são afetadas.

---

### Gross Revenue Anterior (base intermediária)

**Usada por:**
- `% Total Cost Anterior`
- `Spread Anterior`
- `Gross Revenue Growth`
- `Gross Revenue Original Anterior` (indireto)

**Implicação:** mudar a lógica de cálculo do período anterior afeta toda a cadeia de crescimento.

---

## Tabelas mais referenciadas

Sinaliza onde mora a "carne" do modelo — tabelas usadas por mais medidas têm maior peso na arquitetura.

1. `f_operations` — referenciada por ~50 medidas (GMV, Gross Revenue, Gross Profit, Operations, Customers, Spread, Total Cost, Tariff, Refresh, Última Operação, Título SC, todas as colunas calculadas)
2. `d_calendar` — referenciada por ~15 medidas (todas as medidas de período anterior, MTD:, Última Data, Título M0)
3. `p_timeframe` — referenciada por ~15 medidas Anterior (controla toda a lógica de comparação de período)
4. `Medidas` (tabela host) — todas as ~85 medidas são hospedadas aqui
5. `Month over month` — referenciada pelas 10 medidas Color e pelos calculation items

---

## Como usar essa info

- **Antes de refatorar uma medida-base** (ex: `GMV` ou `Gross Revenue`), checa quem depende dela aqui — você pode estar quebrando 8+ outras sem perceber
- **Em revisão de PR** que muda DAX, esse arquivo serve de "blast radius check"
- **Pra onboarding**, a árvore ajuda a entender o "esqueleto" de cálculo do modelo — note que o padrão `{KPI} Anterior` / `{KPI} Growth` / `{KPI} Growth Format %` se repete para cada métrica
- **A lógica de período** (PARALLELPERIOD/DATEADD com controle de MTD) é o coração das comparações — está replicada em ~8 medidas `Anterior`. Uma mudança nessa lógica exige atualizar todas elas

---

*XPERIUN · `/pbi-doc`*
