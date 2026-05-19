# Daily Sales Dashboard — Relacionamentos

## Diagrama do Modelo (Estrela com múltiplas fatos)

```
                           ┌─────────────┐
                           │  dcalendar  │
                           │  Date Key   │
                           └──────┬──────┘
                                  │
            ┌─────────────────────┼────────────────────────┐
            │                     │                         │
    ┌───────▼──────┐   ┌──────────▼──────┐   ┌────────────▼────────┐
    │ f_daily_sales│   │ f_daily_sales_  │   │   f_investimentos   │
    │   date_key   │   │ psu  date_key   │   │     date_key        │
    └──────┬───────┘   └───────┬─────────┘   └─────────────────────┘
           │                   │
    ┌──────▼──────┐    ┌───────▼─────────┐
    │    d_bu     │    │  d_customer_    │
    │     BU      │    │  type           │
    └─────────────┘    └─────────────────┘
           │                   │
    ┌──────▼──────┐    ┌───────▼─────────┐
    │d_business   │    │   d_event_type  │
    │_type        │    │   event_type    │
    └─────────────┘    └─────────────────┘
           │                   │
    ┌──────▼──────┐    ┌───────▼─────────┐
    │  f_gold_ops │    │    d_canal      │
    │ (date, bu,  │    │    canal        │
    │  bt, ct,    │    └─────────────────┘
    │  segment,   │
    │  event_type)│    ┌─────────────────┐
    └─────────────┘    │   d_segment     │
                       │   Segmento      │
    ┌─────────────┐    └─────────────────┘
    │   f_wallet  │
    │(date, bu,   │
    │ bt, ct,     │
    │ segment,    │
    │ event_type) │
    └─────────────┘

    ┌─────────────────────┐
    │  f_pnl_tesouraria   │
    │  date_key, bu       │
    └─────────────────────┘

    ┌─────────────────────┐
    │   f_last_update     │  (sem relacionamentos)
    └─────────────────────┘
```

---

## Tabela de Relacionamentos

| # | De (Tabela.Coluna) | Para (Tabela.Coluna) | Cardinalidade | Direção | Ativo |
|---|--------------------|---------------------|--------------|---------|-------|
| 1 | `f_daily_sales.date_key` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 2 | `f_daily_sales.bu` | `d_bu.BU` | N:1 | Único | Sim |
| 3 | `f_daily_sales.business_type` | `d_business_type.'Business Type'` | N:1 | Único | Sim |
| 4 | `f_daily_sales.event_type` | `d_event_type.Evento` | N:1 | Único | Sim |
| 5 | `f_daily_sales_psu.date_key` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 6 | `f_daily_sales_psu.customer_type` | `d_customer_type.'Customer Type'` | N:1 | Único | Sim |
| 7 | `f_daily_sales_psu.event_type` | `d_event_type.event_type` | N:1 | Único | Sim |
| 8 | `f_daily_sales_psu.canal` | `d_canal.canal` | N:1 | Único | Sim |
| 9 | `f_investimentos.date_key` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 10 | `f_investimentos.customer_type` | `d_customer_type.'Customer Type'` | N:1 | Único | Sim |
| 11 | `f_wallet.date_key` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 12 | `f_wallet.bu` | `d_bu.BU` | N:1 | Único | Sim |
| 13 | `f_wallet.business_type` | `d_business_type.'Business Type'` | N:1 | Único | Sim |
| 14 | `f_wallet.customer_type` | `d_customer_type.'Customer Type'` | N:1 | Único | Sim |
| 15 | `f_wallet.event_type` | `d_event_type.event_type` | N:1 | Único | Sim |
| 16 | `f_wallet.operation_segment` | `d_segment.Segmento` | N:1 | Único | Sim |
| 17 | `f_pnl_tesouraria.date_key` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 18 | `f_pnl_tesouraria.bu` | `d_bu.BU` | N:1 | Único | Sim |
| 19 | `f_gold_ops.operation_date` | `dcalendar.'Date Key'` | N:1 | Único | Sim |
| 20 | `f_gold_ops.bu` | `d_bu.BU` | N:1 | Único | Sim |
| 21 | `f_gold_ops.business_type` | `d_business_type.'Business Type'` | N:1 | Único | Sim |
| 22 | `f_gold_ops.customer_type` | `d_customer_type.'Customer Type'` | N:1 | Único | Sim |
| 23 | `f_gold_ops.operation_segment` | `d_segment.Segmento` | N:1 | Único | Sim |
| 24 | `f_gold_ops.event_type` | `d_event_type.event_type` | N:1 | Único | Sim |

**Total: 24 relacionamentos · todos ativos · todos N:1 · todos direção único**

---

## Tabelas sem Relacionamentos

| Tabela | Motivo |
|--------|--------|
| `# Medidas` | Tabela de medidas DAX — sem colunas de dado |
| `Tabela` | Seletor de KPI — estático, usado via `SELECTEDVALUE` nas medidas |
| `Business` | Seletor de dimensão — estático, usado para filtrar visuais |
| `Intraday Flag` | Toggle booleano — usado via `SELECTEDVALUE` nas medidas |
| `f_last_update` | Utilitário de timestamp — usado apenas pela medida `Last Update` |

---

## Observações

1. **Modelo multifato:** 5 tabelas fato compartilham o mesmo conjunto de dimensões. Cada fato representa uma fonte de dados diferente (vendas agregadas, PSU, investimento, wallet, operações granulares).
2. **Coluna dupla em d_event_type:** A tabela `d_event_type` tem duas colunas — `event_type` (código técnico) e `Evento` (nome de exibição). `f_daily_sales` usa `Evento`; as demais tabelas usam `event_type`.
3. **d_customer_type oculta:** A coluna `Customer Type` em `d_customer_type` está marcada como `isHidden` no modelo — é usada apenas como filtro, não exibida em visuais.
4. **Propagação de filtro:** Com direção único, filtros fluem da dimensão para a fato. Para filtrar uma fato a partir de outra (ex: `f_daily_sales` filtrada por `d_customer_type` usando dados de `f_daily_sales_psu`), é necessário usar `CROSSFILTER` ou `TREATAS` em DAX.
