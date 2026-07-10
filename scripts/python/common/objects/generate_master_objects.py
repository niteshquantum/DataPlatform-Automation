"""
Shared, database-agnostic generator for master_objects.xml.

STRICT CONTRACT (per approved architecture):
  - This script ONLY reads existing object changesets under
    liquibase/<db>/objects/{views,functions,procedures,triggers}/*.xml
  - This script ONLY writes liquibase/<db>/objects/master_objects.xml
  - It NEVER creates, edits, or deletes any individual object changeset
    file. Those files are manually authored and considered immutable.

Usage:
    python generate_master_objects.py <db_name>
    e.g. python generate_master_objects.py mysql
"""
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# scripts/python/common/objects/generate_master_objects.py
# parents[1] = scripts/python/common  (where config_loader.py lives)
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from config_loader import get_project_root  # noqa: E402

NS = "http://www.liquibase.org/xml/ns/dbchangelog"
ET.register_namespace("", NS)

# Object sub-types, in the final approved deployment order.
# (Functions / Procedures / Triggers folders may be empty today; they are
# scanned so this generator does not need to change when they are used.)
OBJECT_FOLDERS = ["views", "functions", "procedures", "triggers"]


def generate(db_name: str) -> Path:
    root_dir = get_project_root()
    objects_dir = root_dir / "liquibase" / db_name / "objects"
    master_objects_xml = objects_dir / "master_objects.xml"

    objects_dir.mkdir(parents=True, exist_ok=True)

    root = ET.Element(
        f"{{{NS}}}databaseChangeLog",
        {
            "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation":
                "http://www.liquibase.org/xml/ns/dbchangelog "
                "https://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd",
        },
    )

    for folder_name in OBJECT_FOLDERS:
        folder = objects_dir / folder_name
        if not folder.is_dir():
            continue

        # Sorted so deployment order within a folder is deterministic,
        # matching the NNN_ prefix convention already used for tables.
        for xml_file in sorted(folder.glob("*.xml")):
            relative_path = f"{folder_name}/{xml_file.name}"
            include_elem = ET.SubElement(root, f"{{{NS}}}include")
            include_elem.set("file", relative_path)
            include_elem.set("relativeToChangelogFile", "true")

    tree = ET.ElementTree(root)
    tree.write(master_objects_xml, encoding="utf-8", xml_declaration=True)

    return master_objects_xml


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: generate_master_objects.py <db_name>")
        sys.exit(1)

    output_path = generate(sys.argv[1])
    print(f"master_objects.xml regenerated: {output_path}")
