import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from database_capabilities import supports_object

from xml_generators.generate_view_xml import generate_view_xml
from xml_generators.generate_function_xml import generate_function_xml
from xml_generators.generate_procedure_xml import generate_procedure_xml
from xml_generators.generate_trigger_xml import generate_trigger_xml
from xml_generators.generate_event_xml import generate_event_xml
from xml_generators.generate_index_xml import generate_index_xml


def generate_liquibase_objects(database):

    print("----------------------------------------")
    print(f"Generating Liquibase Objects : {database}")
    print("----------------------------------------")

    if supports_object(database, "views"):
        generate_view_xml(database)

    if supports_object(database, "functions"):
        generate_function_xml(database)

    if supports_object(database, "procedures"):
        generate_procedure_xml(database)

    if supports_object(database, "triggers"):
        generate_trigger_xml(database)

    if supports_object(database, "events"):
        generate_event_xml(database)

    if supports_object(database, "indexes"):
        generate_index_xml(database)

    print("----------------------------------------")
    print("Liquibase Object Generation Completed")
    print("----------------------------------------")


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage : generate_liquibase_objects.py <database>")
        sys.exit(1)

    generate_liquibase_objects(sys.argv[1])