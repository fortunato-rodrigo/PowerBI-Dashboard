# Scorecard - Business Performance — Relacionamentos

Mapa visual + lista detalhada de relacionamentos entre tabelas.

> **Voltar pra:** [02 · Medidas](02-medidas.md) · **Próxima:** [04 · Dependências](04-dependencias.md)

---

## Diagrama

```
                          ┌──────────────┐
                          │  d_calendar  │
                          └──────┬───────┘
                                 │ 1:N  (processing_date → Date Key)
                                 ▼
  ┌─────────┐  N:1   ┌─────────────────┐  N:1  ┌─────────────────┐
  │  d_bu   │◄───────│                 │───────►│ d_business_type │
  └─────────┘        │                 │        └─────────────────┘
                     │                 │
  ┌──────────────┐   │  f_operations   │   ┌──────────────────┐
  │d_customer_   │◄──│                 │──►│   d_event_type   │
  │   type       │   │                 │   └──────────────────┘
  └──────────────┘   │                 │
                     │                 │   ┌──────────────────┐
                     └────────┬────────┘──►│   d_segment      │
                              │            └──────────────────┘
                              │ N:1 (operation_segment → operation_segment)
```

*Modelo star schema com f_operations como tabela fato central e 6 dimensões.*

---

## Tabela detalhada

| # | From | To | Cardinalidade | Direção | Ativo | Notas |
|---|---|---|---|---|---|---|
| 1 | `f_operations.customer_type` | `d_customer_type.'Customer Type'` | N:1 | Single | ✓ | — |
| 2 | `f_operations.processing_date` | `d_calendar.'Date Key'` | N:1 | Single | ✓ | Dimensão de tempo |
| 3 | `f_operations.event_type` | `d_event_type.event_type` | N:1 | Single | ✓ | — |
| 4 | `f_operations.operation_segment` | `d_segment.operation_segment` | N:1 | Single | ✓ | — |
| 5 | `f_operations.bu` | `d_bu.BU` | N:1 | Single | ✓ | — |
| 6 | `f_operations.business_type` | `d_business_type.'Business Type'` | N:1 | Single | ✓ | — |

> **Notas:** todos os 6 relacionamentos são N:1 com direção Single (sem bi-direcional). Todos ativos.

---

## Análise rápida

O modelo segue um star schema clássico com `f_operations` como fato central. Há 6 relacionamentos, todos N:1, todos single-direction, todos ativos — estrutura limpa e sem ambiguidade de filtro. As dimensões cobrem as perspectivas de análise principais do negócio: tempo (`d_calendar`), tipo de cliente (`d_customer_type`), tipo de negócio (`d_business_type`), unidade de negócio (`d_bu`), segmento de operação (`d_segment`) e tipo de evento (`d_event_type`). As tabelas auxiliares (parameter tables, measure tables, calculation group, `d_faq`, `t_tabela`) não participam de relacionamentos — são usadas via DAX direto ou como slicers sem filtro cruzado na fato.

> **Tom:** descrever, não opinar. Pra auditoria de qualidade dos relacionamentos (anti-patterns, bi-direcional desnecessário, etc.), use `/pbi-modelo-review`.

---

*XPERIUN · `/pbi-doc`*
