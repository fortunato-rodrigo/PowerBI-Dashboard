# 02 — Glossário de Medidas DAX: Mkt Performance

> **Gerado em:** 09/05/2026 · **Ferramenta:** `/pbi-documentacao Mkt Performance`
>
> **Legenda:** ⭐ KPI estratégico (ontologia corporativa) · ⚠️ Medida complexa (5+ funções DAX)

---

## Tabela de medidas: `# Medidas`

---

## Grupo: Performance

### ⭐ % Conversão
```dax
DIVIDE([Aquisições], [Presignups], BLANK())
```
**Negócio:** Taxa de conversão do funil: quantos dos clientes que iniciaram o cadastro (Presignup) chegaram a realizar a primeira operação (Aquisição). Indicador central de eficiência do funil de marketing.

---

### ⭐ Aquisições
```dax
CALCULATE(
    DISTINCTCOUNT(f_mkt_performance[event_id]),
    f_mkt_performance[event_type] = "ACQUISITION"
)
```
**Negócio:** Número de clientes únicos que realizaram sua **primeira operação de câmbio**. É o principal KPI de ativação de clientes novos.

---

### Clientes Únicos
```dax
COUNTA(f_mkt_performance[id_customer]) + 0
```
**Negócio:** Total de clientes (com qualquer tipo de evento registrado no período filtrado).

---

### Clientes Únicos Recorrentes
```dax
CALCULATE([Clientes Únicos], f_mkt_performance[event_type] = "OPERATION") + 0
```
**Negócio:** Clientes que realizaram operações recorrentes (não a primeira). Indica base ativa de clientes fidelizados.

---

### Eventos
```dax
DISTINCTCOUNT(f_mkt_performance[event_id])
```
**Negócio:** Contagem total de eventos únicos no modelo (qualquer tipo). Usada como base para outras medidas.

---

### ⭐ GMV
```dax
CALCULATE(
    SUM(f_mkt_performance[gmv]),
    FILTER(f_mkt_performance,
        f_mkt_performance[event_type] in {"ACQUISITION", "OPERATION"}
    )
)
```
**Negócio:** Volume bruto total transacionado em câmbio (em R$) — considera apenas Aquisições e Operações.

---

### GMV (Aquisição)
```dax
CALCULATE([GMV], f_mkt_performance[event_type] = "ACQUISITION")
```
**Negócio:** GMV gerado exclusivamente pelas primeiras operações (aquisições).

---

### GMV (Recorrência)
```dax
CALCULATE([GMV], f_mkt_performance[event_type] = "OPERATION")
```
**Negócio:** GMV gerado pelas operações recorrentes (não-aquisição).

---

### Histórias Aprovadas
```dax
CALCULATE(
    COUNTA(f_mkt_performance[event_id]),
    f_mkt_performance[event_type] = "APPROVED STORY"
) + 0
```
**Negócio:** Quantidade de histórias de conta global aprovadas no período.

---

### Histórias Criadas
```dax
CALCULATE(
    COUNTA(f_mkt_performance[event_id]),
    f_mkt_performance[event_type] = "CREATED STORY"
) + 0
```
**Negócio:** Quantidade de histórias de conta global criadas no período.

---

### ⭐ Operações
```dax
CALCULATE(
    DISTINCTCOUNT(f_mkt_performance[event_id]),
    FILTER(f_mkt_performance,
        f_mkt_performance[event_type] in {"ACQUISITION", "OPERATION"}
    )
) + 0
```
**Negócio:** Número total de operações processadas (primeira + recorrentes).

---

### ⭐ Presignups
```dax
CALCULATE(
    DISTINCTCOUNT(f_mkt_performance[id_customer]),
    f_mkt_performance[event_type] = "PRESIGNUP"
)
```
**Negócio:** Clientes únicos que iniciaram o cadastro na Remessa Online. É o topo do funil de marketing.

---

### ⭐ Receita
```dax
CALCULATE(
    SUM(f_mkt_performance[gross_revenue]),
    FILTER(f_mkt_performance,
        f_mkt_performance[event_type] IN {"ACQUISITION", "OPERATION"}
    )
)
```
**Negócio:** Receita bruta total gerada pelas operações (spread capturado). Inclui Aquisições e Recorrências.

---

### Receita (Aquisição)
```dax
CALCULATE([Receita], f_mkt_performance[event_type] = "ACQUISITION")
```
**Negócio:** Receita bruta gerada exclusivamente pelas primeiras operações.

---

### Receita (Recorrência)
```dax
CALCULATE([Receita], f_mkt_performance[event_type] = "OPERATION")
```
**Negócio:** Receita bruta gerada pelas operações recorrentes.

---

### Recorrências
```dax
CALCULATE(
    COUNTA(f_mkt_performance[event_id]),
    f_mkt_performance[event_type] = "OPERATION"
) + 0
```
**Negócio:** Total de operações recorrentes (clientes que já operaram antes).

