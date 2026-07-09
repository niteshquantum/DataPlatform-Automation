"""
Shared, database-agnostic validator for deployed database objects.

Confirms that every view declared under liquibase/<db>/objects/views/*.xml
actually exists in the target database after deployment. (Functions /
Procedures / Triggers can extend the same pattern once they are in scope.)

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

# NOTE: query dialect is MySQL-specific today (only MySQL is in scope for
# this phase). PostgreSQL/MSSQL will need their own view-listing query
# when they are brought into scope - flagged, not solved here.
VIEW_LIST_QUERY = "SHOW FULL TABLES WHERE Table_type = 'VIEW'"


def _expected_view_names(db_name: str, root: Path) -> list:
    views_dir = root / "liquibase" / db_name / "objects" / "views"

    if not views_dir.is_dir():
        return []

    names = []
    for xml_file in sorted(views_dir.glob("*.xml")):
        tree = ET.parse(xml_file)
        for view_elem in tree.getroot().iter(f"{{{NS}}}createView"):
            view_name = view_elem.attrib.get("viewName")
            if view_name:
                names.append(view_name)
    return names


def validate(db_name: str) -> bool:
    root = get_project_root()
    expected = _expected_view_names(db_name, root)

    if not expected:
        print("No views declared yet. Nothing to validate.")
        return True

    # Reuse the existing per-database connection module instead of
    # duplicating connection logic here.
    sys.path.insert(0, str(root))
    db_connection = importlib.import_module(
        f"scripts.python.{db_name}.setup.db_connection"
    )

    conn = db_connection.get_connection()
    cursor = conn.cursor()
    cursor.execute(VIEW_LIST_QUERY)
    existing = {row[0] for row in cursor.fetchall()}
    cursor.close()
    conn.close()

    missing = [v for v in expected if v not in existing]

    if missing:
        print(f"VALIDATION FAILED. Missing views: {missing}")
        return False

    print(f"VALIDATION SUCCESSFUL. Views verified: {expected}")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: validate_objects.py <db_name>")
        sys.exit(1)

    ok = validate(sys.argv[1])
    sys.exit(0 if ok else 1)
