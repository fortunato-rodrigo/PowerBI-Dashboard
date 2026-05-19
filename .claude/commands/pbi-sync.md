---
name: pbi-sync
description: Sincroniza alterações de um dashboard Power BI com o repositório. Detecta mudanças via git diff, interpreta o que mudou em linguagem de negócio, atualiza documentação seletivamente, cria branch, commit e PR automaticamente. Rodar após salvar o PBIP e publicar no workspace.
---

# /pbi-sync — Sincronização pós-alteração de dashboard

Invoca o agent `pbi-sync` para automatizar tudo que vem depois de uma alteração no dashboard.

## Uso

```
/pbi-sync [NomeDoDashboard]
```

Exemplos:
```
/pbi-sync Scorecard
/pbi-sync Daily-Sales
```

## Quando usar

Após qualquer alteração no dashboard:
1. Analista fez mudança no Power BI Desktop (via MCP ou manual)
2. Salvou o arquivo (Ctrl+S)
3. Publicou no workspace (File → Publish)
4. Chama `/pbi-sync [Dashboard]`

## Formato suportado

| Formato no repo | Ação |
|-----------------|------|
| PBIP já na pasta `dashboards/` | Executa diretamente |
| PBIX sem PBIP correspondente | Pede: "File → Save As → Power BI Project (.pbip) primeiro" |

## O que o agent faz (8 passos)

```
0. VERIFICAR FORMATO
   Se só PBIX sem PBIP → instrui conversão e para

1. DETECTAR MUDANÇAS
   git diff HEAD -- dashboards/[Dashboard]/ --name-only
   Separa: SemanticModel (*.tmdl) vs Report (*.json)

2. INTERPRETAR DIFF
   tables/*.tmdl    → nova medida, nova coluna, fonte alterada
   relationships    → novo relacionamento
   pages/**         → nova página ou renomeada
   visuals/**       → visual adicionado ou removido

3. ATUALIZAR DOCUMENTAÇÃO (seletiva)
   Nova medida      → 02-medidas.md + 04-dependencias.md
   Nova coluna      → 01-tabelas.md
   Novo relac.      → 03-relacionamentos.md
   Nova fonte       → 05-fontes.md (alerta bronze se aplicável)
   Nova página      → 00-overview.md
   >5 TMDL mudados → regeneração completa via /pbi-documentar

4. VERIFICAR sql-examples/
   Medida ou coluna renomeada/removida?
   → alerta YAMLs potencialmente stale (não edita automaticamente)

5. SUGERIR ONTOLOGIA
   Novas medidas estratégicas → propor ao KPIS.md
   (sempre aguarda confirmação — nunca edita direto)

6. CRIAR BRANCH
   git checkout -b fix/dashboard-[Nome]-[YYYYMMDD]

7. COMMITAR
   git add dashboards/[Dashboard]/
   git commit -m "fix([Nome]): [resumo em linguagem de negócio]"

8. ABRIR PR
   gh pr create --title "..." --body "[PR body estruturado]"
```

## PR gerado automaticamente

```markdown
## O que mudou

**SemanticModel:**
- [lista de mudanças no modelo]

**Report:**
- [lista de mudanças no relatório]

## Documentação atualizada
- [lista dos arquivos de _documentacao/ atualizados]

## Verificar antes de mergear
- [ ] [checkboxes de ações pendentes]

Gerado por /pbi-sync
```

## Outputs

- Branch `fix/dashboard-[Nome]-[YYYYMMDD]` criada
- Commit com mensagem business-friendly
- PR aberto com URL entregue ao analista
- `_documentacao/` atualizada seletivamente

## Pré-requisitos

- `gh` CLI instalado e autenticado (`gh auth status`)
- Arquivo PBIP presente em `dashboards/[Dashboard]/`
- Mudanças não comitadas (`git status` mostra arquivos modificados)
