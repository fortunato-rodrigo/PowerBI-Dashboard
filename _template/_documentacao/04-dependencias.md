# [NomeDoDashboard] — Dependências entre Medidas

> **Voltar pra:** [03 · Relacionamentos](03-relacionamentos.md) · **Próxima:** [05 · Fontes](05-fontes.md)

---

## Como ler este arquivo

- **Árvore de dependência:** mostra de quais outras medidas/colunas cada medida depende
- **Referência reversa:** mostra quais medidas usam uma medida específica
- Medidas base (sem dependências de outras medidas) são raízes da árvore

---

## Árvore de dependência

```
[MedidaBase]  (não depende de nada — usa colunas diretamente)
├── [MedidaFilha1]  (usa MedidaBase)
│   └── [MedidaNeta1]  (usa MedidaFilha1)
└── [MedidaFilha2]  (usa MedidaBase)
```

---

## Referência reversa — quem usa quem

| Medida | É usada por |
|--------|-------------|
| A definir | A definir |

---

## Medidas órfãs (sem uso identificado)

> Medidas que não aparecem em nenhuma outra medida nem em visuais conhecidos.
> Podem ser candidatas a limpeza — confirmar com o owner antes de remover.

| Medida | Última modificação | Recomendação |
|--------|-------------------|--------------|
| A definir | A definir | Verificar com owner |

---

*Documentado por Claude Code + `/pbi-documentacao` · Remessa Online*
