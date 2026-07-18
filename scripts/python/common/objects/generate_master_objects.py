import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from config_loader import get_project_root
from database_capabilities import get_supported_objects
from templates.mysql.liquibase_master_template import (
    MASTER_HEADER,
    MASTER_INCLUDE,
    MASTER_FOOTER
)


def generate_master_objects(database):

    root = get_project_root()

    object_root = (
        root
        / "liquibase"
        / database
        / "objects"
        / "generated"
    )

    master_file = (
        root
        / "liquibase"
        / database
        / "master_objects.xml"
    )

    xml = MASTER_HEADER

    for object_type in get_supported_objects(database):

        folder = object_root / object_type

        if not folder.exists():
            continue

        files = sorted(folder.glob("*.xml"))

        for file in files:

            include = (
                f"objects/generated/"
                f"{object_type}/"
                f"{file.name}"
            )

            xml += MASTER_INCLUDE.format(
                file=include
            )

    xml += MASTER_FOOTER

    with open(
        master_file,
        "w",
        encoding="utf-8"
    ) as file:

        file.write(xml)

    print(
        f"Generated : {master_file.name}"
    )


if __name__ == "__main__":

    if len(sys.argv) != 2:

        print(
            "Usage : generate_master_objects.py <database>"
        )

        sys.exit(1)

    generate_master_objects(
        sys.argv[1]
    )