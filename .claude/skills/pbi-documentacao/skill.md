---
name: pbi-documentacao
description: Documenta um dashboard Power BI (PBIP) da Remessa Online gerando 7 arquivos em _documentacao/. Detecta camadas Databricks, alerta bronze, identifica Dataflows e cruza com a ontologia corporativa. Use quando o usuário pedir "documenta o [Dashboard]", "/pbi-documentacao [Nome]", ou apontar uma pasta PBIP para documentação.
---

# /pbi-documentacao — Documentação de dashboards Power BI (Remessa Online)

Gera documentação completa de um dashboard Power BI no formato PBIP.
Segue o padrão de 7 arquivos definido no `CLAUDE.md` deste repositório.

## Uso

```
/pbi-documentacao [NomeDoDashboard]
```

Exemplos:
```
/pbi-documentacao Scorecard
/pbi-documentacao Daily Sales Dashboard
/pbi-documentacao Gestao de Receita
```

Se `[NomeDoDashboard]` não for fornecido, perguntar uma vez:
> Qual dashboard devo documentar? (ex: Scorecard, Daily-Sales)

## Pré-requisitos

1. Dashboard salvo em formato PBIP em `dashboards/[NomeDoDashboard]/`
2. Estrutura esperada:
   ```
   dashboards/[NomeDoDashboard]/
   ├── [Nome].pbip
   ├── [Nome].SemanticModel/
   │   └── definition/
   │       ├── model.tmdl
   │       ├── relationships.tmdl
   │       └── tables/*.tmdl
   └── [Nome].Report/
       └── definition/pages/
   ```

Se a pasta não existir em `dashboards/`, verificar se está em outro local e avisar.
Se o projeto ainda estiver em `.pbix`, instruir conversão:
> Esse projeto ainda está em `.pbix`. Para documentar, salve como PBIP: `File → Save as → Power BI Project (.pbip)`. Avise quando converter.

## Processo de execução

### Etapa 1 — Leitura do SemanticModel

Ler todos os arquivos `.tmdl` de `dashboards/[NomeDoDashboard]/[Nome].SemanticModel/definition/`:
- `model.tmdl` — configurações gerais, cultura, formato
- `relationships.tmdl` — todos os relacionamentos
- `tables/*.tmdl` — uma por tabela (excluir `LocalDateTable_*` e `DateTableTemplate_*`)

Inventariar:
- **Tabelas:** nome, tipo (fato/dim/medidas/auxiliar), colunas, partição/source M
- **Medidas:** nome, DAX, displayFolder, formatString, referências
- **Relacionamentos:** from, to, cardinalidade, direção, ativo

### Etapa 2 — Leitura do Report

Ler `dashboards/[NomeDoDashboard]/[Nome].Report/definition/pages/*/page.json` para:
- Nome e tipo de cada página (visível, oculta, drillthrough, tooltip)
- Número de visuais por página
- Tipos de visuais presentes

### Etapa 3 — Detecção de camadas Databricks

Para cada tabela, analisar o source M e classificar:

| Padrão encontrado | Camada |
|-------------------|--------|
| `bronze.` | ⚠️ bronze |
| `silver.` | 🟡 silver |
| `gold.` | 🟢 gold |
| `diamond.` | 🔵 diamond |
| `PowerPlatform.Dataflows` | Dataflow (ver Etapa 4) |
| DAX / tabela calculada | Sem camada externa |

**Regra de alerta bronze:** se qualquer tabela ou JOIN usar camada `bronze`, gerar aviso
explícito em `05-fontes.md`. JOINs em bronze dentro de native queries também contam.

### Etapa 4 — Identificação e Documentação de Dataflows

Se qualquer tabela tiver `PowerPlatform.Dataflows` no source M, documentar inline — **não** exigir skill separada. Toda informação acessível pelo filesystem deve ser resolvida aqui.

#### 4a — Extração dos metadados da query M

Para cada tabela com `PowerPlatform.Dataflows`, extrair:

