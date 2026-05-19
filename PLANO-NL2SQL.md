# Plano: Data Intelligence Platform — NL2SQL para Remessa Online

## Objetivo

Usuário de negócio digita uma pergunta em PT no **chat do claude.ai** →
Claude consulta a documentação do repositório e os schemas do Databricks →
executa a query → responde com dados ao vivo.

Sem VS Code, sem terminal, sem SQL, sem uploads manuais.

---

## Arquitetura final

```
┌──────────────────────────────────────────────────────────────┐
│  CLAUDE PROJECT (instrução mínima — raramente muda)          │
│  Instructions: regras críticas de comportamento              │
│  • sempre excluir FxaaS de presignups                        │
│  • event_sequence = 1 obrigatório no funnel_event            │
│  • is_ops_processed = TRUE + is_intercompany = FALSE         │
│  • para tabelas: consultar MAPPING.md via GitHub MCP         │
│  Atualização: manual, mas muito raramente necessária         │
└──────────────────────────────────────────────────────────────┘
                          ↓
         ┌────────────────┴──────────────────┐
         ▼                                   ▼
┌─────────────────────┐           ┌──────────────────────────┐
│  GITHUB MCP         │           │  DATABRICKS SQL MCP       │
│  (contexto ao vivo) │           │  (dados ao vivo)          │
│                     │           │                           │
│  Lê direto dos repos:│           │  Endpoint nativo:         │
│  PowerBI-Dashboard: │           │  /api/2.0/mcp/sql         │
│  • ontologia/       │           │                           │
│    MAPPING.md       │           │  OAuth "on-behalf-of":    │
│    GLOSSARY.md      │           │  cada usuário usa sua     │
│    KPIS.md          │           │  própria conta Databricks │
│  • sql-examples/    │           │  → Unity Catalog, RLS e   │
│  data-config:       │           │    CLS respeitados        │
│  • models/**/*.yml  │           │                           │
│                     │           │  Audit log individual     │
│  PR mergeado?       │           │  via AI Gateway           │
│  → contexto já      │           │                           │
│    atualizado       │           │                           │
└─────────────────────┘           └──────────────────────────┘
```

**Por que funciona sem uploads manuais:**
- GitHub MCP lê os arquivos do repositório em tempo real
- PR mergeado com nova tabela, ontologia atualizada ou novo exemplo SQL?
  → Claude já vê na próxima conversa, zero intervenção humana

---

## O que é cada peça

| Peça | O que é | Quem mantém | Frequência de mudança |
|------|---------|-------------|----------------------|
| Claude Project Instructions | Regras imperativas de comportamento para o Claude | IT / time de dados | Raramente |
| `ontologia/` (MAPPING, GLOSSARY, KPIS) | Conhecimento de negócio detalhado | Time de dados via PR | ~Mensal |
| `sql-examples/` | Queries validadas como few-shot | Time de dados via PR | Contínuo |
| `data-config` repo (DBT YML) | Schemas e descrições de tabelas | Time de dados via PR | A cada mudança no DBT |
| Unity Catalog (Databricks) | Schemas ao vivo + metadata DBT | Zero — gerenciado pelo Databricks | Automático |
| Databricks MCP | Execução de SQL ao vivo | Zero (gerenciado pelo Databricks) | — |
| GitHub MCP | Leitura do repositório | Zero (gerenciado pelo GitHub) | — |

---

## Status atual

| Item | Status |
|------|--------|
| MCP Databricks (Claude Code) | ✅ Funcionando — time de dados já usa |
| Ontologia (GLOSSARY, KPIS, MAPPING) | ✅ Robusta — 70+ termos, 156 mapeamentos, regras FxaaS |
| `07-queries-sql.md` em 6 dashboards | ✅ ~30 queries reais com linhagem e filtros de negócio |
| `sql-examples/` (YAML estruturado) | ✅ **Concluído** — 43 YAMLs (13 do Genie + 30 novos de alto valor) |
| `sql-examples/` diagnósticos (6 YAMLs) | ⏳ Pendente — ver Fase 3 |
| Skill `/new-sql-examples` | ✅ Criada em `.claude/skills/new-sql-examples/` |
| Claude Project criado | ❌ Não existe ainda |
| GitHub MCP no claude.ai org | ❌ Não configurado |
| Databricks MCP no claude.ai org | ❌ Não configurado |
| Skill `/pbi-sync` | ❌ Não existe ainda — ver Fase 4 |

---

## Roadmap

### Fase 1 — Setup do claude.ai para usuários de negócio

