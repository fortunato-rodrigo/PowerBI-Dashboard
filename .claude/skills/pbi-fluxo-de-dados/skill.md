---
name: pbi-fluxo-de-dados
description: Re-documenta ou atualiza a linhagem de Power BI Dataflows em um dashboard já documentado. Use quando quiser atualizar apenas a seção de Dataflows do 05-fontes.md sem re-gerar toda a documentação. ATENÇÃO: a skill /pbi-documentacao já incorpora a documentação de Dataflows inline — esta skill é complementar, não obrigatória.
---

# /pbi-fluxo-de-dados — Atualização de Linhagem de Dataflows

Re-documenta ou atualiza a seção de Dataflows em `05-fontes.md` de um dashboard já documentado.

> **Nota:** A skill `/pbi-documentacao` já incorpora a documentação de Dataflows inline (Etapa 4).
> Use esta skill apenas quando quiser **atualizar** a linhagem de um dashboard já documentado
> sem re-gerar os 7 arquivos completos.

## Uso

```
/pbi-fluxo-de-dados [NomeDoDashboard]
```

Exemplo:
```
/pbi-fluxo-de-dados Scorecard
```

Se o nome não for fornecido, perguntar qual dashboard atualizar.

## Contexto de uso

Use esta skill quando:

1. **Atualização pontual** — um Dataflow foi alterado e você quer atualizar só o `05-fontes.md`
2. **Dashboard legado** — documentação foi gerada antes da Etapa 4 incorporar Dataflows inline
3. **Re-inspeção** — quer revisar a linhagem sem re-gerar toda a documentação

## O que são Power BI Dataflows

Dataflows são pipelines ETL dentro do Power BI Service (Power Platform). Eles:
- Recebem dados de fontes externas (Databricks, SharePoint, SQL, APIs)
- Aplicam transformações Power Query (linguagem M)
- Disponibilizam tabelas prontas para uso em modelos Power BI

Em dashboards da Remessa Online, Dataflows geralmente se situam **entre** o Databricks e o Power BI — são uma camada de transformação intermediária.

## Processo de execução

### Etapa 1 — Identificar Dataflows no dashboard

Ler os arquivos `.tmdl` em `dashboards/[NomeDoDashboard]/[Nome].SemanticModel/definition/tables/`.

Para cada tabela com `PowerPlatform.Dataflows` no source M, extrair:
- **Workspace ID** — GUID do workspace Power BI
- **Dataflow ID** — GUID do Dataflow específico
- **Entidade** — nome da entidade/tabela dentro do Dataflow
- **Nome da tabela no modelo** — como aparece no Power BI

Exemplo de pattern a identificar na query M:
```m
PowerPlatform.Dataflows(null){[workspaceId="<WORKSPACE_ID>",
  dataflowId="<DATAFLOW_ID>"]}[data]{[entity="<ENTIDADE>",...]}
```

### Etapa 2 — Documentar metadados disponíveis

Com as informações extraídas da query M, documentar o que for possível identificar:

| Campo | Fonte | Disponibilidade |
|-------|-------|-----------------|
| Workspace ID | Query M | ✅ Disponível |
| Dataflow ID | Query M | ✅ Disponível |
| Nome da entidade | Query M | ✅ Disponível |
| Fontes originais do Dataflow | Configuração do Dataflow no Service | ⚠️ Requer acesso ao Power BI Service |
| Transformações M | Configuração do Dataflow no Service | ⚠️ Requer acesso ao Power BI Service |
| Frequência de atualização | Configuração do Dataflow no Service | ⚠️ Requer acesso ao Power BI Service |

> **Nota:** Claude Code não tem acesso direto ao Power BI Service. As informações que requerem acesso ao Service devem ser preenchidas manualmente pelo analista ou via API do Power BI.

### Etapa 3 — Inferir linhagem a partir do contexto

Com base no que conhecemos do modelo e da ontologia:
- Se a tabela é uma dimensão de negócio (ex: `d_customer_type`), inferir que o Dataflow provavelmente carrega dados de uma fonte do sistema de CRM ou Databricks silver/gold
- Cruzar com `dbt-metadata/` para identificar possíveis modelos DBT de origem
- Cruzar com `ontologia/MAPPING.md` para enriquecer o contexto

### Etapa 4 — Atualizar 05-fontes.md

Atualizar a seção "Fonte: Power BI Dataflow" em `dashboards/[NomeDoDashboard]/_documentacao/05-fontes.md` com:

```markdown
### Dataflow: [Nome da entidade]

| Campo | Valor |
|-------|-------|
| Workspace ID | [GUID extraído] |
| Dataflow ID | [GUID extraído] |
| Entidade | [nome da entidade] |
| Tabela destino no modelo | [nome no Power BI] |
| Fontes originais | A definir — verificar no Power BI Service |
| Transformações | A definir — verificar no Power BI Service |
| Frequência de atualização | A definir |
| Linhagem inferida | [Databricks silver/gold → Dataflow → Power BI] (inferida) |
```

### Etapa 5 — Gerar seção de linhagem estendida

Adicionar ao final de `05-fontes.md` uma seção de linhagem estendida:

```
Linhagem estendida (com Dataflows):

[Fonte original — ex: Databricks silver]
  └─► [Power BI Dataflow: nome/ID]
        └─► [Tabela no modelo: d_customer_type]
              └─► [f_operations via relacionamento]
                    └─► [Visuais do dashboard]
```

## Outputs

Atualiza `dashboards/[NomeDoDashboard]/_documentacao/05-fontes.md` com:
- Metadados de cada Dataflow identificado
- Linhagem estendida com Dataflows

## Mensagem final no chat

```
✅ Linhagem de Dataflows documentada em 05-fontes.md

Dataflows identificados: [N]
- [nome entidade 1] → tabela [d_xxx] (Workspace: ..., Dataflow: ...)
- [nome entidade 2] → tabela [d_yyy] (...)

⚠️ Informações pendentes (requerem acesso ao Power BI Service):
- Fontes originais de cada Dataflow
- Transformações M aplicadas
- Frequência de atualização

Para completar: acesse o Power BI Service → Workspace → Dataflows e preencha
os campos "A definir" em 05-fontes.md.
```

## Regras

1. Nunca inventar IDs, nomes ou configurações de Dataflow
2. Para campos não disponíveis via filesystem, usar `"A definir"` e indicar como obter
3. Não modificar arquivos `.tmdl` — apenas `_documentacao/`
4. PT-BR em toda documentação gerada
