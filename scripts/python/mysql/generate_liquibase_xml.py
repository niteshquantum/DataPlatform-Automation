import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

schema_file = ROOT / "metadata" / "mysql" / "schema_registry.json"
liquibase_dir = ROOT / "liquibase" / "mysql"

liquibase_dir.mkdir(parents=True, exist_ok=True)

with open(schema_file, "r", encoding="utf-8") as f:
    schema_registry = json.load(f)

existing_files = [
    f for f in liquibase_dir.glob("*.xml")
    if f.name != "master.xml"
]

existing_tables = set()

for file in existing_files:
    try:
        content = file.read_text(encoding="utf-8")
        match = re.search(r'tableName="([^"]+)"', content)
        if match:
            existing_tables.add(match.group(1).lower())
    except:
        pass

next_number = len(existing_files) + 1

for table_name, columns in schema_registry.items():

    table_name = table_name.lower()

    change_id = f"{next_number:03d}"
    filename = f"{change_id}_create_{table_name}.xml"

    xml_path = liquibase_dir / filename

    column_xml = ""

    for col in columns:
        col = col.replace("\ufeff", "").strip()

        column_xml += f'''
        <column name="{col}" type="VARCHAR(255)"/>
'''

    xml_content = f'''<?xml version="1.0" encoding="UTF-8"?>

<databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <changeSet id="{change_id}" author="tanisha">

    <preConditions onFail="MARK_RAN">
        <not>
            <tableExists tableName="{table_name}"/>
        </not>
    </preConditions>

    <createTable tableName="{table_name}">
{column_xml}
        </createTable>

    </changeSet>

</databaseChangeLog>
'''

    with open(xml_path, "w", encoding="utf-8") as f:
        f.write(xml_content)

    print(f"Generated {filename}")

    next_number += 1