**Passo 1 — Criar Claude Project no claude.ai Enterprise**
- Acessar claude.ai → Projects → New Project
- Nome: "Data Intelligence — Remessa Online"
- Instructions (colar diretamente no campo):
  ```
  Você é um assistente de dados da Remessa Online.
  Ao responder perguntas sobre dados:
  - Consulte ontologia/MAPPING.md no GitHub para identificar tabelas relevantes
  - Consulte ontologia/GLOSSARY.md para definições de negócio
  - Consulte sql-examples/ para queries similares validadas
  - Sempre aplique: event_sequence=1, email NOT LIKE '%fxaas%' (PSU sem FxaaS por padrão),
    is_ops_processed=TRUE, is_intercompany=FALSE
  - Para perguntas do tipo "por que estamos caindo em X":
    1. Execute comparação do período atual vs anterior para confirmar a queda
    2. Decomponha pelas dimensões: in_or_out (Receiving/Sending), nature_operation_name,
       operation_segment, business_type, bu + customer_type
    3. Calcule contribuicao_pct de cada dimensão para o delta total
    4. Responda identificando os 2-3 maiores detratores
  - Execute via Databricks MCP e responda em linguagem natural
  ```
- Compartilhar com a organização

**Passo 2 — Configurar GitHub MCP no claude.ai**
- Acessar: claude.ai → Organization Settings → Connectors → Add
- URL: `https://api.githubcopilot.com/mcp/`
- Auth: GitHub Personal Access Token (escopo: `repo read` nos dois repos)
- Nome: "GitHub — Remessa Online"
- ⚠️ O PAT precisa ter acesso a ambos os repositórios:
  - `PowerBI-Dashboard` → ontologia, sql-examples, documentação dos dashboards
  - `data-config` → YML do DBT com descrições de tabelas e colunas

**Passo 3 — Configurar Databricks SQL MCP no claude.ai**
- Acessar: claude.ai → Organization Settings → Connectors → Add
- URL: `https://beetech-prod-analytics.cloud.databricks.com/api/2.0/mcp/sql`
- Auth: OAuth (cada usuário autentica com sua própria conta Databricks)
- Nome: "Databricks SQL"

**Passo 4 — Testar com power users**
- Abrir o Project, ativar os dois conectores, fazer perguntas reais
- Validar: Claude acessa MAPPING.md? Executa SQL correto? Respeita FxaaS?
- Ajustar as Instructions do Project conforme feedback

---

### Fase 2 — Store de exemplos SQL validados ✅ CONCLUÍDO

**43 YAMLs criados em `sql-examples/`:**
- 13 originados do Genie Space RemessaGPT (validados em produção)
- 20 queries de negócio (GMV, receita, spread, custos, metas MTD)
- 10 queries de funil e marketing (canal_lc, CPP, CPA, cohorts)

**Skill `/new-sql-examples` criada** — guia o time de Analytics a contribuir com novos exemplos no formato correto.

**Pendência desta fase:** 6 YAMLs diagnósticos adicionais → ver Fase 3.

---

### Fase 3 — SQL Examples para Perguntas Diagnósticas ⏳ PENDENTE

**Por que um conjunto separado:** perguntas do tipo "por que estamos caindo?" requerem multi-step reasoning — o Claude roda múltiplas queries em sequência e sintetiza. Os YAMLs fornecem os **building blocks corretos** (patterns de comparação MoM, attribution analysis, funnel decomposition) para que o Claude não desperdice tokens errando `in_or_out = 'Receiving'` ou o padrão de FULL OUTER JOIN entre períodos.

**6 YAMLs a criar:**

| Arquivo | Pergunta-tipo | Pattern-chave |
|---------|---------------|---------------|
| `variacao-mom-por-dimensao.yaml` | "Por que caindo em PF Recebimento?" | MoM CTE + FULL OUTER JOIN + contribuicao_pct |
| `variacao-aquisicao-por-canal-mom.yaml` | "Queda no APP — qual detrator?" | canal_lc + pivot MoM |
| `funil-comparativo-mom-por-canal.yaml` | "É queda de PSU ou conversão?" | Multi-step CTE PSU→SU→ACQ + FxaaS |
| `base-ativa-ganho-perda-mom.yaml` | "Ganhando ou perdendo base ativa?" | FULL OUTER JOIN entre períodos |
| `contribuicao-delta-gmv-por-segmento.yaml` | "Qual BU puxou a queda de GMV?" | Attribution: CROSS JOIN totais + contribuicao_pct |
| `diagnostico-funil-conversao-steps.yaml` | "Onde perdemos mais no funil?" | conv_psu_su_pct + conv_su_acq_pct por mês |

