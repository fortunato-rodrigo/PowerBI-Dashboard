# Dashboard - Recebimento — Glossário de Negócio

## Sobre este arquivo

Termos de negócio específicos do dashboard Recebimento (Ordens e Remetentes). Para termos corporativos transversais, consulte a [ontologia corporativa](../../../ontologia/GLOSSARY.md).

---

## Termos específicos deste dashboard

### Ordem de Pagamento

Uma instrução de transferência enviada por um cliente para o sistema da Remessa Online. Cada ordem tem um ciclo de vida: **criada → pendente → resgatada** (ou cancelada/rejeitada).

**Distinção com Operação:** Uma "operação" (`gold.fact_operations`) representa a transação de câmbio processada e liquidada. Uma "ordem" (`silver.orders`) representa a intenção de pagamento, que pode estar em vários status. Ordens pendentes ainda não viraram operações.

---

### Status da Ordem (`status_ordem_resumo`)

| Status | Significado |
|--------|-------------|
| **Resgatado** | Ordem processada — crédito confirmado na conta do beneficiário |
| **Pendente** | Ordem criada, aguardando processamento ou identificação do crédito |
| Cancelado/Rejeitado | Ordens que não avançaram (não aparecem nas medidas principais) |

---

### Resgate

Processo de liquidação de uma ordem de pagamento — momento em que o valor em moeda estrangeira é convertido e creditado. O "prazo de resgate" é o tempo entre a criação e a liquidação da ordem.

---

### Prazo de Resgate

Coluna calculada que classifica o tempo entre criação e liquidação da ordem:
- **≤ 180 dias:** resgate dentro do prazo padrão
- **> 180 dias:** resgate tardio — pode indicar ordens problemáticas ou casos especiais

---

### Resgate no Mesmo Mês

Flag `resgate_mesmo_mes = TRUE` quando a ordem foi criada **e** resgatada dentro do mesmo mês calendário. Indicador de eficiência operacional — quanto mais ordens resgatadas no mesmo mês, mais fluído é o processo.

---

### GMV Pendente (Forecast) vs. GMV Resgatado

| Conceito | Fonte | Confiabilidade |
|----------|-------|----------------|
| **GMV (Resgatado)** | `f_orders[gmv]` — valor real da operação liquidada | Alta — dado real |
| **GMV Pendente (Forecast)** | `f_orders[gmv_forecast]` = `quantity × cotação do dia` | Estimativa — cotação pode mudar até o resgate |

---

### Receita Pendente (Forecast)

Estimativa de receita para as ordens ainda em aberto. Calculada como:

```
GMV Pendente (Forecast) × Spread (What if?)
```

> ⚠️ **Dependência de parâmetro:** O resultado varia conforme o spread selecionado no slider "What if?". O modelo não usa o spread real das ordens pendentes — usa o spread do simulador.
>
> ⚠️ **Spread hardcoded:** A coluna `gross_revenue_forecast = quantity * 0.0083` usa 0,83% fixo. Diferente do spread real que varia por cliente e política.

---

### Simulador de Spread ("What if?")

Slider interativo no dashboard que permite projetar receita com diferentes hipóteses de spread:

| Parâmetro | Range | Passo |
|-----------|-------|-------|
| **Spread (What if?)** | 0% a 2% | 0,01% |

Com 0,83% selecionado, o valor coincide com o spread padrão hardcoded. Com valores diferentes, simula cenários alternativos.

---

### Remetente vs. Contraparte

| Conceito | Coluna | Origem | Significado |
|----------|--------|--------|-------------|
| **Remetente** | `Remetente` | `original_counterpart` | Nome original da instituição que enviou o pagamento |
| **Contraparte Ajustada** | `Contraparte Ajustada` | `counterpart` | Após normalização de nomes (ex: variações do mesmo banco) |
| **Contraparte** | `Contraparte` | `contraparte_ajustada_para_ranking_final` | Versão final usada para ranqueamento e análise |

Divergências entre `Remetente` e `Contraparte` indicam que o nome foi normalizado durante o processo de conciliação.

---

### Crédito Identificado

Status intermediário no ciclo da ordem de pagamento. Ocorre quando o sistema da Remessa Online identifica que um crédito chegou ao banco parceiro (Topázio), mas ainda não foi totalmente processado.

**Por que somente Topázio?** O filtro `id_financial_institution = 3` na tabela `f_credito_identificado` limita a visão ao banco Topázio. Outras instituições financeiras parceiras não aparecem nesta página do dashboard.

---

### Fonte de Entrada de Ordens (`fonte_entrada`)

Classificação de como uma ordem de pagamento foi criada no sistema:

