# 06 — Glossário de Negócio: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`
>
> Termos específicos deste dashboard. Para termos corporativos canônicos, consultar `ontologia/GLOSSARY.md`.

---

## Termos específicos do Mkt Performance

---

### Attribution Window (Janela de Atribuição)
**Definição:** Modelo de atribuição que contabiliza eventos (Presignups e Aquisições) que **não foram capturados** pelo modelo de Last Click padrão — ou seja, sessões que ocorreram mas não geraram uma sessão de Last Click registrada. Representado pela tabela `f_attribution_window`. Filtra sessões cujo `session_id` **não aparece** em `google_analytics.last_click_sessions`.

**Por que existe:** O Last Click pode perder eventos quando o usuário navega por múltiplas sessões ou dispositivos. A Attribution Window complementa o funil capturando esses casos.

**Medida DAX relacionada:** Ver medidas no grupo de `f_attribution_window`.

**Ver também:** Last Click, First Click

---

### Canal (canal_lc / canal_fc)
**Definição:** Agrupamento de alto nível do canal de marketing que originou o Presignup do cliente. Exemplos: `paid search`, `organic`, `display`, `paid social`, `referral`, `unknown`.
- `canal_lc` = Last Click (última interação antes do PSU)
- `canal_fc` = First Click (primeira interação registrada)

**Regra especial:** Campanhas com nome contendo `%pmax%` são automaticamente classificadas como `display`.

**Tabela de referência:** `d_canal` (Last Click) e `d_canal_fc` (First Click)

---

### Cluster de Campanha (cluster_campaign)
**Definição:** Agrupamento editorial de campanhas de marketing em categorias macro. Usado para análise de performance por grupo estratégico de campanhas, em vez de campanha individual.

**Coluna:** `f_mkt_performance[cluster_campaign_lc]` / `d_mkt_campaign[cluster_campaign]`

---

### Cohort PSU → ACQ
**Definição:** Segmentação do tempo decorrido entre o Presignup e a Aquisição de um cliente. Agrupado em faixas: `00 a 05 dias`, `06 a 10 dias`, ..., `120+ dias`, `Não convertido`.

**Para que serve:** Entender quanto tempo os clientes levam para converter após iniciar o cadastro. KPI importante para o time de CRM e Growth.

**Coluna:** `f_mkt_performance[cohort_psu_acq]`

---

### CPA (Custo por Aquisição)
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada nova aquisição (cliente que realiza o primeiro câmbio). Calculado como `Investimento ÷ Aquisições`. Menor = mais eficiente.

**Variantes neste dashboard:**
- `CPA PF` = CPA para segmento Pessoa Física
- `CPA PJ` = CPA para segmento Pessoa Jurídica

**Ver também:** CPP, ontologia/GLOSSARY.md#CPA

---

### CPP (Custo por Presignup)
**Definição:** Quanto a Remessa Online investe em mídia paga para gerar cada Presignup. Calculado como `Investimento ÷ Presignups`. Mede a eficiência do topo do funil.

**Variantes neste dashboard:**
- `CPP PF` = CPP para segmento Pessoa Física
- `CPP PJ` = CPP para segmento Pessoa Jurídica

**Ver também:** CPA, Presignup

---

### Customer Type (Tipo de Cliente)
**Definição:** Segmentação do cliente em dois grupos principais:
- **PF** = Pessoa Física (câmbio pessoal — remessa para o exterior, viagem, etc.)
- **PJ** = Pessoa Jurídica (câmbio empresarial — pagamentos internacionais, importação/exportação)

**Coluna:** `f_mkt_performance[Customer Type]` / `d_customer_type[Customer Type]`

**Atenção:** O split do investimento entre PF e PJ é feito com **fatores fixos hardcoded** na query M de `f_investimento` (PF=58,22%, PJ=41,78%). Esses fatores devem ser revisados periodicamente com o time de Marketing.

---