---

### Signups
```dax
CALCULATE(
    DISTINCTCOUNT(f_mkt_performance[id_customer]),
    FILTER(f_mkt_performance, f_mkt_performance[event_type] = "SIGNUP")
)
```
**Negócio:** Clientes únicos que completaram o cadastro. Etapa intermediária do funil: PSU → SU → ACQ.

---

### ⭐ Spread
```dax
DIVIDE([Receita], [GMV], BLANK())
```
**Negócio:** Margem percentual da Remessa Online por operação (Receita ÷ GMV). Indica a eficiência de precificação.

---

### Spread (Aquisição)
```dax
DIVIDE([Receita (Aquisição)], [GMV (Aquisição)], BLANK())
```
**Negócio:** Spread das operações de aquisição.

---

### Spread (Recorrência)
```dax
DIVIDE([Receita (Recorrência)], [GMV (Recorrência)], BLANK())
```
**Negócio:** Spread das operações recorrentes.

---

### Ticket Médio (GMV)
```dax
DIVIDE([GMV], [Operações], BLANK())
```
**Negócio:** Valor médio transacionado por operação (GMV ÷ Operações).

---

### Ticket Médio (GMV - Aquisição)
```dax
DIVIDE([GMV (Aquisição)], [Aquisições], BLANK())
```
**Negócio:** Ticket médio das primeiras operações.

---

### Ticket Médio (GMV - Recorrência)
```dax
DIVIDE([GMV (Recorrência)], [Recorrências], BLANK())
```
**Negócio:** Ticket médio das operações recorrentes.

---

## Grupo: Investimento

### ⭐ Investimento
```dax
SUM(f_investimento[investimento])
```
**Negócio:** Total investido em mídia paga no período. ⚠️ Baseado em dados `bronze.paid_media_investments`.

---

### PF Investimento
```dax
CALCULATE([Investimento], d_customer_type[Customer Type] = "PF")
```
**Negócio:** Investimento em mídia atribuído ao segmento Pessoa Física.

---

### PJ Investimento
```dax
CALCULATE([Investimento], d_customer_type[Customer Type] = "PJ")
```
**Negócio:** Investimento em mídia atribuído ao segmento Pessoa Jurídica.

---

