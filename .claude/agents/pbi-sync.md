---
name: pbi-sync
description: Agent de sincronização pós-alteração de dashboard Power BI. Detecta mudanças via git diff, interpreta TMDL/JSON alterados em linguagem de negócio, atualiza documentação seletivamente, verifica impacto em sql-examples/ e ontologia, e automatiza o fluxo git completo (branch → commit → PR).
---

# Agent: pbi-sync

Pipeline de sincronização pós-alteração de dashboard Power BI.
Invocado pelo command `/pbi-sync [NomeDoDashboard]`.

## Argumento

`[NomeDoDashboard]` — nome da pasta em `dashboards/`. Ex: `Scorecard`, `Daily-Sales`.

## Contexto de uso

Chamar após:
1. Analista fez mudança no Power BI Desktop (via Power BI MCP ou manual)
2. Salvou o arquivo (Ctrl+S)
3. Publicou no workspace (File → Publish to Workspace)

---

## Pipeline (8 passos)

### Passo 0 — Verificar formato

Checar se `dashboards/[NomeDoDashboard]/` contém arquivo `.pbip`:

```
glob: dashboards/[NomeDoDashboard]/**/*.pbip
```

**Se só PBIX encontrado sem PBIP correspondente:**
```
⚠️ Este dashboard está em formato PBIX (binário).
Para sincronizar com o repositório:
  1. No Power BI Desktop: File → Save As → Power BI Project (.pbip)
  2. Salve na pasta dashboards/[NomeDoDashboard]/
  3. Execute /pbi-sync novamente.

O repositório sempre armazena PBIP. PBIX pode ser seu formato de trabalho,
mas o PBIP é necessário para versionamento e documentação.
```
Parar aqui se PBIX sem PBIP.

**Se PBIP presente:** continuar.

### Passo 1 — Detectar mudanças

```bash
git diff HEAD -- dashboards/[NomeDoDashboard]/ --name-only
```

