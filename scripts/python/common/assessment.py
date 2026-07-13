"""Shared persistence and report helpers for database assessments."""

import json
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ASSESSMENT_ROOT = ROOT / "outputs" / "assessments"


def json_value(value):
    """Return a JSON-safe value without changing inventory-specific data."""
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    return value


def rows_as_dicts(cursor):
    columns = [column[0] for column in cursor.description]
    return [
        {name: json_value(value) for name, value in zip(columns, row)}
        for row in cursor.fetchall()
    ]


def write_inventory(database, inventory, rows, status="complete", detail=None):
    """Persist one portable inventory using the same layout for every engine."""
    destination = ASSESSMENT_ROOT / database / f"{inventory}.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "database_platform": database,
        "inventory": inventory,
        "status": status,
        "record_count": len(rows),
        "records": rows,
    }
    if detail:
        payload["detail"] = detail
    destination.write_text(json.dumps(payload, indent=2, default=json_value) + "\n", encoding="utf-8")
    print(f"{inventory}: {payload['record_count']} record(s) -> {destination.relative_to(ROOT)}")
    return payload


def run_selected(run_inventory, inventory_names, selected):
    """Run one inventory or every inventory without duplicating CLI behaviour."""
    names = inventory_names if selected == "all" else [selected]
    return [run_inventory(name) for name in names]
