from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[4]

liquibase_dir = ROOT / "liquibase"
mysql_dir = liquibase_dir / "mysql"
master_xml = liquibase_dir / "master.xml"

# Namespace
NS = "http://www.liquibase.org/xml/ns/dbchangelog"
ET.register_namespace("", NS)

# Create master.xml if it doesn't exist
if not master_xml.exists():

    root = ET.Element(
        f"{{{NS}}}databaseChangeLog"
    )

    tree = ET.ElementTree(root)
    tree.write(master_xml, encoding="utf-8", xml_declaration=True)

# Load master.xml
tree = ET.parse(master_xml)
root = tree.getroot()

# Existing include files
existing_includes = set()

for elem in root.findall(f"{{{NS}}}include"):
    existing_includes.add(elem.attrib["file"])

# Scan all xml files
xml_files = sorted(mysql_dir.glob("*.xml"))

for xml_file in xml_files:

    relative_path = f"mysql/{xml_file.name}"

    if relative_path in existing_includes:
        continue

    include_elem = ET.SubElement(
        root,
        f"{{{NS}}}include"
    )

    include_elem.set("file", relative_path)

    print(f"Added {relative_path}")

# Save
tree.write(
    master_xml,
    encoding="utf-8",
    xml_declaration=True
)

print("\nmaster.xml updated successfully")