# 03 — Relacionamentos: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`

---

## Diagrama ASCII

```
                          ┌───────────────┐
                          │   d_calendar  │
                          │  [Date Key]   │
                          └───────┬───────┘
                                  │
          ┌───────────────────────┼──────────────────────────┐
          │                       │                          │
   [event_date]              [date_nao_usar]           [date]
          │  (ativo)              │ (ativo)              │ (ativo)
          │                       │                          │
┌─────────┴──────────┐   ┌───────┴──────────┐   ┌──────────┴──────────┐
│  f_mkt_performance │   │   f_investimento │   │ f_trading_quotation │
│                    │   │                  │   └─────────────────────┘
│   [canal_lc]───────┼──→│ [canal_pmkt]─────┼──→ d_canal [canal]
│   [medium_lc]──────┼──→│ [medium_pmkt]────┼──→ d_medium [medium]
│   [source_lc]──────┼──→│ [source_pmkt]────┼──→ d_source [source]
│   [mkt_campaign_lc]┼──→│ [mkt_campaign_pm]┼──→ d_mkt_campaign [Campaign]
│   [ad_group_lc]────┼──→│ [ad_group]───────┼──→ d_adgroup [ad_group]
│   [Customer Type]──┼──→│ [customer_type]──┼──→ d_customer_type [Customer Type]
│   [canal_fc]───────┼──→│                  │    d_canal_fc [canal]
│   [mkt_campaign_fc]┼──→│                  │    d_mkt_campaign_fc [Campaign]
│   [primeira_perg.] ┼──→│                  │    d_qualificacao_1
│   [segunda_perg.]  ┼──→│                  │    d_qualificacao_2
│   [psu_date]───────┼─ ─│─(inativo)────────┼─── d_calendar [Date Key]
└────────────────────┘   └──────────────────┘

               ┌─────────────────────┐
               │ f_attribution_window│
               │   [event_date]──────┼──→ d_calendar [Date Key] (ativo)
               │   [canal]───────────┼──→ d_canal [canal]
               │   [medium]──────────┼──→ d_medium [medium]
               │   [source]──────────┼──→ d_source [source]
               │   [mkt_campaign]────┼──→ d_mkt_campaign [Campaign]
               │   [ad_group_lc]─────┼──→ d_adgroup [ad_group]
               │   [customer_type]───┼──→ d_customer_type [Customer Type]
               │   [canal]───────────┼──→ d_canal_fc [canal]
               └─────────────────────┘

  Períodos de comparação (relacionamentos inativos — usados via USERELATIONSHIP):
  t_Período 1 [Date] ─ ─ ─ d_calendar [Date Key]
  t_Período 2 [Date] ─ ─ ─ d_calendar [Date Key]
  t_Período 3 [Date] ─ ─ ─ d_calendar [Date Key]
```

---

## Tabela de Relacionamentos

| # | De (Tabela) | De (Coluna) | Para (Tabela) | Para (Coluna) | Cardinalidade | Direção do Filtro | Ativo |
|---|-------------|-------------|---------------|---------------|---------------|-------------------|-------|
| 1 | f_mkt_performance | canal_lc | d_canal | canal | Muitos→Um | Único | Sim |
| 2 | f_mkt_performance | medium_lc | d_medium | medium | Muitos→Um | Único | Sim |
| 3 | f_mkt_performance | source_lc | d_source | source | Muitos→Um | Único | Sim |
| 4 | f_mkt_performance | mkt_campaign_lc | d_mkt_campaign | Campaign | Muitos→Um | Único | Sim |
| 5 | f_mkt_performance | ad_group_lc | d_adgroup | ad_group | Muitos→Um | Único | Sim |
| 6 | f_mkt_performance | Customer Type | d_customer_type | Customer Type | Muitos→Um | Único | Sim |
| 7 | f_mkt_performance | canal_fc | d_canal_fc | canal | Muitos→Um | Único | Sim |
| 8 | f_mkt_performance | mkt_campaign_fc | d_mkt_campaign_fc | Campaign | Muitos→Um | Único | Sim |
| 9 | f_mkt_performance | primeira_pergunta | d_qualificacao_1 | primeira_pergunta | Muitos→Um | Único | Sim |
| 10 | f_mkt_performance | segunda_pergunta | d_qualificacao_2 | segunda_pergunta | Muitos→Um | Único | Sim |
| 11 | f_mkt_performance | event_date | d_calendar | Date Key | Muitos→Um | Único | Sim |
| 12 | f_mkt_performance | psu_date | d_calendar | Date Key | Muitos→Um | Único | **Não** |
| 13 | f_investimento | channel_pmkt | d_canal | canal | Muitos→Um | Único | Sim |
| 14 | f_investimento | medium_pmkt | d_medium | medium | Muitos→Um | Único | Sim |
| 15 | f_investimento | source_pmkt | d_source | source | Muitos→Um | Único | Sim |
| 16 | f_investimento | mkt_campaign_pmkt | d_mkt_campaign | Campaign | Muitos→Um | Único | Sim |
| 17 | f_investimento | ad_group | d_adgroup | ad_group | Muitos→Um | Único | Sim |
| 18 | f_investimento | customer_type | d_customer_type | Customer Type | Muitos→Um | Único | Sim |
| 19 | f_investimento | date_nao_usar | d_calendar | Date Key | Muitos→Um | Único | Sim |
| 20 | f_attribution_window | canal | d_canal | canal | Muitos→Um | Único | Sim |
| 21 | f_attribution_window | medium | d_medium | medium | Muitos→Um | Único | Sim |
| 22 | f_attribution_window | source | d_source | source | Muitos→Um | Único | Sim |
| 23 | f_attribution_window | mkt_campaign | d_mkt_campaign | Campaign | Muitos→Um | Único | Sim |
| 24 | f_attribution_window | ad_group_lc | d_adgroup | ad_group | Muitos→Um | Único | Sim |
| 25 | f_attribution_window | customer_type | d_customer_type | Customer Type | Muitos→Um | Único | Sim |
| 26 | f_attribution_window | event_date | d_calendar | Date Key | Muitos→Um | Único | Sim |
| 27 | f_attribution_window | canal | d_canal_fc | canal | Muitos→Um | Único | Sim |
| 28 | f_trading_quotation | date | d_calendar | Date Key | Muitos→Um | Único | Sim |
| 29 | t_Período 1 | Date | d_calendar | Date Key | Um→Muitos | Ambas | **Não** |
| 30 | t_Período 2 | Date | d_calendar | Date Key | Um→Muitos | Ambas | **Não** |
| 31 | t_Período 3 | Date | d_calendar | Date Key | Um→Muitos | Ambas | **Não** |

**Total de relacionamentos ativos: 27 | Inativos: 4**

---

## Notas sobre relacionamentos inativos

- **f_mkt_performance[psu_date] → d_calendar[Date Key]:** Permite filtrar pelo calendário pela data de Presignup em vez da data do evento. Ativado via `USERELATIONSHIP` nas medidas específicas de PSU.
- **t_Período 1/2/3[Date] → d_calendar[Date Key]:** Relacionamentos de "Many to One" invertidos (One side = Período) com filtro bidirecional. Ativados via `USERELATIONSHIP` nas medidas de comparação temporal (P1, P2, P3). Permitem isolar cada período de análise sem interferência de filtros cruzados.
