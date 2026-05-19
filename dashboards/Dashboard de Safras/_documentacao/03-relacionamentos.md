# Dashboard de Safras — Relacionamentos do Modelo

**Total:** 6 relacionamentos · todos do tipo Many-to-One · direção única

---

## Diagrama ASCII

```
                                         d_calendar
                                        ┌──────────────────┐
                                        │ 'Date Key' (PK)  │
                                        └────────┬─────────┘
                                                 │ (1)
                                                 │ event_date
    d_canal          d_medium         f_funnel_events          d_source
   ┌─────────┐      ┌──────────┐     ┌─────────────────┐      ┌──────────┐
   │canal(PK)│◄─────┤canal_lc  │     │   event_date    │      │source(PK)│
   └─────────┘(1)  (*)│ medium_lc│◄───┤   canal_lc      │────►│(1)source │
                   │  └──────────┘(*)│   medium_lc     │(*)  └──────────┘
                   │ medium(PK) (1)  │   source_lc     │
                   └─────────────────│   mkt_campaign_lc│
                                     │   ad_group_lc   │
                                     └────────┬────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              │                               │
                         d_mkt_campaign                  d_adgroup
                        ┌──────────────┐                ┌──────────────┐
                        │ Campaign(PK) │                │ ad_group(PK) │
                        └──────────────┘                └──────────────┘
                              (1)                             (1)
```

**Legenda:** (1) = lado "um" · (*) = lado "muitos" · ◄─ = direção do filtro

---

## Tabela de Relacionamentos

| # | De (tabela.coluna) | Para (tabela.coluna) | Cardinalidade | Direção | Ativo |
|---|-------------------|----------------------|---------------|---------|-------|
| 1 | `f_funnel_events.event_date` | `d_calendar.'Date Key'` | N:1 | Única (→ fato) | Sim |
| 2 | `f_funnel_events.canal_lc` | `d_canal.canal` | N:1 | Única (→ fato) | Sim |
| 3 | `f_funnel_events.medium_lc` | `d_medium.medium` | N:1 | Única (→ fato) | Sim |
| 4 | `f_funnel_events.source_lc` | `d_source.source` | N:1 | Única (→ fato) | Sim |
| 5 | `f_funnel_events.mkt_campaign_lc` | `d_mkt_campaign.Campaign` | N:1 | Única (→ fato) | Sim |
| 6 | `f_funnel_events.ad_group_lc` | `d_adgroup.ad_group` | N:1 | Única (→ fato) | Sim |

---

## Observações

- **Modelo em estrela simples:** Todos os relacionamentos partem da tabela fato `f_funnel_events` para suas dimensões. Não há relacionamentos entre dimensões.
- **Tabelas sem relacionamento:** `d_last_update`, `NomeSemana`, `d_intervalo_meses`, `t_Cohort`, `# Medidas` e todas as tabelas `p_*` não têm relacionamentos no modelo — são usadas via `SELECTEDVALUE()` ou `USERELATIONSHIP()` dentro das medidas DAX.
- **Chave de data:** O relacionamento de data usa `event_date` (data de ocorrência do evento) — não existe relacionamento separado para `signup_date` ou `acquisition_date`, portanto filtros de calendário atuam sempre sobre a data do evento.