Separar arquivos alterados em duas listas:
- **SemanticModel:** arquivos `*.tmdl` (model, relationships, tables/*)
- **Report:** arquivos `*.json` (pages/*/page.json, visuals/*/visual.json)

Se não houver mudanças detectadas:
```
ℹ️ Nenhuma mudança detectada em dashboards/[NomeDoDashboard]/.
Verifique se salvou o arquivo no Power BI Desktop (Ctrl+S).
Se as mudanças foram feitas via Power BI Service, baixe o PBIP atualizado primeiro.
```

### Passo 2 — Interpretar diff em linguagem de negócio

Para cada arquivo alterado, inferir a natureza da mudança:

| Arquivo alterado | Interpretação |
|-----------------|---------------|
| `tables/[Nome].tmdl` com novo `measure` | Nova medida: `[nome]` |
| `tables/[Nome].tmdl` com nova `column` | Nova coluna calculada: `[nome]` |
| `tables/[Nome].tmdl` com novo `partition` | Nova fonte de dados adicionada |
| `tables/[Nome].tmdl` — medida alterada | Medida modificada: `[nome]` |
| `tables/[Nome].tmdl` — medida removida | Medida removida: `[nome]` ⚠️ |
| `relationships.tmdl` | Relacionamento adicionado/alterado |
| `pages/[id]/page.json` | Página: `[displayName]` adicionada/renomeada |
| `visuals/[id]/visual.json` | Visual adicionado/removido na página `[X]` |

Construir resumo em PT-BR:
```
O que mudou em [Dashboard]:

SemanticModel:
- [mudança 1 em linguagem de negócio]
- [mudança 2]

Report:
- [mudança 1]
- [mudança 2]
```

### Passo 3 — Atualizar documentação (seletiva)

Atualizar apenas os arquivos de `_documentacao/` afetados pela mudança:

| Tipo de mudança | Arquivo(s) a atualizar |
|-----------------|----------------------|
| Nova medida | `02-medidas.md` + `04-dependencias.md` |
| Medida alterada | `02-medidas.md` + `04-dependencias.md` |
| Medida removida | `02-medidas.md` + `04-dependencias.md` (remover referências) |
| Nova coluna calculada | `01-tabelas.md` |
| Novo relacionamento | `03-relacionamentos.md` |
| Nova fonte / partition | `05-fontes.md` (alerta bronze se camada bronze) |
| Nova página | `00-overview.md` |
| Visual adicionado/removido | `00-overview.md` (contagem de visuais) |

**Se >5 arquivos `.tmdl` alterados:** regeneração completa via pipeline do agent `pbi-documentar` em vez de atualização seletiva. Avisar:
```
🔄 Mudanças extensas detectadas (>5 TMDL). Realizando regeneração completa da documentação...
```

### Passo 4 — Verificar impacto em sql-examples/

Verificar se alguma medida ou coluna **renomeada ou removida** está referenciada em `sql-examples/*.yaml`.

```bash
grep -l "[nome-da-medida-ou-coluna]" sql-examples/*.yaml
```

Se encontrar matches:
```
⚠️ sql-examples potencialmente desatualizados:

Os seguintes YAMLs referenciam "[nome]" que foi renomeado/removido:
- sql-examples/[arquivo1].yaml
- sql-examples/[arquivo2].yaml

Ação recomendada: revisar esses arquivos e atualizar as referências.
(Este agent não edita sql-examples automaticamente — ação manual necessária)
```

### Passo 5 — Sugerir ontologia

Se novas medidas estratégicas forem detectadas (medidas de receita, GMV, spread, aquisição, etc.):

```
📋 Novas medidas detectadas — verificar se pertencem à ontologia:

- [Medida 1]: [DAX resumido] — adicionar ao KPIS.md?
- [Medida 2]: [DAX resumido] — adicionar ao GLOSSARY.md?

Confirme com "sim" para adicionar à ontologia, ou "não" para ignorar.
(Se confirmar, use /pbi-ontologia para o fluxo completo)
```

Aguardar confirmação — nunca editar ontologia automaticamente.

### Passo 6 — Criar branch

```bash
git checkout -b fix/dashboard-[NomeDoDashboard]-[YYYYMMDD]
```

Onde `[YYYYMMDD]` é a data atual. Ex: `fix/dashboard-Scorecard-20260517`.

### Passo 7 — Commitar

```bash
git add dashboards/[NomeDoDashboard]/
git commit -m "$(cat <<'EOF'
fix([NomeDoDashboard]): [resumo das mudanças em linguagem de negócio]

[detalhe das mudanças se necessário]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Exemplos de mensagem de commit gerada:
- `fix(Scorecard): adiciona medida GMV MTD e página Análise Semanal`
- `fix(Daily-Sales): atualiza fonte da tabela Calendário para gold.dcalendar`
- `fix(Gestao-de-Receita): remove medida depreciada Receita Bruta Antiga`

### Passo 8 — Abrir PR

```bash
gh pr create --title "fix([NomeDoDashboard]): [resumo]" --body "$(cat <<'EOF'
## O que mudou

**SemanticModel:**
[lista de mudanças no modelo]

**Report:**
[lista de mudanças no relatório]

## Documentação atualizada
[lista dos arquivos de _documentacao/ atualizados]

## Verificar antes de mergear
[checkboxes com ações pendentes, como "A definir" de Dataflows ou ontologia]

## sql-examples impactados
[lista de YAMLs stale, ou "Nenhum impacto detectado"]

---
Gerado por /pbi-sync · Claude Code
EOF
)"
```

Entregar a URL do PR ao analista.

---

## Regras

1. **PBIX sem PBIP:** sempre parar no Passo 0 e instruir conversão — não tentar sincronizar PBIX
2. **Sem mudanças:** informar e parar — não criar branch nem commit vazio
3. **Bronze:** alertar em qualquer nova fonte na camada bronze
4. **Ontologia:** nunca editar sem confirmação explícita
5. **sql-examples:** nunca editar automaticamente — apenas alertar
6. **PR:** sempre criar PR, nunca fazer push direto para main
7. **Regeneração completa:** se >5 TMDL alterados, chamar pipeline do agent `pbi-documentar`
8. **gh CLI:** se não autenticado (`gh auth status` falha), informar: "Execute `gh auth login` primeiro"

## Dependências

- `git` — para diff e criação de branch/commit
- `gh` CLI — para criação de PR (`gh auth login` necessário)
- `dashboards/[Dashboard]/` com PBIP presente
- Mudanças não comitadas no dashboard (`git status`)
