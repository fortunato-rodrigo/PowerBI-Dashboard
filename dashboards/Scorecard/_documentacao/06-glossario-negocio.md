# Scorecard - Business Performance — Glossário de Negócio

> **Voltar pra:** [05 · Fontes](05-fontes.md)
>
> Este glossário lista os termos de negócio **específicos deste dashboard**.
> Para o glossário corporativo completo e canônico, consulte [`ontologia/GLOSSARY.md`](../../ontologia/GLOSSARY.md).

---

## KPIs principais do Scorecard ⭐

| Termo | Definição de negócio | Medida DAX | Camada Databricks |
|-------|---------------------|------------|-------------------|
| **GMV** | Volume total transacionado em câmbio — soma do valor bruto de todas as operações processadas. Métrica de escala do negócio. | `GMV` | `gold.fact_operations` |
| **Gross Revenue** ⭐ | Receita bruta — valor total recebido pelo cliente (GMV) descontado o valor enviado ao beneficiário. Representa o spread capturado. | `Gross Revenue` | `gold.fact_operations` |
| **Gross Profit** ⭐ | Lucro bruto — Gross Revenue menos custos operacionais diretos (mensagem, bank take, payout de afiliado). | `Gross Profit` | `gold.fact_operations` |
| **Operations** | Número de operações de câmbio processadas no período. Métrica de volume operacional. | `Operations` | `gold.fact_operations` |
| **Spread** | Margem percentual capturada por operação — diferença entre taxa cobrada ao cliente e taxa de mercado. | `Spread` | `gold.fact_operations` |
| **Customers** | Número de clientes únicos que realizaram ao menos uma operação no período. | `Customers` | `gold.fact_operations` |

---

## Termos operacionais

| Termo | Definição |
|-------|-----------|
| **Operação de câmbio** | Transação de envio ou conversão de moeda estrangeira processada pela Remessa Online. |
| **BU (Business Unit)** | Unidade de negócio responsável pela operação. Identifica qual linha de produto originou a transação. |
| **Business Type** | Classificação do tipo de negócio (ex: B2C, B2B). |
| **Customer Type** | Segmentação do cliente (ex: recorrente, novo). |
| **Event Type** | Tipo de evento que originou a operação (ex: remessa, pagamento). |
| **Segment** | Segmento operacional da transação — dimensão de análise transversal. |
| **Processing Date** | Data em que a operação foi processada no sistema. Chave de relacionamento com `d_calendar`. |
| **is_intercompany** | Flag que indica transações entre empresas do grupo. O Scorecard **exclui** estas transações (`is_intercompany = false`). |
| **is_ops_processed** | Flag que indica operações efetivamente processadas. O Scorecard considera apenas processadas (`is_ops_processed = true`). |

---

## Termos de comparação temporal

O Scorecard usa um **Calculation Group** (`Month over month`) para comparações temporais. Os conceitos abaixo são controlados pelo parâmetro `p_timeframe`.

| Termo | Definição | Seletor |
|-------|-----------|---------|
| **Realizado** | Valor do período atual selecionado (dia, mês ou ano). | `p_timeframe` |
| **Anterior** | Valor do mesmo período no ciclo anterior (dia anterior, mês anterior, ano anterior). | `p_timeframe` |
| **Growth** | Variação percentual (%) entre Realizado e Anterior. | Calculado automaticamente |
| **MTD (Month-to-Date)** | Acumulado do mês corrente até a data de referência. | `p_timeframe` |
| **MoM (Month-over-Month)** | Comparação mês a mês — mês atual vs. mês anterior. | Calculation Group |
| **YoY (Year-over-Year)** | Comparação ano a ano — período atual vs. mesmo período do ano anterior. | Calculation Group |

---

## Termos técnicos do modelo

| Termo | Definição |
|-------|-----------|
| **Calculation Group** | Recurso DAX que define variações de cálculo (Realizado, Anterior, Growth) aplicadas dinamicamente a qualquer medida base. Implementado na tabela `Month over month`. |
| **Parameter Table** | Tabela DAX sem dados reais — usada como slicer para controlar comportamento do relatório (ex: `p_timeframe`, `p_dimension`). |
| **Native Query** | Consulta SQL enviada diretamente ao Databricks, sem tradução pelo Power Query. Usada em `f_operations` para maior controle e performance. |
| **Total Cost** | Soma dos custos operacionais diretos: custo de mensagem + bank take + payout de afiliado. |
| **Bank Take** | Custo cobrado pelo banco parceiro por operação processada. |
| **Payout** | Valor pago a afiliados/parceiros por operações originadas por eles. |

---

## Links úteis

- [Ontologia corporativa completa](../../ontologia/GLOSSARY.md)
- [KPIs estratégicos com owners e metas](../../ontologia/KPIS.md)
- [Mapeamento termo → DAX → Databricks](../../ontologia/MAPPING.md)
- [Modelos DBT — Gold](../../dbt-metadata/gold_models.md)

---

*Documentado por Claude Code + `/pbi-documentacao` · Remessa Online*
