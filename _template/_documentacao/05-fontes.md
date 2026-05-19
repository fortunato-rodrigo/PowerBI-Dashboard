# [NomeDoDashboard] — Fontes de Dados

> **Voltar pra:** [04 · Dependências](04-dependencias.md) · **Próxima:** [06 · Glossário de Negócio](06-glossario-negocio.md)

---

## ⚠️ Alertas de camada

> Esta seção deve ser preenchida com alertas se o dashboard conectar em `bronze`.
> Se não houver bronze, remover esta seção.

| Nível | Tabela | Detalhe |
|-------|--------|---------|
| ⚠️ bronze | A definir | A definir — confirmar migração para silver/gold com o time de dados |

---

## Resumo das fontes

| Tabela | Tipo de Fonte | Camada | Confiança | Alerta |
|--------|--------------|--------|-----------|--------|
| A definir | Databricks / Dataflow / DAX calculada | bronze/silver/gold/diamond | ⚠️/🟡/🟢/🔵 | — |

---

## Fonte: Databricks

**Camada:** A definir
**Endpoint:** A definir
**Protocolo:** DirectQuery / Import / Native Query

### Tabela: [nome]

**Query base (resumo):**
```sql
-- colar query ou resumo aqui
```

**Modelo DBT correspondente:**

| Campo | Valor |
|-------|-------|
| Modelo DBT | A definir |
| Documentação | Ver `dbt-metadata/[camada]_models.md` |

---

## Fonte: Power BI Dataflow

> Se este dashboard usar Dataflows, documentar aqui após rodar `/pbi-fluxo-de-dados`.

**Workspace ID:** A definir
**Tabelas originadas:** A definir

---

## Fonte: Tabelas calculadas (DAX)

| Tabela | Tipo | Propósito |
|--------|------|-----------|
| A definir | Parameter table / Calculation Group / DATATABLE | A definir |

---

## Linhagem resumida

```
[Fonte bruta]
  └─► [Camada Databricks]
        └─► [Tabela Power BI]
              └─► [Visuais do dashboard]
```

---

*Documentado por Claude Code + `/pbi-documentacao` · Remessa Online*
