# Ontologia Corporativa — Glossário Canônico (Remessa Online)

> **Propriedade:** transversal — pertence a toda a empresa, não a um dashboard específico.
> **Como contribuir:** nunca editar diretamente. Use `/pbi-ontologia` após documentar um dashboard.
> **Última revisão:** Mai 2026 · Atualizado com Daily Sales Dashboard, Gestão de Receita, Dashboard - Recebimento e Mkt Performance

---

## Regras de uso

1. Este glossário define os termos **canônicos** — são estes os nomes que devem aparecer em dashboards, medidas DAX e comunicações de negócio.
2. Quando um dashboard usar um sinônimo (ex: "Revenue Bruta" em vez de "Gross Revenue"), registrar em **Sinônimos** e apontar para o termo canônico.
3. Nunca duplicar definições — se o termo já existe, atualizar em vez de criar novo.

---

## A

### Aquisição (ACQ)
**Tipo:** KPI ⭐ · Evento de funil
**Definição:** Momento em que um cliente realiza sua **primeira operação de câmbio** na Remessa Online. É a métrica de ativação — o cliente passa de "cadastrado" para "cliente ativo". Cada cliente tem apenas uma Aquisição (na primeira operação); as seguintes são contabilizadas como Operações.
**Sinônimos:** primeira operação, ativação, ACQ
**Dashboards:** Dashboard de Safras, Daily Sales Dashboard
**Medida DAX:** `# Medidas.Aquisições`
**Coluna Databricks:** `gold.funnel_event.event_type = 'ACQUISITION'` / `gold.fact_operations.event_type = 'ACQUISITION'`
**Ver também:** Presignup, Signup, Operação de câmbio

---

### Afiliado / Parceiro
**Tipo:** Entidade
**Definição:** Empresa ou pessoa que origina operações de câmbio para a Remessa Online mediante acordo comercial. Recebe **Payout** por operação.
**Sinônimos:** parceiro, partner
**Dashboards:** Scorecard

---

### Attribution Window (Janela de Atribuição)
**Tipo:** Modelo de atribuição · Marketing
**Definição:** Eventos de Presignup ou Aquisição que **não foram capturados** pelo modelo de Last Click padrão — sessões que ocorreram mas não geraram um registro em `google_analytics.last_click_sessions`. Complementa o funil de marketing identificando clientes que navegaram por múltiplas sessões ou dispositivos sem deixar rastro no last-click.
**Sinônimos:** attribution window, janela de atribuição
**Dashboards:** Mkt Performance
**Ver também:** Last Click, First Click

---

## B

### Bank Take
**Tipo:** Custo operacional
**Definição:** Custo cobrado pelo banco parceiro por cada operação de câmbio processada. Compõe o **Total Cost**.
**Sinônimos:** bank take, custo do banco
**Dashboards:** Scorecard, Gestão de Receita
**Coluna Databricks:** `gold.fact_operations.cost_bank_take`
**Atenção:** No Gestão de Receita existem duas formas de calcular: (1) `processed_operations` usa `cost_bank_take` por operação diretamente de gold; (2) `customer` aloca o bank take mensal total de `finance_cube.kpi_list` proporcionalmente ao GMV — os valores podem divergir.

### Bronze
**Tipo:** Camada de dados (Databricks)
**Definição:** Camada de dados brutos sem transformação. Dados diretos das fontes de origem. ⚠️ Baixo nível de confiança — não usar em métricas de negócio sem validação.
**Sinônimos:** raw layer
**Ver também:** Silver, Gold, Diamond

### BU (Business Unit)
**Tipo:** Dimensão
**Definição:** Unidade de negócio responsável por uma operação ou conjunto de operações. Identifica qual linha de produto originou a transação na Remessa Online.
**Sinônimos:** —
**Dashboards:** Scorecard
**Coluna Databricks:** `gold.fact_operations.bu`

### Business Type
**Tipo:** Dimensão
**Definição:** Classificação do tipo de negócio da operação (ex: B2C — pessoa física, B2B — pessoa jurídica).
**Sinônimos:** —
**Dashboards:** Scorecard
**Coluna Databricks:** `gold.fact_operations.business_type`

---

## C

### CPA (Custo por Aquisição)
**Tipo:** KPI ⭐ · Eficiência de marketing
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada nova aquisição (cliente que realiza o primeiro câmbio). Calculado como `Investimento em Marketing ÷ Aquisições`. **Menor = mais eficiente.** Indica a eficiência do funil completo PSU → ACQ.
**Fórmula DAX:** `DIVIDE([Investimento], [Aquisições], BLANK())`
**Sinônimos:** custo de aquisição, custo por cliente
**Dashboards:** Daily Sales Dashboard
**Medida DAX:** `# Medidas.CPA`
**Tabelas Databricks:** `bronze.paid_media_investments` (investimento) + `gold.fact_operations` (aquisições)
**Ver também:** CPP, Aquisição, Investimento em Marketing

---

