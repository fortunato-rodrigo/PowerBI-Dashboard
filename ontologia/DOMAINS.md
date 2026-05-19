# Ontologia Corporativa — Domínios de Negócio (Remessa Online)

> **Propriedade:** transversal · **Gestão:** `/pbi-ontologia`
> **Seed:** Mai 2026 a partir do dashboard Scorecard

---

## O que são domínios

Domínios são agrupamentos lógicos de dados e métricas por área de negócio.
Cada domínio tem um **time responsável** pelos dados (owner de dados) e um
**time consumidor** principal (quem usa os dashboards daquele domínio).

---

## Domínios identificados

### Câmbio / Operações

**Status:** Ativo · Seed do Scorecard

| Campo | Valor |
|-------|-------|
| **Descrição** | Domínio central do negócio Remessa Online — engloba todas as operações de câmbio processadas, desde a solicitação do cliente até a liquidação. |
| **Owner de dados** | Time de Dados (A definir — squad específico) |
| **Owner de negócio** | A definir |
| **Dashboards** | Scorecard, Dash-de-Ordens (a documentar) |
| **Tabela fato principal** | `gold.fact_operations` |
| **KPIs principais** | GMV, Gross Revenue, Gross Profit, Operations, Spread, Customers |
| **Dimensões** | BU, Business Type, Customer Type, Event Type, Segment, Calendar |
| **Camada de dados** | `gold` (operações) · `diamond` quando disponível |

---

### Receita / Financeiro

**Status:** Identificado (parcial) · A expandir

| Campo | Valor |
|-------|-------|
| **Descrição** | Domínio de métricas financeiras derivadas das operações — Gross Revenue, Gross Profit, Total Cost, Spread. |
| **Owner de dados** | A definir |
| **Owner de negócio** | A definir (Financeiro / CFO) |
| **Dashboards** | Scorecard, Gestao-de-Receita (a criar) |
| **KPIs principais** | Gross Revenue, Gross Profit, Spread, % Total Cost |
| **Notas** | Domínio transversal — métricas são derivadas de `Câmbio / Operações` via medidas DAX. |

---

### Clientes

**Status:** Identificado (parcial) · A expandir

| Campo | Valor |
|-------|-------|
| **Descrição** | Domínio de análise de base de clientes — segmentação, aquisição, retenção e ativação. |
| **Owner de dados** | A definir |
| **Owner de negócio** | A definir (Growth / CRM) |
| **Dashboards** | Scorecard (parcial), A definir |
| **KPIs principais** | Customers, Customer Type |
| **Tabela principal** | `gold.fact_customers` (referenciada em join de `f_operations`) |

---

### Parceiros / Afiliados

**Status:** Identificado (parcial) · A expandir

| Campo | Valor |
|-------|-------|
| **Descrição** | Domínio de gestão de parceiros e afiliados que originam operações para a Remessa Online. |
| **Owner de dados** | A definir |
| **Owner de negócio** | A definir (Parcerias) |
| **Dashboards** | A definir |
| **Fonte de dados** | `bronze.hubspot_partners` (⚠️ camada bronze — validar migração para silver/gold) |
| **KPIs principais** | Payout, operações por afiliado |

---

## Como adicionar um novo domínio

1. Rodar `/pbi-documentacao [NovoDashboard]`
2. A skill identificará tabelas e métricas de novos domínios
3. Confirmar a sugestão de domínio novo com `/pbi-ontologia`
4. Adicionar entrada neste arquivo via PR separado

---

*Gerenciado via `/pbi-ontologia` · Remessa Online*
