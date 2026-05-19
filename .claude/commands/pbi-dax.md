---
name: pbi-dax
description: Cria medidas DAX a partir de descrição em português. Lê o modelo real (.tmdl) para validar nomes de colunas e tabelas, sugere 3 opções de nome seguindo a convenção existente, e gera a fórmula com explicação de negócio.
---

# /pbi-dax — Criação de medidas DAX

Invoca a skill `pbi-dax-create` para criar medidas DAX a partir de descrição em PT-BR.

## Uso

```
/pbi-dax "[descrição da medida em PT-BR]"
```

Ou com contexto de dashboard:
```
/pbi-dax "[descrição]" --dashboard [NomeDoDashboard]
```

Exemplos:
```
/pbi-dax "GMV do mês atual filtrado por BU"
/pbi-dax "Receita acumulada no ano vs meta anual" --dashboard Scorecard
/pbi-dax "Taxa de conversão de PSU para aquisição no canal APP"
```

## O que este command faz

Carrega e executa a skill `pbi-dax-create`. A skill:

1. (Modo Code) Lê `.tmdl` do modelo para validar tabelas e colunas existentes
2. Analisa a descrição em PT-BR identificando: tipo de cálculo, dimensões, filtros, período
3. Gera 3 sugestões de nome seguindo a convenção do projeto (detectada no modelo)
4. Produz a fórmula DAX com boas práticas (DIVIDE, variáveis, CALCULATE correto)
5. Inclui explicação em PT-BR linha-a-linha do que a medida calcula
6. Verifica medidas similares já existentes para evitar duplicata

## Output no chat

```
📐 Medida criada: [Nome sugerido]

Sugestões de nome:
1. [Opção 1] — [justificativa]
2. [Opção 2] — [justificativa]
3. [Opção 3] — [justificativa]

DAX:
[fórmula completa]

Explicação:
[linha-a-linha em PT-BR]

⚠️ Verificar: [alertas se alguma coluna não foi encontrada no modelo]
```

## Boas práticas aplicadas automaticamente

- `DIVIDE(numerador, denominador, 0)` em vez de `/`
- Variáveis `VAR` para expressões reutilizadas
- `SUMX` vs `SUM` conforme o contexto
- `DISTINCTCOUNT` com alerta se coluna string de alta cardinalidade
- Padrões time intelligence: `DATEADD`, `TOTALYTD`, `SAMEPERIODLASTYEAR`