| Campo | Como extrair | Exemplo |
|-------|-------------|---------|
| **Workspace ID** | `workspaceId="..."` na query M | `5381a7f5-...` |
| **Dataflow ID** | `dataflowId="..."` na query M | `3cbe0c71-...` |
| **Entidade** | `entity="..."` na query M | `dcalendar` |
| **Transformações no modelo** | Passos M após a leitura da entidade | `+coluna last_day`, `remove coluna bu`, `renomeia X→Y` |
| **Colunas expostas** | Colunas declaradas no `.tmdl` | `Date Key`, `mtd`, `d0`… |

Padrão de query M a identificar:
```m
PowerPlatform.Dataflows(null)
  {[Id="Workspaces"]}[Data]
  {[workspaceId="<WORKSPACE_ID>"]}[Data]
  {[dataflowId="<DATAFLOW_ID>"]}[Data]
  {[entity="<ENTIDADE>",version=""]}[Data]
```

#### 4b — Inferência de linhagem

Com base nas colunas expostas e no papel da tabela no modelo, inferir a linhagem provável:

| Tipo de dimensão | Linhagem inferida |
|-----------------|-------------------|
| Calendário (`dcalendar`) | Provavelmente configuração interna ou `gold.dcalendar` |
| BU, Business Type, Segment | Provavelmente `gold.fact_operations` DISTINCT ou tabela de configuração |
| Customer Type | Provavelmente lista estática (PF/PJ) ou `gold.fact_operations.customer_type` |
| Event Type com label PT-BR | Provavelmente tabela de configuração com código + tradução |
| Canal de marketing | Provavelmente `gold.funnel_event.canal_lc` ou configuração UTM |

Marcar sempre como **inferida** — nunca afirmar como certa sem acesso ao PBI Service.

#### 4c — O que fica como "A definir"

As informações abaixo **só existem no PBI Service** e devem ser marcadas como `A definir`:
- Fonte original do Dataflow (qual sistema alimenta a entidade)
- Transformações internas do Dataflow (código M dentro do Dataflow em si)
- Frequência de atualização agendada

#### 4d — Documentação no 05-fontes.md

Gerar uma subseção por Dataflow com esta estrutura:

```markdown
### Dataflow: [nome da entidade] [⏳ Novo se não documentado antes]

| Campo | Valor |
|-------|-------|
| Workspace ID | `[GUID]` |
| Dataflow ID | `[GUID]` |
| Entidade | `[nome]` |
| Tabela destino | `[nome no modelo]` |
| Colunas disponíveis | `col1`, `col2`… |
| Transformações no modelo | [passos M após leitura: +coluna X, remove Y, renomeia Z] ou "Nenhuma" |
| Fonte original | A definir — verificar no PBI Service |
| Frequência de atualização | A definir |
| Linhagem inferida | [Databricks provável] → Dataflow [ID] → [tabela no modelo] |

**Query M no modelo:**
[bloco de código com a query completa]

**Linhagem inferida:**
[diagrama ASCII mostrando fluxo até os visuais]
```

#### 4e — Linhagem estendida

Ao final da seção de Dataflows em `05-fontes.md`, adicionar diagrama ASCII completo mostrando:
```
FONTES EXTERNAS → DATAFLOWS → TABELAS DO MODELO → MEDIDAS → VISUAIS
```

#### 4f — Tabela de pendências

Encerrar a seção com tabela de pendências por Dataflow (fonte original, transformações internas, frequência de atualização) e por outras fontes com alertas (bronze, explore).

### Etapa 5 — Cruzamento com ontologia

Ler `ontologia/GLOSSARY.md`, `ontologia/KPIS.md` e `ontologia/MAPPING.md`.

Para cada medida identificada:
- Verificar se já está mapeada na ontologia
- Marcar com ⭐ se for KPI estratégico listado em `KPIS.md`
- Usar a definição de negócio do glossário se disponível

Para colunas Databricks identificadas:
- Cruzar com `MAPPING.md` para enriquecer descrições

### Etapa 6 — Cruzamento com dbt-metadata

