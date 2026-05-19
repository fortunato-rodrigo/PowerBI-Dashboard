# Daily Sales Dashboard — Glossário de Negócio

> **Escopo:** termos específicos ou particularmente relevantes neste dashboard.
> **Ontologia corporativa:** termos transversais estão em [`ontologia/GLOSSARY.md`](../../../ontologia/GLOSSARY.md) e [`ontologia/KPIS.md`](../../../ontologia/KPIS.md).
> **Conflito entre fontes:** o glossário corporativo tem precedência sobre este arquivo.

---

## Termos de Período e Contexto Temporal

### D-1 (Fechamento)
**Definição:** O último dia com dados completamente fechados — exclui o dia corrente (que ainda está em andamento). É o modo padrão do dashboard quando o toggle `Intraday = FALSE`.
**Exemplo:** Em 09/05/2026, o D-1 é 08/05/2026.
**Como aparece nas medidas:** `Realizado (D-1)`, `Meta (D-1)`, `% GAP (D-1)`, `CPA (D-1)`, `CPP (D-1)`.
**Ver também:** Intraday, MTD.

---

### MTD (Month-to-Date)
**Definição:** Acumulado do mês corrente — soma de todos os dias fechados desde o dia 1 do mês até o D-1.
**Como aparece nas medidas:** `Realizado (MTD)`, `Meta (MTD)`, `% GAP (MTD)`, `Presignups (MTD)`.
**Ver também:** PMTD, YTD, D-1.

---

### PMTD (Previous Month-to-Date)
**Definição:** O mesmo período do mês anterior. Exemplo: se hoje é dia 9 de maio, o PMTD é a soma do dia 1 ao dia 8 de abril. Permite comparação justa de mês vs. mês no mesmo ponto do ciclo.
**Como aparece nas medidas:** `Realizado (PMTD)`, `Presignups (PMTD)`, `CPA (PMTD)`, `CPP (PMTD)`.
**Ver também:** MTD, % MOM (MTD).

---

### YTD (Year-to-Date)
**Definição:** Acumulado do ano corrente — soma de todos os dias fechados desde 01/01 do ano até o D-1.
**Como aparece nas medidas:** `Realizado YTD`, `Meta YTD`, `% GAP (YTD)`, `# GAP (YTD)`.

---

### MOM (Month over Month)
**Definição:** Variação do indicador em relação ao mesmo período do mês anterior. Pode ser percentual (`% MOM`) ou absoluta (`# MOM`). Neste dashboard, sempre comparado no período MTD vs. PMTD.
**Exemplo:** `Presignups % MOM (MTD)` = (Presignups MTD − Presignups PMTD) ÷ Presignups PMTD.
**Como aparece nas medidas:** `% MOM (MTD)`, `# MOM (MTD)`, `Investimento % MOM (MTD)`.

---

### Intraday
**Definição:** Modo de visualização que **inclui os dados do dia corrente** (ainda parciais, pois o dia não fechou). Ativado pelo toggle `Intraday Flag = TRUE`. No modo Intraday, os números de hoje aparecem com os dados disponíveis até o momento da última atualização — útil para acompanhamento durante o dia.
**Contraste:** Quando `Intraday = FALSE`, o dashboard exibe apenas dias com fechamento completo (D-1 em diante) — modo recomendado para análises comparativas.
**Impacto nas medidas:** `Receita`, `GMV`, `Ops` e todas as variantes de `Realizado` respondem ao toggle. O comportamento é implementado via `SELECTEDVALUE('Intraday Flag'[Intraday])` combinado com filtros de calendário.

---

## Termos de Meta e Projeção

### Meta Diária
**Definição:** Valor-alvo definido para cada dia do mês, extraído da camada gold do Databricks (`gold.daily_sales`). As metas de GMV, Receita e Operações já vêm integradas nesta tabela — são calculadas upstream no DBT, não no Power BI.
**Exceção:** A meta de PNL é hardcoded na query M da tabela `f_pnl_tesouraria` — ver [05-fontes.md](05-fontes.md).
**Como aparece nas medidas:** `Meta de Receita`, `Meta de GMV`, `Meta de Ops`, `Meta` (dinâmica via seletor KPI).

---

