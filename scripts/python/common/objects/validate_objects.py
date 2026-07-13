"""
Shared, database-agnostic validator for deployed database objects.

Confirms that every object declared under liquibase/<db>/objects exists in
the target database after deployment.

Usage:
    python validate_objects.py <db_name>
    e.g. python validate_objects.py mysql
"""
import importlib
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# scripts/python/common/objects/validate_objects.py
# parents[1] = scripts/python/common (where config_loader.py lives)
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from config_loader import get_project_root  # noqa: E402

NS = "http://www.liquibase.org/xml/ns/dbchangelog"

OBJECT_QUERIES = {
    "mysql": {
        "views": """
            SELECT table_name
            FROM information_schema.views
            WHERE table_schema = DATABASE()
        """,
        "functions": """
            SELECT routine_name
            FROM information_schema.routines
            WHERE routine_schema = DATABASE()
              AND routine_type = 'FUNCTION'
        """,
        "procedures": """
            SELECT routine_name
            FROM information_schema.routines
            WHERE routine_schema = DATABASE()
              AND routine_type = 'PROCEDURE'
        """,
        "triggers": """
            SELECT trigger_name
            FROM information_schema.triggers
            WHERE trigger_schema = DATABASE()
        """,
    },
    "postgresql": {
        "views": """
            SELECT table_name
            FROM information_schema.views
            WHERE table_schema = 'public'
        """,
        "functions": """
            SELECT routine_name
            FROM information_schema.routines
            WHERE specific_schema = 'public'
              AND routine_type = 'FUNCTION'
        """,
        "procedures": """
            SELECT routine_name
            FROM information_schema.routines
            WHERE specific_schema = 'public'
              AND routine_type = 'PROCEDURE'
        """,
        "triggers": """
            SELECT trigger_name
            FROM information_schema.triggers
            WHERE trigger_schema = 'public'
        """,
    },
    "mssql": {
        "views": """
            SELECT name
            FROM sys.views
        """,
        "functions": """
            SELECT name
            FROM sys.objects
            WHERE type IN ('FN', 'IF', 'TF', 'FS', 'FT')
        """,
        "procedures": """
            SELECT name
            FROM sys.procedures
        """,
        "triggers": """
            SELECT name
            FROM sys.triggers
        """,
    },
}


def _expected_names(db_name: str, root: Path) -> dict:
    objects_dir = root / "liquibase" / db_name / "objects"
    expected = {
        "views": [],
        "functions": [],
        "procedures": [],
        "triggers": [],
    }

    view_dir = objects_dir / "views"
    if view_dir.is_dir():
        for xml_file in sorted(view_dir.glob("*.xml")):
            tree = ET.parse(xml_file)
            for view_elem in tree.getroot().iter(f"{{{NS}}}createView"):
                view_name = view_elem.attrib.get("viewName")
                if view_name:
                    expected["views"].append(view_name)

    sql_patterns = {
        "functions": "CREATE FUNCTION ",
        "procedures": "CREATE PROCEDURE ",
        "triggers": "CREATE TRIGGER ",
    }

    for object_type, prefix in sql_patterns.items():
        object_dir = objects_dir / object_type
        if not object_dir.is_dir():
            continue

        for xml_file in sorted(object_dir.glob("*.xml")):
            tree = ET.parse(xml_file)
            for sql_elem in tree.getroot().iter(f"{{{NS}}}sql"):
                sql_text = " ".join((sql_elem.text or "").split())
                upper_sql = sql_text.upper()
                start = upper_sql.find(prefix)
                if start == -1:
                    continue
                name_text = sql_text[start + len(prefix):].strip()
                if object_type == "triggers":
                    name = name_text.split(None, 1)[0]
                else:
                    name = name_text.split("(", 1)[0].strip()
                if name:
                    normalized = name.strip("`\"")
                    if "." in normalized:
                        normalized = normalized.rsplit(".", 1)[1].strip("`\"")
                    expected[object_type].append(normalized)

    return expected


def validate(db_name: str) -> bool:
    root = get_project_root()
    expected = _expected_names(db_name, root)

    if not any(expected.values()):
        print("No objects declared yet. Nothing to validate.")
        return True

    # Reuse the existing per-database connection module instead of
    # duplicating connection logic here.
    sys.path.insert(0, str(root))
    db_connection = importlib.import_module(
        f"scripts.python.{db_name}.setup.db_connection"
    )

    if db_name not in OBJECT_QUERIES:
        raise ValueError(
            f"No object validation query mapping for '{db_name}'. "
            f"Supported: {list(OBJECT_QUERIES)}"
        )

    conn = db_connection.get_connection()
    cursor = conn.cursor()
    missing = {}

    for object_type, query in OBJECT_QUERIES[db_name].items():
        cursor.execute(query)
        existing = {row[0] for row in cursor.fetchall()}
        missing_names = [
            name for name in expected[object_type]
            if name not in existing
        ]
        if missing_names:
            missing[object_type] = missing_names

    cursor.close()
    conn.close()

    if missing:
        print(f"VALIDATION FAILED. Missing objects: {missing}")
        return False

    print(f"VALIDATION SUCCESSFUL. Objects verified: {expected}")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: validate_objects.py <db_name>")
        sys.exit(1)

    ok = validate(sys.argv[1])
    sys.exit(0 if ok else 1)