| Fonte | Descrição | Sistema de origem |
|-------|-----------|-------------------|
| **API** | Integração programática com o sistema | `beecambio` |
| **Arquivo da OPR** | Upload de arquivo batch de ordens | `beecambio` |
| **Ferramenta de Emenda** | Correção via ferramenta interna | `beecambio` |
| **Coleta Local** | Pagamento coletado presencialmente | `beecambio` |
| **Emenda Manual** | Ajuste manual pelo backoffice | `beecambio` |
| **Wallet / Conta Global** | Originada da carteira digital | `banking_payments` |
| **Falha API** | Tentativa via API que falhou | `conciliation_service` |
| **N/A** | Tipo não identificado | — |

---

### Funil de Drop-off

Análise de clientes que passaram por etapas do funil de aquisição (Presignup → Signup → Aquisição) mas **nunca realizaram uma ordem de pagamento**. Identificados pelo anti-join entre `gold.funnel_event` e `silver.orders`.

**Etapas do funil:**

| Etapa | `event_type` | Significado |
|-------|-------------|-------------|
| Presignup | `PRESIGNUP` | Iniciou o cadastro |
| Signup | `SIGNUP` | Completou o cadastro |
| Aquisição | `ACQUISITION` | Primeira operação |
| Operação | `OPERATION` | Operação recorrente |

Clientes no funil de drop-off ficaram presos entre Presignup e Aquisição sem chegar a criar uma ordem.

---

### Granularidade Temporal (`p_Timeframe`)

Seletor que controla a granularidade dos visuais de tendência e comparação:

| Opção | Granularidade |
|-------|--------------|
| Year | Anual |
| Quarter | Trimestral |
| Month | Mensal |
| Week | Semanal |
| Date | Diário |

A medida `Ordens Anterior` se adapta automaticamente à granularidade e ao modo MTD selecionado.

---

### MTD vs. MTD Calendário

| Conceito | Flag | Significado |
|----------|------|-------------|
| **MTD (dias úteis)** | `d_calendar[mtd] = TRUE` | Acumula apenas dias úteis do mês corrente |
| **MTD Calendário** | `d_calendar[mtd_calendar_days] = TRUE` | Acumula todos os dias corridos do mês |

Importante para a medida `Ordens Anterior` — a comparação com o mês anterior respeita o mesmo tipo de MTD selecionado.

---

### Instituição Financeira

Banco parceiro que executa a liquidação das ordens. Neste dashboard, o foco é em **Topázio** (id=3) na página "Crédito Identificado". A coluna `Instituição Financeira` em `f_orders` lista todas as instituições associadas às ordens.

---

### Seletores de Dimensão (Dimensão 1, 2, 3)

O dashboard permite decompor as métricas por até **3 dimensões simultâneas**. Cada seletor tem as mesmas 28 opções:

`BU`, `Onboarding Flow`, `Contraparte Ajustada`, `Contraparte`, `Cupom`, `Currency`, `Customer Type`, `Desconto`, `Fenix`, `Funil`, `Filtrar Google`, `ID Customer`, `ID da Ordem`, `Instituição Financeira`, `Onboarding Type`, `Prazo de Resgate`, `Remittance Nature`, `Resgate no mesmo mês`, `Type`, `Canal`, `Medium`, `Source`, `Mkt Campaign`, `Última BU`, `Última Business Type`, `Última Natureza`, `Último Segmento`, `Último Subsegmento`

---

## Termos corporativos usados neste dashboard

Para definições completas, consulte [ontologia/GLOSSARY.md](../../../ontologia/GLOSSARY.md):

| Termo | Ver também |
|-------|-----------|
| GMV | GLOSSARY.md → GMV |
| Gross Revenue / Receita Bruta | GLOSSARY.md → Gross Revenue |
| BU (Unidade de Negócio) | GLOSSARY.md → BU |
| Aquisição / Recorrência | GLOSSARY.md → Aquisição |
| Presignup / Signup | GLOSSARY.md → Presignup |
| Natureza da Operação | GLOSSARY.md → Natureza da Operação |

---

## Sugestões para a ontologia corporativa

| Termo | Definição proposta | Arquivo sugerido |
|-------|-------------------|-----------------|
| Ordem de Pagamento | Instrução de transferência criada pelo cliente — pode estar Pendente ou Resgatada | GLOSSARY.md |
| Resgate | Liquidação de uma ordem de pagamento — conversão e crédito ao beneficiário | GLOSSARY.md |
| Crédito Identificado | Status intermediário onde o crédito chegou ao banco parceiro mas ainda não foi totalmente processado | GLOSSARY.md |
| Fonte de Entrada | Como uma ordem foi criada: API, OPR, Coleta Local, Wallet, etc. | GLOSSARY.md |
| Funil de Drop-off | Clientes com presignup mas sem nenhuma ordem de pagamento | GLOSSARY.md |
| Instituição Financeira (parceira) | Banco que executa a liquidação das ordens (ex: Topázio, Master) | GLOSSARY.md |
| Remetente | Instituição financeira que enviou o pagamento para a Remessa Online | GLOSSARY.md |