Ler `dbt-metadata/gold_models.md`, `dbt-metadata/silver_models.md`, `dbt-metadata/diamond_models.md`.
Se o modelo DBT for `"A definir"` (placeholder), registrar em `05-fontes.md` como "A definir — executar `/extrair-dbt-metadata`".

### Etapa 7 — Geração dos 7 arquivos

Gerar e salvar em `dashboards/[NomeDoDashboard]/_documentacao/`:

| Arquivo | Conteúdo |
|---------|---------|
| `00-overview.md` | Objetivo, público, páginas, owner (A definir se não disponível), métricas do modelo |
| `01-tabelas.md` | Inventário completo com tipo, camada, colunas, source M resumido |
| `02-medidas.md` | Todas as medidas com DAX + explicação PT. ⭐ para KPIs. ⚠️ para medidas com 5+ funções |
| `03-relacionamentos.md` | Diagrama ASCII + tabela detalhada com cardinalidade e direção |
| `04-dependencias.md` | Árvore de dependências + referência reversa + medidas órfãs |
| `05-fontes.md` | Fontes detalhadas com camada, query, modelo DBT, alertas bronze, Dataflows |
| `06-glossario-negocio.md` | Termos deste dashboard + link para ontologia corporativa |

Se `_documentacao/` já existir: sobrescrever (idempotente) e avisar no chat.

### Etapa 8 — Sugestões para a ontologia

Ao final, verificar:
- Termos/KPIs novos (não listados em `ontologia/`) encontrados neste dashboard
- Mapeamentos DAX → Databricks novos encontrados
- Novos domínios de negócio identificados

Se houver sugestões, apresentar no chat:
```
📋 Sugestões para a ontologia corporativa:

Novos termos para GLOSSARY.md:
- [Termo]: [Definição proposta]

Novos KPIs para KPIS.md:
- [KPI]: owner=A definir, meta=A definir

Novos mapeamentos para MAPPING.md:
- [Medida] → [Coluna Databricks]

Confirme com "sim" para aplicar, ou "não" para ignorar.
```

**Nunca editar a ontologia sem confirmação explícita.**

## Outputs

```
dashboards/[NomeDoDashboard]/
└── _documentacao/
    ├── 00-overview.md       ← gerado
    ├── 01-tabelas.md        ← gerado
    ├── 02-medidas.md        ← gerado
    ├── 03-relacionamentos.md ← gerado
    ├── 04-dependencias.md   ← gerado
    ├── 05-fontes.md         ← gerado
    └── 06-glossario-negocio.md ← gerado
```

## Regras invioláveis

1. **Idioma:** PT-BR em toda documentação gerada
2. **Tom:** linguagem de negócio — acessível a stakeholders não-técnicos
3. **DAX:** sempre incluir fórmula original + explicação em negócio
4. **Bronze:** sempre alertar — nunca silenciar
5. **Ontologia:** nunca editar sem confirmação
6. **Dataflows:** documentar inline na Etapa 4 — nunca delegar para `/pbi-fluxo-de-dados` como passo separado obrigatório
7. **Campos sem info:** usar `"A definir"` — nunca inventar
8. **KPIs:** marcar com ⭐ · medidas complexas (5+ funções) com ⚠️
9. **SemanticModel:** nunca modificar — somente leitura
10. **Git:** não commitar — seguir fluxo de PR do CLAUDE.md

## Mensagem final no chat

Após gerar os 7 arquivos:
```
✅ Documentação gerada em dashboards/[NomeDoDashboard]/_documentacao/

📊 [N] tabelas · [N] medidas · [N] relacionamentos
🗂️ Fontes: [lista resumida com camadas]
[⚠️ Alertas bronze se houver]
[📋 Sugestões de ontologia se houver]

Próximos passos:
- Abra _documentacao/ para revisar
- Preencha os campos "A definir" nos Dataflows: PBI Service → workspace → Dataflow → Edit
- Execute /pbi-modelo-review para auditoria técnica de qualidade
```
