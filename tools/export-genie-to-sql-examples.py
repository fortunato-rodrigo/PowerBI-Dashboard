"""
Exporta certified questions do Genie Space para arquivos YAML em sql-examples/.

Uso:
    python tools/export-genie-to-sql-examples.py

Requer: pip install requests python-dotenv pyyaml
"""

import os
import re
import json
import requests
import yaml
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

HOST = os.getenv("DATABRICKS_HOST", "").rstrip("/")
TOKEN = os.getenv("DATABRICKS_TOKEN", "")
SPACE_ID = "01f00a7b6f251beabd6e7a0da9c67fde"

HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
BASE_URL = f"https://{HOST}/api/2.0"

DOMAIN_MAP = {
    "presignup": "marketing",
    "psu": "marketing",
    "cpp": "marketing",
    "cpa": "marketing",
    "investimento": "marketing",
    "canal": "marketing",
    "aquisic": "clientes",
    "cohort": "clientes",
    "segunda operac": "clientes",
    "cliente": "clientes",
    "gmv": "operacoes",
    "operac": "operacoes",
    "spread": "receita",
    "receita": "receita",
    "gross": "receita",
    "custo": "receita",
    "ordens": "recebimento",
    "pendente": "recebimento",
    "resgat": "recebimento",
    "pnl": "receita",
    "tesourar": "receita",
}


def infer_domain(question: str, sql: str) -> str:
    text = (question + " " + sql).lower()
    for keyword, domain in DOMAIN_MAP.items():
        if keyword in text:
            return domain
    return "outros"


def slug(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text)
    return text[:60].rstrip("-")


def get_certified_questions():
    url = f"{BASE_URL}/genie/spaces/{SPACE_ID}/certified-questions"
    resp = requests.get(url, headers=HEADERS)
    resp.raise_for_status()
    return resp.json().get("certified_questions", [])


def build_yaml(question: str, sql: str, guidance: str, index: int) -> dict:
    domain = infer_domain(question, sql)
    return {
        "question_variants": [question],
        "sql": sql.strip(),
        "tables_used": sorted(set(re.findall(r"(?:from|join)\s+([\w.]+)", sql, re.IGNORECASE))),
        "domain": domain,
        "notes": guidance.strip() if guidance else "A definir",
        "validated_by": "genie-remessagpt",
        "validated_date": "2026-05-16",
    }


def save_yaml(data: dict, domain: str, filename: str):
    out_dir = Path("sql-examples") / domain
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{filename}.yaml"
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, allow_unicode=True, sort_keys=False, default_flow_style=False)
    return out_path


def main():
    if not HOST or not TOKEN:
        print("ERRO: DATABRICKS_HOST e DATABRICKS_TOKEN precisam estar no .env")
        return

    print(f"Buscando certified questions do Genie Space {SPACE_ID}...")
    try:
        questions = get_certified_questions()
    except requests.HTTPError as e:
        print(f"ERRO na API: {e.response.status_code} -- {e.response.text}")
        return

    if not questions:
        print("Nenhuma certified question encontrada. Verifique o Space ID.")
        return

    print(f"{len(questions)} questions encontradas\n")

    for i, q in enumerate(questions, 1):
        question = q.get("question", "")
        sql = q.get("sql", "")
        guidance = q.get("usage_guidance", "") or q.get("description", "")

        if not question or not sql:
            print(f"  [{i}] Ignorado -- sem pergunta ou SQL")
            continue

        data = build_yaml(question, sql, guidance, i)
        domain = data["domain"]
        filename = slug(question) or f"query-{i:03d}"
        path = save_yaml(data, domain, filename)
        print(f"  [{i}] {domain}/{filename}.yaml")

    print(f"\nArquivos salvos em sql-examples/")
    print("Proximo passo: abra cada YAML e adicione variacoes em question_variants")


if __name__ == "__main__":
    main()