### CPP (Custo por Presignup)
**Tipo:** KPI ⭐ · Eficiência de marketing
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada novo presignup. Calculado como `Investimento em Marketing ÷ Presignups`. **Menor = mais eficiente.** Mede a eficiência do topo do funil.
**Fórmula DAX:** `DIVIDE([Investimento], [Presignups], BLANK())`
**Sinônimos:** custo por lead, custo por cadastro
**Dashboards:** Daily Sales Dashboard
**Medida DAX:** `# Medidas.CPP`
**Tabelas Databricks:** `bronze.paid_media_investments` (investimento) + `gold.daily_sales_psu` (presignups)
**Ver também:** CPA, Presignup, Investimento em Marketing

---

### Crédito Identificado
**Tipo:** Status operacional
**Definição:** Estágio intermediário no ciclo de uma ordem de pagamento em que o sistema da Remessa Online confirma que o crédito chegou ao banco parceiro (Topázio), mas o processamento completo ainda não foi concluído. Rastreado na tabela `f_credito_identificado` (filtro `id_status = 3`).
**Sinônimos:** crédito id, crédito recebido
**Dashboards:** Dashboard - Recebimento
**Ver também:** Ordem de Pagamento, Resgate

---

### Churn
**Tipo:** Status de cliente
**Definição:** Cliente sem nenhuma operação de câmbio processada nos **últimos 120 dias**. Indica inatividade prolongada. O campo `first_date_churn_lifetime` registra a data em que o cliente entrou em churn pela primeira vez.
**Contraste:** Ver `Cliente Ativo` (operação nos últimos 120 dias).
**Tabela Databricks:** `gold.fact_customers`
**Coluna Databricks:** `gold.fact_customers.first_date_churn_lifetime`
**Ver também:** Cliente Ativo, Aquisição

---

### Cliente Ativo
**Tipo:** Status de cliente
**Definição:** Cliente com ao menos uma operação de câmbio processada nos **últimos 120 dias**. Métrica de base ativa — quantifica o núcleo de clientes engajados com a plataforma.
**Tabela Databricks:** `gold.fact_customers`
**Ver também:** Churn, Aquisição

---

### Created Story
**Tipo:** Evento de funil — PF e PJ
**Definição:** Evento que ocorre quando o cliente cria sua primeira "história" no processo de onboarding da Remessa Online. Etapa intermediária entre SIGNUP e APPROVED STORY no funil de ativação. Ocorre tanto para clientes Pessoa Física quanto Pessoa Jurídica.
**Sinônimos:** história criada
**Coluna Databricks:** `gold.funnel_event.event_type = 'CREATED STORY'` — ordenar pela coluna `sequence`
**Ver também:** Signup, Histórias Aprovadas, Aquisição

---

### Cohort Dinâmico
**Tipo:** Filtro analítico
**Definição:** Modalidade de análise de safra que filtra conversões ocorridas dentro de uma janela de dias configurável após o evento de origem (ex: PSU). Exemplo: "Cohort de 30 dias" mostra apenas clientes que converteram nos primeiros 30 dias após o Presignup.
**Sinônimos:** cohort por dias, janela de conversão
**Dashboards:** Dashboard de Safras
**Configurado via:** Slicer `p_Cohort` / medida `Aquisições Cohortadas do Presignup | Cohort Dinâmico`

### Conversão Cohortada
**Tipo:** KPI ⭐ · Taxa
**Definição:** Taxa de conversão calculada sobre a safra de origem. Divide o número de clientes de uma safra que chegaram a converter pelo total da safra — independentemente de quando a conversão ocorreu. Diferente da conversão simples (uncohorted), que mistura safras diferentes do mesmo período.
**Fórmula principal:** `Aquisições Cohortadas do Presignup / Presignups`
**Sinônimos:** CR cohortado, taxa de conversão da safra
**Dashboards:** Dashboard de Safras
**Medida DAX:** `# Medidas.Conversão Cohortada (ACQ/PSU)`

### Customers
**Tipo:** KPI ⭐
**Definição:** Número de clientes únicos que realizaram ao menos uma operação de câmbio no período analisado. Métrica de alcance e engajamento.
**Sinônimos:** clientes, usuários ativos
**Dashboards:** Scorecard
**Medida DAX:** `Medidas.Customers`
**Coluna Databricks:** A definir (customer_id em `gold.fact_operations`)

### Customer Type
**Tipo:** Dimensão
**Definição:** Segmentação do cliente quanto ao seu perfil de relacionamento com a Remessa Online (ex: novo, recorrente, inativo).
**Sinônimos:** tipo de cliente, perfil de cliente
**Dashboards:** Scorecard
**Coluna Databricks:** `gold.fact_operations.customer_type`

---

## D

### D-1 (Fechamento)
**Tipo:** Período de referência
**Definição:** O último dia com dados completamente fechados — exclui o dia corrente, que ainda está em andamento. Modo padrão do Daily Sales Dashboard quando o toggle `Intraday = FALSE`. Garante que os números exibidos são definitivos, sem parcialidades do dia em curso.
**Exemplo:** Em 09/05/2026, D-1 = 08/05/2026.
**Sinônimos:** dia fechado, dia anterior com fechamento
**Dashboards:** Daily Sales Dashboard
**Ver também:** Intraday, MTD, PMTD

