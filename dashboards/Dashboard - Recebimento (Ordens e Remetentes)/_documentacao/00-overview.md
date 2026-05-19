# Dashboard - Recebimento (Ordens e Remetentes) — Visão Geral

## Objetivo

Monitorar o ciclo completo das ordens de pagamento da Remessa Online: volume e status de resgate, receita realizada vs. projetada, comportamento por remetente, rastreamento de créditos identificados e funil de drop-off entre presignup e primeira operação.

## Público-alvo

Times de Operações, Produto, Risco e Negócio que precisam acompanhar o fluxo diário de ordens — do recebimento ao resgate — e identificar gargalos operacionais.

## Páginas

| # | Nome | Descrição | Tipo |
|---|------|-----------|------|
| 1 | **Home** | Tela de navegação com imagem de fundo (`orders.png`) | Navegação |
| 2 | **Overview** | Visão consolidada de ordens, GMV, receita (realizado + pendente), tendência, breakdown por dimensão | Principal |
| 3 | **Analítico** | Tabela analítica detalhada com decomposição por até 3 dimensões simultâneas | Análise |
| 4 | **Remetente** | Perfil e comportamento dos remetentes (contrapartes originais) | Detalhe |
| 5 | **Funil de Drop** | Clientes com presignup mas sem operação — análise de drop-off | Funil |
| 6 | **Crédito Identificado** | Ordens com crédito identificado (status 3) via Topázio — backoffice operacional | Operacional |

## Modelo de dados

| Item | Valor |
|------|-------|
| Tabelas | 14 |
| Medidas | ~27 |
| Relacionamentos | 4 |
| Camada principal | Silver (`silver.orders`) |
| Schemas não-padrão | `beecambio.*`, `banking_payments.*`, `conciliation_service.*`, `stage.*`, `google_analytics.*`, `legacy.*`, `bronze.*` |
| Dataflow | `dcalendar` (workspace `5381a7f5`, dataflow `3cbe0c71`) |

## Alertas

> ⚠️ **`gross_revenue_forecast` HARDCODED:** O spread de 0,83% é fixo na coluna calculada `gross_revenue_forecast = quantity * 0.0083`. Qualquer alteração de política de spread exige edição manual no modelo.
>
> ⚠️ **Múltiplos schemas não-padrão:** `beecambio`, `banking_payments`, `conciliation_service`, `stage`, `google_analytics`, `legacy`, `bronze`. Conexões mistas com schemas fora do `gold`/`silver` padrão elevam o risco de inconsistência e dependência de acordos implícitos entre times.

## Owner

A definir

## Frequência de uso

Diária (operacional) — acompanhamento de ordens em andamento e créditos identificados.

## Cobertura temporal

`f_orders`: a partir de 2024-01-01 · `d_calendar`: a partir de 2023 · `d_trading_quotation`: a partir de 2024-01-01 · `f_credito_identificado`: a partir de 2024-01-01
