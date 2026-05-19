# 00 — Visão Geral: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`

---

## Objetivo

O dashboard **Mkt Performance** centraliza o monitoramento de desempenho do funil de marketing da Remessa Online. Ele permite acompanhar, por canal, source, medium, campanha e ad group, os principais KPIs de atração e conversão de clientes (Presignups, Signups, Aquisições), além do investimento em mídia paga (CPA, CPP), GMV, Receita, Spread e Ticket Médio. Também contempla análise de janela de atribuição (Attribution Window), comparação entre três períodos configuráveis, visão por tipo de cliente (PF/PJ), vouchers e termos de busca.

---

## Público-alvo

- **Time de Marketing** — análise de eficiência de campanhas e canais
- **Growth / Performance** — acompanhamento de funil PSU → SU → ACQ
- **Liderança de Marketing e Product** — comparação de períodos e benchmarks de investimento
- **Time de BI** — manutenção e evolução do modelo

---

## Alertas de modelo

> ⚠️ **ALERTA BRONZE:** A tabela `f_investimento` conecta diretamente em `bronze.paid_media_investments`. Dados de custo de mídia paga possuem **baixo nível de confiança** por serem dados brutos não transformados pelo DBT. Validar valores com o time de Marketing antes de uso em relatórios executivos.

> ⚠️ **Schema não-padrão:** A tabela `f_mkt_performance` cruza camadas mistas: `gold` (funnel_event, fact_customers, fact_operations), `silver` (customers, histories), `stage` (dim_monthly_subsegmentation), `google_analytics` (first_click_sessions), `sandbox_datascience` (leadscore) e `prod.beecambio` (qualificação). Conexões em `stage` e `sandbox_datascience` indicam fontes potencialmente experimentais — verificar estabilidade com o time de dados.

> ℹ️ **Power BI Dataflows:** As dimensões `d_calendar`, `d_canal`, `d_canal_fc`, `d_medium`, `d_source`, `d_mkt_campaign`, `d_mkt_campaign_fc`, `d_adgroup` e `d_customer_type` são oriundas de **Power BI Dataflows** (workspace `5381a7f5-5b4c-4fa7-96d6-48992d85d88e`). A fonte original de cada Dataflow é `A definir` (requer acesso ao Power BI Service).

---

## Páginas do relatório

| # | Nome da Página | Tipo | Observação |
|---|----------------|------|------------|
| 1 | Home | Visível | Página inicial / sumário |
| 2 | Calendário | Visível | Seletor de datas e períodos |
| 3 | Channels Daily | Visível | Desempenho diário por canal |
| 4 | Bumbo CRM | Visível | Análise de CRM e funil |
| 5 | Analítico PF | Visível | Análise detalhada Pessoa Física |
| 6 | Analítico PJ | Visível | Análise detalhada Pessoa Jurídica |
| 7 | Investimento | Visível | Investimento em mídia paga (CPA, CPP) |
| 8 | Search Term | Visível | Termos de busca orgânica/paga |
| 9 | Vouchers | Visível | Análise de uso de vouchers |
| 10 | Comparações | Visível | Comparação entre P1, P2 e P3 |
| 11 | dica | Oculta | Página de suporte / tooltip |
| 12 | dica_sem_din | Oculta | Página de suporte sem dimensão |
| 13 | Funnel | Oculta | Visão de funil |
| 14 | CNAE | Oculta | Análise por classificação CNAE |

---

## Métricas do modelo

| Métrica | Valor |
|---------|-------|
| Tabelas de fato | 4 (`f_mkt_performance`, `f_investimento`, `f_attribution_window`, `f_trading_quotation`) |
| Tabelas de dimensão | 11 (`d_calendar`, `d_canal`, `d_canal_fc`, `d_medium`, `d_source`, `d_mkt_campaign`, `d_mkt_campaign_fc`, `d_adgroup`, `d_customer_type`, `d_qualificacao_1`, `d_qualificacao_2`) |
| Tabelas de medidas | 1 (`# Medidas`) |
| Tabelas auxiliares / DAX | 4 (`t_Período 1`, `t_Período 2`, `t_Período 3`, `t_Tabela`) |
| Tabelas parâmetro/seletor | 13 (prefixo `p_`) |
| Tabelas de cálculo | 1 (`Grupo de cálculo`) |
| Tabela auxiliar | 1 (`d_blank`) |
| **Total de tabelas** | **35** |
| Medidas DAX (estimado) | ~130+ medidas em `# Medidas` |
| Relacionamentos | 27 (18 ativos + 4 inativos para períodos + 5 adicionais) |
| Páginas | 14 (10 visíveis + 4 ocultas) |

---

## Frequência de atualização

A definir — verificar configuração no Power BI Service.

---

## Owner

A definir — verificar com o time de Marketing / Growth.
