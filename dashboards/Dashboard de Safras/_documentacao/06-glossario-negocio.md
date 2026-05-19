# Dashboard de Safras — Glossário de Negócio

Termos específicos deste dashboard, com definições no contexto da Remessa Online.
Para o glossário corporativo completo, consulte [ontologia/GLOSSARY.md](../../../ontologia/GLOSSARY.md).

---

## Conceitos Centrais

### Safra (Cohort)

**Definição:** Conjunto de clientes que realizaram um determinado evento (ex: Presignup) no mesmo mês. Cada mês gera uma nova "safra" que é acompanhada ao longo do tempo.

**Exemplo:** A "safra de Janeiro/2024 no Presignup" = todos os clientes que fizeram presignup em jan/2024. O dashboard mostra quantos desses converteram em jan/2024, fev/2024, mar/2024, etc.

**Por que importa:** Permite entender o comportamento real de conversão isolado de efeitos sazonais — em vez de comparar meses diferentes que têm origens diferentes de clientes.

---

### Presignup (PSU)

**Definição:** Primeira etapa da jornada do cliente — o momento em que o usuário demonstra interesse em abrir uma conta na Remessa Online e inicia o processo de cadastro.

**No modelo:** `event_type = 'PRESIGNUP'`
**Medida:** `Presignups`

---

### Signup (SU)

**Definição:** Segunda etapa — o cliente concluiu o cadastro completo na plataforma.

**No modelo:** `event_type = 'SIGNUP'`
**Medida:** `Signups`

---

### Aquisição (ACQ)

**Definição:** O momento em que o cliente realiza sua **primeira operação de câmbio**. É a métrica de ativação — o cliente passa de cadastrado para cliente ativo.

**No modelo:** `event_type = 'ACQUISITION'`
**Medida:** `Aquisições`

**Importante:** No modelo, "Acquisition" e "Operation" são eventos distintos. A Aquisição é contabilizada apenas na primeira operação.

---

### Conversão Cohortada

**Definição:** Taxa de conversão calculada sobre a safra de origem — divide o número de clientes que converteram pelo total da safra, independentemente de quando a conversão aconteceu.

**Exemplo:** "Conversão Cohortada (ACQ/PSU) de Janeiro/2024 = 35%" significa que 35% dos clientes que fizeram presignup em janeiro chegaram a fazer uma operação em algum momento.

**Diferença de conversão não-cohortada (Uncohorted):** A conversão uncohorted simplesmente divide aquisições por presignups do mesmo período — mistura safras diferentes e pode distorcer a análise.

---

### Conversão no Mesmo Mês vs. Meses Seguintes

**Mesmo Mês:** O cliente converteu no mesmo mês em que iniciou a etapa anterior.
**Meses Seguintes:** O cliente levou mais de um mês para converter após iniciar.

O dashboard separa essas duas parcelas para entender a velocidade de conversão de cada safra.

---

### Cohort Dinâmico (dias)

**Definição:** Filtro que permite analisar a conversão dentro de uma janela de dias configurável (ex: 7, 14, 30, 60, 90 dias após o presignup). Responde a perguntas como "qual % dos clientes converte nos primeiros 30 dias?".

**Configurado via:** Slicer `p_Cohort`

---

### GMV (Gross Merchandise Volume)

**Definição:** Volume total em reais (R$) das operações de câmbio realizadas pelos clientes. Representa o dinheiro movimentado — não a receita da Remessa Online.

**No modelo:** `SUM(f_funnel_events[gmv])` para eventos de OPERATION e ACQUISITION.

---

### Gross Revenue (Receita Bruta)

**Definição:** Receita bruta gerada pelas operações — corresponde ao spread/taxa cobrado pela Remessa Online sobre o volume transacionado (GMV). É menor que o GMV.

---

### Histórias Aprovadas (Approved Story)

**Definição:** Evento específico da jornada PJ — ocorre quando o histórico de crédito ou perfil empresarial do cliente é aprovado. É uma etapa intermediária antes da Aquisição para clientes Pessoa Jurídica.

**No modelo:** `event_type = 'APPROVED STORY'`

---

### PJ (Pessoa Jurídica)

**Definição:** Clientes do tipo Pessoa Jurídica — empresas que realizam operações de câmbio. A página "PJ" do dashboard filtra exclusivamente esse segmento (`Customer Type = 'PJ'`).

**Relevância:** A jornada PJ tem etapas adicionais (ex: APPROVED STORY) e taxas de conversão diferentes da jornada PF.

---

### Segunda Operação (Cohorted)

**Definição:** Clientes que realizaram ao menos uma operação após a Aquisição (segunda operação em diante). Indicador de retenção — mede quantos clientes voltam a operar após a primeira transação.

---

### Canal / Source / Medium / Campaign (UTM)

**Definição:** Parâmetros de tracking de marketing (UTM parameters) que identificam como o cliente chegou à Remessa Online.

| Parâmetro | Descrição | Exemplo |
|-----------|-----------|---------|
| Canal | Agrupamento alto nível | paid, organic, referral |
| Source | Origem do tráfego | google, facebook, bing |
| Medium | Meio de veiculação | cpc, email, organic |
| Campaign | Nome da campanha | black-friday-2024 |
| Ad Group | Grupo de anúncios dentro da campanha | remessa-pj-v1 |

---

### Refresh Date

**Definição:** Timestamp da última atualização dos dados do dashboard, ajustado para UTC-3 (fuso de Brasília). Indica até quando os dados estão atualizados.

---

## Siglas Usadas no Dashboard

| Sigla | Significado |
|-------|------------|
| PSU | PreSignUp |
| SU | SignUp |
| ACQ | ACQuisition (Aquisição) |
| GMV | Gross Merchandise Volume |
| CR | Conversion Rate (Taxa de Conversão) |
| PJ | Pessoa Jurídica |
| PF | Pessoa Física |
| KPI | Key Performance Indicator |
| MTD | Month To Date |
| YTD | Year To Date |

---

## Link para Ontologia Corporativa

- [ontologia/GLOSSARY.md](../../../ontologia/GLOSSARY.md) — Glossário corporativo completo
- [ontologia/KPIS.md](../../../ontologia/KPIS.md) — KPIs estratégicos da Remessa Online
- [ontologia/MAPPING.md](../../../ontologia/MAPPING.md) — Mapeamento DAX → Databricks
