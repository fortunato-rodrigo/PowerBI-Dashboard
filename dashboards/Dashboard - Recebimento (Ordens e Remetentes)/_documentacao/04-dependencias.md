# Dashboard - Recebimento — Mapa de Dependências

## Árvore de Dependências

```
Medidas de Volume
├── Ordens
│   └── f_orders[id] (DISTINCTCOUNT)
├── Resgatadas
│   └── f_orders[id, status_ordem_resumo]
├── Resgatadas (mesmo mês)
│   └── [Ordens] + f_orders[resgate_mesmo_mes]
├── Pendentes
│   └── f_orders[id, status_ordem_resumo]
├── % Resgate
│   ├── [Resgatadas]
│   └── [Ordens]
└── % Resgate no mesmo mês
    ├── [Resgatadas (mesmo mês)]
    └── [Ordens]

Medidas de GMV
├── GMV (Resgatado)
│   └── f_orders[gmv, status_ordem_resumo]
├── GMV Pendente (Forecast)
│   └── f_orders[gmv_forecast, status_ordem_resumo]
│       └── gmv_forecast = quantity * trading_quotation (coluna calculada)
│           └── d_trading_quotation[trading_quotation] via LOOKUPVALUE
├── GMV (Resgatado + Pendente)
│   ├── f_orders[gmv] (resgatadas)
│   └── f_orders[gmv_forecast] (pendentes com gmv BLANK)
├── Ticket Médio (Resgatado)
│   ├── [GMV (Resgatado)]
│   └── [Resgatadas]
├── AVG Ticket (Pendente)
│   ├── [GMV Pendente (Forecast)]
│   └── [Pendentes]
└── Ticket Médio (Resgatado + Pendente)
    ├── [GMV (Resgatado + Pendente)]
    └── [Ordens]

Medidas de Receita
├── Receita (Resgatado)
│   └── f_orders[gross_revenue, status_ordem_resumo]
└── Receita Pendente (Forecast)  ⚠️
    ├── [GMV Pendente (Forecast)]
    └── p_Spread (What if?)[Valor Spread (What if?)]  ← SLIDER 0%–2%
        └── gross_revenue_forecast = quantity * 0.0083  ← HARDCODED

Medidas de Clientes
├── Clientes únicos
│   └── f_orders[id_customer] (DISTINCTCOUNT)
└── Ordens por cliente
    ├── [Ordens]
    └── [Clientes únicos]

Medidas de Moeda Estrangeira
├── ME
│   └── f_orders[quantity] (SUM)
├── ME (Resgatado)
│   └── f_orders[quantity, status_ordem_resumo]
└── ME (Pendente)
    └── f_orders[quantity, status_ordem_resumo]

Medidas de Comparação Temporal ⚠️
├── Ordens Anterior  ⚠️
│   ├── [Ordens]
│   ├── p_Timeframe[SelectedValue]  ← Year/Quarter/Month/Week/Date
│   ├── f_orders[mtd]               ← filtro MTD dias úteis
│   ├── f_orders[mtd_calendar_days] ← filtro MTD calendário
│   ├── d_calendar[Date Key]        ← PARALLELPERIOD / DATEADD
│   └── d_calendar[mtd], d_calendar[mtd_calendar_days]
└── PercentualCrescimento
    ├── [Ordens]
    └── [Ordens Anterior]

Medidas de Cotação FX
├── Max  → d_trading_quotation[trading_quotation]
├── Min  → d_trading_quotation[trading_quotation]
└── Median → d_trading_quotation[trading_quotation]

Medidas Auxiliares
├── Última Data   → d_calendar[Date Key, mtd]
├── Último dia útil → d_calendar[workday, mtd]
└── Refresh Date  → d_last_update[last_update]

Funil de Drop-off
└── Total Users → f_etapa_drop[id_customer]

Parâmetro de Spread
└── Valor Spread (What if?) → p_Spread (What if?)[Spread (What if?)]
```

---

## Referência Reversa — Colunas Críticas

| Coluna | Tabela | Medidas que dependem dela |
|--------|--------|--------------------------|
| `id` | `f_orders` | Ordens, Resgatadas, Pendentes, % Resgate, % Resgate no mesmo mês |
| `status_ordem_resumo` | `f_orders` | Resgatadas, Pendentes, GMV (Resgatado), GMV Pendente (Forecast), Receita (Resgatado), Receita Pendente (Forecast), ME (Resgatado), ME (Pendente) |
| `gmv` | `f_orders` | GMV (Resgatado), GMV (Resgatado + Pendente), Ticket Médio (Resgatado) |
| `gmv_forecast` | `f_orders` | GMV Pendente (Forecast), GMV (Resgatado + Pendente), AVG Ticket (Pendente), Ticket Médio (Resgatado + Pendente) |
| `gross_revenue` | `f_orders` | Receita (Resgatado) |
| `quantity` | `f_orders` | ME, ME (Resgatado), ME (Pendente) |
| `id_customer` | `f_orders` | Clientes únicos, Ordens por cliente |
| `resgate_mesmo_mes` | `f_orders` | Resgatadas (mesmo mês), % Resgate no mesmo mês |
| `trading_quotation` | `d_trading_quotation` | Max, Min, Median (e indiretamente gmv_forecast) |
| `Date Key` | `d_calendar` | Ordens Anterior (via PARALLELPERIOD/DATEADD), Última Data |
| `mtd` | `d_calendar` / `f_orders` | Ordens Anterior, Última Data, Último dia útil |
| `SelectedValue` | `p_Timeframe` | Ordens Anterior |
| `Spread (What if?)` | `p_Spread (What if?)` | Valor Spread (What if?), Receita Pendente (Forecast) |
| `id_customer` | `f_etapa_drop` | Total Users |
| `last_update` | `d_last_update` | Refresh Date |

---

## Medidas Atômicas (sem dependência de outras medidas)

| Medida | Dependência direta |
|--------|-------------------|
| `Ordens` | `f_orders[id]` |
| `Resgatadas` | `f_orders[id, status_ordem_resumo]` |
| `Pendentes` | `f_orders[id, status_ordem_resumo]` |
| `GMV (Resgatado)` | `f_orders[gmv, status_ordem_resumo]` |
| `GMV Pendente (Forecast)` | `f_orders[gmv_forecast, status_ordem_resumo]` |
| `Receita (Resgatado)` | `f_orders[gross_revenue, status_ordem_resumo]` |
| `Clientes únicos` | `f_orders[id_customer]` |
| `ME` | `f_orders[quantity]` |
| `ME (Resgatado)` | `f_orders[quantity, status_ordem_resumo]` |
| `ME (Pendente)` | `f_orders[quantity, status_ordem_resumo]` |
| `Max` / `Min` / `Median` | `d_trading_quotation[trading_quotation]` |
| `Última Data` | `d_calendar[Date Key, mtd]` |
| `Último dia útil` | `d_calendar[workday, mtd]` |
| `Refresh Date` | `d_last_update[last_update]` |
| `Total Users` | `f_etapa_drop[id_customer]` |
| `Valor Spread (What if?)` | `p_Spread (What if?)[Spread]` |

---

## Medidas Órfãs (apenas no modelo, potencialmente sem uso em visuais)

Verificar uso nos visuais:
- `Último dia útil` — auxiliar de calendário, verificar se é referenciada em algum visual
- `Última Data` — auxiliar de calendário, idem
- `ME` — sem filtro de status, verificar se há visual que a usa diretamente
