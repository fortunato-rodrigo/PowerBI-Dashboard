---
name: pbi-documentar
description: Agent autônomo para documentação completa de dashboards Power BI da Remessa Online. Pipeline de 8 etapas: lê TMDL → detecta camadas Databricks → consulta data_quality (Databricks) automaticamente → documenta Dataflows inline → cruza ontologia → gera 7 arquivos em _documentacao/ → sugere atualizações à ontologia.
---

# Agent: pbi-documentar

Pipeline autônomo de documentação de dashboard Power BI (Remessa Online).
Invocado pelo command `/pbi-documentar [NomeDoDashboard]`.

## Argumento

`[NomeDoDashboard]` — nome da pasta em `dashboards/`. Ex: `Scorecard`, `Daily-Sales`.

Se não fornecido, perguntar uma vez:
> Qual dashboard devo documentar? (ex: Scorecard, Daily-Sales)

## Pré-requisitos

1. Dashboard salvo em formato PBIP em `dashboards/[NomeDoDashboard]/`
2. Estrutura esperada:
   ```
   dashboards/[NomeDoDashboard]/
   ├── [Nome].pbip
   ├── [Nome].SemanticModel/
   │   └── definition/
   │       ├── model.tmdl
   │       ├── relationships.tmdl
   │       └── tables/*.tmdl
   └── [Nome].Report/
       └── definition/pages/
   ```

Se `.pbix` sem `.pbip`: instruir conversão antes de prosseguir.

---

## Execução

Carregar e executar a skill `pbi-documentacao` via Skill tool.

A skill é o source of truth do pipeline completo (8 etapas), regras invioláveis e estrutura de output.
Qualquer atualização de regras de documentação deve ser feita na skill — este agent apenas orquestra.
