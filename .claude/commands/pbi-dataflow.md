---
name: pbi-dataflow
description: Atualiza apenas a seção de Dataflows em 05-fontes.md de um dashboard já documentado, sem re-gerar os 7 arquivos completos. Use quando um Dataflow foi alterado e você quer update pontual. Para documentação inicial, use /pbi-documentar (que já inclui Dataflows inline).
---

# /pbi-dataflow — Atualização pontual de Dataflows

Atualiza somente a seção de Dataflows em `05-fontes.md` de um dashboard já documentado.

> **Nota:** `/pbi-documentar` já documenta Dataflows inline na Etapa 4.
> Use este command apenas quando um Dataflow foi alterado e você quer update pontual
> sem re-gerar os 7 arquivos completos.

## Uso

```
/pbi-dataflow [NomeDoDashboard]
```

Exemplos:
```
/pbi-dataflow Scorecard
/pbi-dataflow Daily-Sales
```

## Quando usar

| Situação | Command a usar |
|----------|---------------|
| Documentar dashboard pela primeira vez | `/pbi-documentar` |
| Dataflow foi alterado, quer só atualizar lineage | `/pbi-dataflow` |
| Dashboard legado sem Dataflows documentados | `/pbi-dataflow` |
| Re-inspeção de linhagem sem re-gerar tudo | `/pbi-dataflow` |

## O que este command faz

Carrega e executa a skill `pbi-fluxo-de-dados`. O agent:

1. Lê `.tmdl` do SemanticModel identificando tabelas com `PowerPlatform.Dataflows`
2. Extrai workspace ID, dataflow ID e nome da entidade de cada Dataflow
3. Identifica transformações M aplicadas no modelo (após leitura da entidade)
4. Infere linhagem provável cruzando com `ontologia/MAPPING.md` e `dbt-metadata/`
5. Atualiza a seção de Dataflows em `dashboards/[Dashboard]/_documentacao/05-fontes.md`

## Output

Atualiza apenas:
```
dashboards/[Dashboard]/_documentacao/
└── 05-fontes.md    ← seção de Dataflows atualizada
```

## Campos sempre "A definir" (requerem Power BI Service)

- Fonte original do Dataflow
- Transformações internas do Dataflow (M code interno)
- Frequência de atualização agendada

Para preencher: PBI Service → Workspace → Dataflows → Editar.
