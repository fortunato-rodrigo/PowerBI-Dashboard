# Guia de contribuição — PowerBI-Dashboard

---

## Índice

1. [Configuração do ambiente](#1-configuração-do-ambiente)
2. [Adicionando um novo dashboard](#2-adicionando-um-novo-dashboard)
3. [Atualizando um dashboard existente](#3-atualizando-um-dashboard-existente)
4. [Convenções de nomenclatura](#4-convenções-de-nomenclatura)
5. [Convenções de commit](#5-convenções-de-commit)
6. [Fluxo de PR](#6-fluxo-de-pr)
7. [Ontologia corporativa](#7-ontologia-corporativa)
8. [Metadados DBT](#8-metadados-dbt)
9. [Segurança](#9-segurança)

---

## 1. Configuração do ambiente

```powershell
git clone <url-do-repo>
cd PowerBI-Dashboard
aws sso login --profile <seu-perfil>
.\tools\Setup-Env.ps1
```

Se as credenciais expirarem (erro de autenticação ao rodar scripts):

```powershell
aws sso login --profile <seu-perfil>
.\tools\Setup-Env.ps1 -Force
```

---

## 2. Adicionando um novo dashboard

### Passo 1 — Criar branch

```powershell
git checkout dev
git pull
git checkout -b feat/dashboard-<nome-em-kebab-case>
```

Exemplos de nomes de branch:
```
feat/dashboard-gestao-de-receita
feat/dashboard-daily-sales
feat/dashboard-safras
```

### Passo 2 — Adicionar os arquivos PBIP

Copie a pasta do dashboard para `dashboards/<Nome>/`, seguindo a convenção de nomes:

| Nome do dashboard | Pasta |
|---|---|
| Gestão de Receita | `dashboards/Gestao-de-Receita/` |
| Daily Sales | `dashboards/Daily-Sales/` |
| Safras | `dashboards/Safras/` |
| Dash de Ordens | `dashboards/Dash-de-Ordens/` |

> Regra: kebab-case, sem acentos, sem espaços.

A estrutura esperada dentro da pasta:

```
dashboards/Gestao-de-Receita/
├── Gestao-de-Receita.pbip
├── Gestao-de-Receita.SemanticModel/
│   └── definition/
│       └── tables/          ← arquivos .tmdl
└── Gestao-de-Receita.Report/
    └── definition/
        └── pages/
```

### Passo 3 — Gerar a documentação

Abra o Claude Code na raiz do repositório e execute:

```
/pbi-documentar Gestao-de-Receita
```

O Claude vai:
1. Ler todos os `.tmdl` do Semantic Model
2. Detectar a camada de cada fonte (bronze/silver/gold/diamond)
3. Documentar Dataflows inline (sem chamar script separado)
4. Cruzar com a ontologia corporativa e metadados DBT
5. Gerar `_documentacao/` com 7 arquivos

### Passo 4 — Revisar a documentação gerada

Verifique os arquivos em `_documentacao/` e preencha os campos marcados como `"A definir"`:

| Arquivo | O que revisar |
|---|---|
| `00-overview.md` | Owner, público-alvo, frequência de uso |
| `01-tabelas.md` | Confirmar camada de cada tabela |
| `02-medidas.md` | Confirmar explicação de negócio das medidas |
| `05-fontes.md` | Validar alertas de bronze se existirem |
| `06-glossario-negocio.md` | Completar definições específicas deste dashboard |

### Passo 5 — Confirmar sugestões à ontologia

Ao final da documentação, o Claude vai sugerir novos termos para o glossário corporativo.
Revise as sugestões e confirme apenas o que for de fato novo e correto.

### Passo 6 — Commit e PR

```powershell
git add dashboards/<Nome>/
git commit -m "feat: adiciona dashboard <Nome> com documentacao"
git push -u origin feat/dashboard-<nome>
```

Abra o PR apontando para `dev`. Veja as regras de PR na [seção 6](#6-fluxo-de-pr).

---

## 3. Atualizando um dashboard existente

```powershell
git checkout -b fix/dashboard-<nome>-<descricao-curta>
# Faça as alterações nos arquivos PBIP
# Regenere a documentação se o modelo mudou:
/pbi-documentar <Nome>
git add dashboards/<Nome>/
git commit -m "fix: atualiza modelo do dashboard <Nome>"
git push -u origin fix/dashboard-<nome>-<descricao-curta>
```

---

## 4. Convenções de nomenclatura

### Pastas de dashboard

```
kebab-case, sem acentos, sem espaços
Correto:   dashboards/Gestao-de-Receita/
Incorreto: dashboards/Gestão de Receita/
Incorreto: dashboards/gestao_de_receita/
```

### Medidas DAX

```
[Nome Em Title Case]          ← medidas normais
[KPI Nome]                    ← KPIs estratégicos (⭐ no glossário)
[_Nome Auxiliar]              ← medidas internas (prefixo _)
```

### Nomes de tabelas no modelo

```
PascalCase para tabelas fato e dimensão:
  FactOperations, DimCalendar, DimCustomer

Prefixo para tabelas de suporte:
  Medidas        ← tabela de medidas
  Parâmetros     ← tabela de parâmetros/slicers
```

---

## 5. Convenções de commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo | Quando usar |
|---|---|
| `feat:` | Novo dashboard ou nova funcionalidade |
| `fix:` | Correção em dashboard ou documentação existente |
| `docs:` | Alterações apenas em documentação |
| `chore:` | Atualização de scripts, gitignore, config |
| `ontologia:` | Mudanças na pasta `ontologia/` |
| `dbt:` | Atualização dos metadados em `dbt-metadata/` |

Exemplos:

```
feat: adiciona dashboard Gestao-de-Receita com documentacao
fix: corrige relacionamento DimCalendar no Scorecard
docs: atualiza overview do dashboard Daily-Sales
ontologia: adiciona termos Safra e Cohort ao GLOSSARY
chore: atualiza Setup-Env.ps1 para novo path do SSM
```

---

## 6. Fluxo de PR

### Branches

```
main   ← produção (protegida — apenas merge via PR)
dev    ← integração (base para todos os PRs)
feat/* ← novos dashboards
fix/*  ← correções
```

### Regras de PR

- PR sempre aponta para `dev`, nunca direto para `main`
- Pelo menos 1 aprovação antes de mergear
- Descrição obrigatória: o que mudou e por quê
- PRs de ontologia devem ser separados dos PRs de dashboard

### Template de PR

```
## O que foi feito
- Adicionado dashboard X com documentação completa
- Fonte principal: gold.fact_operations

## Revisão necessária
- [ ] Revisar campos "A definir" em _documentacao/
- [ ] Confirmar owner do dashboard no 00-overview.md
- [ ] Validar alertas de bronze se aplicável

## Impacto na ontologia
- Nenhum / Sugestões de novos termos: [listar]
```

---

## 7. Ontologia corporativa

A ontologia em `ontologia/` pertence a toda a empresa — qualquer mudança impacta todos os dashboards.

**Nunca edite diretamente.** O fluxo correto:

1. Rode a documentação de um dashboard (`/pbi-documentar`)
2. O Claude sugere termos novos ao final
3. Revise as sugestões
4. Confirme com `sim`
5. Abra um **PR separado** com prefixo `ontologia:` para as mudanças em `ontologia/`

Para consolidar sugestões de múltiplos dashboards:

```
/pbi-ontologia
```

---

## 8. Metadados DBT

Os arquivos em `dbt-metadata/` são gerados automaticamente a partir do repositório DBT da Remessa Online. **Não edite manualmente.**

Para atualizar após mudanças no DBT:

```
/extrair-dbt
```

> Rodar sempre que o time de dados atualizar modelos silver, gold ou diamond.

---

## 9. Segurança

| Regra | Detalhe |
|---|---|
| Nunca commite `.env` | Está no `.gitignore`. Use `.\tools\Setup-Env.ps1` para gerar localmente |
| Nunca commite `localSettings.json` | Contém caminhos locais e cache — está no `.gitignore` |
| Credenciais no código | Proibido. Sempre via `.env` ou AWS SSM |
| Rotação de credenciais | Após rotação no SSM, rode `.\tools\Setup-Env.ps1 -Force` |
| Dúvidas sobre acesso | Contatar o time de Analytics
