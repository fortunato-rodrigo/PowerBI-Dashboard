# Gestão de Receita — Glossário de Negócio

## Sobre este arquivo

Termos de negócio específicos do dashboard Gestão de Receita. Para termos corporativos transversais, consulte a [ontologia corporativa](../../../ontologia/GLOSSARY.md).

---

## Termos específicos deste dashboard

### Bank Take

Custo cobrado pelo banco correspondente em uma operação de câmbio — o valor que o banco parceiro retém para processar a transação.

**Atenção:** Existem **duas formas de calcular** o bank take neste dashboard:
- **`processed_operations`**: usa `cost_bank_take` direto de `gold.fact_operations` — valor por operação já calculado pelo Databricks.
- **`customer`**: aloca o bank take mensal total de `finance_cube.kpi_list` proporcionalmente ao GMV de cada operação. Os valores podem divergir.

---

### Política de Preço (`policy_label`)

Rótulo da política de precificação aplicada à operação, proveniente de `beecambio.beecambio_tbl_remittance_operation`. Indica qual regime de spread/tarifa foi aplicado (ex: política padrão, política corporativa, preço fixo).

---

### Natureza da Operação (`natureza`)

Classificação do propósito da remessa — campo `nature_operation_name` em `gold.fact_operations`, renomeado para `natureza` no modelo. Ex: Viagem, Educação, Manutenção de Pessoa, Importação.

---

### Spread Real vs. Spread Calculado

| Conceito | Descrição |
|----------|-----------|
| **`spread`** | Spread conforme registrado em `gold.fact_operations` — valor declarado no momento da operação |
| **`spread_calculado`** | `gross_revenue / gmv` — spread implícito calculado pela receita efetiva capturada |
| **`Class Spread Real`** | Compara os dois: "Spread Real Maior", "Spread Real igual" ou "Spread Real menor" |

Divergências entre spread declarado e calculado podem indicar ajustes pós-operação, descontos retroativos ou inconsistências de dados.

---

### Parceiro Maxima (`partner_name`)

Parceiro da rede Maxima associado ao cliente — agente de câmbio externo que indica ou processa operações pela Remessa Online. Proveniente de `beecambio.beecambio_maxima_partners`.

**Distinção `Escritórios`:** A coluna calculada `Escritórios` classifica parceiros em "Sim" (escritório legítimo da rede) ou "Não" (empresas com características distintas: lista hardcoded de 8 parceiros). Ver [05-fontes.md](05-fontes.md) para a lista completa.

---

### Subsegmento PF

Classificação de persona do cliente Pessoa Física com base em comportamento de uso — proveniente de `stage.dim_last_subsegments`. Exemplos de subsegmentos: High Value, Turista, Recorrente, Casual.

**Granularidade:** cliente × mês. O relacionamento com `processed_operations` é apenas por `id_customer` — ao filtrar, todas as operações do cliente são incluídas independentemente do mês do subsegmento.

---

### Simulador de Cenários

Ferramenta interativa com dois sliders que permite projetar receita hipotética:

| Parâmetro | Range | Significado |
|-----------|-------|-------------|
| **Delta Operações** | -100% a +100% | Simula variação no volume de operações |
| **Delta Spread** | -100% a +100% | Simula variação no spread médio |

Com ambos em 0%, os valores do cenário são iguais ao histórico real. Com delta positivo, projeta crescimento. Com delta negativo, projeta queda.

As medidas de cenário (`Total Gross Revenue - Cenário`, `Total operações - Cenário`, `% spread`) iteram sobre cada operação existente e aplicam os fatores multiplicadores.

---

### Faixas de Análise

| Faixa | Coluna | Descrição |
|-------|--------|-----------|
| **Ticket Range** | `Ticket Range` | 8 faixas de GMV: de 0 até +30.000 |
| **Faixa Spread** | `Faixa Spread` | 9 faixas de spread: Negativo → Acima de 1,2% |
| **Faixa perc_mensageria** | `Faixa perc_mensageria` | 7 faixas de % custo de mensageria sobre GR: 0% → Acima 90% |

---

### Clientes Negativados vs. Clientes Positivos

