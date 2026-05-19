# Ontologia Corporativa — KPIs Estratégicos (Remessa Online)

> **Propriedade:** transversal · **Gestão:** `/pbi-ontologia`
> **Seed:** Mai 2026 a partir do dashboard Scorecard · Atualizado com Daily Sales Dashboard, Gestão de Receita, Dashboard - Recebimento e Mkt Performance

---

## Como usar este arquivo

- ⭐ = KPI estratégico (aparece em relatórios executivos)
- **Owner:** time ou pessoa responsável pela definição e monitoramento do KPI
- **Meta:** valor ou faixa alvo — preencher com o time de negócio

---

## ⚠️ Regras de negócio críticas

| Regra | KPIs afetados | Padrão | Exceção |
|-------|---------------|--------|---------|
| **FxaaS — excluir de PSU** | Presignups, CPP, Conversão Cohortada (ACQ/PSU), (SU/PSU), Aquisições Cohortadas | Sempre filtrar `email NOT LIKE '%fxaas%'` | Somente incluir FxaaS se o usuário/analista pedir explicitamente "com FxaaS" ou "total bruto" |
| **is_ops_processed** | Operations, GMV, Gross Revenue, Gross Profit | `is_ops_processed = TRUE` | Análises de pipeline/ordens pendentes |
| **is_intercompany** | Operations, GMV, Gross Revenue | `is_intercompany = FALSE` | Análises internas do grupo |
| **event_sequence = 1** | Presignups, Signups, Aquisições | Sempre filtrar `event_sequence = 1` em `gold.funnel_event` | Nunca — evita contar o mesmo cliente N vezes |

---

## KPIs de Volume

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| ⭐ **GMV** | Volume bruto total transacionado em câmbio | A definir | A definir | Scorecard, Dashboard de Safras, Daily Sales Dashboard, Gestão de Receita | `Medidas.GMV` / `# Medidas.GMV` / `Medidas.Total GMV` |
| ⭐ **Operations / Ops** | Número de operações processadas no período | A definir | A definir | Scorecard, Daily Sales Dashboard, Gestão de Receita | `Medidas.Operations` / `# Medidas.Ops` / `Medidas.Total operações` |
| ⭐ **Customers** | Clientes únicos com ao menos 1 operação | A definir | A definir | Scorecard | `Medidas.Customers` |
| ⭐ **Presignups** | Clientes únicos que iniciaram o cadastro (topo do funil) — ⚠️ **sempre excluir FxaaS** (`email NOT LIKE '%fxaas%'`); só incluir parceiros FxaaS se explicitamente solicitado | A definir | A definir | Dashboard de Safras, Daily Sales Dashboard | `# Medidas.Presignups` |
| ⭐ **Aquisições** | Clientes únicos que realizaram a primeira operação | A definir | A definir | Dashboard de Safras, Daily Sales Dashboard | `# Medidas.Aquisições` |
| **Signups** | Clientes únicos que completaram o cadastro | A definir | A definir | Dashboard de Safras | `# Medidas.Signups` |
| **Clientes Únicos** | Clientes com ao menos 1 operação (ACQ ou recorrente) | A definir | A definir | Dashboard de Safras | `# Medidas.Clientes Únicos` |

---

## KPIs de Receita e Margem

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| ⭐ **Gross Revenue / Receita** | Receita bruta (spread capturado) | A definir | A definir | Scorecard, Daily Sales Dashboard, Gestão de Receita | `Medidas.Gross Revenue` / `# Medidas.Receita` / `Medidas.Total Gross Revenue` |
| ⭐ **Gross Profit** | Lucro bruto (Gross Revenue − Total Cost) | A definir | A definir | Scorecard | `Medidas.Gross Profit` |
| ⭐ **Spread** | Margem percentual por operação (GR / GMV) | A definir | A definir | Scorecard, Gestão de Receita | `Medidas.Spread` (Scorecard) / `Medidas.Spread` (Gestão de Receita — ponderado) |
| **Net Revenue / Receita Líquida** | Receita após todos os custos diretos por operação | A definir | A definir | Gestão de Receita | `Medidas.Total Receita Líquida` |
| **Total Cost** | Custo operacional direto por operação | A definir | A definir | Scorecard, Gestão de Receita | `Medidas.Total Cost` / `Medidas.Total custo` |
| **% Total Cost** | Total Cost como % da Gross Revenue | A definir | A definir | Scorecard, Gestão de Receita | `Medidas.% Total Cost` / `Medidas.% custo` |
| **% ops negativas** | % de operações com lucro negativo no período | A definir | A definir | Gestão de Receita | `Medidas.% ops negativas` |

---