**Dimensões pendentes de confirmação** (não documentadas no MAPPING.md):
- `country_name` / `destination_country` em `gold.fact_operations` — verificar com time de dados
- `currency_code` — verificar
- `bank_name` — verificar

---

## O que NÃO construir

| Item | Por quê não |
|------|-------------|
| `dbt-metadata/` no repo | Redundante — Unity Catalog já tem os metadados ao vivo |
| Backend Python / FastAPI | Desnecessário — GitHub MCP + Databricks MCP resolvem |
| Vector DB | TF-IDF nos 43 YAMLs é suficiente. Vector DB só para 1000+ exemplos |
| Fine-tuning | Few-shot com exemplos validados tem o mesmo efeito com custo zero |
| Slack Bot / Web App customizado | claude.ai já é a interface |
| Upload manual de arquivos para Project | GitHub MCP elimina essa necessidade |

---

## Fase 4 — Fluxo Automatizado de Mudanças em Dashboard (Change Request → PR)

### Problema

O time de Analytics faz uma mudança no Power BI → depois precisa manualmente: garantir que está salvo como PBIP, re-documentar o que mudou, criar branch, commitar, abrir PR. Esse pós-mudança é tedioso e frequentemente ignorado, gerando documentação desatualizada.

### Formatos suportados: PBIX e PBIP

O analista pode trabalhar em **qualquer um dos dois formatos**:

| Formato | Quando usar | Git diff? | Fluxo para sync |
|---------|-------------|-----------|-----------------|
| **PBIP** | Dashboards já versionados no repo (ex: Scorecard, Daily-Sales) | ✅ Sim — TMDL/JSON são texto | Ctrl+S → `/pbi-sync` direto |
| **PBIX** | Dashboards ainda não migrados, ou preferência do analista | ❌ Binário — sem diff | Save As PBIP → `/pbi-sync` |

**Regra:** o repo sempre armazena PBIP. PBIX é o formato de trabalho opcional — precisa ser convertido antes do sync.

---

### Power BI MCP (confirmado)

O Power BI MCP é **local, conectado ao Power BI Desktop aberto**. Suporta:
- Criar/editar medidas DAX, colunas calculadas, tabelas
- Editar fontes de dados
- Modificar layout do report, documentar medidas
- Qualquer operação que o Desktop suporta — sem o analista usar a interface

O que o MCP **não faz automaticamente**: publicar no workspace e sincronizar com o GitHub.

**A maior dor confirmada pelo time: "Publicar + sincronizar PBIP"** — é exatamente o pós-mudança.

---

### Arquitetura: Desktop (PBIX ou PBIP) → Save → `/pbi-sync`

```
Demanda de negócio
        │
        ▼
Analista abre o arquivo no Power BI Desktop
        │
   ┌────┴────────────────────────┐
   │                             │
   ▼                             ▼
PBIX                           PBIP
(formato padrão)           (já no repo)
   │                             │
Power BI Desktop MCP         Power BI Desktop MCP
ou mudança manual            ou mudança manual
   │                             │
   ▼                             │
File → Save As                   │
→ Power BI Project (.pbip)       │
(migra para PBIP no repo)        │
   │                             │
   └──────────┬──────────────────┘
              │
              ▼
Ctrl+S  +  File → Publish to Workspace
              │
              ▼
      /pbi-sync [Dashboard]
              │
  ┌───────────┴───────────────────────────────────┐
  │ 0. Verifica formato                           │
  │    PBIX detectado sem PBIP? → pede conversão  │
  │                                               │
  │ 1. git diff HEAD -- dashboards/[Dashboard]/   │
  │    → lista TMDL/JSON alterados                │
  │                                               │
  │ 2. Interpreta diff → linguagem de negócio     │
  │    "nova medida [GMV MTD], página X adicionada"│
  │                                               │
  │ 3. Atualiza APENAS as seções de doc afetadas  │
  │    (se > 5 arquivos TMDL: regeneração total)  │
  │                                               │
  │ 4. Verifica impacto em sql-examples/          │
  │    (algum YAML ficou stale com rename?)       │
  │                                               │
  │ 5. Sugere ontologia se novos KPIs detectados  │
  │    (aguarda confirmação — nunca edita direto) │
  │                                               │
  │ 6. git checkout -b fix/dashboard-[Nome]-[date]│
  │ 7. git commit (mensagem business-friendly)    │
  │ 8. gh pr create (PR body descritivo)          │
  └───────────────────────────────────────────────┘
              │
              ▼
         PR URL entregue → analista revisa e faz merge
```

