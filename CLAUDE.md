# CLAUDE.md — PowerBI-Dashboard (Remessa Online)

## Contexto do projeto

Repositório de dashboards Power BI da Remessa Online em formato PBIP, com documentação e NL2SQL automatizados.
Stack: **AWS** → **Databricks** (bronze/silver/gold/diamond) → **DBT** → **Power BI Dataflows** → **Power BI (PBIP)**.
Regra de ouro: `diamond` é a camada mais refinada e autoritativa — priorizar sempre que disponível.
Lineage autoritativa: `data_quality.tables_in_dashboards_pbix` (DAG Airflow, atualizada automaticamente).

---

## Estrutura do repositório

```
PowerBI-Dashboard/
├── CLAUDE.md                    ← este arquivo
├── ontologia/                   ← GLOSSARY.md · KPIS.md · DOMAINS.md · MAPPING.md
├── sql-examples/                ← 43+ YAMLs para NL2SQL (flat, sem subdiretórios)
├── tools/                       ← Extract-QueryMetadata.ps1 · Get-DataflowMetadata.ps1 · Setup-*.ps1
├── dashboards/[Nome]/           ← PBIP + _documentacao/ gerada pelos agents
└── .claude/
    ├── skills/                  ← conhecimento especializado (DAX, qualidade, curadoria SQL)
    ├── commands/                ← atalhos operacionais (slash commands)
    └── agents/                  ← pipelines autônomos multi-etapas
```

---

## Mapa de commands

| Quero fazer… | Command |
|---|---|
| Documentar um dashboard (7 arquivos) | `/pbi-documentar [Dashboard]` |
| Extrair lineage SQL via Databricks antes | `/pbi-queries [Dashboard]` |
| Sincronizar após alterar dashboard (→ PR) | `/pbi-sync [Dashboard]` |
| Auditar qualidade do modelo Power BI | `/pbi-review [Dashboard]` |
| Criar medida DAX a partir de descrição PT | `/pbi-dax "[descrição]"` |
| Atualizar só Dataflows sem re-documentar | `/pbi-dataflow [Dashboard]` |
| Consolidar e aplicar atualizações à ontologia | `/pbi-ontologia` |
| Adicionar 1 query validada ao sql-examples/ | `/pbi-sql-example` |
| Sincronizar lote do Genie Space | `/pbi-genie-sync` |

> `/pbi-doc` · `/pbi-dax-create` · `/pbi-modelo-review` — skills genéricas (sem integração Databricks/ontologia). Para documentação Remessa-específica, usar `/pbi-documentar`.

---

## Camadas Databricks

| Camada | Descrição | Confiança |
|--------|-----------|-----------|
| `bronze` | Dados brutos, sem transformação | ⚠️ Baixo — sempre alertar na documentação |
| `silver` | Dados limpos e padronizados (DBT) | 🟡 Médio |
| `gold` | Modelos analíticos consolidados (DBT) | 🟢 Alto |
| `diamond` | Mais refinada — fonte autoritativa | 🔵 Máximo — priorizar sempre |

Conexões mistas bronze + diamond na mesma view: aviso global no topo de `05-fontes.md`.

---

## Padrões obrigatórios

1. **Idioma:** sempre PT-BR — nunca EN na documentação gerada
2. **Campos sem info:** usar `"A definir"` — nunca inventar valores
3. **Ontologia:** nunca editar sem confirmação explícita do usuário
4. **Git:** nunca commitar diretamente — usar `/pbi-sync` para criar branch e PR
5. **KPIs:** marcar com ⭐ · medidas complexas (5+ funções) com ⚠️

---

## Setup inicial

```powershell
.\tools\Setup-Env.ps1       # busca credenciais Power BI + Databricks do AWS SSM → cria .env
.\tools\Setup-Python.ps1    # cria .venv + instala requirements.txt (para genie-sync)
```

---

## Fluxo de PR (novo dashboard ou alteração)

```
1. git checkout -b feat/dashboard-[nome]     ← ou automático via /pbi-sync
2. Adicionar/editar dashboards/[Nome]/ PBIP
3. /pbi-documentar [Nome]                    ← gera _documentacao/ (consulta data_quality automaticamente)
4. Revisar _documentacao/ e confirmar ontologia se sugerido
5. /pbi-sync [Nome]                          ← commit + PR automático
6. Revisão → merge
```

---

## Convenção de nomes de pastas

Kebab-case, sem acentos, sem espaços: `Scorecard` · `Daily-Sales` · `Safras` · `Dash-de-Ordens` · `Gestao-de-Receita`

---

## Estrutura _documentacao/ (padrão obrigatório)

| Arquivo | Conteúdo |
|---------|---------|
| `00-overview.md` | Objetivo, público, páginas, owner, frequência de uso |
| `01-tabelas.md` | Inventário: tipo, camada, colunas, source M |
| `02-medidas.md` | DAX + explicação de negócio, agrupado por tema |
| `03-relacionamentos.md` | Diagrama ASCII + tabela com cardinalidade |
| `04-dependencias.md` | Árvore de dependências + medidas órfãs |
| `05-fontes.md` | Camada Databricks, tabela, modelo DBT, alertas bronze, Dataflows |
| `06-glossario-negocio.md` | Termos deste dashboard + link para ontologia corporativa |