---

### Direção (in_or_out)
**Tipo:** Dimensão · Fluxo operacional
**Definição:** Indica o sentido de uma operação de câmbio em relação à Remessa Online:
- **Receiving** (Recebimento / Inbound): cliente recebe recursos do exterior
- **Sending** (Envio / Outbound): cliente envia recursos para o exterior

**Sinônimos:** sentido da operação, fluxo, in_or_out
**Coluna Databricks:** `gold.fact_operations.in_or_out`

---

### Diamond
**Tipo:** Camada de dados (Databricks)
**Definição:** Camada mais refinada e autoritativa da Remessa Online — acima do Gold. Dados totalmente consolidados, validados e aprovados por negócio e time de dados. 🔵 Nível máximo de confiança. **Prioridade de uso sempre que disponível.**
**Sinônimos:** —
**Ver também:** Bronze, Silver, Gold

---

## E

### Event Type
**Tipo:** Dimensão
**Definição:** Tipo de evento que originou a operação de câmbio (ex: remessa internacional, pagamento de boleto, conversão de moeda).
**Sinônimos:** tipo de evento
**Dashboards:** Scorecard
**Coluna Databricks:** `gold.fact_operations.event_type`

---

## F

### First Click (FC)
**Tipo:** Modelo de atribuição · Marketing
**Definição:** Modelo que credita a **primeira sessão** do cliente como origem de conversão (Presignup ou Aquisição). Contrasta com o Last Click, que credita a última sessão. No modelo Power BI, implementado como dimensões duplicadas (`d_canal_fc`, `d_mkt_campaign_fc`) para permitir relacionamento com colunas `canal_fc`/`mkt_campaign_fc` da fato.
**Sinônimos:** first-click attribution, primeira interação
**Dashboards:** Mkt Performance
**Ver também:** Last Click, Attribution Window

---

### Fonte de Entrada
**Tipo:** Dimensão operacional
**Definição:** Como uma ordem de pagamento foi criada no sistema da Remessa Online. Classifica a origem técnica da instrução de pagamento.

| Tipo | Descrição |
|------|-----------|
| API | Integração programática |
| Arquivo da OPR | Upload de arquivo batch |
| Ferramenta de Emenda | Correção via ferramenta interna |
| Coleta Local | Pagamento coletado presencialmente |
| Emenda Manual | Ajuste manual pelo backoffice |
| Wallet / Conta Global | Originada da carteira digital |
| Falha API | Tentativa de API que falhou |
| N/A | Tipo não identificado |

**Dashboards:** Dashboard - Recebimento
**Tabelas Databricks:** `beecambio.beecambio_tbl_payment_order`, `banking_payments.public_payment_order`, `conciliation_service.conciliation_payment_orders`

---

### Funil de Drop-off
**Tipo:** Análise de funil · Retenção
**Definição:** Conjunto de clientes que passaram pelo Presignup (e possivelmente Signup) mas **nunca realizaram uma ordem de pagamento**. Identificados pelo anti-join entre `gold.funnel_event` e `silver.orders`. Foco da página "Funil de Drop" no Dashboard - Recebimento.
**Sinônimos:** drop-off, churn de cadastro, abandono de funil
**Dashboards:** Dashboard - Recebimento
**Medida DAX:** `Total Users` (DISTINCTCOUNT de clientes no funil sem operação)
**Ver também:** Presignup, Aquisição, Ordem de Pagamento

---

### FxaaS
**Tipo:** Canal de parceiros · Classificação de origem
**Definição:** Modelo de distribuição em que parceiros B2B integram a plataforma da Remessa Online via API para originar PSUs e operações em nome de seus próprios clientes. Identificado pelo padrão `%fxaas%` no email do cliente (para presignups/signups) ou pela flag `is_fxaas = TRUE` em operações.
**Impacto em análises:** PSUs e operações FxaaS **não representam captação de marketing** — são volume de parceiros. Incluí-los distorce métricas como CPP, taxa de conversão e eficiência de canal.
**Sinônimos:** fxaas, parceiros FxaaS, B2B API
**Dashboards:** Scorecard, Dashboard de Safras, Daily Sales Dashboard, Mkt Performance, Gestão de Receita
**Como identificar:**
- Presignups/Signups: `bronze.beecambio_customer.email LIKE '%fxaas%'` ou `silver.signup.email LIKE '%fxaas%'`
- Operações: `gold.fact_operations.is_fxaas = TRUE`
- Nome do parceiro: `gold.fact_operations.partner_name_from_fxaas`
**Ver também:** Presignup, Afiliado / Parceiro, is_fxaas

---

## G

### GMV (Gross Merchandise Volume)
**Tipo:** KPI ⭐
**Definição:** Volume total transacionado em câmbio — soma do valor bruto de todas as operações de câmbio processadas no período. Métrica primária de escala do negócio.
**Sinônimos:** volume transacionado, volume bruto
**Dashboards:** Scorecard, Daily Sales Dashboard
**Medida DAX:** `Medidas.GMV` (Scorecard) / `# Medidas.GMV` (Daily Sales)
**Coluna Databricks:** A definir (valor da operação em `gold.fact_operations`)