---

### Skill 1: `/pbi-sync [Dashboard]` ← Entrega imediata, maior valor

**Propósito:** Chamada pelo analista após salvar o PBIP. Detecta tudo que mudou e automatiza o que vem depois.

**Passos:**

```
0. VERIFICAR FORMATO
   Se dashboards/[Dashboard]/ tem só .pbix (sem .pbip):
   → "Este dashboard ainda está em PBIX. Para sincronizar:
      File → Save As → Power BI Project (.pbip)
      Salve na pasta dashboards/[Dashboard]/ e rode /pbi-sync novamente."
   Se tem .pbip → continua

1. DETECTAR MUDANÇAS
   git diff HEAD -- dashboards/[Dashboard]/ --name-only
   Separar: SemanticModel (*.tmdl) vs Report (*.json)

2. INTERPRETAR DIFF
   tables/*.tmdl  → nova medida, nova coluna, fonte alterada
   relationships.tmdl → novo relacionamento
   pages/**/page.json → nova página ou renomeada
   visuals/**/visual.json → visual adicionado ou removido

3. ATUALIZAR DOCUMENTAÇÃO (seletiva)
   Nova medida     → 02-medidas.md + 04-dependencias.md
   Nova coluna     → 01-tabelas.md
   Novo relac.     → 03-relacionamentos.md
   Nova fonte      → 05-fontes.md (alerta bronze se aplicável)
   Nova página     → 00-overview.md
   > 5 TMDL alterados → regeneração completa via /pbi-documentacao

4. VERIFICAR sql-examples/
   Medida ou coluna renomeada/removida?
   → alertar YAMLs que podem estar stale (não edita)

5. SUGERIR ONTOLOGIA
   Novas medidas estratégicas → propor ao KPIS.md
   (sempre aguarda confirmação explícita)

6. GIT FLOW
   git checkout -b fix/dashboard-[Nome]-[YYYYMMDD]
   git add dashboards/[Dashboard]/
   git commit -m "fix([Nome]): [resumo business-friendly]"
   gh pr create --title "..." --body "[PR body estruturado]"
```

**PR body gerado automaticamente:**
```markdown
## O que mudou

**SemanticModel:**
- Medida `[GMV MTD]` adicionada em tabela Operações
- Coluna calculada `gmv_categoria` adicionada

**Report:**
- Página `Análise Semanal` adicionada (3 visuais)

## Documentação atualizada
- `02-medidas.md` — nova medida com DAX + explicação de negócio
- `01-tabelas.md` — nova coluna documentada

## Verificar antes de mergear
- [ ] Confirmar se `GMV MTD` deve entrar no KPIS.md
- [ ] Nenhum sql-example impactado detectado

Gerado por /pbi-sync
```

---

### Skill 2: `/pbi-change [Dashboard] "[demanda]"` ← Entrega futura

**Propósito:** Recebe demanda em PT e usa o Power BI Desktop MCP para executar sem o analista abrir a interface.

**Pré-condição:** Desktop aberto com o arquivo do dashboard (PBIX ou PBIP).

**Fluxo:**
1. Interpreta demanda: "Adiciona filtro de BU na página Visão Geral"
2. Usa Power BI Desktop MCP para executar a mudança
3. Exibe resultado: "Verifique no Desktop. Quando OK → Ctrl+S + Publish + /pbi-sync [Dashboard]"
4. Analista confirma → `/pbi-sync` chamado automaticamente

**Nota:** Publicação no workspace ainda manual (File → Publish no Desktop) ou via Power BI REST API com `POWERBI_*` do `.env`. A validar preferência do time.

---

### Prioridade de implementação

```
Fase 4a — ENTREGA IMEDIATA (maior valor, zero risco):
  → /pbi-sync [Dashboard]
  → Suporta PBIX e PBIP — detecta formato e orienta
  → Analista faz mudanças como sempre (Desktop + MCP ou manual)
  → Elimina: verificar formato, criar branch, atualizar docs, commitar, abrir PR
  → Dependências: gh CLI instalado + autenticado

Fase 4b — ENTREGA FUTURA:
  → /pbi-change [Dashboard] "[demanda]"
  → End-to-end: demanda → MCP faz no Desktop → analista confirma → /pbi-sync
  → Requer: Desktop MCP configurado no Claude Code da máquina do analista
```

---

*Plano revisado em 17/05/2026 — PBIX/PBIP, sql-examples concluídos, YAMLs diagnósticos pendentes*