### First Click (FC)
**Definição:** Modelo de atribuição que credita a **primeira sessão** do cliente como origem da conversão. Contrasta com Last Click, que credita a última sessão.

**Campos no modelo:** `canal_fc`, `mkt_campaign_fc` em `f_mkt_performance`; dimensões `d_canal_fc`, `d_mkt_campaign_fc`

**Por que há duas dimensões duplicadas (d_canal / d_canal_fc):** O modelo Power BI não permite que uma mesma dimensão se relacione com duas colunas diferentes de uma mesma tabela fato ao mesmo tempo. Por isso, `d_canal_fc` é uma cópia de `d_canal` usada exclusivamente para o relacionamento com `canal_fc`.

---

### fxaas
**Definição:** Identificação de clientes associados a contas de email do tipo `fxaas` (provavelmente contas de parceiros ou integrações específicas). Clientes com `email_fxaas = 'fxaas'` são segmentados separadamente.

**Coluna:** `f_mkt_performance[email_fxaas]`

---

### High / Mid / Low (Subsegmentação)
**Definição:** Classificação mensal do cliente por volume de operações ou valor — High, Mid ou Low. Gerada pela tabela `stage.dim_monthly_subsegmentation`.

**Atenção:** Dado proveniente do schema `stage`, potencialmente experimental.

**Coluna:** `f_mkt_performance[high_mid_low]`

---

### Investimento em Marketing
**Definição:** Total gasto em mídia paga no período, oriundo de `bronze.paid_media_investments`. Inclui todas as plataformas (Google Ads, Meta, etc.).

> ⚠️ **Alerta:** Dado de bronze — usar com cautela em comparações executivas.

**Medida DAX:** `[Investimento]`

---

### Last Click (LC)
**Definição:** Modelo de atribuição que credita a **última sessão** do cliente como origem do Presignup (PSU). É o modelo padrão usado em `f_mkt_performance`.

**Campos:** `canal_lc`, `source_lc`, `medium_lc`, `mkt_campaign_lc`, `ad_group_lc`

---

### Lead Score
**Definição:** Pontuação calculada por modelos de machine learning do time de Data Science da Remessa Online, que estima a probabilidade de conversão de um Presignup em Aquisição. Valores distintos para PF e PJ.

**Fonte:** `sandbox_datascience.leadscore_notas_pf` e `_pj` (ambiente sandbox — verificar estabilidade)

**Coluna:** `f_mkt_performance[score]`

---

### Media Funnel
**Definição:** Categorização da campanha de marketing por etapa do funil de mídia:
- **Performance** — campanhas de conversão direta (padrão)
- **Consideracao** — campanhas de consideração (mid-funnel)
- **Awareness** — campanhas de reconhecimento de marca (topo)

**Regra:** Campanhas com `%consideracao%` no nome → Consideracao; com `%awareness%` → Awareness; demais → Performance.

**Colunas:** `f_mkt_performance[media_funnel_lc]`, `f_investimento[media_funnel]`, `d_mkt_campaign[media_funnel]`

---

### Medium
**Definição:** Classificação do meio de veiculação da campanha. Exemplos: `cpc`, `organic`, `email`, `referral`, `none`.

**Tabela de referência:** `d_medium`

---

### Month PSU = Month ACQ
**Definição:** Flag booleana que indica se o mês do Presignup é o mesmo que o mês da Aquisição. Usado para análise de conversão dentro do mesmo mês.

**Colunas relacionadas:** `Month PSU = Month ACQ`, `Month PSU = Month SU`, `Month SU = Month ACQ`

---

### Operação Simbólica (API)
**Definição:** Operação realizada via API que é marcada como "simbólica" — possivelmente de testes ou integrações que não representam transações reais de câmbio.

**Coluna:** `f_mkt_performance[ops_simbolica_api]` (boolean)

---

### Origin Presignup Platform
**Definição:** Plataforma de origem do Presignup (web, app iOS, app Android, etc.).

**Coluna:** `f_mkt_performance[Origin Presignup Platform]`

---

