---
name: pbi-sql-examples
description: Adiciona um novo exemplo de pergunta+SQL ao store sql-examples/. Guia o usuário para fornecer a pergunta em PT, o SQL validado e notas de contexto, então gera e salva o YAML no formato correto. Use quando alguém do time de Analytics quiser contribuir com uma nova query validada para o NL2SQL.
---

# /pbi-sql-examples — Adicionar exemplo SQL ao store NL2SQL

Adiciona um novo par pergunta→SQL ao diretório `sql-examples/` no formato YAML padrão.

## Uso

```
/pbi-sql-examples
/pbi-sql-examples "Qual o GMV por país em 2025?"
```

Se a pergunta não for fornecida como argumento, perguntar interativamente.

---

## Processo de execução

### Etapa 1 — Coletar a pergunta principal

Se não fornecida como argumento, perguntar:

```
Qual é a pergunta de negócio que esse SQL responde?
(ex: "Qual o GMV total por BU em abril?")
```

### Etapa 2 — Coletar o SQL

Perguntar:

```
Cole o SQL validado para essa pergunta:
```

Se o SQL contiver:
- `prod.gold.` → normalizar para `gold.`
- `prod.silver.` → normalizar para `silver.`
- Backticks em nomes de tabelas/colunas padrão → remover
- `LIMIT 1000` sem contexto → remover e mencionar no chat: "LIMIT 1000 do Genie removido — adicione LIMIT explícito na pergunta se necessário"

### Etapa 3 — Gerar question_variants

Com base na pergunta principal fornecida, gerar automaticamente 3 variações em português natural — formas alternativas de como um usuário de negócio poderia fazer a mesma pergunta.

Exemplos de variações para "Qual o GMV total por BU em abril?":
- "GMV de abril segmentado por BU"
- "Quanto de GMV cada BU fez em abril?"
- "Volume de câmbio por unidade de negócio no mês de abril"

Apresentar as variações geradas e perguntar:
```
Variações geradas. Quer ajustar alguma ou adicionar mais? (Enter para confirmar)
```

### Etapa 4 — Extrair tables_used

Analisar o SQL e identificar automaticamente as tabelas referenciadas (após FROM e JOIN).

Apresentar para confirmação:
```
Tabelas identificadas: [gold.fact_operations, gold.fact_customers]
Correto? (Enter para confirmar ou corrija)
```

### Etapa 5 — Coletar notes

Perguntar:

```
Alguma regra de negócio importante para esse SQL?
(ex: filtros obrigatórios, colunas com significado especial, cuidados ao interpretar)
Enter para pular.
```

Se o SQL contiver filtros da ontologia, sugerir automaticamente as notes relevantes:
- `is_ops_processed = TRUE` → sugerir: "is_ops_processed=TRUE obrigatório"
- `is_intercompany = FALSE` → sugerir: "is_intercompany=FALSE obrigatório"
- `email NOT LIKE '%fxaas%'` → sugerir: "PSU sem FxaaS — excluir parceiros B2B por padrão"
- `event_sequence = 1` → sugerir: "event_sequence=1 obrigatório para evitar contar o mesmo cliente N vezes"
- `operation_event_type = 'Aquisição'` → sugerir: "Aquisição = primeira operação do cliente"

### Etapa 6 — Gerar nome do arquivo

Gerar automaticamente o nome do arquivo a partir da pergunta:
- Lowercase, sem acentos, espaços → hífens, máximo 50 caracteres
- Exemplos:
  - "Qual o GMV por país em 2025?" → `gmv-por-pais.yaml`
  - "Quantos clientes PF fizeram segunda operação?" → `segunda-operacao-clientes-pf.yaml`

Apresentar: `Arquivo: sql-examples/[nome-gerado].yaml — OK?`

Se já existir um arquivo com esse nome, alertar e sugerir nome alternativo.

### Etapa 7 — Apresentar preview e confirmar

Mostrar o YAML completo antes de salvar:

```yaml
question_variants:
  - "[pergunta principal]"
  - "[variação 1]"
  - "[variação 2]"
  - "[variação 3]"
sql: |
  [SQL normalizado]
tables_used: [tabela1, tabela2]
notes: "[notes consolidadas]"
validated_by: [nome do usuário ou "equipe-analytics"]
validated_date: [data de hoje]
```

Perguntar: `Salvar em sql-examples/[nome].yaml? (sim/não)`

### Etapa 8 — Salvar o arquivo

Após confirmação:
1. Criar o arquivo `sql-examples/[nome].yaml`
2. Confirmar no chat:

```
Salvo em sql-examples/[nome].yaml

Próximos passos:
- Revise e ajuste question_variants para cobrir mais formas de perguntar
- Abra um PR para incorporar ao repositório: git add sql-examples/[nome].yaml
```

---

## Regras invioláveis

1. **Nunca salvar sem confirmação** — sempre mostrar preview completo antes de escrever
2. **Nunca inventar SQL** — apenas formatar e normalizar o SQL fornecido pelo usuário
3. **Sempre normalizar** `prod.gold.` → `gold.` e remover backticks desnecessários
4. **Sempre sugerir** notes de ontologia quando os filtros padrão (is_ops_processed, FxaaS, event_sequence) forem detectados no SQL
5. **PT-BR** em todas as interações

---

## Formato obrigatório do YAML

```yaml
question_variants:
  - "Pergunta principal exatamente como o usuário digitaria"
  - "Variação 2"
  - "Variação 3"
  - "Variação 4 (opcional)"
sql: |
  SELECT ...
  FROM gold.tabela
  WHERE ...
tables_used: [gold.tabela1, gold.tabela2]
notes: "Regras de negócio, filtros obrigatórios, contexto de uso."
validated_by: equipe-analytics
validated_date: YYYY-MM-DD
```

**Campos obrigatórios:** `question_variants` (mínimo 2), `sql`, `tables_used`, `validated_by`, `validated_date`
**Campo opcional:** `notes` (omitir se não houver nada relevante)