### PF Presignups / PJ Presignups
```dax
CALCULATE([Presignups], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** Presignups segmentados por tipo de cliente.

---

### PF Signups / PJ Signups
```dax
CALCULATE([Signups], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** Signups segmentados por tipo de cliente.

---

### PF Aquisições / PJ Aquisições
```dax
CALCULATE([Aquisições], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** Aquisições segmentadas por tipo de cliente.

---

### ⭐ CPA PF
```dax
DIVIDE([PF Investimento], [PF Aquisições], BLANK())
```
**Negócio:** Custo por Aquisição do segmento Pessoa Física — quanto foi investido para cada novo cliente PF.

---

### ⭐ CPA PJ
```dax
DIVIDE([PJ Investimento], [PJ Aquisições], BLANK())
```
**Negócio:** Custo por Aquisição do segmento Pessoa Jurídica.

---

### ⭐ CPP PF
```dax
DIVIDE([PF Investimento], [PF Presignups], BLANK())
```
**Negócio:** Custo por Presignup (PF) — eficiência do topo do funil para Pessoa Física.

---

### ⭐ CPP PJ
```dax
DIVIDE([PJ Investimento], [PJ Presignups], BLANK())
```
**Negócio:** Custo por Presignup (PJ) — eficiência do topo do funil para Pessoa Jurídica.

---

### PF Ticket Médio (Aquisição) / PJ Ticket Médio (Aquisição)
```dax
CALCULATE([Ticket Médio (GMV - Aquisição)], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** Ticket médio das aquisições segmentado por tipo de cliente.

---

### PF GMV (Aquisição) / PJ GMV (Aquisição)
```dax
CALCULATE([GMV (Aquisição)], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** GMV de aquisição segmentado por tipo de cliente.

---

### PF Receita (Aquisição) / PJ Receita (Aquisição)
```dax
CALCULATE([Receita (Aquisição)], f_mkt_performance[Customer Type] = "PF")  -- e "PJ"
```
**Negócio:** Receita de aquisição segmentada por tipo de cliente.

---

### Aquisições Cohortadas
A definir — leitura incompleta do arquivo. Ver source `.tmdl` para fórmula completa.

---

## Grupo: Fast Analytics

### Valor da Moeda (Max)
```dax
MAX(f_trading_quotation[trading_quotation])
```
**Negócio:** Cotação máxima da moeda no período filtrado.

---

### Valor da Moeda (Med)
```dax
MEDIAN(f_trading_quotation[trading_quotation])
```
**Negócio:** Cotação mediana da moeda no período filtrado.

---

### Valor da Moeda (Min)
```dax
MIN(f_trading_quotation[trading_quotation])
```
**Negócio:** Cotação mínima da moeda no período filtrado.

---

## Grupo: Outras Medidas

### Last Update
```dax
MAX(f_mkt_performance[last_update])
```
**Negócio:** Data e hora da última atualização dos dados de performance.

---

### ⚠️ Filter Date
```dax
VAR PrimeiraData = CALCULATE(MIN(d_calendar[Date Key]), REMOVEFILTERS(d_calendar))
VAR UltimaData = CALCULATE(MAX(d_calendar[Date Key]), REMOVEFILTERS(d_calendar))
VAR DataSelecionada = MIN(d_calendar[Date Key])
VAR FiltrarGrafico =
    IF(DataSelecionada >= PrimeiraData && DataSelecionada <= UltimaData, 1, 0)
RETURN FiltrarGrafico
```
**Negócio:** Controle de exibição de gráficos — retorna 1 quando a data está dentro do intervalo total disponível. Usada para ocultar pontos fora do range.

---

### Título
```dax
SELECTEDVALUE(p_Medidas[Parâmetro]) && " por " && SELECTEDVALUE(p_Timeframe[Timeframe])
```
**Negócio:** Gera dinamicamente o título dos visuais com base nos parâmetros selecionados pelo usuário.

---

## Grupo: Comparações — Oficial (P1 vs P2 vs P3)

Medidas para comparação entre três períodos configuráveis. O usuário define P1, P2 e P3 através dos seletores de calendário.

### ⚠️ P1, P2, P3
```dax
-- Exemplo P1:
IF(
    HASONEVALUE(t_Tabela[KPI]),
    SWITCH(
        VALUES(t_Tabela[KPI]),
        "GMV", [GMV P1],
        "Receita", [Receita P1],
        "Operações", [OPS P1],
        "Presignups", [PSU P1],
        "Signups", [SU P1],
        "Ticket Médio", [Ticket P1]
    ),
    BLANK()
)
```
**Negócio:** Medidas dinâmicas que retornam o KPI selecionado para cada período (P1=atual, P2=anterior, P3=comparativo). Usadas na página de Comparações.

---

### % P1 x P2 / % P1 x P3
```dax
DIVIDE([P1], [P2], BLANK()) - 1  -- variação percentual
```
**Negócio:** Variação percentual entre P1 e P2 (ou P3). Mostra crescimento/queda relativo.

---

### ∆ P1 x P2 / ∆ P1 x P3
```dax
[P1] - [P2]  -- variação absoluta
```
**Negócio:** Diferença absoluta entre P1 e P2 (ou P3). Mostra crescimento/queda em valores absolutos.

---

### Filtrar Zero
```dax
SWITCH(TRUE(), [P1] = 0 && [P2] = 0 && [P3] = 0, 1, 0)
```
**Negócio:** Filtra linhas onde todos os três períodos têm valor zero — evita poluição visual.

---

## Subgrupos de Comparação por KPI

Para cada KPI abaixo, existem medidas análogas: `[KPI] P1`, `[KPI] P2`, `[KPI] P3`, `[KPI] - % P1 x P2`, `[KPI] - % P1 x P3`, `[KPI] - ∆ P1 x P2`, `[KPI] - ∆ P1 x P3`.

| KPI base | Prefixo das medidas |
|----------|-------------------|
| Operações | `OPS P1/P2/P3`, `OPS - ...` |
| GMV | `GMV P1/P2/P3`, `GMV - ...` |
| Presignups | `PSU P1/P2/P3`, `PSU - ...` |
| Receita | `Receita P1/P2/P3`, `Receita - ...` |
| Signups | `SU P1/P2/P3`, `SU - ...` |
| Ticket Médio | `Ticket P1/P2/P3`, `Ticket - ...` |
| Spread | `Spread P1/P2/P3`, `Spread - ...` |
| Histórias Aprovadas | `HIS APROV P1/P2/P3`, `HIS APROV - ...` |
| Histórias Criadas | `HIS CRIADA P1/P2/P3`, `HIS CRIADA - ...` |

Todas as medidas Px usam `USERELATIONSHIP(d_calendar[Date Key], 't_Período N'[Date])` para ativar o relacionamento inativo com o calendário correspondente ao período N.

---

## Medidas de Título (Labels)

Medidas que retornam strings para exibição em visuais:

| Medida | Valor retornado |
|--------|----------------|
| `_PSU` | "Presignups" |
| `_SU` | "Signups" |
| `_GMV` | "GMV" |
| `_OPS` | "Operações" |
| `_REC` | "Receita" |
| `_SPR` | "Spread" |
| `_TCK` | "Ticket" |
| `_HIS Ap` | "Hist. Aprovadas" |
| `_HIS Cr` | "Hist. Criadas" |
