---
name: pbi-ontologia
description: Consolida sugestões pendentes de múltiplos dashboards e propõe edições ao GLOSSARY.md, KPIS.md, DOMAINS.md e MAPPING.md para revisão e aprovação. Nunca edita automaticamente — sempre apresenta diff e aguarda confirmação. Use quando o usuário quiser incorporar novos termos ou KPIs na ontologia corporativa.
---

# /pbi-ontologia — Atualização da ontologia corporativa

Consolida e aplica (com aprovação) atualizações à ontologia corporativa em `ontologia/`.

## Uso

```
/pbi-ontologia
```

Ou com escopo específico:
```
/pbi-ontologia --dashboard Scorecard
/pbi-ontologia --arquivo GLOSSARY
```

## Regra inviolável

**Nunca editar a ontologia sem confirmação explícita do usuário.**
Sempre apresentar o diff proposto e aguardar "sim" ou aprovação equivalente antes de escrever qualquer arquivo.

## Processo de execução

### Etapa 1 — Coletar sugestões pendentes

Verificar se há sugestões pendentes geradas por execuções anteriores de `/pbi-documentacao`.
Sugestões ficam no final dos arquivos `_documentacao/06-glossario-negocio.md` de cada dashboard,
marcadas com `📋 Sugestão pendente para ontologia`.

Também aceitar sugestões fornecidas diretamente na conversa pelo usuário.

### Etapa 2 — Ler estado atual da ontologia

Ler os 4 arquivos em `ontologia/`:
- `GLOSSARY.md`
- `KPIS.md`
- `DOMAINS.md`
- `MAPPING.md`

### Etapa 3 — Identificar conflitos e duplicatas

Para cada sugestão, verificar:
- O termo já existe na ontologia? → propor atualização, não duplicata
- Há conflito com definição existente? → apresentar as duas versões e pedir decisão
- A definição é consistente com outros termos relacionados? → alertar se não

### Etapa 4 — Apresentar diff consolidado

Apresentar no chat o que seria alterado em cada arquivo:

```
📋 Atualizações propostas para a ontologia corporativa:

━━━ ontologia/GLOSSARY.md ━━━

NOVO — Ticket Médio:
  Definição: Valor médio por operação = GMV / Operations
  Sinônimos: ticket, AOV
  Dashboards: Daily-Sales
  Medida DAX: Medidas.Ticket Médio

ATUALIZAÇÃO — GMV (linha 47):
  Antes: "Métrica de escala do negócio."
  Depois: "Métrica de escala do negócio. GMV consolidado inclui..."

━━━ ontologia/KPIS.md ━━━

NOVO — Ticket Médio:
  Owner: A definir
  Meta: A definir
  Dashboard: Daily-Sales

━━━ ontologia/MAPPING.md ━━━

NOVO — Ticket Médio → Medidas.Ticket Médio → gold.fact_operations (calculado)

Confirme com "sim" para aplicar todas, ou indique quais aceitar (ex: "aceito 1 e 3, rejeito 2").
```

### Etapa 5 — Aplicar após confirmação

Somente após confirmação explícita:
1. Editar cada arquivo da ontologia com as mudanças aprovadas
2. Preservar a estrutura e formatação existente
3. Adicionar novos termos em ordem alfabética
4. Atualizar `Última revisão` no cabeçalho dos arquivos editados

### Etapa 6 — Confirmar no chat

```
✅ Ontologia atualizada:

- GLOSSARY.md: [N] termos adicionados, [N] atualizados
- KPIS.md: [N] KPIs adicionados
- MAPPING.md: [N] mapeamentos adicionados

📌 Lembrete: mudanças na ontologia devem ir em um PR separado
   (separado do PR do dashboard que originou as sugestões).
```

## Outputs

Edita diretamente (após aprovação):
- `ontologia/GLOSSARY.md`
- `ontologia/KPIS.md`
- `ontologia/DOMAINS.md` (se houver sugestões de domínio)
- `ontologia/MAPPING.md`

## Regras

1. Nunca editar sem confirmação — sempre mostrar diff primeiro
2. Nunca inventar owners ou metas — usar "A definir"
3. Nunca remover termos existentes sem aprovação explícita
4. Manter ordem alfabética nos arquivos editados
5. PT-BR em toda documentação