### Projeção de Fechamento (Last Day)
**Definição:** Estimativa do valor que o KPI atingirá ao final do mês, calculada com base nos dados acumulados até o momento e no ritmo corrente. É extraída da coluna `projecao_*` da tabela `f_daily_sales` (ex: `projecao_gross_revenue`, `projecao_gmv`), que é computada upstream na camada gold.
**Como aparece:** O dashboard pega o valor da **última linha disponível** no mês usando `dcalendar[last_day] = TRUE()`.
**Medidas:** `Projeção de Receita (Last Day)`, `Projeção de GMV (Last Day)`, `Projeção de Ops (Last Day)`.
**Projeção Acumulada:** Versão que preenche os dias ainda sem realizado no gráfico de linha (dias futuros do mês).

---

### GAP vs. Meta
**Definição:** Diferença entre o realizado e a meta para um determinado período.
- **% GAP:** diferença percentual — `(Realizado − Meta) ÷ Meta`. Positivo = acima da meta.
- **# GAP:** diferença absoluta — `Realizado − Meta`.
**Períodos disponíveis:** D-1, MTD, YTD.
**Regra de exibição:** O GAP só é exibido se houver meta definida para o período (`BLANK()` se meta ausente).

---

## Termos de Eficiência de Marketing

### CPP (Custo por Presignup)
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada novo presignup. Calculado como `Investimento ÷ Presignups`. **Menor = mais eficiente.**
**Fórmula DAX:** `DIVIDE([Investimento], [Presignups], BLANK())`
**Cuidado:** O investimento vem da camada bronze (`bronze.paid_media_investments`) — considerar nível de confiança ⚠️ ao usar para decisões estratégicas.
**Ontologia:** KPI a ser adicionado em [`ontologia/KPIS.md`](../../../ontologia/KPIS.md).
**Ver também:** CPA, Presignups, Investimento em Marketing.

---

### CPA (Custo por Aquisição)
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada nova aquisição (primeiro câmbio). Calculado como `Investimento ÷ Aquisições`. **Menor = mais eficiente.**
**Fórmula DAX:** `DIVIDE([Investimento], [Aquisições], BLANK())`
**Cuidado:** Mesmo alerta de bronze do CPP — investimento vem de `bronze.paid_media_investments`.
**Ontologia:** KPI a ser adicionado em [`ontologia/KPIS.md`](../../../ontologia/KPIS.md).
**Ver também:** CPP, Aquisições, Investimento em Marketing.

---

### Investimento em Marketing
**Definição:** Total gasto em mídia paga (canais pagos como Google, Meta, etc.) no período selecionado. Fonte: `bronze.paid_media_investments`.
**Alocação:** O custo total é alocado artificialmente entre PF (58,22%) e PJ (41,78%) — proporção hardcoded na query M. Verificar com o time de dados se a proporção ainda é válida.
**Medidas:** `Investimento`, `Investimento (D-1)`, `Investimento (MTD)`, `Investimento (PMTD)`.

---

## Termos de Produtos e Segmentos

### PNL / Tesouraria
**Definição no contexto deste dashboard:** Resultado da tesouraria — receita gerada pelas operações de câmbio que flui para a área de tesouraria, registrada na coluna `gross_revenue_treasury` de `gold.fact_operations`. Diferente da Receita Bruta (spread comercial capturado), o PNL de Tesouraria reflete a rentabilidade de tesouraria das operações.
**Meta de PNL:** Definida anualmente por BU e distribuída proporcionalmente pelos dias úteis — atualmente hardcoded na query M da tabela `f_pnl_tesouraria` para 2025 e 2026. ⚠️ Exige edição manual a cada mudança de meta.
**Medidas:** `PNL`, `Meta de PNL`.
**Ver também:** Receita Bruta, BU, [05-fontes.md](05-fontes.md).

---

### Wallet / Conta Global
**Definição:** Produto de cartão internacional da Remessa Online — permite ao cliente realizar transações em moeda estrangeira usando uma conta digital. As transações do cartão são registradas em `explore.wallet_transactions`.
**Código no modelo:** BU = `"Wallet"`, business_type = `"Wallet EUR"`, segment = `"Conta Global"`, event_type = `"Transações do Cartão"`.
**Alerta de camada:** A fonte usa o schema `explore` — não pertence à hierarquia padrão bronze/silver/gold/diamond. ❓ Nível de confiança a definir com o time de dados.
**Contribuição para KPIs:** Soma às medidas de `Receita` e `Ops` (como fallback) via `f_wallet`.