| Conceito | Critério |
|----------|---------|
| **Clientes negativados** | `receita_liquida < 0` na tabela `customer` (histórico acumulado negativo) |
| **Clientes positivos** | `receita_liquida > 0` na tabela `customer` |
| **Clientes positivados** | `receita_liquida > 0` E `ops_negativas > 0` — lucrativos mas com histórico misto |
| **Clientes pelo menos 1 negativa** | Ao menos uma operação com prejuízo, independente do saldo total |

**Atenção:** Estas métricas usam a tabela `customer` (histórico desde 2023-01-01, com bank take alocado). São independentes do filtro de calendário do dashboard.

---

### Moedas Agrupadas

A coluna `Moedas` agrupa as 5 principais moedas individualmente e consolida as demais em "Moeda exótica":

| Grupo | Moedas incluídas |
|-------|-----------------|
| Individual | Dólar Americano, Euro, Libra Esterlina, Peso Chileno, Peso Argentino |
| Moeda exótica | Todas as demais |

---

### Desconto Aplicado

Classifica o tipo de desconto na operação a partir da coluna `applied_discount`:

| Categoria | Critério |
|-----------|---------|
| Sem desconto | `applied_discount = "DISCOUNT NOT APPLIED"` |
| Produccine | Contém "produccine" (case insensitive) |
| Nubank | Contém "nubank" (case insensitive) |
| Com desconto | Tem desconto mas não é Produccine nem Nubank |
| Vazio | Campo em branco |

---

### Seletor de Dimensão (Dimensão 1 a 5)

O dashboard permite decompor as métricas por até 5 dimensões simultâneas. Cada seletor (Dimensão 1 até Dimensão 5) oferece as mesmas 18 opções:

`swift_remessadora`, `Tipo Lucro`, `in_or_out`, `acquisition`, `country`, `customer_type`, `natureza`, `Moedas`, `Ticket Range`, `Tarifa`, `Desconto aplicado`, `Faixa Spread`, `MID`, `Representatividade Mensagem`, `Parceiro`, `Cod. Moeda`, `Remessadora`, `Política de Preço`.

---

## Termos corporativos usados neste dashboard

Para definições completas, consulte [ontologia/GLOSSARY.md](../../../ontologia/GLOSSARY.md):

| Termo | Ver também |
|-------|-----------|
| GMV | GLOSSARY.md → GMV |
| Gross Revenue / Receita Bruta | GLOSSARY.md → Gross Revenue |
| Receita Líquida / Net Revenue | GLOSSARY.md → (a definir) |
| Spread | GLOSSARY.md → (a definir) |
| Aquisição / Recorrência | GLOSSARY.md → Aquisição |
| is_intercompany | GLOSSARY.md → (a definir) |
| is_ops_processed | GLOSSARY.md → (a definir) |
| BU (Unidade de Negócio) | GLOSSARY.md → (a definir) |

---

## Sugestões para a ontologia corporativa

Os seguintes termos foram identificados neste dashboard e ainda não constam na ontologia:

| Termo | Definição proposta | Arquivo sugerido |
|-------|-------------------|-----------------|
| Receita Líquida / Net Revenue | Receita após dedução de todos os custos (mensageria, bank take, payout a afiliados e parceiros) | GLOSSARY.md |
| Spread | Margem percentual capturada na operação de câmbio (gross_revenue / GMV) | GLOSSARY.md |
| Bank Take | Custo cobrado pelo banco correspondente na operação | GLOSSARY.md |
| Natureza da Operação | Classificação regulatória do propósito da remessa (Viagem, Educação, etc.) | GLOSSARY.md |
| Política de Preço | Regime de precificação aplicado à operação (policy_label) | GLOSSARY.md |
| Parceiro Maxima | Agente de câmbio externo que indica ou processa operações via rede Maxima | GLOSSARY.md |
| Subsegmento PF | Classificação de persona de clientes Pessoa Física por comportamento de uso | GLOSSARY.md |
| Custos operacionais diretos | Mensageria + Bank Take + Payout (afiliados + parceiros) | GLOSSARY.md |
