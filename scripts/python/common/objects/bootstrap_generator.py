import shutil
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
from generators.generate_materialized_views import generate_materialized_views
from generators.generate_extensions import generate_extensions
from generate_master_objects import generate_master_objects

from config_loader import get_project_root


# ============================================================
# BOOTSTRAP GENERATOR
#
# Responsibility: GENERATION ONLY.
#
# This script:
#   1. Detects available schema metadata
#   2. Generates SQL object files (generated/)
#   3. Generates Liquibase XML changesets
#   4. Generates master_objects.xml
#
# It does NOT deploy or validate.
# Deployment is handled by deploy_objects.py.
# Validation is handled by validate_objects.py.
#
# The calling BAT/Bash wrapper orchestrates the full sequence:
#   bootstrap_generator.py <database>
#       -> deploy_objects.py <database>
#       -> validate_objects.py <database>
#
# Separating generation from deployment prevents Liquibase
# from executing twice when called through the pipeline.
# ============================================================


def generate(database):

    print()
    print("=====================================")
    print(f"BOOTSTRAP GENERATOR : {database.upper()}")
    print("=====================================")
    print()

    # --------------------------------------------------------
    # PRE-GENERATION CLEANUP
    #
    # Remove stale generated files from a previous run so that
    # schema changes (table renames, additions, removals) are
    # reflected cleanly without leftover artefacts.
    # --------------------------------------------------------

    root = get_project_root()

    sql_out = root / "objects" / database / "generated"
    lq_out  = root / "liquibase" / database / "objects"
    master  = root / "liquibase" / database / "master_objects.xml"

    if sql_out.exists():
        shutil.rmtree(sql_out)

    if lq_out.exists():
        shutil.rmtree(lq_out)

    if master.exists():
        master.unlink()

    # --------------------------------------------------------
    # STEP 1 : Detect schema metadata
    # --------------------------------------------------------

    detector = ObjectDetector(database)
    detector.detect()

    # --------------------------------------------------------
    # STEP 2 : Generate SQL object files
    # --------------------------------------------------------

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

    # PostgreSQL-specific SQL generators
    if supports_object(database, "materialized_views"):
        generate_materialized_views(database)

    if supports_object(database, "extensions"):
        generate_extensions(database)

    # --------------------------------------------------------
    # STEP 3 : Generate Liquibase XML changesets
    # --------------------------------------------------------

    generate_liquibase_objects(database)

    # --------------------------------------------------------
    # STEP 4 : Generate master object changelog
    # --------------------------------------------------------

    generate_master_objects(database)

    print()
    print("=====================================")
    print("BOOTSTRAP GENERATION COMPLETE")
    print("=====================================")
    print()


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage : bootstrap_generator.py <database>")
        sys.exit(1)

    generate(sys.argv[1])