### P1, P2, P3 (Períodos de Comparação)
**Definição:** Três períodos de tempo configuráveis pelo usuário no dashboard, usados para comparar KPIs entre diferentes janelas temporais. O usuário define cada período através dos seletores de calendário nas tabelas `t_Período 1`, `t_Período 2`, `t_Período 3`.

**Como funciona:** Relacionamentos inativos entre cada `t_Período N` e `d_calendar` são ativados via `USERELATIONSHIP` nas medidas de comparação.

---

### Qualificação do Onboarding (Pergunta 1 / Pergunta 2)
**Definição:** Respostas às perguntas de qualificação que o cliente responde durante o processo de cadastro (onboarding). Coletadas no sistema `beecambio` da plataforma.
- **Pergunta 1 (primeira_pergunta):** Objetivo principal do cliente (ex: "Pagar fornecedores")
- **Pergunta 2 (segunda_pergunta):** Objetivo + título da opção escolhida, concatenados

**Fonte:** `prod.beecambio.beecambio_onboarding_qualification_*` (banco transacional)

---

### Search Term (Termo de Busca)
**Definição:** Termo que o usuário buscou no Google (UTM term) antes de chegar ao site da Remessa Online. Extraído da URL da primeira página visitada.

**Coluna:** `f_mkt_performance[search_term]`

**Página do dashboard:** "Search Term"

---

### Source
**Definição:** Origem do tráfego. Exemplos: `google`, `facebook`, `instagram`, `(direct)`, etc.

**Tabela de referência:** `d_source`

---

### Voucher
**Definição:** Código promocional que pode ser aplicado a uma operação para oferecer desconto ou benefício ao cliente.
- `fl_voucher`: flag "Com Voucher" / "Sem Voucher"
- `voucher_code`: código específico
- `voucher_type`: tipo do voucher

---

## Referências à Ontologia Corporativa

Os termos abaixo possuem definição canônica em `ontologia/GLOSSARY.md`:

| Termo local | Termo canônico | Link |
|-------------|----------------|------|
| Aquisições | Aquisição (ACQ) | `ontologia/GLOSSARY.md#aquisição-acq` |
| Presignups | Presignup (PSU) | `ontologia/GLOSSARY.md#presignup-psu` |
| Signups | Signup (SU) | `ontologia/GLOSSARY.md#signup-su` |
| GMV | GMV | `ontologia/GLOSSARY.md#gmv` |
| Receita | Gross Revenue | `ontologia/GLOSSARY.md#gross-revenue` |
| Operações | Operação de Câmbio | `ontologia/GLOSSARY.md#operacao-de-cambio` |
| Spread | Spread | `ontologia/GLOSSARY.md#spread` |
| CPA | CPA | `ontologia/GLOSSARY.md#cpa` |
| CPP | CPP | A definir (sugestão: incluir na ontologia) |
| Media Funnel | A definir | Sugestão: incluir na ontologia |
| Attribution Window | A definir | Sugestão: incluir na ontologia |
| Lead Score | A definir | Sugestão: incluir na ontologia |

---

## Sugestões de atualização à ontologia corporativa

Os seguintes termos foram identificados neste dashboard e ainda não possuem entrada na ontologia. Confirmar com `/pbi-ontologia` para incorporar:

1. **CPP (Custo por Presignup)** — KPI de marketing já presente no KPIS.md com referência ao Daily Sales Dashboard; atualizar para incluir Mkt Performance como dashboard.
2. **CPA (Custo por Aquisição)** — Idem CPP; atualizar para incluir Mkt Performance.
3. **Attribution Window** — Conceito de modelagem de atribuição relevante para o time de Marketing.
4. **Media Funnel** — Categorização Awareness / Consideração / Performance usada em múltiplos dashboards de marketing.
5. **Lead Score** — Produto do time de Data Science usado como dimensão de análise.
6. **First Click (FC) / Last Click (LC)** — Modelos de atribuição usados no dashboard; não há definição canônica na ontologia.
