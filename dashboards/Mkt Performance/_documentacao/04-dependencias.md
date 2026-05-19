# 04 — Mapa de Dependências: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`

---

## Árvore de Dependências das Medidas Principais

### % Conversão
```
% Conversão
├── [Aquisições]
│   └── f_mkt_performance[event_id], f_mkt_performance[event_type]
└── [Presignups]
    └── f_mkt_performance[id_customer], f_mkt_performance[event_type]
```

---

### GMV
```
GMV
└── f_mkt_performance[gmv], f_mkt_performance[event_type]
```

### GMV (Aquisição)
```
GMV (Aquisição)
└── [GMV]
    └── f_mkt_performance[gmv], f_mkt_performance[event_type]
```

### GMV (Recorrência)
```
GMV (Recorrência)
└── [GMV]
    └── f_mkt_performance[gmv], f_mkt_performance[event_type]
```

---

### Receita
```
Receita
└── f_mkt_performance[gross_revenue], f_mkt_performance[event_type]
```

### Receita (Aquisição)
```
Receita (Aquisição)
└── [Receita]
    └── f_mkt_performance[gross_revenue], f_mkt_performance[event_type]
```

---

### Spread
```
Spread
├── [Receita]
│   └── f_mkt_performance[gross_revenue], f_mkt_performance[event_type]
└── [GMV]
    └── f_mkt_performance[gmv], f_mkt_performance[event_type]
```

---

### Ticket Médio (GMV)
```
Ticket Médio (GMV)
├── [GMV]
│   └── f_mkt_performance[gmv], f_mkt_performance[event_type]
└── [Operações]
    └── f_mkt_performance[event_id], f_mkt_performance[event_type]
```

---

### CPA PF
```
CPA PF
├── [PF Investimento]
│   └── [Investimento]
│       └── f_investimento[investimento]
│   + d_customer_type[Customer Type] = "PF"
└── [PF Aquisições]
    └── [Aquisições]
        └── f_mkt_performance[event_id], f_mkt_performance[event_type]
    + f_mkt_performance[Customer Type] = "PF"
```

---

### CPA PJ
```
CPA PJ
├── [PJ Investimento]
│   └── [Investimento]
│       └── f_investimento[investimento]
│   + d_customer_type[Customer Type] = "PJ"
└── [PJ Aquisições]
    └── [Aquisições]
        └── f_mkt_performance[event_id], f_mkt_performance[event_type]
    + f_mkt_performance[Customer Type] = "PJ"
```

---

### P1 (medida dinâmica)
```
P1
└── t_Tabela[KPI]  →  switcha para:
    ├── [GMV P1]
    │   └── [GMV]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
    ├── [Receita P1]
    │   └── [Receita]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
    ├── [OPS P1]
    │   └── [Operações]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
    ├── [PSU P1]
    │   └── [Presignups]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
    ├── [SU P1]
    │   └── [Signups]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
    └── [Ticket P1]
        └── [Ticket Médio (GMV)]  →  d_calendar via USERELATIONSHIP(t_Período 1[Date])
```

---

### % P1 x P2
```
% P1 x P2
├── [P1]  (ver dependência acima)
└── [P2]  (mesmo padrão, período 2)
```

---

### Filter Date
```
Filter Date
└── d_calendar[Date Key]  (REMOVEFILTERS + MIN/MAX)
```

---

## Referência Reversa: Colunas-chave e medidas dependentes

### `f_mkt_performance[event_type]`
Usada por: Aquisições, Presignups, Signups, Operações, Recorrências, GMV, GMV (Aquisição), GMV (Recorrência), Receita, Receita (Aquisição), Receita (Recorrência), Clientes Únicos Recorrentes, Histórias Criadas, Histórias Aprovadas, PF Aquisições, PJ Aquisições, PF Presignups, PJ Presignups, PF Signups, PJ Signups, e todas as medidas de comparação temporal.

### `f_mkt_performance[event_id]`
Usada por: Aquisições, Eventos, Operações, Recorrências, Histórias Criadas, Histórias Aprovadas, e todas as derivadas.

### `f_mkt_performance[id_customer]`
Usada por: Presignups, Signups, Clientes Únicos, e derivadas PF/PJ.

### `f_mkt_performance[gmv]`
Usada por: GMV, GMV (Aquisição), GMV (Recorrência), Ticket Médio (GMV), Ticket Médio (GMV - Aquisição), Ticket Médio (GMV - Recorrência), Spread, e variantes por período e tipo de cliente.

### `f_mkt_performance[gross_revenue]`
Usada por: Receita, Receita (Aquisição), Receita (Recorrência), Spread, e variantes por período e tipo de cliente.

### `f_investimento[investimento]`
Usada por: Investimento, PF Investimento, PJ Investimento, CPA PF, CPA PJ, CPP PF, CPP PJ.

### `d_calendar[Date Key]`
Usada por: Filter Date, Last Update, e todas as medidas de comparação temporal via USERELATIONSHIP.

### `t_Tabela[KPI]`
Usada por: P1, P2, P3, Título (indiretamente).

### `f_trading_quotation[trading_quotation]`
Usada por: Valor da Moeda (Max), Valor da Moeda (Med), Valor da Moeda (Min).

---

## Medidas Isoladas (sem dependência de outras medidas DAX)

Medidas que leem diretamente de colunas de tabelas, sem encadear outras medidas:

| Medida | Tabela base |
|--------|-------------|
| Aquisições | f_mkt_performance |
| Presignups | f_mkt_performance |
| Signups | f_mkt_performance |
| Operações | f_mkt_performance |
| Recorrências | f_mkt_performance |
| Eventos | f_mkt_performance |
| Clientes Únicos | f_mkt_performance |
| GMV | f_mkt_performance |
| Receita | f_mkt_performance |
| Histórias Criadas | f_mkt_performance |
| Histórias Aprovadas | f_mkt_performance |
| Investimento | f_investimento |
| Last Update | f_mkt_performance |
| Valor da Moeda (Max/Med/Min) | f_trading_quotation |
| _PSU, _SU, _GMV, _OPS, _REC, _SPR, _TCK, _HIS Ap, _HIS Cr | Constantes de texto |

---

## Medidas Órfãs

Nenhuma medida órfã identificada. Todas as medidas estão agrupadas em pastas (`displayFolder`) e referenciadas por outras medidas ou visuais.

---

## Dependências entre grupos de medidas

```
Medidas base (agregações simples)
    ↓
Medidas derivadas (CALCULATE com filtro de event_type)
    ↓
Medidas por segmento (PF/PJ via d_customer_type)
    ↓
Medidas de ratio/divisão (CPA, CPP, Spread, Ticket, % Conversão)
    ↓
Medidas por período (P1, P2, P3 via USERELATIONSHIP)
    ↓
Medidas de comparação (%, ∆ entre períodos)
    ↓
Medidas dinâmicas (P1, P2, P3 via SWITCH + t_Tabela[KPI])
    ↓
Medidas de display (Título, Filtrar Zero, Filter Date)
```