---

### PSU (Presignup)
**Definição neste dashboard:** Clientes que iniciaram o cadastro na plataforma (topo do funil). No Daily Sales Dashboard, os presignups são monitorados via `f_daily_sales_psu`, que combina dados de `gold.daily_sales_psu` com sessões do Google Analytics (`google_analytics.last_click_sessions`).
**Canal de aquisição:** A tabela `f_daily_sales_psu` inclui a dimensão `canal` (UTM), permitindo análise de presignups por canal de marketing.
**Meta de PSU:** Vem da coluna `goal_psu` na tabela `gold.daily_sales_psu`.
**Ver também:** CPP, Aquisição, [ontologia/GLOSSARY.md](../../../ontologia/GLOSSARY.md#presignup).

---

## Termos de Estrutura do Dashboard

### Seletor de KPI (`Tabela`)
**Definição:** Tabela auxiliar calculada em DAX que controla qual KPI é exibido nos visuais principais do dashboard. Os valores disponíveis são: GMV, Receita, Operações, Presignups, Investimento, CPP, CPA, PNL.
**Funcionamento:** As medidas `Realizado`, `Meta`, `Projeção` e `% GAP` são dinâmicas — respondem ao KPI selecionado via `SELECTEDVALUE(Tabela[KPI])`. Ao trocar o KPI no seletor, todos os cartões e gráficos principais atualizam automaticamente.

---

### Modo Intraday vs. Fechamento
**Definição:** Os dois modos de operação do dashboard, controlados pelo toggle `Intraday Flag`:

| Modo | Intraday Flag | O que exibe |
|------|--------------|-------------|
| **Fechamento (D-1)** | `FALSE` | Apenas dias com dados completos — exclui o dia atual |
| **Intraday** | `TRUE` | Inclui o dia atual com dados parciais até a última atualização |

**Recomendação:** Usar modo Fechamento para análises comparativas e reports. Usar Intraday apenas para acompanhamento em tempo real durante o dia.

---

## Links para Ontologia Corporativa

| Termo neste dashboard | Entrada na ontologia |
|----------------------|---------------------|
| Receita Bruta | [GLOSSARY.md → Gross Revenue](../../../ontologia/GLOSSARY.md) |
| GMV | [KPIS.md → GMV](../../../ontologia/KPIS.md) |
| Operações | [KPIS.md → Operations](../../../ontologia/KPIS.md) |
| Presignups | [KPIS.md → Presignups](../../../ontologia/KPIS.md) |
| Aquisições | [GLOSSARY.md → Aquisição](../../../ontologia/GLOSSARY.md) |
| BU (Business Unit) | [GLOSSARY.md → BU](../../../ontologia/GLOSSARY.md) |
| Business Type | [GLOSSARY.md → Business Type](../../../ontologia/GLOSSARY.md) |
| Bronze / Gold / Diamond | [GLOSSARY.md → Camadas](../../../ontologia/GLOSSARY.md) |
| CPP, CPA, PNL, Intraday | ⏳ A adicionar — ver sugestões abaixo |

---

## Termos Pendentes na Ontologia Corporativa

Os termos abaixo foram identificados neste dashboard mas **ainda não constam na ontologia corporativa**. Confirme com `/pbi-ontologia` para incluí-los:

| Termo | Tipo | Proposta de definição |
|-------|------|----------------------|
| **CPP** | KPI ⭐ | Custo por Presignup: investimento em marketing ÷ presignups gerados |
| **CPA** | KPI ⭐ | Custo por Aquisição: investimento em marketing ÷ aquisições realizadas |
| **PNL / Tesouraria** | KPI | Resultado de tesouraria (gross_revenue_treasury) por período e BU |
| **Intraday** | Conceito operacional | Modo de visualização que inclui dados parciais do dia corrente |
| **Wallet / Conta Global** | Produto | Cartão internacional — transações em moeda estrangeira |
| **Meta Diária** | Conceito | Valor-alvo por dia extraído da camada gold (gold.daily_sales) |
| **Projeção de Fechamento** | Conceito | Estimativa do valor final do mês baseada no ritmo acumulado |
| **D-1** | Período | Último dia com fechamento completo (exclui o dia corrente) |
| **PMTD** | Período | Previous Month-to-Date — mesmo período do mês anterior |
