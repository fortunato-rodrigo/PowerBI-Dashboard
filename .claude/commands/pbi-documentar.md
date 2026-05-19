---
name: pbi-documentar
description: Documenta um dashboard Power BI (PBIP) da Remessa Online. Gera 7 arquivos em _documentacao/ com detecção de camadas Databricks, alertas bronze, Dataflows e cruzamento com a ontologia corporativa. Use /pbi-queries antes para enriquecer com lineage real do Databricks.
---

# /pbi-documentar — Documentação de dashboard Power BI

Invoca o agent `pbi-documentar` para gerar documentação completa do dashboard informado.

## Uso

```
/pbi-documentar [NomeDoDashboard]
```

Exemplos:
```
/pbi-documentar Scorecard
/pbi-documentar Daily-Sales
/pbi-documentar Gestao-de-Receita
```

## Workflow recomendado

```
1. /pbi-queries [Dashboard]    ← gera 07-queries-sql.md com lineage real (opcional mas recomendado)
2. /pbi-documentar [Dashboard]     ← gera os 7 arquivos em _documentacao/
3. revisar _documentacao/
4. confirmar sugestões de ontologia se apresentadas
```

## O que este command faz

Carrega e executa o agent em `.claude/agents/pbi-documentar.md` com o nome do dashboard como argumento. O agent:

1. Lê todos os `.tmdl` do SemanticModel
2. Lê a estrutura de páginas/visuais do Report
3. Detecta camada Databricks de cada fonte (bronze ⚠️ / silver / gold / diamond)
4. Documenta Dataflows inline (workspace ID, dataflow ID, linhagem inferida)
5. Usa `07-queries-sql.md` se existir para enriquecer com lineage real
6. Cruza com `ontologia/` (GLOSSARY, KPIS, MAPPING)
7. Cruza com `dbt-metadata/`
8. Gera 7 arquivos em `dashboards/[Dashboard]/_documentacao/`
9. Sugere atualizações à ontologia (aguarda confirmação)

## Outputs

```
dashboards/[Dashboard]/_documentacao/
├── 00-overview.md
├── 01-tabelas.md
├── 02-medidas.md
├── 03-relacionamentos.md
├── 04-dependencias.md
├── 05-fontes.md
└── 06-glossario-negocio.md
```

## Skills relacionadas

- `/pbi-queries [Dashboard]` — gerar lineage via Databricks antes de documentar
- `/pbi-review [Dashboard]` — auditoria de qualidade após documentar
- `/pbi-dataflow [Dashboard]` — atualizar só a seção de Dataflows
- `/pbi-ontologia` — consolidar sugestões de ontologia após documentar vários dashboards
