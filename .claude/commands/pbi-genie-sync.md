---
name: pbi-genie-sync
description: Exporta todas as perguntas certificadas do Genie Space da Remessa Online para sql-examples/ no formato YAML. Requer .env com DATABRICKS_HOST e DATABRICKS_TOKEN, e Python venv ativo.
---

# /pbi-genie-sync — Sincronizar perguntas certificadas do Genie

Executa `tools/export-genie-to-sql-examples.py` para importar queries certificadas do Genie Space para `sql-examples/`.

## Uso

```
/pbi-genie-sync
```

## O que este command faz

1. Verifica se `.venv/` existe — se não, orienta rodar `.\tools\Setup-Python.ps1`
2. Verifica `.env` com `DATABRICKS_HOST` e `DATABRICKS_TOKEN` — se não, orienta rodar `.\tools\Setup-Env.ps1`
3. Executa:
   ```powershell
   .\.venv\Scripts\Activate.ps1
   python tools/export-genie-to-sql-examples.py
   ```
4. O script busca todas as perguntas certificadas do Genie Space `01f00a7b6f251beabd6e7a0da9c67fde`
5. Converte cada pergunta para YAML e salva em `sql-examples/` (flat — sem subdiretórios)

## Pré-requisitos

```
.\tools\Setup-Env.ps1          ← cria .env com credenciais do AWS SSM
.\tools\Setup-Python.ps1       ← cria .venv e instala requirements.txt
```

## Output

```
sql-examples/
└── [nome-da-pergunta].yaml    ← arquivos flat (sem subdiretórios)
```

## Nota sobre estrutura flat

O script gera arquivos **flat** em `sql-examples/` sem subdiretórios — alinhado com os 43 YAMLs existentes. Não criar subdiretórios por domínio.

## Quando usar

- Após o time de dados certificar novas perguntas no Genie Space
- Para bootstrapar o store de exemplos com perguntas já validadas em produção
- Periodicamente para manter sql-examples/ atualizado com o Genie

## Relação com /pbi-sql-example

| Situação | Command |
|----------|---------|
| Adicionar 1 query validada manualmente | `/pbi-sql-example` |
| Sincronizar lote do Genie Space | `/pbi-genie-sync` |
