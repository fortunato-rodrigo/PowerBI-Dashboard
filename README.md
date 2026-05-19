# PowerBI-Dashboard — Remessa Online

Repositório central de todos os dashboards Power BI da Remessa Online no formato **PBIP** (Power BI Project), com documentação gerada automaticamente e ontologia corporativa versionada.


---

## Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| Git | 2.x | [git-scm.com](https://git-scm.com) |
| PowerShell | 5.1 | Nativo no Windows 10/11 |
| Python | 3.10+ | [python.org](https://python.org) — para scripts de dados |
| AWS CLI | 2.x | [aws.amazon.com/cli](https://aws.amazon.com/cli) |
| Power BI Desktop | Atual | Microsoft Store |
| Claude Code | Atual | [claude.ai/code](https://claude.ai/code) — para gerar documentação |

---

## Configuração inicial

```powershell
# 1. Clonar o repositório
git clone https://github.com/BeeTech-global/powerbi-dashboard.git
cd PowerBI-Dashboard

# 2. Autenticar na AWS (se ainda não estiver autenticado)
aws sso login --profile <seu-perfil>

# 3. Criar o .env local com as credenciais Power BI
.\tools\Setup-Env.ps1

# 4. Configurar o ambiente Python (uma vez)
.\tools\Setup-Python.ps1
```

> O `.env` é gerado automaticamente a partir do AWS SSM Parameter Store.
> Nunca commite esse arquivo — ele já está no `.gitignore`.

> A venv fica em `.venv/` (também no `.gitignore`). Ative com `.\.venv\Scripts\Activate.ps1` antes de rodar scripts Python.

---

## Estrutura do repositório

```
PowerBI-Dashboard/
├── dashboards/               ← um subdiretório por dashboard PBIP
│   └── Scorecard/
│       ├── *.pbip            ← arquivo do projeto Power BI
│       ├── *.SemanticModel/  ← modelo semântico (tabelas, medidas, relacionamentos)
│       ├── *.Report/         ← definição de páginas e visuais
│       └── _documentacao/    ← gerada automaticamente (não editar manualmente)
│
├── ontologia/                ← glossário corporativo único — transversal a todos os dashboards
│   ├── GLOSSARY.md           ← termos canônicos da Remessa Online
│   ├── KPIS.md               ← KPIs estratégicos com owner e meta
│   ├── DOMAINS.md            ← domínios de negócio e responsabilidades
│   └── MAPPING.md            ← termo de negócio → medida DAX → coluna Databricks
│
├── sql-examples/             ← 43+ queries validadas para NL2SQL (question → SQL, flat)
│
├── tools/                    ← scripts de automação
│   ├── Setup-Env.ps1                    ← configura .env a partir do AWS SSM
│   ├── Setup-Python.ps1                 ← cria venv e instala dependências Python
│   ├── Get-DataflowMetadata.ps1         ← documenta Dataflows de um dashboard
│   ├── Extract-QueryMetadata.ps1        ← extrai queries SQL do Databricks
│   └── export-genie-to-sql-examples.py ← exporta certified questions do Genie para YAML
│
├── .claude/
│   ├── skills/               ← conhecimento especializado (DAX, qualidade, curadoria SQL)
│   ├── commands/             ← slash commands (/pbi-documentar, /pbi-sync, /pbi-review, ...)
│   └── agents/               ← pipelines autônomos multi-etapas
│
└── _template/                ← modelo para criar novos dashboards
```

---

## Camadas de dados

| Camada | Descrição | Confiança |
|---|---|---|
| `bronze` | Dados brutos, sem transformação | ⚠️ Baixa |
| `silver` | Dados limpos e padronizados (DBT) | 🟡 Média |
| `gold` | Modelos analíticos consolidados (DBT) | 🟢 Alta |
| `diamond` | Camada mais refinada — fonte autoritativa da Remessa Online | 🔵 Máxima |

**Regra:** sempre priorizar `diamond` como fonte. Conexão com `bronze` gera alerta explícito na documentação.

---

## Adicionando um novo dashboard

Veja o guia completo em [CONTRIBUTING.md](CONTRIBUTING.md).

Resumo:

```powershell
git checkout -b feat/dashboard-<nome>
# Copie os arquivos PBIP para dashboards/<Nome>/
# Dentro do Claude Code:
/pbi-documentar <Nome>
```

---

## Scripts disponíveis

### `tools/Setup-Env.ps1`

Cria o `.env` local com as credenciais Power BI buscadas do AWS SSM.

```powershell
.\tools\Setup-Env.ps1                          # primeira vez
.\tools\Setup-Env.ps1 -Force                   # regenerar após rotação de credenciais
.\tools\Setup-Env.ps1 -Profile prod            # perfil AWS específico
```

### `tools/Get-DataflowMetadata.ps1`

Descobre e documenta os Dataflows usados por um dashboard.

```powershell
.\tools\Get-DataflowMetadata.ps1 -Dashboard Scorecard
```

### `tools/Extract-QueryMetadata.ps1`

Consulta `data_quality.tables_in_dashboards_pbix` no Databricks e gera
`_documentacao/07-queries-sql.md` com as queries SQL reais e linhagem completa
por camada (gold/silver/bronze/diamond). Usa o service principal do Power BI — sem credenciais extras.

```powershell
.\tools\Extract-QueryMetadata.ps1 -Dashboard Scorecard
.\tools\Extract-QueryMetadata.ps1 -Dashboard Scorecard -Force   # regenerar
```

### `tools/Setup-Python.ps1`

Cria a venv em `.venv/` e instala as dependências de `requirements.txt`.

```powershell
.\tools\Setup-Python.ps1           # primeira vez
.\tools\Setup-Python.ps1 -Force    # recriar do zero
```

### `tools/export-genie-to-sql-examples.py`

Exporta as certified questions do Genie Space RemessaGPT para arquivos YAML em `sql-examples/`.
Requer venv ativa e `.env` com `DATABRICKS_HOST` e `DATABRICKS_TOKEN`.

```powershell
.\.venv\Scripts\Activate.ps1
python tools/export-genie-to-sql-examples.py
```

---

## Commands do Claude Code

| Command | Descrição |
|---|---|
| `/pbi-documentar <Dashboard>` | Gera 7 arquivos de documentação em `_documentacao/` (com Databricks + ontologia) |
| `/pbi-queries <Dashboard>` | Extrai lineage SQL real via Databricks (`07-queries-sql.md`) |
| `/pbi-sync <Dashboard>` | Sincroniza após alterar dashboard: diff → docs → branch → PR automático |
| `/pbi-review <Dashboard>` | Audita qualidade do modelo (score 0-100 + recomendações) |
| `/pbi-dax "<descrição>"` | Cria medida DAX a partir de descrição em PT-BR |
| `/pbi-dataflow <Dashboard>` | Atualiza só a seção de Dataflows sem re-documentar |
| `/pbi-ontologia` | Consolida e aplica atualizações à ontologia (com aprovação) |
| `/pbi-sql-example` | Adiciona query validada ao `sql-examples/` |
| `/pbi-genie-sync` | Sincroniza lote de perguntas certificadas do Genie Space |

---

## Dúvidas e suporte

- Documentação de contribuição: [CONTRIBUTING.md](CONTRIBUTING.md)
- Ontologia corporativa: [ontologia/GLOSSARY.md](ontologia/GLOSSARY.md)
- Owner técnico: rodrigo.fortunato@remessaonline.com.br