### Gold
**Tipo:** Camada de dados (Databricks)
**Definição:** Modelos analíticos consolidados, gerados e documentados via DBT. 🟢 Alto nível de confiança. Fonte padrão para dashboards analíticos quando Diamond não estiver disponível.
**Sinônimos:** —
**Ver também:** Bronze, Silver, Diamond

### Gross Profit
**Tipo:** KPI ⭐
**Definição:** Lucro bruto — Gross Revenue descontados os custos operacionais diretos (Bank Take + custo de mensagem + Payout de afiliado). Representa o ganho líquido por operação antes de despesas indiretas.
**Fórmula:** `Gross Revenue - Total Cost`
**Sinônimos:** lucro bruto, margem bruta
**Dashboards:** Scorecard
**Medida DAX:** `Medidas.Gross Profit`

### Gross Revenue
**Tipo:** KPI ⭐
**Definição:** Receita bruta — valor total recebido do cliente menos o valor remetido ao beneficiário. Representa o spread financeiro capturado pela Remessa Online em cada operação.
**Sinônimos:** receita bruta, revenue, Receita
**Dashboards:** Scorecard, Daily Sales Dashboard
**Medida DAX:** `Medidas.Gross Revenue` (Scorecard) / `# Medidas.Receita` (Daily Sales)
**Coluna Databricks:** A definir

### Growth
**Tipo:** Métrica derivada
**Definição:** Variação percentual de um KPI em relação ao período anterior equivalente. Calculado automaticamente pelo Calculation Group `Month over month`.
**Fórmula:** `(Valor Atual - Valor Anterior) / |Valor Anterior|`
**Sinônimos:** variação, crescimento, delta
**Dashboards:** Scorecard

---

## H

### Histórias Aprovadas (Approved Story)
**Tipo:** Evento de funil — jornada PJ
**Definição:** Evento que ocorre quando o histórico de crédito ou perfil empresarial de um cliente Pessoa Jurídica é aprovado pela Remessa Online. Etapa intermediária entre Signup e Aquisição para clientes PJ.
**Sinônimos:** Approved Story, aprovação de crédito PJ
**Dashboards:** Dashboard de Safras
**Medida DAX:** `# Medidas.Histórias Aprovadas`
**Coluna Databricks:** `gold.funnel_event.event_type = 'APPROVED STORY'`

---

## I

### Intraday
**Tipo:** Modo de visualização
**Definição:** Modo do Daily Sales Dashboard que **inclui os dados do dia corrente** (parciais, pois o dia ainda não fechou). Ativado pelo toggle `Intraday Flag = TRUE`. Útil para acompanhamento em tempo real durante o dia. Contraste com o modo **Fechamento (D-1)**, que exibe apenas dias com dados completos.
**Impacto:** As medidas `Receita`, `GMV`, `Ops` e todas as variantes de `Realizado` respondem ao toggle via `SELECTEDVALUE('Intraday Flag'[Intraday])`.
**Recomendação:** Usar modo Fechamento para análises comparativas e reports executivos. Usar Intraday apenas para acompanhamento operacional durante o dia.
**Sinônimos:** modo ao vivo, tempo real
**Dashboards:** Daily Sales Dashboard
**Ver também:** D-1, MTD

---

### Instituição Financeira Parceira
**Tipo:** Entidade · Parceiro operacional
**Definição:** Banco que executa a liquidação das ordens de pagamento na infraestrutura da Remessa Online. Atualmente monitorado com foco em **Topázio** (id=3) no Dashboard - Recebimento (Crédito Identificado). Outras instituições parceiras (ex: Master) processam outros tipos de ordens.
**Sinônimos:** banco parceiro, financial institution
**Dashboards:** Dashboard - Recebimento
**Ver também:** Crédito Identificado, Ordem de Pagamento

---

### is_intercompany
**Tipo:** Flag (filtro)
**Definição:** Indica transações realizadas entre empresas do grupo Remessa Online. O Scorecard **exclui** estas transações (`is_intercompany = false`) para refletir apenas operações externas com clientes reais.
**Coluna Databricks:** `gold.fact_operations.is_intercompany`

### is_ops_processed
**Tipo:** Flag (filtro)
**Definição:** Indica operações efetivamente processadas e liquidadas no sistema. O Scorecard considera apenas operações processadas (`is_ops_processed = true`).
**Coluna Databricks:** `gold.fact_operations.is_ops_processed`

---

## L

### Last Click (LC)
**Tipo:** Modelo de atribuição · Marketing
**Definição:** Modelo padrão de atribuição de marketing que credita a **última sessão** do cliente como origem do Presignup (PSU). É o modelo principal usado no Mkt Performance. Campos associados: `canal_lc`, `source_lc`, `medium_lc`, `mkt_campaign_lc`, `ad_group_lc`.
**Sinônimos:** last-click attribution, última interação
**Dashboards:** Mkt Performance
**Ver também:** First Click, Attribution Window

---

