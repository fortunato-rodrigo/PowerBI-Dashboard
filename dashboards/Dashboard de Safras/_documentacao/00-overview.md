# Dashboard de Safras — Visão Geral

## Objetivo

Analisar a jornada de conversão de clientes desde o Presignup até a Aquisição, rastreando cohorts mensais de usuários ao longo do funil. Permite entender quanto tempo cada "safra" de clientes leva para converter, segmentar por canal de marketing, tipo de cliente (PJ/PF) e mensurar o volume e qualidade das aquisições ao longo do tempo.

## Público-alvo

- Time de Growth e Marketing
- Time de Produto
- Diretoria Comercial e C-level

## Frequência de atualização

A definir — atualização controlada pela tabela `d_last_update` (campo `last_update` baseado em `CURRENT_TIMESTAMP - 3 horas`).

## Owner

A definir

---

## Páginas do relatório (15 total)

### Páginas visíveis (10)

| Ordem | Nome da Página | Descrição |
|-------|----------------|-----------|
| 1 | home | Tela inicial do dashboard com branding e navegação |
| 2 | Calendário | Seleção de período e configurações de calendário |
| 3 | O que é uma safra? | Página explicativa — define o conceito de safra para o usuário |
| 4 | Cohort | Análise cohortada principal: Presignups × Aquisições por mês de origem |
| 5 | Funil | Visualização do funil de conversão PSU → SU → ACQ |
| 6 | Conversão | Taxas de conversão cohortadas por período (mesmo mês e meses seguintes) |
| 7 | PJ | Análise específica para clientes Pessoa Jurídica (filtro Customer Type = 'PJ') |
| 8 | Aquisições | Visão de volume de aquisições ao longo do tempo |
| 9 | Cohort da Aquisição | Cohort visto pela data da aquisição (perspectiva inversa ao Cohort principal) |
| 10 | Query SQL | Página de referência técnica com a query SQL base do dashboard |

### Páginas ocultas (5)

| Nome | Tipo | Descrição |
|------|------|-----------|
| FAQ - Conceitos | HiddenInViewMode | Glossário de conceitos internos |
| dica1 | Tooltip | Tooltip explicativo (visual) |
| dica3 (x2) | Tooltip | Tooltips explicativos (visuais) |
| Página 1 | HiddenInViewMode | Página em construção ou descontinuada |

---

## Métricas do modelo semântico

| Dimensão | Quantidade |
|----------|-----------|
| Tabelas | 34 |
| Relacionamentos | 6 |
| Medidas DAX | ~80+ |
| Páginas visíveis | 10 |
| Fontes de dados distintas | 3 (Databricks, Power BI Dataflows, Databricks direto) |

---

## Tipos de eventos rastreados (event_type)

| Evento | Significado |
|--------|-------------|
| `PRESIGNUP` | Início da jornada — usuário expressou interesse |
| `SIGNUP` | Cadastro concluído |
| `ACQUISITION` | Primeira operação realizada (cliente ativado) |
| `OPERATION` | Operação subsequente (segunda operação em diante) |
| `APPROVED STORY` | Histórico de crédito aprovado (relevante para PJ) |

---

## Conceito de Safra

Uma **safra** (cohort) é o conjunto de clientes que realizaram um determinado evento (ex: Presignup) em um mesmo mês. O dashboard acompanha o comportamento dessas safras ao longo do tempo, medindo quantos clientes de cada mês de origem chegaram a converter em meses subsequentes.

Exemplo: "Safra de Janeiro/2024 — Presignups" = todos os clientes que fizeram presignup em Jan/2024 e o percentual que virou Aquisição em Jan/2024, Fev/2024, Mar/2024...
