# Gestão de Receita — Relacionamentos do Modelo

## Resumo

| Item | Valor |
|------|-------|
| Total de relacionamentos | 3 |
| Ativos | 3 |
| Inativos | 0 |
| Direção de filtro única (→) | 3 |
| Direção de filtro dupla (↔) | 0 |

> **Observação:** A tabela `customer` **não possui relacionamento** com `dcalendar` nem com outras tabelas dimensionais — ela é usada para análise de clientes com métricas históricas sem filtragem por período do calendário.

---

## Diagrama de relacionamentos

```
┌─────────────────────────────┐
│         dcalendar           │
│  (Dataflow — dim temporal)  │
│  Date Key (PK)              │
└──────────────┬──────────────┘
               │ 1
               │ Date Key → processed_date
               │ M
┌──────────────▼──────────────────────────────────────────┐
│                   processed_operations                   │
│                 (fato principal — gold)                  │
│  id_remittance   id_customer   processed_date            │
└──────┬─────────────────┬──────────────────────────────────┘
       │                 │
       │ M               │ M
       │ id_customer     │ id_customer
       │ 1               │ 1
┌──────▼──────────┐  ┌───▼──────────────┐
│ 'Subsegmento PF'│  │    Parceiros     │
│ (dim — stage +  │  │ (dim — beecambio)│
│  silver)        │  │                  │
│ id_customer (PK)│  │ id_customer (PK) │
└─────────────────┘  └──────────────────┘


┌──────────────────────────────┐
│           customer           │
│  (fato — gold + outros)      │
│  id_customer (sem relação)   │
│  [tabela autônoma]           │
└──────────────────────────────┘
```

---

## Tabela detalhada

| # | De (tabela) | De (coluna) | Para (tabela) | Para (coluna) | Cardinalidade | Direção | Ativo |
|---|------------|-------------|---------------|---------------|---------------|---------|-------|
| 1 | `processed_operations` | `id_customer` | `Subsegmento PF` | `id_customer` | Muitos:1 | → | ✅ |
| 2 | `processed_operations` | `id_customer` | `Parceiros` | `id_customer` | Muitos:1 | → | ✅ |
| 3 | `processed_operations` | `processed_date` | `dcalendar` | `Date Key` | Muitos:1 | → | ✅ |

---

## Descrição de cada relacionamento

### 1. processed_operations → Subsegmento PF

**Propósito:** Enriquecer cada operação com o subsegmento do cliente PF no mês correspondente, permitindo filtrar e agrupar operações por segmento de persona (ex: High Value, Turista, Recorrente).

**Observação de granularidade:** `Subsegmento PF` tem granularidade de cliente × mês. Como o relacionamento é apenas por `id_customer` (sem a coluna `month_id`), o filtro de subsegmento pode trazer valores de meses diferentes do filtro do calendário. Usar com atenção em análises temporais refinadas.

**Filtro:** operações → subsegmento (unidirecional). Filtros no subsegmento propagam para `processed_operations`.

---

### 2. processed_operations → Parceiros

**Propósito:** Enriquecer cada operação com o nome do parceiro Maxima associado ao cliente, permitindo análises de rentabilidade por parceiro de distribuição.

**Cobertura:** Somente clientes que têm `maxima_partner_code NOT NULL` em `beecambio.beecambio_tbl_customer`. Clientes sem parceiro terão BLANK() no filtro de parceiro.

**Filtro:** operações → parceiros (unidirecional). Filtros no parceiro propagam para `processed_operations`.

---

### 3. processed_operations → dcalendar

**Propósito:** Conectar operações à dimensão de calendário, permitindo filtros por mês, trimestre, ano e visualizações de série temporal. Habilita a medida `Mes anterior` via `PREVIOUSMONTH(dcalendar[date_month])`.

**Granularidade:** `processed_date` (data) → `Date Key` (data). Relacionamento de granularidade diária.

**Filtro:** operações → calendário (unidirecional). Filtros no calendário propagam para `processed_operations`.

---

## Tabelas sem relacionamento direto

| Tabela | Motivo | Impacto |
|--------|--------|---------|
| `customer` | Agrega métricas históricas por cliente sem janela temporal | Medidas da tabela `customer` (Clientes negativados, Clientes positivos etc.) não respondem a filtros de calendário |
| `KPI` | Seletor calculado (DATATABLE) — sem dados factuais | Controla apenas a medida `Metricas de operações` via SELECTEDVALUE |
| `Dimensão 1–5` | Seletores calculados (DATATABLE) — sem dados factuais | Controlam os seletores de dimensão nos visuais |
| `Escolha a métrica` | Seletor calculado (DATATABLE) | Controla o seletor de métrica na análise de clientes |
| `Timeframe` | Seletor calculado (DATATABLE) | Controla a granularidade temporal dos visuais |
| `Cenários Delta Operações` | Parâmetro — valores de slider (-1 a +1) | Alimenta medidas de cenário via `SELECTEDVALUE` |
| `Cenários Delta Spread` | Parâmetro — valores de slider (-1 a +1) | Alimenta medidas de cenário via `SELECTEDVALUE` |
