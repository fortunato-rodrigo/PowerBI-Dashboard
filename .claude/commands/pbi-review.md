---
name: pbi-review
description: Audita a qualidade do modelo Power BI (PBIP) e gera relatório com score 0-100, anti-patterns priorizados e recomendações acionáveis. Cobre 6 famílias de checks: modelagem, relacionamentos, performance, naming, DAX, documentação.
---

# /pbi-review — Auditoria de qualidade do modelo Power BI

Invoca a skill `pbi-modelo-review` para auditar o modelo e gerar relatório de qualidade.

## Uso

```
/pbi-review [NomeDoDashboard]
```

Ou com filtro de severidade:
```
/pbi-review [NomeDoDashboard] --nivel critico
/pbi-review [NomeDoDashboard] --nivel medio
```

Exemplos:
```
/pbi-review Scorecard
/pbi-review Daily-Sales --nivel critico
```

## O que este command faz

Carrega e executa a skill `pbi-modelo-review`. A skill:

1. Lê todos os `.tmdl` do SemanticModel (read-only)
2. Aplica 6 famílias de checks com heurísticas de detecção
3. Calcula score: `max(0, 100 - (crítico×4) - (médio×1.5) - (leve×0.4))`
4. Gera relatório priorizado com fixes acionáveis
5. Salva em `dashboards/[Dashboard]/_review/`

## Famílias de checks

| Família | Exemplos de problemas detectados |
|---------|----------------------------------|
| Modelagem | Schema flat, refs circulares, fato usada como dimensão |
| Relacionamentos | Bidirecional desnecessário, M:M sem bridge, 1:1 suspeito |
| Performance | Coluna calculada deveria ser medida, DISTINCTCOUNT em string |
| Naming | Convenções mistas, sem prefixo de tabela, siglas sem contexto |
| DAX | Falta DIVIDE, variáveis não usadas, CALCULATE aninhado |
| Documentação | Medidas sem descrição, paths pessoais hardcoded |

## Outputs

```
dashboards/[Dashboard]/_review/
├── index.html    ← relatório visual com filtros interativos por severidade
└── relatorio.md  ← versão markdown exportável
```

## Workflow recomendado

```
/pbi-documentar [Dashboard]    ← documentar primeiro (opcional)
/pbi-review [Dashboard]    ← auditar qualidade
corrigir issues críticos    ← priorizar score
/pbi-sync [Dashboard]      ← sync após correções
```
