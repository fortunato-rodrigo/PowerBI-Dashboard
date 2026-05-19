# Dashboard de Safras — Mapa de Dependências

---

## Árvore de Dependências por Medida

### Medidas de base (sem dependências de outras medidas)

| Medida | Tabelas/Colunas usadas |
|--------|----------------------|
| `Presignups` | `f_funnel_events[id_customer]`, `f_funnel_events[event_type]` |
| `Signups` | `f_funnel_events[id_customer]`, `f_funnel_events[event_type]` |
| `Aquisições` | `f_funnel_events[id_customer]`, `f_funnel_events[event_type]` |
| `Clientes Únicos` | `f_funnel_events[id_customer]`, `f_funnel_events[event_type]` |
| `Operações` | `f_funnel_events[event_id]`, `f_funnel_events[event_type]` |
| `Eventos` | `f_funnel_events[event_id]` |
| `Histórias Aprovadas` | `f_funnel_events[event_id]`, `f_funnel_events[event_type]` |
| `GMV` | `f_funnel_events[gmv]`, `f_funnel_events[event_type]` |
| `Gross Revenue` | `f_funnel_events[gross_revenue]`, `f_funnel_events[event_type]` |
| `Refresh Date` | `d_last_update[last_update]` |
| `Signups Cohortados do Presignup` | `f_funnel_events[id_customer]`, `[event_type]`, `[signup_date]` |
| `Aquisições Cohortadas do Presignup` | `f_funnel_events[id_customer]`, `[event_type]`, `[Mês da Aquisição]` |
| `Aquisições Cohortadas do Signup` | `f_funnel_events[id_customer]`, `[event_type]`, `[Mês da Aquisição]` |
| `Segunda Operação (Cohorted)` | `f_funnel_events[id_customer]`, `[event_type]`, `[second_operation_month]` |

---

### Medidas derivadas (dependem de outras medidas)

```
Conversão Cohortada (ACQ/PSU)
├── Aquisições Cohortadas do Presignup
│   └── f_funnel_events[id_customer, event_type, Mês da Aquisição]
└── Presignups
    └── f_funnel_events[id_customer, event_type]

Conversão Cohortada (ACQ/PSU) | Mesmo Mês
├── Aquisições Cohortadas do Presignup | Mesmo Mês
│   └── f_funnel_events[id_customer, event_type, Mês da Aquisição, Month PSU = Month ACQ]
└── Presignups

Conversão Cohortada (ACQ/PSU) | Meses Seguintes
├── Aquisições Cohortadas do Presignup | Meses Seguintes
└── Presignups

Conversão Cohortada Acumulada (ACQ/PSU)
├── Aquisições Cohortadas do Presignup - Acumulado
│   ├── Aquisições Cohortadas do Presignup
│   └── d_calendar[Date Key, date_month]
└── Presignups (Acumulado)
    ├── Presignups
    └── d_calendar[Date Key, date_month]

Conversão Cohortada (ACQ/SU)
├── Aquisições Cohortadas do Signup
└── Signups

Conversão Cohortada (SU/PSU)
├── Signups Cohortados do Presignup
└── Presignups

Aquisições Cohortadas do Presignup - Média Móvel Últimos 6 meses
├── Aquisições Cohortadas do Presignup
├── f_funnel_events[event_month]
├── d_calendar[Date Key]
└── d_intervalo_meses[Interval]  (via SELECTEDVALUE)

Aquisições Cohortadas do Presignup | Cohort Dinâmico
├── Aquisições Cohortadas do Presignup
├── f_funnel_events[Diferença de Dias entre Presignup e Aquisição]
└── p_Cohort[SelectedValue]  (via SELECTEDVALUE)

% do Total de Aquisições (PSU - Cohorted)
├── Aquisições Cohortadas do Presignup
└── Total de Aquisições (PSU - Cohorted)
    └── Aquisições Cohortadas do Presignup (ALLSELECTED Mês do Presignup)

Aquisições Dinâmicas - Diferença de Meses
├── Aquisições
├── f_funnel_events[Diferença de Meses]
└── p_Modo de Exibição[Exibição]  (via SELECTEDVALUE)

LineColor
└── d_calendar[Current Month]  (via SELECTEDVALUE)

Cadastro 100% Preenchido
└── Presignups + f_funnel_events[full_registration]

Total de Presignups - KPI
├── Total de Presignups - Valor Min (MINX)
│   └── Presignups
├── Total de Presignups - Valor Max (MAXX)
│   └── Presignups
└── Presignups

Total de Presignups - KPI Limpo
├── Total de Presignups - KPI
└── Presignups
    └── f_funnel_events[Mês do Presignup]
```

---

## Referência Reversa (quem usa cada tabela)

### f_funnel_events

Usada por praticamente todas as medidas. Colunas mais referenciadas:

| Coluna | Medidas que a referenciam |
|--------|--------------------------|
| `id_customer` | Presignups, Signups, Aquisições, Clientes Únicos, todas cohortadas |
| `event_type` | Todas as medidas de volume e cohort |
| `event_id` | Eventos, Operações, Histórias Aprovadas |
| `Mês da Aquisição` | Todas as medidas cohortadas |
| `Month PSU = Month ACQ` | Cohortadas | Mesmo Mês |
| `gmv` | GMV, Total GMV, % GMV |
| `gross_revenue` | Gross Revenue e variantes |
| `second_operation_month` | Segunda Operação (Cohorted) |
| `Diferença de Meses` | Aquisições Dinâmicas - Diferença de Meses |
| `Diferença de Dias...` | Cohort Dinâmico |

### d_calendar

| Coluna | Usada em |
|--------|----------|
| `Date Key` | Relacionamento com f_funnel_events.event_date; medidas Acumulado |
| `date_month` | Medidas Acumulado |
| `Current Month` | LineColor, Aquisições (Current Month), Aquisições Previous Month |

### d_intervalo_meses

| Coluna | Usada em |
|--------|----------|
| `Interval` | Aquisições Cohortadas - Média Móvel Últimos 6 meses |

### p_Cohort

| Coluna | Usada em |
|--------|----------|
| `SelectedValue` | Aquisições Cohortadas | Cohort Dinâmico |
| `p_Cohort` | Cohort Dinâmico Selecionado (texto) |

### p_Modo de Exibição

| Coluna | Usada em |
|--------|----------|
| `Exibição` | Aquisições Dinâmicas - Diferença de Meses, Diferença de Dias |

### NomeSemana

| Coluna | Usada em |
|--------|----------|
| `InicioNome` | DiaSemanaAjustado_Medida, Debug_Selected (d_calendar) |
| `InicioNum` | DiaSemanaAjustado_Num_Measure (d_calendar) |
| `mNomeSemana` | WeekStartDate (coluna calculada d_calendar) |

### d_last_update

| Coluna | Usada em |
|--------|----------|
| `last_update` | Refresh Date |

---

## Medidas Potencialmente Órfãs

Medidas que parecem auxiliares ou em desenvolvimento (não referenciadas por outras medidas conhecidas):

| Medida | Observação |
|--------|-----------|
| `Eventos MAXX AAAAA` | Nome incomum — possível medida de desenvolvimento |
| `p_Medida_Tentativa` | Tabela com nome que sugere experimento |
| `Debug_Selected`, `Debug_DataContext` | Medidas de debug — verificar se estão em visuais |
| `Texto Conversão PSU` | Rótulo estático — verificar se ainda está em uso |

> Recomendação: revisar se essas medidas estão referenciadas em visuais antes de remover.