### Lead Score
**Tipo:** Dimensão analítica · Ciência de dados
**Definição:** Pontuação calculada por modelos de machine learning do time de Data Science da Remessa Online que estima a probabilidade de conversão de um Presignup em Aquisição. Valores distintos para PF e PJ. Proveniente de `sandbox_datascience.leadscore_notas_pf/pj`.
**Atenção:** Dado do schema `sandbox_datascience` — ambiente potencialmente experimental. Verificar estabilidade com o time de Dados.
**Sinônimos:** score de conversão, propensão de conversão
**Dashboards:** Mkt Performance
**Coluna Databricks:** `sandbox_datascience.leadscore_notas_pf`, `sandbox_datascience.leadscore_notas_pj`

---

## M

### MoM (Month-over-Month)
**Tipo:** Comparativo temporal
**Definição:** Comparação de um KPI entre o mês atual e o mês imediatamente anterior. Calculado pelo Calculation Group.
**Sinônimos:** mês a mês, variação mensal
**Dashboards:** Scorecard

### Media Funnel
**Tipo:** Dimensão de marketing · Estratégia
**Definição:** Categorização das campanhas de mídia paga por etapa estratégica do funil:
- **Performance** — conversão direta (padrão)
- **Consideração** — mid-funnel (campanhas com `%consideracao%` no nome)
- **Awareness** — reconhecimento de marca (campanhas com `%awareness%` no nome)

**Sinônimos:** etapa do funil, funil de mídia
**Dashboards:** Mkt Performance
**Coluna Databricks:** derivado do nome da campanha em `bronze.paid_media_investments`
**Ver também:** CPA, CPP

---

### Meta Diária
**Tipo:** Conceito de planejamento
**Definição:** Valor-alvo definido para cada dia do mês. No Daily Sales Dashboard, as metas de GMV, Receita e Operações são extraídas diretamente da camada gold (`gold.daily_sales`), calculadas upstream pelo DBT. **Exceção:** a Meta de PNL é hardcoded na query M da tabela `f_pnl_tesouraria` — exige edição manual a cada mudança.
**Sinônimos:** target diário, goal
**Dashboards:** Daily Sales Dashboard
**Ver também:** GAP vs. Meta, Projeção de Fechamento

---

### MTD (Month-to-Date)
**Tipo:** Acumulado temporal
**Definição:** Valor acumulado do mês corrente, da virada do mês até a data de referência (D-1 no modo Fechamento).
**Sinônimos:** acumulado do mês
**Dashboards:** Scorecard, Daily Sales Dashboard
**Ver também:** PMTD, YTD, D-1

---

## N

### Natureza da Operação
**Tipo:** Dimensão regulatória
**Definição:** Classificação do propósito legal da remessa internacional conforme regulamentação cambial. Exemplos: Viagem, Educação, Manutenção de Pessoa no Exterior, Importação. Campo obrigatório em operações de câmbio.
**Regra de uso:** Sempre usar `UPPER(nature_operation_name)` — os valores são armazenados em maiúsculas no Databricks.

**Mapeamentos frequentes:**

| Descrição coloquial | Valor em Databricks (`UPPER`) |
|--------------------|------------------------------|
| "ganho com ações" | `GANHO EM AÇÕES` |
| "mandar pra mim mesmo" | `DISPONIBILIDADE NO EXTERIOR` |
| "investir fora" / "bolsa americana" | `CONTA INVESTIMENTO` |

**Sinônimos:** natureza, nature_operation_name
**Dashboards:** Gestão de Receita
**Coluna Databricks:** `gold.fact_operations.nature_operation_name` (renomeado para `natureza` no modelo)

### Net Revenue / Receita Líquida
**Tipo:** KPI · Resultado por operação
**Definição:** Receita líquida por operação após dedução de todos os custos diretos: mensageria + bank take + payout de afiliados + comissões de parceiros. É o "lucro por operação". Pode ser negativo quando os custos superam a receita bruta.
**Fórmula:** `Gross Revenue − bank_take − real_message_cost − payout_affiliate − partner_commissioning`
**Sinônimos:** lucro por operação, net revenue, receita líquida
**Dashboards:** Gestão de Receita
**Medida DAX:** `Medidas.Total Receita Líquida`
**Coluna Databricks:** `gold.fact_operations.net_revenue`
**Atenção:** No Gestão de Receita, o `net_revenue` em `processed_operations` usa `cost_bank_take` direto de gold. O cálculo equivalente em `customer` usa bank take alocado via `finance_cube.kpi_list` — os valores podem divergir. Ver `Bank Take`.

---

## O

### Ordem de Pagamento
**Tipo:** Entidade operacional
**Definição:** Instrução de transferência enviada por um cliente para o sistema da Remessa Online. Ciclo de vida: **criada → pendente → resgatada** (ou cancelada/rejeitada). Uma ordem pendente ainda não virou uma operação de câmbio liquidada. Registrada em `silver.orders`.
**Distinção com Operação:** Uma "operação" (`gold.fact_operations`) representa a transação liquidada. Uma "ordem" pode estar em vários status — as pendentes são estimadas com `gmv_forecast = quantity × cotação_do_dia`.
**Sinônimos:** payment order, order, instrução de pagamento
**Dashboards:** Dashboard - Recebimento
**Tabela Databricks:** `silver.orders`
**Ver também:** Resgate, Crédito Identificado, Operação de câmbio

