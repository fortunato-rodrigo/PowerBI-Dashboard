# Gestão de Receita — Visão Geral

## Objetivo

Dashboard analítico de **rentabilidade operacional** das operações de câmbio da Remessa Online. Diferente do Scorecard (visão executiva de alto nível) e do Daily Sales Dashboard (acompanhamento diário de metas), o Gestão de Receita permite **decomposição granular** da receita, spread, custos e lucro por qualquer combinação de 18 dimensões disponíveis. Inclui simulador de cenários interativo para projetar o impacto de variações de volume e spread na receita.

## Público-alvo

- Time de Revenue / Pricing (análise de spread por segmento, moeda, parceiro)
- Time Financeiro (análise de rentabilidade, custos, lucro líquido)
- Analytics (exploração ad-hoc de dados operacionais)

## Páginas

| # | Nome | Tipo | Descrição |
|---|------|------|-----------|
| 1 | Home | Capa | Imagem de boas-vindas (gestao.png) |
| 2 | Resultado por Natureza | Análise | Decomposição de receita e spread por natureza da operação |
| 3 | Análise rentabilidade | Análise principal | Análise completa de lucro, custos e spread com 5 seletores de dimensão |
| 4 | Análise rentabilidade v1 | Análise (versão antiga) | Versão anterior da página de rentabilidade — manter para referência |
| 5 | Extrair Dados | Exportação | Tabela detalhada para exportação de dados granulares |
| 6 | Testes de visualização | Oculta | Página oculta para testes — não exibida aos usuários |

## Alertas

> ⚠️ **SCHEMAS NÃO-PADRÃO:** Este dashboard conecta diretamente a múltiplos schemas fora da hierarquia padrão bronze/silver/gold/diamond. Schemas identificados: `beecambio.*`, `automations.*`, `finance_cube.*`, `stage.*`. Ver [05-fontes.md](05-fontes.md) para detalhes e riscos.

> ⚠️ **GRANULARIDADE OPERAÇÃO:** A tabela `processed_operations` carrega dados no nível de **operação individual** (não agregados por dia), com janela a partir de 2024-01-01 e sem filtro de `is_intercompany`. O volume de dados pode ser elevado.

> ⚠️ **BANCO_TAKE VIA FINANCE_CUBE:** O custo de bank_take na tabela `customer` vem de `finance_cube.kpi_list` (alocado proporcionalmente pelo GMV) — schema não-padrão. A tabela `processed_operations` usa `cost_bank_take` direto de `gold.fact_operations`. Os dois podem divergir.

## Métricas do Modelo

| Item | Quantidade |
|------|-----------|
| Tabelas fato | 3 (`processed_operations`, `customer`, `Parceiros`) |
| Tabelas fato com subsegmento | 1 (`Subsegmento PF`) |
| Tabelas dimensão | 1 via Dataflow (`dcalendar`) |
| Tabelas calculadas (seletores) | 9 (`KPI`, `Dimensão 1–5`, `Escolha a métrica`, `Timeframe`) |
| Tabelas de cenário (parâmetros) | 2 (`Cenários Delta Operações`, `Cenários Delta Spread`) |
| Tabelas de medidas | 2 (`Medidas`, `Cenários`) |
| **Total de tabelas** | **18** |
| Medidas DAX | ~50 |
| Relacionamentos | 3 |
| Páginas visíveis | 5 |
| Páginas ocultas | 1 |
| Dataflows | 1 (`dcalendar`) |

## Owner

| Campo | Valor |
|-------|-------|
| Owner do dashboard | A definir |
| Time responsável | Revenue / Pricing / Analytics |
| Frequência de atualização | A definir |
| Última revisão da documentação | Mai 2026 |
