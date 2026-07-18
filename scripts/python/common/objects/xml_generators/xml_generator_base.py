from pathlib import Path

from config_loader import get_project_root
from template_loader import load_liquibase_template


class XMLGeneratorBase:

    def __init__(self, database, object_type):

        self.database = database

        self.object_type = object_type

        self.project_root = get_project_root()

        self.sql_folder = (
            self.project_root
            / "objects"
            / database
            / "generated"
            / object_type
        )

        self.xml_folder = (
            self.project_root
            / "liquibase"
            / database
            / "objects"
            / "generated"
            / object_type
        )

        self.xml_folder.mkdir(
            parents=True,
            exist_ok=True
        )

        self.template = load_liquibase_template(
            database,
            object_type
        )