---

### Operação de câmbio
**Tipo:** Entidade central
**Definição:** Transação de envio ou conversão de moeda estrangeira processada pela Remessa Online. É a unidade atômica de negócio — 1 linha em `gold.fact_operations` = 1 operação.
**Sinônimos:** operação, transação, order
**Coluna Databricks:** `gold.fact_operations` (tabela inteira)

### Operations
**Tipo:** KPI ⭐
**Definição:** Número de operações de câmbio processadas no período. Métrica de volume operacional — conta operações, não clientes.
**Sinônimos:** número de operações, transações, orders, Ops
**Dashboards:** Scorecard, Daily Sales Dashboard
**Medida DAX:** `Medidas.Operations` (Scorecard) / `# Medidas.Ops` (Daily Sales)

---

## P

### PNL / Tesouraria
**Tipo:** KPI · Resultado financeiro
**Definição:** Resultado da tesouraria nas operações de câmbio — receita específica que flui para a área de tesouraria, registrada na coluna `gross_revenue_treasury` de `gold.fact_operations`. Diferente da **Gross Revenue** (spread comercial capturado), o PNL de Tesouraria reflete a rentabilidade das operações sob a ótica da tesouraria.
**Meta de PNL:** Definida anualmente por BU e distribuída proporcionalmente pelos dias úteis — atualmente hardcoded na query M de `f_pnl_tesouraria` (2025 e 2026). ⚠️ Exige edição manual a cada mudança de meta ou BU.
**Sinônimos:** resultado de tesouraria, PNL
**Dashboards:** Daily Sales Dashboard
**Medida DAX:** `# Medidas.PNL`
**Coluna Databricks:** `gold.fact_operations.gross_revenue_treasury`
**Ver também:** Gross Revenue, Meta Diária

---

### PMTD (Previous Month-to-Date)
**Tipo:** Período de comparação
**Definição:** O mesmo intervalo do mês anterior — do dia 1 até o mesmo dia N do mês corrente, mas no mês passado. Permite comparação justa de performance no mesmo ponto do ciclo mensal. Exemplo: se hoje é dia 9 de maio, PMTD = soma do dia 1 ao dia 8 de abril.
**Sinônimos:** mesmo período do mês anterior
**Dashboards:** Daily Sales Dashboard
**Ver também:** MTD, MOM

---

### Presignup (PSU)
**Tipo:** Evento de funil · Topo do funil
**Definição:** Primeira etapa da jornada do cliente na Remessa Online — o momento em que o usuário demonstra interesse e inicia o processo de abertura de conta. É o início de uma **safra** (cohort). Todo cliente passa pelo Presignup antes de chegar ao Signup e à Aquisição.

**Variantes — distinção FxaaS:**

| Variante | Descrição | Quando usar |
|----------|-----------|-------------|
| **Sem FxaaS** | PSUs de clientes orgânicos e de marketing — originados pela Remessa Online diretamente | Padrão em análises de marketing, CPP, funil de conversão |
| **Com FxaaS** | PSUs de contas de parceiros (integrações B2B) — identificados pelo padrão `%fxaas%` no email | Análise de parceiros, volume bruto total |

**Regra de uso:** Análises de marketing (CPP, canal, conversão) devem sempre excluir FxaaS — caso contrário, os PSUs de parceiros distorcem as métricas de eficiência de mídia. O padrão adotado nos dashboards é analisar **sem FxaaS**.

**Como filtrar presignups sem FxaaS:**
```sql
-- via gold.funnel_event + bronze.beecambio_customer
WHERE fe.event_type = 'PRESIGNUP'
  AND fe.event_sequence = 1
  AND dc.email NOT LIKE '%fxaas%'

-- via gold.funnel_event + silver.signup
WHERE fe.event_type = 'PRESIGNUP'
  AND fe.event_sequence = 1
  AND sv.email NOT LIKE '%fxaas%'
```

**Sinônimos:** PSU, pré-cadastro, início de cadastro
**Dashboards:** Dashboard de Safras, Daily Sales Dashboard, Mkt Performance
**Medida DAX:** `# Medidas.Presignups`
**Coluna Databricks:** `gold.funnel_event.event_type = 'PRESIGNUP'` / `gold.daily_sales_psu.realizado_psu`
**FxaaS em operações:** `gold.fact_operations.is_fxaas` (boolean) — flag equivalente para transações
**Ver também:** Signup, Aquisição, Safra, FxaaS

---

