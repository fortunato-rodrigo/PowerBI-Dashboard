# Daily Sales Dashboard — Mapa de Dependências

## Hierarquia de Dependências das Medidas

```
Colunas Databricks / Fatos
│
├── f_gold_ops[gross_revenue]
│   └── Receita (base)
│       ├── Receita (MTD)
│       ├── Receita (D-1)
│       ├── % Meta x Receita → % GAP de Receita
│       │       ├── % Gap de Receita (D-1)
│       │       └── % Gap de Receita (MTD)
│       └── Realizado [quando KPI=Receita]
│           ├── Realizado (D-1)
│           ├── Realizado (MTD) → % MOM (MTD), # MOM (MTD)
│           ├── Realizado (M-1) → % MOM
│           ├── Realizado (PMTD)
│           └── Realizado YTD → % GAP (YTD), # GAP (YTD), Gauge - GAP YTD
│
├── f_gold_ops[gmv] + f_daily_sales[gmv]
│   └── GMV (base)
│       ├── Meta de GMV → Projeção de GMV (Last Day) → Projeção [quando KPI=GMV]
│       └── Realizado [quando KPI=GMV] → (mesma árvore de D-1/MTD/YTD acima)
│
├── f_daily_sales[operations] + f_gold_ops[operations] + f_wallet[transactions]
│   └── Ops (base)
│       ├── Meta de Ops
│       ├── % GAP de Ops → % Gap de Ops (D-1/MTD)
│       ├── Aquisições → Aquisições (D-1/MTD), % Gap de Aquisições
│       │           └── CPA → CPA (D-1/MTD/PMTD/Acumulado/# MOM)
│       └── Realizado [quando KPI=Operações]
│
├── f_daily_sales_psu[realizado_psu]
│   └── Presignups
│       ├── Presignups (D-1/MTD/PMTD)
│       ├── Presignups % MOM (MTD)
│       └── CPP → CPP (D-1/MTD/PMTD/# MOM)
│
├── f_investimentos[investimento]
│   └── Investimento
│       ├── Investimento (D-1/MTD/PMTD)
│       ├── Investimento % MOM (MTD)
│       ├── Investimento Sem Filtro de Ano
│       ├── CPP (usa [Investimento] / [Presignups])
│       └── CPA (usa [Investimento] / [Aquisições])
│
├── f_gold_ops[gross_revenue_treasury]
│   └── PNL
│
├── f_gold_ops[real_message_cost]
│   └── Custo de Mensageria
│
├── f_gold_ops[cost_bank_take]
│   └── Take do Banco
│
├── f_pnl_tesouraria[meta_pnl]
│   └── Meta de PNL
│
├── f_last_update[last_update]
│   └── Last Update → Título Report Diário
│
└── dcalendar[Date Key / month_year / mtd / d0 / last_day / etc.]
    ├── Filtros temporais (todas as medidas MTD / D-1 / YTD / PMTD)
    └── Mês Anterior, MaxData, Current Month Processed, Bom Dia Dream Makers
```

---

## Medidas Dinâmicas (dependentes de seletores)

Estas medidas dependem de **dois seletores** além das colunas de dado:

| Medida | Seletor 1 | Seletor 2 |
|--------|-----------|-----------|
| `Realizado` | `Tabela[KPI]` | `Intraday Flag[Intraday]` |
| `Realizado (D-1/M-1/MTD/PMTD/YTD)` | `Tabela[KPI]` (via Realizado) | `Intraday Flag[Intraday]` |
| `Meta` | `Tabela[KPI]` | — |
| `Meta (D-1/MTD/Acumulada/YTD/FY)` | `Tabela[KPI]` (via Meta) | — |
| `Projeção` | `Tabela[KPI]` | — |
| `% GAP`, `# GAP` (todas variantes) | `Tabela[KPI]` (via Realizado/Meta) | `Intraday Flag` (indiretamente) |
| `% MOM (MTD)`, `# MOM (MTD)` | `Tabela[KPI]` | `Intraday Flag` |
| `Resumo Dashboard` | Todos os KPIs individuais (HTML) | — |

---

## Referência Reversa — Quais Tabelas Alimentam Cada KPI

| KPI | f_daily_sales | f_gold_ops | f_daily_sales_psu | f_investimentos | f_wallet | f_pnl_tesouraria |
|-----|:---:|:---:|:---:|:---:|:---:|:---:|
| GMV | ✅ | ✅ (fallback) | — | — | — | — |
| Receita | ✅ | ✅ (prioritário intraday) | — | — | ✅ | — |
| Ops | ✅ | ✅ (fallback) | — | — | ✅ (fallback) | — |
| Aquisições | — | ✅ | — | — | — | — |
| Presignups | — | — | ✅ | — | — | — |
| Investimento | — | — | — | ✅ | — | — |
| CPP | — | — | ✅ (PSU) | ✅ (invest.) | — | — |
| CPA | — | ✅ (ACQ) | — | ✅ (invest.) | — | — |
| PNL | — | ✅ (treasury) | — | — | — | — |
| Meta de PNL | — | — | — | — | — | ✅ |
| Custo Mensageria | — | ✅ | — | — | — | — |
| Take do Banco | — | ✅ | — | — | — | — |

---

## Dependências de Formato

O dashboard usa **formatação dinâmica** — as medidas do grupo `# Oficial` aplicam formatos diferentes conforme o KPI selecionado:

| Tipo de KPI | Formato aplicado |
|-------------|-----------------|
| GMV, Receita, Ticket Médio, Investimento, PNL | R$ com escala automática (B/M/K) |
| CPP, CPA | R$ #,0.00 |
| Operações, Presignups, DAUs | Número inteiro com escala automática |
| Spread | Percentual (0.00%) |

---

## Medidas Potencialmente Órfãs

Medidas que podem não estar sendo usadas em nenhum visual (identificadas por não aparecerem nas fórmulas de outras medidas):

| Medida | Display Folder | Observação |
|--------|---------------|-----------|
| `Gauge Meta 0` | # Oficial\Meta | Constante 0 — pode ser usada como âncora de gauge visual |
| `Current Month Processed` | Auxiliar | Texto estático hardcoded — verificar se ainda em uso |
| `Investimento Sem Filtro de Ano` | Investimento | Usada em análise histórica cross-year? Verificar |
| `Projeção de Receita Acumulada` | Receita | Complemento de `Projeção Acumulada` — verifica se está no visual de linha |
| `Meta (D0)` | # Oficial\Meta | Meta do dia de hoje exato — verificar se usada separada de `Meta (D-1)` |
