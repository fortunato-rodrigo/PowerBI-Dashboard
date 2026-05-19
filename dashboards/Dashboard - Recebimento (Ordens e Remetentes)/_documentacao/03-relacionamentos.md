# Dashboard - Recebimento — Relacionamentos do Modelo

## Diagrama ASCII

```
d_trading_quotation ──────────────────────────────┐
  [date]                                           │ M:1
                                                   ▼
f_etapa_drop ─────────────────────────────► d_calendar
  [event_date]                              [Date Key]
                                                   ▲
f_fonte_entrada ──────────────────────────────────┘
  [data_criacao_data]                       M:1
                                                   ▲
f_orders ─────────────────────────────────────────┘
  [created_date]                            M:1

─ ─ ─ SEM RELACIONAMENTO ─ ─ ─
f_credito_identificado  (sem join com d_calendar)
```

> `f_credito_identificado` não possui relacionamento com `d_calendar`. A filtragem temporal nessa tabela é feita diretamente na query SQL pelo campo `date >= 2024-01-01`.

---

## Tabela de Relacionamentos

| # | Tabela Origem | Coluna Origem | Tabela Destino | Coluna Destino | Cardinalidade | Direção | Ativo |
|---|---------------|---------------|----------------|----------------|---------------|---------|-------|
| 1 | `d_trading_quotation` | `date` | `d_calendar` | `Date Key` | M:1 | → (single) | ✅ |
| 2 | `f_etapa_drop` | `event_date` | `d_calendar` | `Date Key` | M:1 | → (single) | ✅ |
| 3 | `f_fonte_entrada` | `data_criacao_data` | `d_calendar` | `Date Key` | M:1 | → (single) | ✅ |
| 4 | `f_orders` | `created_date` | `d_calendar` | `Date Key` | M:1 | → (single) | ✅ |

---

## Notas

- Todos os relacionamentos são **muitos-para-um (M:1)**, com direção única (tabela de fato → dimensão de calendário).
- `d_calendar` é o hub central — todas as análises temporais passam por ele.
- `f_credito_identificado` é uma tabela independente no modelo — filtros de calendário **não se propagam** para ela. Útil para consultas de backoffice sem contexto de data do dashboard.
- As tabelas de parâmetro (`p_Medida`, `p_Dimension 1/2/3`, `p_Spread`, `p_Timeframe`) não têm relacionamentos físicos — operam via `SELECTEDVALUE` nas medidas e nas colunas calculadas.