### Projeção de Fechamento
**Tipo:** Estimativa prospectiva
**Definição:** Estimativa do valor que um KPI atingirá ao final do mês, calculada com base no ritmo acumulado até o momento. No Daily Sales Dashboard, é extraída das colunas `projecao_*` da tabela `f_daily_sales` (ex: `projecao_gross_revenue`), computadas upstream na camada gold. O dashboard pega o valor da **última linha disponível** no mês (`dcalendar[last_day] = TRUE()`).
**Sinônimos:** projeção mensal, forecast de fechamento, last day projection
**Dashboards:** Daily Sales Dashboard
**Medida DAX:** `# Medidas.Projeção de Receita (Last Day)`, `# Medidas.Projeção de GMV (Last Day)`, `# Medidas.Projeção de Ops (Last Day)`
**Coluna Databricks:** `gold.daily_sales.projecao_gross_revenue`, `gold.daily_sales.projecao_gmv`, `gold.daily_sales.projecao_operations`
**Ver também:** Meta Diária, GAP vs. Meta

### Parceiro Maxima
**Tipo:** Entidade · Canal de distribuição
**Definição:** Agente de câmbio externo cadastrado na rede Maxima que indica ou processa operações pela Remessa Online. Identificado pelo `maxima_partner_code` do cliente em `beecambio.beecambio_tbl_customer`. A classificação `Escritórios` distingue escritórios legítimos da rede de outros tipos de parceiro.
**Sinônimos:** parceiro, partner_name (Maxima)
**Dashboards:** Gestão de Receita
**Tabela Databricks:** `beecambio.beecambio_maxima_partners` (schema não-padrão)
**Ver também:** Afiliado / Parceiro

### Payout
**Tipo:** Custo operacional
**Definição:** Valor pago a afiliados/parceiros por operações originadas por eles. Compõe o **Total Cost**.
**Sinônimos:** comissão de afiliado, payout de afiliado
**Dashboards:** Scorecard, Gestão de Receita
**Coluna Databricks:** `gold.fact_operations.payout_affiliate` (afiliados) + `gold.fact_operations.partner_commissioning` (parceiros)

### Política de Preço
**Tipo:** Dimensão de precificação
**Definição:** Rótulo do regime de precificação aplicado à operação de câmbio — indica qual política de spread/tarifa foi usada (ex: política padrão, política corporativa, spread fixo). Campo `policy_label` proveniente de `beecambio.beecambio_tbl_remittance_operation`.
**Sinônimos:** policy_label, regime de preço
**Dashboards:** Gestão de Receita
**Tabela Databricks:** `beecambio.beecambio_tbl_remittance_operation` (schema não-padrão)

---

### Premium (Regras de Classificação)
**Tipo:** Segmentação de clientes · Regras críticas
**Definição:** Classificação de clientes e operações como Premium ou Potencial Premium na Remessa Online.

**Regras para operações (`gold.fact_operations`):**

| Tipo | Filtro correto | ⚠️ Nunca usar |
|------|---------------|---------------|
| Premium | `business_type IN ('Premium PF', 'Pjtão')` | `is_premium` — campo legado, não confiável |
| Potencial Premium | `is_potencial_premium = TRUE` | — |

**Regra para status atual do cliente (`gold.fact_customers`):**
- `premium_status = 'Premium'` → cliente Premium
- `premium_status = 'Potencial Premium'` → cliente Potencial Premium

**⚠️ Atenção:** `is_premium` é um campo legado. Qualquer filtro baseado nele pode retornar valores incorretos. Use exclusivamente `business_type` para operações e `premium_status` para status do cliente.
**Tabelas Databricks:** `gold.fact_operations` (operações) · `gold.fact_customers` (status do cliente)
**Ver também:** Business Type, Customer Type

---

### Processing Date
**Tipo:** Chave temporal
**Definição:** Data em que a operação de câmbio foi processada no sistema da Remessa Online. Chave de relacionamento com a dimensão `d_calendar` no modelo Power BI.
**Coluna Databricks:** `gold.fact_operations.processing_date`

---

## R

### Remetente
**Tipo:** Dimensão operacional · Contraparte
**Definição:** Instituição financeira que enviou o pagamento ao sistema da Remessa Online — nome original antes de qualquer normalização (`original_counterpart`). Diferente da "Contraparte Ajustada" (após normalização) e "Contraparte" (versão final para ranking).
**Sinônimos:** original_counterpart, banco remetente, instituição pagadora
**Dashboards:** Dashboard - Recebimento
**Coluna Databricks:** `silver.orders.original_counterpart`
**Ver também:** Ordem de Pagamento

---

### Resgate
**Tipo:** Evento operacional · Status de ordem
**Definição:** Liquidação de uma ordem de pagamento — momento em que o valor em moeda estrangeira é convertido e creditado ao beneficiário. Uma ordem "Resgatada" é equivalente a uma operação de câmbio concluída. O **prazo de resgate** é o tempo entre a criação e a liquidação.
**Distinção:** "Resgatado" = ordem liquidada (dado real). "Pendente" = ordem em aberto (dado estimado via `gmv_forecast`).
**Sinônimos:** liquidação, conversão, cash out
**Dashboards:** Dashboard - Recebimento
**Ver também:** Ordem de Pagamento, Crédito Identificado

---

## S

