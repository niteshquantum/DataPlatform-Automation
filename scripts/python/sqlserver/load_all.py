import sys
import logging

from create_database import create_database
from create_tables import create_tables
from generate_dataset import generate_datasets
from load_data import load_data

# ============================================================
# Logging Configuration
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

LOGGER = logging.getLogger(__name__)

# ============================================================
# Workflow Execution
# ============================================================

def execute_step(step_name, step_function):
    """
    Execute workflow step and stop on failure.
    """

    LOGGER.info(
        "=================================================="
    )

    LOGGER.info(
        "STARTING STEP: %s",
        step_name
    )

    LOGGER.info(
        "=================================================="
    )

    result = step_function()

    if not result:

        LOGGER.error(
            "STEP FAILED: %s",
            step_name
        )

        return False

    LOGGER.info(
        "STEP COMPLETED: %s",
        step_name
    )

    return True


# ============================================================
# Main Workflow
# ============================================================

def run_workflow():
    """
    Execute SQL Server setup workflow.
    """

    workflow = [
        (
            "Create Database",
            create_database
        ),
        (
            "Create Tables",
            create_tables
        ),
        (
            "Generate Datasets",
            generate_datasets
        ),
        (
            "Load Data",
            load_data
        )
    ]

    for step_name, step_function in workflow:

        if not execute_step(
            step_name,
            step_function
        ):
            return False

    LOGGER.info(
        "=================================================="
    )

    LOGGER.info(
        "SQL SERVER LOAD WORKFLOW COMPLETED SUCCESSFULLY"
    )

    LOGGER.info(
        "=================================================="
    )

    return True


# ============================================================
# Main
# ============================================================

def main():

    try:

        LOGGER.info(
            "Starting SQL Server load workflow"
        )

        if run_workflow():

            LOGGER.info(
                "Workflow completed successfully"
            )

            sys.exit(0)

        LOGGER.error(
            "Workflow failed"
        )

        sys.exit(1)

    except Exception as exc:

        LOGGER.exception(
            "Unexpected error: %s",
            exc
        )

        sys.exit(1)


if __name__ == "__main__":
    main()