# 01 — Inventário de Tabelas: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`

---

## Resumo

| Categoria | Qtd |
|-----------|-----|
| Fato (Databricks direct query) | 4 |
| Dimensão (Dataflow PBI) | 9 |
| Dimensão (Databricks direct query) | 2 |
| Medidas DAX | 1 |
| Parâmetro / Seletor (Field Parameter) | 13 |
| Tabelas calculadas DAX | 4 |
| Cálculo (Calculation Group) | 1 |
| Auxiliar estática (DAX/M) | 2 |
| **Total** | **36** |

---

## Tabelas de Fato

### f_mkt_performance
| Atributo | Valor |
|----------|-------|
| **Tipo** | Fato principal |
| **Camada Databricks** | Gold / Silver / Stage / google_analytics / sandbox_datascience (mista — ver alerta) |
| **Modo de carga** | Import |
| **Grupo** | Fato |
| **Janela temporal** | `event_date >= '2024-01-01'` |

> ⚠️ **Alerta de schema misto:** A query desta tabela cruza múltiplas camadas e schemas não-padrão. Detalhes completos em `05-fontes.md`.

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `event_id` | int64 | Identificador único do evento |
| `id_customer` | int64 | Identificador do cliente |
| `event_type` | string | Tipo do evento: PRESIGNUP, SIGNUP, ACQUISITION, OPERATION, CREATED STORY, APPROVED STORY |
| `event_date` | date | Data do evento |
| `event_month` | date | Mês do evento (truncado) |
| `canal_lc` | string | Canal de marketing (Last Click / PSU) |
| `source_lc` | string | Source (Last Click / PSU) |
| `medium_lc` | string | Medium (Last Click / PSU) |
| `mkt_campaign_lc` | string | Campanha de marketing (Last Click / PSU) |
| `cluster_campaign_lc` | string | Cluster da campanha (Last Click / PSU) |
| `ad_group_lc` | string | Ad group (Last Click / PSU) |
| `canal_fc` | string | Canal de marketing (First Click) |
| `mkt_campaign_fc` | string | Campanha (First Click) |
| `Customer Type` | string | Tipo de cliente: PF ou PJ |
| `gmv` | double | Volume bruto transacionado (R$) |
| `gross_revenue` | double | Receita bruta (spread) |
| `psu_date` | date | Data do Presignup |
| `signup_date` | date | Data do Signup |
| `acquisition_date` | date | Data da Aquisição |
| `operation_date` | date | Data da Operação |
| `voucher_code` | string | Código do voucher (se aplicável) |
| `fl_voucher` | string | Flag: Com Voucher / Sem Voucher |
| `voucher_type` | string | Tipo de voucher |
| `is_affiliate` | boolean | Indica se é operação de afiliado |
| `crm_status` | string | Status CRM: Com CRM / Sem CRM |
| `primeira_pergunta` | string | Resposta à 1ª pergunta de qualificação (onboarding) |
| `segunda_pergunta` | string | Resposta à 2ª pergunta de qualificação (onboarding) |
| `country` | string | País da operação |
| `currency_abbreviation` | string | Abreviação da moeda |
| `in_or_out` | string | Direção da operação (envio ou recebimento) |
| `high_mid_low` | string | Subsegmentação do cliente (High/Mid/Low) |
| `score` | double | Lead score do cliente (modelos ML) |
| `last_update` | dateTime | Timestamp da última atualização |
| `cohort_psu_acq` | string | Coorte PSU→ACQ em faixas de dias |
| `search_term` | string | Termo de busca (UTM term) |
| `first_page_url` | string | URL da primeira página visitada |
| `cluster_url` | string | Cluster da URL de entrada |
| `device_brand_psu` | string | Marca do dispositivo no PSU |
| `device_category_psu` | string | Categoria do dispositivo no PSU |
| `os_name_psu` | string | Sistema operacional no PSU |
| `cnae_session` / `cnae_division` / `cnae_group` / `cnae_class` / `cnae_subclass` | string | Classificação CNAE do cliente PJ |
| `company_type` / `onboarding_type` / `business_type` | string | Atributos de perfil do cliente |
| `media_funnel_lc` | string | Funil de mídia (Awareness / Consideracao / Performance) |

---

### f_investimento
| Atributo | Valor |
|----------|-------|
| **Tipo** | Fato de investimento em mídia paga |
| **Camada Databricks** | ⚠️ **BRONZE** — `bronze.paid_media_investments` |
| **Modo de carga** | Import |
| **Grupo** | Fato |
| **Janela temporal** | `year(date) >= 2023 AND date < current_date` |