### Safra
**Tipo:** Conceito analítico · Cohort
**Definição:** Conjunto de clientes que realizaram um determinado evento (ex: Presignup) no **mesmo mês**. Cada mês gera uma nova safra, acompanhada ao longo do tempo para medir conversão. Exemplo: "Safra de Janeiro/2024 — PSU" = todos os clientes que fizeram presignup em jan/2024.
**Sinônimos:** cohort, coorte, grupo de origem
**Dashboards:** Dashboard de Safras
**Ver também:** Presignup, Aquisição, Conversão Cohortada

### Signup (SU)
**Tipo:** Evento de funil · Segunda etapa
**Definição:** Segunda etapa do funil da Remessa Online — o cliente concluiu o cadastro completo na plataforma. Ocorre após o Presignup e antes da Aquisição.
**Sinônimos:** SU, cadastro completo, sign up
**Dashboards:** Dashboard de Safras
**Medida DAX:** `# Medidas.Signups`
**Coluna Databricks:** `gold.funnel_event.event_type = 'SIGNUP'`
**Ver também:** Presignup, Aquisição

### Segment
**Tipo:** Dimensão
**Definição:** Segmento operacional da transação — dimensão de análise transversal que classifica operações por perfil de uso ou produto.
**Sinônimos:** segmento de operação
**Dashboards:** Scorecard
**Coluna Databricks:** `gold.fact_operations.operation_segment`

### Silver
**Tipo:** Camada de dados (Databricks)
**Definição:** Dados limpos e padronizados, gerados e documentados via DBT. 🟡 Nível médio de confiança. Usar quando Gold/Diamond não cobrir o dado necessário.
**Sinônimos:** —
**Ver também:** Bronze, Gold, Diamond

### Subsegmento PF
**Tipo:** Dimensão de segmentação
**Definição:** Classificação de persona de clientes Pessoa Física com base em comportamento de uso — indica o perfil de uso predominante do cliente em determinado mês (ex: High Value, Turista, Recorrente, Casual). Granularidade: cliente × mês.
**Sinônimos:** subsegmento, segmento PF
**Dashboards:** Gestão de Receita
**Tabela Databricks:** `stage.dim_last_subsegments` (schema não-padrão — verificar estabilidade com time de dados)
**Atenção:** O relacionamento com `processed_operations` é feito apenas por `id_customer` (sem `month_id`) — ao filtrar por subsegmento, todas as operações do cliente são incluídas independentemente do mês.

### Spread
**Tipo:** KPI ⭐
**Definição:** Margem percentual capturada por operação — quanto da Gross Revenue representa em relação ao GMV. Principal indicador de pricing da Remessa Online.
**Fórmula:** `Gross Revenue / GMV`
**Sinônimos:** margem de câmbio, taxa de spread
**Dashboards:** Scorecard, Gestão de Receita
**Medida DAX:** `Medidas.Spread` (Scorecard) / `Medidas.Spread` (Gestão de Receita — ponderado por GMV) / `Medidas.Spread medio` (Gestão de Receita — média simples por operação)
**Coluna Databricks:** `gold.fact_operations.spread` (spread declarado) / calculado como `gross_revenue / gmv`
**Atenção:** No Gestão de Receita, `spread` (declarado no momento da operação) pode divergir de `spread_calculado` (`gross_revenue / gmv`) por descontos retroativos ou ajustes pós-operação.

---

## T

### Total Cost
**Tipo:** Custo agregado
**Definição:** Soma de todos os custos operacionais diretos de uma operação: custo de mensagem + Bank Take + Payout de afiliado.
**Fórmula:** `Custo Mensagem + Bank Take + Payout`
**Sinônimos:** custo total, custos operacionais
**Dashboards:** Scorecard
**Medida DAX:** `Medidas.Total Cost`

---

## Y

## W

### Wallet / Conta Global
**Tipo:** Produto · Linha de negócio
**Definição:** Produto de cartão internacional da Remessa Online — permite ao cliente realizar transações em moeda estrangeira usando uma conta digital. As transações do cartão contribuem para as métricas de Receita e Operações no Daily Sales Dashboard. No modelo Power BI, aparece com os atributos fixos: BU = `"Wallet"`, business_type = `"Wallet EUR"`, segment = `"Conta Global"`, event_type = `"Transações do Cartão"`.
**Alerta:** A fonte de dados usa o schema `explore` (`explore.wallet_transactions`), que não pertence à hierarquia padrão bronze/silver/gold/diamond. ❓ Nível de confiança a verificar com o time de dados.
**Sinônimos:** Conta Global, cartão internacional, cartão Remessa
**Dashboards:** Daily Sales Dashboard
**Tabela Databricks:** `explore.wallet_transactions` (schema não-padrão — verificar)
**Ver também:** BU, Business Type, Operação de câmbio

---

## Y

### YoY (Year-over-Year)
**Tipo:** Comparativo temporal
**Definição:** Comparação de um KPI entre o período atual e o mesmo período do ano anterior. Elimina sazonalidade para análise de tendência de longo prazo.
**Sinônimos:** ano a ano, variação anual
**Dashboards:** Scorecard

---

*Ontologia gerenciada via `/pbi-ontologia` · Remessa Online · Mai 2026 — inclui Scorecard, Safras, Daily Sales, Gestão de Receita, Dashboard - Recebimento, Mkt Performance*