## KPIs de Funil e Cohort

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| ⭐ **Conversão Cohortada (ACQ/PSU)** | % de Presignups que chegaram a Aquisição (qualquer mês) — ⚠️ PSU base deve excluir FxaaS | A definir | A definir | Dashboard de Safras | `# Medidas.Conversão Cohortada (ACQ/PSU)` |
| **Conversão Cohortada (SU/PSU)** | % de Presignups que chegaram ao Signup — ⚠️ PSU base deve excluir FxaaS | A definir | A definir | Dashboard de Safras | `# Medidas.Conversão Cohortada (SU/PSU)` |
| **Conversão Cohortada (ACQ/SU)** | % de Signups que chegaram à Aquisição | A definir | A definir | Dashboard de Safras | `# Medidas.Conversão Cohortada (ACQ/SU)` |
| **Aquisições Cohortadas do Presignup** | PSU que converteram em ACQ (acumulado da safra) — ⚠️ PSU base deve excluir FxaaS | A definir | A definir | Dashboard de Safras | `# Medidas.Aquisições Cohortadas do Presignup` |
| **Segunda Operação (Cohorted)** | Clientes que realizaram ao menos uma segunda operação | A definir | A definir | Dashboard de Safras | `# Medidas.Segunda Operação (Cohorted)` |
| **Gross Revenue** | Receita bruta gerada pelas operações de câmbio | A definir | A definir | Scorecard, Dashboard de Safras | `# Medidas.Gross Revenue` |

---

## KPIs de Comparação Temporal

Os KPIs abaixo são derivados automaticamente dos KPIs base pelo Calculation Group `Month over month`.

| KPI | Tipo | Exemplo |
|-----|------|---------|
| **[KPI] Anterior** | Valor do período anterior | `GMV Anterior` |
| **[KPI] Growth** | Variação % vs período anterior | `GMV Growth` |
| **[KPI] MTD** | Acumulado do mês | `Gross Revenue MTD` |
| **[KPI] MoM** | Mês sobre mês | `Operations MoM` |
| **[KPI] YoY** | Ano sobre ano | `Customers YoY` |

---

## KPIs de Marketing (Daily Sales Dashboard)

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| ⭐ **CPP** | Custo por Presignup: investimento ÷ presignups — ⚠️ PSU sempre sem FxaaS; incluir FxaaS subestima o CPP real de marketing | A definir | A definir | Daily Sales Dashboard, Mkt Performance | `# Medidas.CPP` / variantes `CPP PF`, `CPP PJ` (Mkt Performance) |
| ⭐ **CPA** | Custo por Aquisição: investimento ÷ aquisições | A definir | A definir | Daily Sales Dashboard, Mkt Performance | `# Medidas.CPA` / variantes `CPA PF`, `CPA PJ` (Mkt Performance) |
| **Investimento em Marketing** | Total gasto em mídia paga no período | A definir | A definir | Daily Sales Dashboard, Mkt Performance | `# Medidas.Investimento` |

---

## KPIs de Volume — Dashboard - Recebimento

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| **Ordens** | Total de ordens de pagamento criadas no período | A definir | A definir | Dashboard - Recebimento | `# Medidas.Ordens` |
| **Resgatadas** | Ordens com status "Resgatado" (liquidadas) | A definir | A definir | Dashboard - Recebimento | `# Medidas.Resgatadas` |
| **Pendentes** | Ordens ainda aguardando processamento | A definir | A definir | Dashboard - Recebimento | `# Medidas.Pendentes` |
| **% Resgate** | % de ordens resgatadas sobre o total | A definir | A definir | Dashboard - Recebimento | `# Medidas.% Resgate` |
| **GMV (Resgatado)** | GMV real das ordens liquidadas | A definir | A definir | Dashboard - Recebimento | `# Medidas.GMV (Resgatado)` |
| **GMV Pendente (Forecast)** | GMV estimado das ordens pendentes (quantity × cotação do dia) | A definir | A definir | Dashboard - Recebimento | `# Medidas.GMV Pendente (Forecast)` |
| **Receita (Resgatado)** | Gross revenue real das ordens liquidadas | A definir | A definir | Dashboard - Recebimento | `# Medidas.Receita (Resgatado)` |
| **Receita Pendente (Forecast)** | Estimativa de receita das pendentes (GMV × spread simulado) | A definir | A definir | Dashboard - Recebimento | `# Medidas.Receita Pendente (Forecast)` |

> ⚠️ `Receita Pendente (Forecast)` depende do spread selecionado no simulador "What if?" (slider 0%–2%). O spread base de 0,83% está hardcoded na coluna `gross_revenue_forecast`.

---

## KPIs de Tesouraria (Daily Sales Dashboard)

| KPI | Definição resumida | Owner | Meta | Dashboards | Medida DAX |
|-----|-------------------|-------|------|------------|------------|
| **PNL / Tesouraria** | Receita de tesouraria das operações (`gross_revenue_treasury`) | A definir | A definir | Daily Sales Dashboard | `# Medidas.PNL` |
| **Meta de PNL** | Meta anual de PNL por BU distribuída pelos dias úteis | A definir | Hardcoded em M (2025/2026) | Daily Sales Dashboard | `# Medidas.Meta de PNL` |

> ⚠️ **Atenção:** A Meta de PNL está hardcoded na query M da tabela `f_pnl_tesouraria`. Qualquer mudança de meta ou BU exige edição manual da query no Power BI.

---

## KPIs A Definir (identificados mas sem metadados completos)

Os KPIs abaixo foram identificados no modelo mas ainda não têm owner e meta definidos. Usar `/pbi-ontologia` após revisão com o time de negócio.

| KPI | Dashboard de origem | Notas |
|-----|---------------------|-------|
| A definir conforme novos dashboards | — | — |

---

*Gerenciado via `/pbi-ontologia` · Remessa Online · Mai 2026 — inclui Scorecard, Safras, Daily Sales, Gestão de Receita, Dashboard - Recebimento, Mkt Performance*
