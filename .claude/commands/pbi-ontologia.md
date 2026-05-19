---
name: pbi-ontologia
description: Consolida sugestões pendentes de múltiplos dashboards e propõe edições ao GLOSSARY.md, KPIS.md, DOMAINS.md e MAPPING.md. Apresenta diff antes de qualquer alteração e aguarda confirmação explícita. Nunca edita automaticamente.
---

# /pbi-ontologia — Atualização da ontologia corporativa

Carrega e executa a skill `pbi-ontologia` para consolidar e aplicar (com aprovação) atualizações à ontologia em `ontologia/`.

## Uso

```
/pbi-ontologia
```

Com escopo específico:
```
/pbi-ontologia --dashboard Scorecard
/pbi-ontologia --arquivo GLOSSARY
```

## Regra inviolável

**Nunca edita sem confirmação explícita.** Sempre apresenta o diff proposto e aguarda "sim" ou aprovação equivalente antes de escrever qualquer arquivo.

## O que este command faz

A skill:

1. Coleta sugestões pendentes de `_documentacao/06-glossario-negocio.md` de todos os dashboards (marcadas com `📋 Sugestão pendente`)
2. Aceita também sugestões fornecidas diretamente na conversa
3. Lê o estado atual dos 4 arquivos em `ontologia/`
4. Detecta conflitos, duplicatas e inconsistências entre sugestões e ontologia existente
5. Apresenta diff consolidado no chat (o que será adicionado/atualizado em cada arquivo)
6. Aplica apenas após confirmação — preservando estrutura e ordem alfabética
7. Atualiza o timestamp "Última revisão" nos arquivos editados

## Outputs (após confirmação)

```
ontologia/
├── GLOSSARY.md    ← termos novos/atualizados
├── KPIS.md        ← KPIs novos/atualizados
├── DOMAINS.md     ← domínios (se houver sugestões)
└── MAPPING.md     ← mapeamentos DAX → Databricks novos
```

## Boas práticas

- Rodar após documentar múltiplos dashboards para consolidar sugestões em lote
- Criar PR separado para mudanças na ontologia (separado do PR do dashboard)
- Não inventar owners ou metas — usar "A definir"
