# Daily Sales Dashboard — Visão Geral

## Objetivo

Painel operacional de **acompanhamento diário de vendas** da Remessa Online. Monitora em tempo real o desempenho dos principais KPIs de negócio — GMV, Receita, Operações, Presignups, Investimento em marketing, CPP, CPA e PNL — comparando o realizado contra metas diárias e mensais. Suporta tanto a visão do **fechamento D-1** quanto o modo **intraday** (dados do dia corrente ainda em aberto).

## Público-alvo

Liderança de vendas, marketing e produto; times de operações; C-Level que acompanham resultado do dia.

## Diferencial vs. outros dashboards

- **Metas diárias integradas** — cada KPI tem meta diária proporcional distribuída ao longo do mês
- **Modo Intraday** — toggle que inclui (ou exclui) dados parciais do dia corrente
- **Cobertura ampla** — integra câmbio tradicional (gold.fact_operations), resultado de projetos (gold.daily_sales), wallet (explore.wallet_transactions) e marketing (bronze.paid_media_investments)
- **HTML Narrativo** — medida `Bom Dia Dream Makers` gera texto automático de resumo executivo em HTML

---

## Páginas

| # | Nome | Tipo | Visuais | Descrição |
|---|------|------|---------|-----------|
| 1 | **Home** | Navegação | 2 | Splash screen com imagem de fundo; navegação para as demais páginas |
| 2 | **Resumo Executivo** | Principal | ~60 | Visão consolidada de todos os KPIs com Realizado × Meta × Projeção × MoM. Página longa (scroll) |
| 3 | **Venda Diária** | Análise | ~30 | Gráfico de barras diário com Realizado × Meta × Projeção acumulada no mês |
| 4 | **Mkt - Export Excel** | Exportação | ~15 | Tabela de dados de marketing (Investimento, CPP, CPA) formatada para export |
| 5 | **Intraday** | Operacional | ~30 | Visão do dia em andamento — muda comportamento quando `Intraday Flag = TRUE` |
| 6 | **FAQ - Projeção** | Oculta | — | Página oculta explicando a metodologia de projeção (`visibility: HiddenInViewMode`) |

---

## Métricas do Modelo

| Dimensão | Quantidade |
|----------|-----------|
| Tabelas | 18 |
| Medidas DAX | ~85 |
| Relacionamentos | 22 |
| Dataflows como fonte | 7 |
| Páginas | 6 (5 visíveis + 1 oculta) |
| Camadas Databricks | gold, bronze, explore |

---

## KPIs Monitorados

| KPI | Sigla | O que mede |
|-----|-------|-----------|
| GMV | — | Volume bruto transacionado em câmbio |
| Receita | — | Gross revenue (spread capturado) |
| Operações | Ops | Número de operações processadas |
| Aquisições | ACQ | Primeiras operações (clientes ativados) |
| Presignups | PSU | Novos cadastros iniciados |
| Investimento | — | Gasto em mídia paga |
| Custo por Presignup | CPP | Investimento ÷ Presignups |
| Custo por Aquisição | CPA | Investimento ÷ Aquisições |
| PNL (Tesouraria) | PNL | Gross revenue treasury (`gross_revenue_treasury`) |
| Custo de Mensageria | — | Custo de mensagens por operação (`real_message_cost`) |
| Take do Banco | — | Custo cobrado pelo banco parceiro (`cost_bank_take`) |

---

## Owner

| Campo | Valor |
|-------|-------|
| **Owner** | A definir |
| **Frequência de uso** | Diária |
| **Workspace Power BI** | `5381a7f5-5b4c-4fa7-96d6-48992d85d88e` |
| **Workspace Databricks** | `beetech-prod-analytics.cloud.databricks.com` |
| **Última atualização do modelo** | Ver medida `Last Update` no dashboard |
| **Janela histórica** | A partir de 2024-01-01 |

---

## Alertas

> ⚠️ **ALERTA BRONZE:** 3 tabelas utilizam a camada bronze do Databricks (`bronze.paid_media_investments`, `bronze.beecambio_customer`, `bronze.dcalendar`). Dados bronze são brutos e sem transformação DBT — podem conter inconsistências. Ver `05-fontes.md` para detalhes.

> ❓ **LAYER NÃO-PADRÃO:** `f_wallet` usa `explore.wallet_transactions` — o schema `explore` não pertence às camadas padrão (bronze/silver/gold/diamond). Verificar com o time de dados qual é o nível de confiança.

> 📋 **Dataflows:** 7 tabelas dimensão são alimentadas por Power BI Dataflows (5 novos não documentados anteriormente). Executar `/pbi-fluxo-de-dados "Daily Sales Dashboard"` para mapear a linhagem completa.