> ⚠️ **ALERTA BRONZE:** Esta tabela lê diretamente de `bronze.paid_media_investments`. Dados brutos, não validados pelo DBT. Usar com cautela em análises executivas.

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date_nao_usar` | date | Data do investimento (oculta no modelo — não usar diretamente) |
| `mkt_campaign_pmkt` | string | Campanha de marketing (oculta) |
| `channel_pmkt` | string | Canal (oculta) |
| `medium_pmkt` | string | Medium (oculta) |
| `source_pmkt` | string | Source (oculta) |
| `ad_group` | string | Ad group |
| `customer_type` | string | Tipo de cliente: PF ou PJ |
| `investimento` | decimal | Valor investido em R$ (custo × fator de split PF=0,5822 / PJ=0,4178) |
| `media_funnel` | string | Funil de mídia (Awareness / Consideracao / Performance) |

**Nota sobre split PF/PJ:** O custo total é dividido entre PF e PJ usando fatores fixos hardcoded na query M (PF: 58,22% / PJ: 41,78%).

---

### f_attribution_window
| Atributo | Valor |
|----------|-------|
| **Tipo** | Fato de janela de atribuição (sessões não capturadas pelo Last Click) |
| **Camada Databricks** | google_analytics / silver / gold (mista) |
| **Modo de carga** | Import |
| **Grupo** | Fato |
| **Janela temporal** | `event_date >= '2023-08-01'` |

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `event_date` | date | Data do evento |
| `canal` | string | Canal de marketing |
| `source` | string | Source |
| `medium` | string | Medium |
| `mkt_campaign` | string | Campanha |
| `ad_group_lc` | string | Ad group |
| `customer_type` | string | Tipo de cliente |
| `presignups` / `presignups_pf` / `presignups_pj` | int64 | Contagem de Presignups (total, PF, PJ) |
| `acquisitions` / `acquisitions_pf` / `acquisitions_pj` | int64 | Contagem de Aquisições (total, PF, PJ) |

---

### f_trading_quotation
| Atributo | Valor |
|----------|-------|
| **Tipo** | Fato de cotações de moeda |
| **Camada Databricks** | Silver — `silver.trading_quotations` |
| **Modo de carga** | Import |
| **Grupo** | Fato |

**Colunas principais:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `date` | date | Data da cotação |
| `trading_quotation` | double | Valor da cotação (R$/moeda) |
| `id_currency` | int64 | ID da moeda |
| `currency_abbreviation` | string | Abreviação da moeda |
| `currency_name` | string | Nome da moeda |

---

## Tabelas de Dimensão — via Power BI Dataflow

Todas as dimensões abaixo provêm do **mesmo workspace** de Dataflow:
- **Workspace ID:** `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`

Detalhes completos de cada Dataflow em `05-fontes.md`.

### d_calendar
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de tempo |
| **Fonte** | Dataflow ID: `3cbe0c71-8501-42b4-bcea-9dfb4ff7adef` · Entidade: `dcalendar` |
| **Modo de carga** | Import |
| **Transformações M adicionais** | Adiciona coluna `Fim do Mês` e flag `last_day` |

**Colunas principais:** `Date Key` (chave), `date_month`, `month_year`, `year`, `week`, `Quarter`, `month`, `day`, `dayofweek`, `is_holiday`, `workday`, `mtd`, `m0`, `m1`, `last_day`, `is_ytd`, `Google Day`, `Current Month`, `Filter Today`

---

### d_canal
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de canal de marketing |
| **Fonte** | Dataflow ID: `e4f720d3-c121-4344-a842-0c3f84f0380c` · Entidade: `mkt_canal` |

**Colunas:** `canal`

---

### d_canal_fc
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de canal (First Click) |
| **Fonte** | Dataflow ID: `e4f720d3-c121-4344-a842-0c3f84f0380c` · Entidade: `mkt_canal` |

**Nota:** Mesma entidade que `d_canal`. Criada como tabela separada para suportar relacionamentos com First Click sem criar ambiguidade.

**Colunas:** `canal`

---

### d_medium
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de medium de marketing |
| **Fonte** | Dataflow ID: `85ec54e9-eae3-4eaa-85e9-ef8150b1f8e8` · Entidade: `mkt_medium` |

**Colunas:** `medium`

---

### d_source
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de source de marketing |
| **Fonte** | Dataflow ID: `b1d3ec0b-66a7-4ccd-be25-7cffbd3c9852` · Entidade: `mkt_source` |

**Colunas:** `source`

---

### d_mkt_campaign
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de campanha de marketing (Last Click) |
| **Fonte** | Dataflow ID: `b289027c-da70-4578-8627-0c05c1471ac3` · Entidade: `mkt_campaign` |

**Colunas:** `Campaign`, `cluster_campaign`, `investment_type`, `media_funnel`, `paid_search_restructuring`, `awareness_2024`

---

### d_mkt_campaign_fc
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de campanha (First Click) |
| **Fonte** | Dataflow ID: `b289027c-da70-4578-8627-0c05c1471ac3` · Entidade: `mkt_campaign` |

**Nota:** Mesma entidade que `d_mkt_campaign`. Separada para relacionamento com First Click.

**Colunas:** `Campaign`, `cluster_campaign`, `investment_type`, `media_funnel`, `paid_search_restructuring`, `awareness_2024`

---

### d_adgroup
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de ad group |
| **Fonte** | Dataflow ID: `d823fda8-e56a-4fdb-a243-e10604f3ff69` · Entidade: `mkt_adgroup` |

**Colunas:** `ad_group`

---

### d_customer_type
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de tipo de cliente |
| **Fonte** | Dataflow ID: `ee7b4dce-a733-4365-9194-bfea34031f1a` · Entidade: `customer_type` |

**Colunas:** `Customer Type` (PF / PJ)

---

## Tabelas de Dimensão — via Databricks (query direta)

### d_qualificacao_1
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de qualificação de onboarding (pergunta 1) |
| **Camada Databricks** | Silver / prod.beecambio (mista) |
| **Modo de carga** | Import |

**Colunas:** `primeira_pergunta` (goal da resposta de qualificação)

---

### d_qualificacao_2
| Atributo | Valor |
|----------|-------|
| **Tipo** | Dimensão de qualificação de onboarding (pergunta 2) |
| **Camada Databricks** | Silver / prod.beecambio (mista) |
| **Modo de carga** | Import |

**Colunas:** `segunda_pergunta` (goal + título concatenados)

---

## Tabelas de Medidas

### # Medidas
| Atributo | Valor |
|----------|-------|
| **Tipo** | Tabela de medidas DAX |
| **Fonte** | DAX — sem dados, somente medidas |

Contém todas as medidas principais do modelo (~130+ medidas). Detalhes em `02-medidas.md`.

---

## Tabelas Calculadas / DAX

### t_Período 1, t_Período 2, t_Período 3
| Atributo | Valor |
|----------|-------|
| **Tipo** | Tabela calculada DAX (seletor de período para comparação) |
| **Fonte** | DAX — `CALENDAR(MIN(f_mkt_performance[event_date]), MAX(f_mkt_performance[event_date]))` |

Geram calendários dinâmicos usados com `USERELATIONSHIP` para comparação de P1 vs P2 vs P3.

**Colunas:** `Date`, `Ano`

---

### t_Tabela
| Atributo | Valor |
|----------|-------|
| **Tipo** | Tabela estática DAX (lista de KPIs + formatos) |
| **Fonte** | DAX — `DATATABLE(...)` |

Lista de KPIs disponíveis para seleção nas comparações: Receita, GMV, Ticket Médio, Operações, Presignups, Signups, Spread.

**Colunas:** `KPI`, `Format`

---

### Grupo de cálculo
| Atributo | Valor |
|----------|-------|
| **Tipo** | Calculation Group (base para extensão futura) |
| **Fonte** | DAX |

Contém apenas `item de cálculo` = `SELECTEDMEASURE()`. Placeholder ou base para cálculos dinâmicos.

---

## Tabelas Parâmetro / Seletor (Field Parameters)

As tabelas com prefixo `p_` são **Field Parameters** do Power BI — permitem ao usuário selecionar dinamicamente qual dimensão ou medida exibir nos visuais.

| Tabela | Finalidade |
|--------|-----------|
| `p_Medidas` | Seletor de medida principal |
| `p_Medidas 2` | Seletor de medida secundária |
| `p_Medidas (Ops)` | Seletor para visualizações de Operações |
| `p_Medidas PF` | Seletor de medida para análise PF |
| `p_Medidas PF 2` | Seletor secundário PF |
| `p_Medidas PJ` | Seletor de medida para análise PJ |
| `p_Medidas PJ 2` | Seletor secundário PJ |
| `p_Medidas Investimento 1` | Seletor de medida de investimento (primário) |
| `p_Medidas Investimento 2` | Seletor de medida de investimento (secundário) |
| `p_Timeframe` | Seletor de granularidade temporal (dia/semana/mês...) |
| `p_Eixo X` | Seletor de dimensão para eixo X |
| `p_Eixo Y` | Seletor de dimensão para eixo Y |
| `p_Dimension 1 a 6 - Aba Analítico` | Seletores de dimensão para páginas analíticas |
| `p_Dimension 1 a 4 - PSU` | Seletores de dimensão para análise PSU |
| `p_Dimension Voucher` | Seletor de dimensão para análise de vouchers |

---

## Tabela Auxiliar

### d_blank
| Atributo | Valor |
|----------|-------|
| **Tipo** | Tabela auxiliar estática |
| **Fonte** | M — tabela com coluna única `Blank` (valor vazio) |

Usada em seletores para representar "sem filtro" ou opção em branco.
