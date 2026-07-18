import sys

from object_detector import ObjectDetector
from database_capabilities import supports_object
from generate_liquibase_objects import generate_liquibase_objects

from generators.generate_views import generate_views
from generators.generate_functions import generate_functions
from generators.generate_procedures import generate_procedures
from generators.generate_triggers import generate_triggers
from generators.generate_events import generate_events
from generators.generate_indexes import generate_indexes
from generate_master_objects import generate_master_objects
from deploy_objects import deploy_objects
from validate_objects import validate_objects


def generate(database):

    detector = ObjectDetector(database)

    detector.detect()

    if supports_object(database, "views"):
        generate_views(database)

    if supports_object(database, "functions"):
        generate_functions(database)

    if supports_object(database, "procedures"):
        generate_procedures(database)

    if supports_object(database, "triggers"):
        generate_triggers(database)

    if supports_object(database, "events"):
        generate_events(database)

    if supports_object(database, "indexes"):
        generate_indexes(database)

    generate_liquibase_objects(database)

    generate_master_objects(database)

    deploy_objects(database)

    validate_objects(database)


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage : bootstrap_generator.py <database>")
        sys.exit(1)

    generate(sys.argv[1])