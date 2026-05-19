# Dashboard de Safras — Inventário de Tabelas

**Total:** 34 tabelas | 1 fato · 7 dimensões · 3 auxiliares · 1 medidas · 22 parâmetros

---

## Tabela Fato

### f_funnel_events

| Atributo | Valor |
|----------|-------|
| Tipo | Fato |
| Camada | 🟢 gold (com JOINs bronze ⚠️) |
| Fonte | Databricks — `Value.NativeQuery` |
| Tabela base | `gold.funnel_event` |

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id_customer` | string | Identificador único do cliente |
| `event_type` | string | Tipo do evento: PRESIGNUP, SIGNUP, ACQUISITION, OPERATION, APPROVED STORY |
| `event_id` | string | Identificador único do evento |
| `event_date` | date | Data do evento (chave de relacionamento com d_calendar) |
| `event_month` | date | Mês do evento |
| `Customer Type` | string | Tipo de cliente: PF ou PJ |
| `Company Type` | string | Tipo de empresa (para PJ) |
| `Onboarding Type` | string | Tipo de onboarding |
| `cnae_session` | string | Seção CNAE (atividade econômica) |
| `cnae_division` | string | Divisão CNAE |
| `cnae_group` | string | Grupo CNAE |
| `cnae_class` | string | Classe CNAE |
| `cnae_subclass` | string | Subclasse CNAE |
| `signup_date` | date | Data de signup do cliente |
| `signup_month` | date | Mês de signup |
| `canal_lc` | string | Canal de marketing (chave para d_canal) |
| `medium_lc` | string | Meio de marketing (chave para d_medium) |
| `source_lc` | string | Fonte de marketing (chave para d_source) |
| `mkt_campaign_lc` | string | Campanha de marketing (chave para d_mkt_campaign) |
| `ad_group_lc` | string | Grupo de anúncios (chave para d_adgroup) |
| `gmv` | decimal | Volume bruto de negócios (Gross Merchandise Volume) |
| `gross_revenue` | decimal | Receita bruta da operação |
| `full_registration` | boolean | Cadastro 100% preenchido |
| `Mês do Presignup` | date | Mês de ocorrência do presignup |
| `Mês do Signup` | date | Mês de ocorrência do signup |
| `Mês da Aquisição` | date | Mês de ocorrência da aquisição |
| `Mês da Operação` | date | Mês de ocorrência da operação |
| `Month PSU = Month ACQ` | boolean | Flag: presignup e aquisição no mesmo mês |
| `Month SU = Month ACQ` | boolean | Flag: signup e aquisição no mesmo mês |
| `Month PSU = Month SU` | boolean | Flag: presignup e signup no mesmo mês |
| `Diferença de Meses` | int | Meses entre presignup e aquisição |
| `Diferença de Dias entre Presignup e Aquisição` | int | Dias entre presignup e aquisição |
| `diff_days_psu_to_acq_category` | string | Categoria da diferença em dias |
| `second_operation_month` | date | Mês da segunda operação (para cohort de retenção) |
| `origin_platform_psu` | string | Plataforma de origem no presignup |
| `event_type_id` | int | Ordenação numérica dos event_types |

> ⚠️ **Alerta Bronze:** A query SQL desta tabela inclui JOINs com `bronze.beecambio_history` e tabelas do schema `beecambio.*`. Dados bronze não passaram por transformação DBT — maior risco de inconsistências. Ver [05-fontes.md](05-fontes.md).

---

## Tabelas Dimensão

### d_calendar

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Calendário |
| Camada | Dataflow (linhagem pendente — ver `/pbi-fluxo-de-dados`) |
| Fonte | Power BI Dataflow `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` |
| Entidade Dataflow | `dcalendar` |
| Workspace | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |

Tabela de calendário compartilhada com outros dashboards (ex: Scorecard). Contém colunas de data, mês, trimestre, semana, flags MTD, YTD, dia útil, e suporte a semana personalizada via `NomeSemana`.

---

### d_canal

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Canal de Marketing |
| Camada | Dataflow (linhagem pendente) |
| Fonte | Power BI Dataflow `e4f720d3-c121-4344-a842-0c3f84f0380c` |
| Entidade Dataflow | `mkt_canal` |

Contém os canais de marketing (ex: organic, paid, referral). Relacionada via `canal_lc`.

---

### d_source

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Fonte de Marketing |
| Camada | Dataflow (linhagem pendente) |
| Fonte | Power BI Dataflow (workspace `5381a7f5`) |

Fontes de tráfego (ex: google, facebook, direct). Relacionada via `source_lc`.

---

### d_medium

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Meio de Marketing |
| Camada | Dataflow (linhagem pendente) |
| Fonte | Power BI Dataflow (workspace `5381a7f5`) |

Meios de tráfego (ex: cpc, email, organic). Relacionada via `medium_lc`.

---

### d_adgroup

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Grupo de Anúncios |
| Camada | Dataflow (linhagem pendente) |
| Fonte | Power BI Dataflow (workspace `5381a7f5`) |

Grupos de anúncios de campanhas pagas. Relacionada via `ad_group_lc`.

---

### d_mkt_campaign

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Campanha de Marketing |
| Camada | Dataflow (linhagem pendente) |
| Fonte | Power BI Dataflow (workspace `5381a7f5`) |

Campanhas de marketing (UTM campaign). Relacionada via `mkt_campaign_lc`.

---

### d_last_update

| Atributo | Valor |
|----------|-------|
| Tipo | Dimensão — Controle de Atualização |
| Camada | 🟢 Databricks (query direta) |
| Fonte | `SELECT CURRENT_TIMESTAMP - INTERVAL '3' HOUR AS last_update` |

Tabela com uma linha, retorna o timestamp da última carga ajustado para fuso horário de Brasília (UTC-3).

---

## Tabelas Auxiliares

### NomeSemana

| Atributo | Valor |
|----------|-------|
| Tipo | Auxiliar — Seleção de Dia de Início de Semana |
| Fonte | Tabela estática (M) |

Permite ao usuário selecionar qual dia da semana começa a semana (Segunda, Terça... Domingo). Usada por medidas dinâmicas em `d_calendar`.

---

### d_intervalo_meses

| Atributo | Valor |
|----------|-------|
| Tipo | Auxiliar — Seleção de Intervalo |
| Fonte | Tabela estática (M) |

Parâmetro de seleção do intervalo de meses para a média móvel (ex: 3 meses, 6 meses). Usada pela medida `Aquisições Cohortadas do Presignup - Média Móvel Últimos 6 meses`.

---

### t_Cohort

| Atributo | Valor |
|----------|-------|
| Tipo | Auxiliar — Seleção de Dias para Cohort Dinâmico |
| Fonte | Tabela estática (M) |

Lista de valores de dias (ex: 7, 14, 30, 60, 90) para o filtro de "Cohort Dinâmico" — permite analisar conversão dentro de X dias.

---

## Tabelas de Parâmetro (22 tabelas `p_*`)

Tabelas de seleção e configuração de visuais. Não possuem fonte de dados externa — são construídas via DAX/M ou são parâmetros dinâmicos usados pelos visuais de matriz cohort.

| Tabela | Finalidade |
|--------|-----------|
| `p_Timeframe` | Seleção de janela temporal |
| `p_Dimension_PSU_1` a `_6` | Dimensões de análise do Presignup (até 6 eixos de corte) |
| `p_Dimension_ACQ` | Dimensão de análise da Aquisição |
| `p_Aquisições (PSU - Cohort)` | Parâmetro de medida para a matriz cohort de PSU |
| `p_Aquisições (SU - Cohort)` | Parâmetro de medida para a matriz cohort de SU |
| `p_Clientes únicos` | Parâmetro para análise de clientes únicos |
| `p_Presignups` | Parâmetro para análise de presignups |
| `p_Segunda Operação (ACQ - Cohorted)` | Parâmetro para análise de segunda operação |
| `p_Funil_1` / `_2` / `_3` | Configurações do visual de funil |
| `p_Cohort` | Seleção de dias para cohort dinâmico |
| `p_Modo de Exibição` | Alterna entre visualização absoluta (#) e percentual (%) |
| `p_Medidas` | Seletor dinâmico de medida |
| `p_Medidas_Telas` | Controle de quais medidas aparecem em cada tela |
| `p_Medida_Tentativa` | Medida auxiliar em desenvolvimento |
| `p_Onboarding_PJ` | Parâmetro específico para análise PJ |
