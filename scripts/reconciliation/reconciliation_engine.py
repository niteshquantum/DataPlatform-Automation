"""
Reconciliation Framework - Main Entry Point

Compares expected incoming dataset metrics from profiling.json
with actual loaded database tables or MongoDB collections.

Supports:
    - MySQL
    - PostgreSQL
    - MSSQL
    - MongoDB

Generates:
    metadata/reconciliation/<database>/reconciliation.json
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Tuple


# ============================================================
# PROJECT ROOT AND IMPORT SETUP
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


from scripts.profiling.data_profiler import read_dataset

from scripts.reconciliation.reconciliation_metrics import (
    detect_reconciliation_issues,
    determine_reconciliation_status,
    reconcile_column_counts,
    reconcile_row_counts,
    summarize_reconciliation_issues,
)


# ============================================================
# CONSTANTS
# ============================================================

SUPPORTED_DATABASES = (
    "mysql",
    "postgresql",
    "mssql",
    "mongodb",
)

SYSTEM_TABLES = {
    "databasechangelog",
    "databasechangeloglock",
}


# ============================================================
# PROFILING INPUT
# ============================================================

def load_profiling_results(
    database: str,
) -> Dict[str, Any]:
    """
    Load profiling.json for the selected database.
    """

    profiling_file = (
        PROJECT_ROOT
        / "metadata"
        / "profiling"
        / database
        / "profiling.json"
    )

    if not profiling_file.exists():
        raise FileNotFoundError(
            f"Profiling output not found: {profiling_file}"
        )

    with profiling_file.open(
        "r",
        encoding="utf-8",
    ) as file:
        return json.load(file)


# ============================================================
# DATASET NAME HANDLING
# ============================================================

def get_dataset_name(
    file_name: str,
) -> str:
    """
    Convert incoming filename into expected target object name.

    Example:
        products.csv -> products
        cart_events.json -> cart_events
    """

    return Path(file_name).stem


# ============================================================
# EXPECTED DATASET METRICS
# ============================================================

def build_expected_datasets(
    profiling_output: Dict[str, Any],
) -> Dict[str, Dict[str, Any]]:
    """
    Build expected dataset information from profiling results.
    """

    expected_datasets = {}

    for dataset in profiling_output.get(
        "datasets",
        [],
    ):

        dataset_name = get_dataset_name(
            dataset["file_name"]
        )

        expected_datasets[
            dataset_name.lower()
        ] = {
            "dataset_name": dataset_name,
            "source_file": dataset["file_name"],
            "expected_rows": dataset[
                "basic_metrics"
            ]["total_rows"],
            "expected_columns": dataset[
                "basic_metrics"
            ]["total_columns"],
        }

    return expected_datasets


# ============================================================
# MYSQL TARGET METRICS
# ============================================================

def get_mysql_target_metrics() -> Dict[str, Dict[str, Any]]:
    """
    Read actual table row and column counts from MySQL.
    """

    import mysql.connector

    from scripts.python.common.config_loader import (
        load_database_config,
    )

    config = load_database_config("mysql")

    connection = mysql.connector.connect(
        host=config["MYSQL_HOST"],
        port=int(config["MYSQL_PORT"]),
        user=config["MYSQL_USER"],
        password=config["MYSQL_PASSWORD"],
        database=config["MYSQL_DB"],
    )

    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = DATABASE()
            """
        )

        tables = [
            row[0]
            for row in cursor.fetchall()
        ]

        target_metrics = {}

        for table_name in tables:

            if table_name.lower() in SYSTEM_TABLES:
                continue

            cursor.execute(
                f"SELECT COUNT(*) FROM `{table_name}`"
            )

            row_count = int(
                cursor.fetchone()[0]
            )

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name = %s
                """,
                (table_name,),
            )

            column_count = int(
                cursor.fetchone()[0]
            )

            target_metrics[
                table_name.lower()
            ] = {
                "target_name": table_name,
                "actual_rows": row_count,
                "actual_columns": column_count,
            }

        return target_metrics

    finally:

        cursor.close()
        connection.close()


# ============================================================
# POSTGRESQL TARGET METRICS
# ============================================================

def get_postgresql_target_metrics() -> Dict[str, Dict[str, Any]]:
    """
    Read actual table row and column counts from PostgreSQL.
    """

    import psycopg2

    from scripts.python.common.config_loader import (
        load_database_config,
    )

    config = load_database_config(
        "postgresql"
    )

    connection = psycopg2.connect(
        host=config["POSTGRESQL_HOST"],
        port=int(config["POSTGRESQL_PORT"]),
        user=config["POSTGRESQL_USER"],
        password=config["POSTGRESQL_PASSWORD"],
        dbname=config["POSTGRESQL_DB"],
    )

    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
            """
        )

        tables = [
            row[0]
            for row in cursor.fetchall()
        ]

        target_metrics = {}

        for table_name in tables:

            if table_name.lower() in SYSTEM_TABLES:
                continue

            safe_table_name = (
                table_name.replace('"', '""')
            )

            cursor.execute(
                f'SELECT COUNT(*) '
                f'FROM "{safe_table_name}"'
            )

            row_count = int(
                cursor.fetchone()[0]
            )

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = %s
                """,
                (table_name,),
            )

            column_count = int(
                cursor.fetchone()[0]
            )

            target_metrics[
                table_name.lower()
            ] = {
                "target_name": table_name,
                "actual_rows": row_count,
                "actual_columns": column_count,
            }

        return target_metrics

    finally:

        cursor.close()
        connection.close()


# ============================================================
# MSSQL TARGET METRICS
# ============================================================

def get_mssql_target_metrics() -> Dict[str, Dict[str, Any]]:
    """
    Read actual table row and column counts from MSSQL.
    """

    from scripts.python.mssql.setup.db_connection import (
        get_connection,
    )

    connection = get_connection()

    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_CATALOG = DB_NAME()
              AND TABLE_TYPE = 'BASE TABLE'
            """
        )

        tables = [
            row[0]
            for row in cursor.fetchall()
        ]

        target_metrics = {}

        for table_name in tables:

            if table_name.lower() in SYSTEM_TABLES:
                continue

            safe_table_name = (
                table_name.replace("]", "]]")
            )

            cursor.execute(
                f"SELECT COUNT(*) "
                f"FROM [{safe_table_name}]"
            )

            row_count = int(
                cursor.fetchone()[0]
            )

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_CATALOG = DB_NAME()
                  AND TABLE_NAME = ?
                """,
                table_name,
            )

            column_count = int(
                cursor.fetchone()[0]
            )

            target_metrics[
                table_name.lower()
            ] = {
                "target_name": table_name,
                "actual_rows": row_count,
                "actual_columns": column_count,
            }

        return target_metrics

    finally:

        cursor.close()
        connection.close()


# ============================================================
# MONGODB TARGET METRICS
# ============================================================

def get_mongodb_target_metrics() -> Dict[str, Dict[str, Any]]:
    """
    Read actual collection row/document counts and field counts
    from MongoDB.

    Column count is determined using the union of top-level
    fields found across collection documents.
    """

    from scripts.python.mongodb.setup.db_connection import (
        get_db,
    )

    database = get_db()

    collections = (
        database.list_collection_names()
    )

    target_metrics = {}

    for collection_name in collections:

        collection = database[
            collection_name
        ]

        document_count = int(
            collection.count_documents({})
        )

        fields = set()

        for document in collection.find(
            {},
            projection=None,
        ):

            fields.update(
                key
                for key in document.keys()
                if key != "_id"
            )

        target_metrics[
            collection_name.lower()
        ] = {
            "target_name": collection_name,
            "actual_rows": document_count,
            "actual_columns": len(fields),
        }

    return target_metrics


# ============================================================
# TARGET METRICS ROUTER
# ============================================================

def get_target_metrics(
    database: str,
) -> Dict[str, Dict[str, Any]]:
    """
    Route target metric collection to selected database.
    """

    if database == "mysql":
        return get_mysql_target_metrics()

    if database == "postgresql":
        return get_postgresql_target_metrics()

    if database == "mssql":
        return get_mssql_target_metrics()

    if database == "mongodb":
        return get_mongodb_target_metrics()

    raise ValueError(
        f"Unsupported database: {database}"
    )


# ============================================================
# DATASET RECONCILIATION
# ============================================================

def reconcile_dataset(
    expected_dataset: Dict[str, Any],
    target_dataset: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Reconcile one source dataset with one target object.
    """

    dataset_name = expected_dataset[
        "dataset_name"
    ]

    row_reconciliation = reconcile_row_counts(
        expected_dataset["expected_rows"],
        target_dataset["actual_rows"],
    )

    column_reconciliation = (
        reconcile_column_counts(
            expected_dataset[
                "expected_columns"
            ],
            target_dataset[
                "actual_columns"
            ],
        )
    )

    issues = detect_reconciliation_issues(
        dataset_name,
        row_reconciliation,
        column_reconciliation,
    )

    return {
        "dataset_name": dataset_name,
        "source_file": expected_dataset[
            "source_file"
        ],
        "target_name": target_dataset[
            "target_name"
        ],
        "row_reconciliation": (
            row_reconciliation
        ),
        "column_reconciliation": (
            column_reconciliation
        ),
        "reconciliation_status": (
            determine_reconciliation_status(
                row_reconciliation,
                column_reconciliation,
            )
        ),
        "reconciliation_issue_summary": (
            summarize_reconciliation_issues(
                issues
            )
        ),
        "reconciliation_issues": issues,
    }


# ============================================================
# MAIN RECONCILIATION PROCESS
# ============================================================

def run_reconciliation(
    database: str,
) -> Dict[str, Any]:
    """
    Run reconciliation for selected database.
    """

    print()
    print("=====================================")
    print("DATA RECONCILIATION STARTED")
    print("=====================================")
    print(f"Database: {database}")
    print()

    profiling_output = (
        load_profiling_results(database)
    )

    expected_datasets = (
        build_expected_datasets(
            profiling_output
        )
    )

    target_metrics = get_target_metrics(
        database
    )

    reconciliation_results = []

    all_issues = []

    reconciled_datasets = 0

    not_reconciled_datasets = 0

    missing_target_datasets = 0

    # --------------------------------------------------------
    # EXPECTED DATASET PROCESSING
    # --------------------------------------------------------

    for dataset_key, expected_dataset in (
        expected_datasets.items()
    ):

        dataset_name = expected_dataset[
            "dataset_name"
        ]

        print(
            f"Reconciling: {dataset_name}"
        )

        target_dataset = target_metrics.get(
            dataset_key
        )

        if target_dataset is None:

            issue = {
                "issue_type": (
                    "MISSING_TARGET_DATASET"
                ),
                "severity": "HIGH",
                "dataset": dataset_name,
                "message": (
                    f"Expected dataset "
                    f"'{dataset_name}' was not "
                    "found in the target database."
                ),
            }

            result = {
                "dataset_name": dataset_name,
                "source_file": expected_dataset[
                    "source_file"
                ],
                "target_name": None,
                "reconciliation_status": (
                    "NOT_RECONCILED"
                ),
                "reconciliation_issue_summary": (
                    summarize_reconciliation_issues(
                        [issue]
                    )
                ),
                "reconciliation_issues": [
                    issue
                ],
            }

            reconciliation_results.append(
                result
            )

            all_issues.append(issue)

            missing_target_datasets += 1

            not_reconciled_datasets += 1

            print(
                "Status      : NOT_RECONCILED"
            )
            print(
                "Reason      : TARGET NOT FOUND"
            )
            print()

            continue

        result = reconcile_dataset(
            expected_dataset,
            target_dataset,
        )

        reconciliation_results.append(
            result
        )

        all_issues.extend(
            result["reconciliation_issues"]
        )

        if (
            result["reconciliation_status"]
            == "RECONCILED"
        ):

            reconciled_datasets += 1

        else:

            not_reconciled_datasets += 1

        print(
            f"Status      : "
            f"{result['reconciliation_status']}"
        )
        print()

    # --------------------------------------------------------
    # EXTRA TARGET DATASETS
    # --------------------------------------------------------

    extra_target_datasets = []

    for target_key, target_dataset in (
        target_metrics.items()
    ):

        if target_key not in expected_datasets:

            issue = {
                "issue_type": (
                    "EXTRA_TARGET_DATASET"
                ),
                "severity": "MEDIUM",
                "dataset": target_dataset[
                    "target_name"
                ],
                "message": (
                    f"Target object "
                    f"'{target_dataset['target_name']}' "
                    "does not have a corresponding "
                    "incoming source dataset."
                ),
            }

            extra_target_datasets.append(
                target_dataset["target_name"]
            )

            #all_issues.append(issue)

    issue_summary = (
        summarize_reconciliation_issues(
            all_issues
        )
    )

    # --------------------------------------------------------
    # OUTPUT
    # --------------------------------------------------------

    output_directory = (
        PROJECT_ROOT
        / "metadata"
        / "reconciliation"
        / database
    )

    output_file = (
        output_directory
        / "reconciliation.json"
    )

    reconciliation_output = {
        "reconciliation_metadata": {
            "database": database,
            "generated_at_utc": datetime.now(
                timezone.utc
            ).isoformat(),
            "profiling_source": str(
                PROJECT_ROOT
                / "metadata"
                / "profiling"
                / database
                / "profiling.json"
            ),
        },
        "reconciliation_summary": {
            "expected_datasets": len(
                expected_datasets
            ),
            "target_datasets": len(
                target_metrics
            ),
            "reconciled_datasets": (
                reconciled_datasets
            ),
            "not_reconciled_datasets": (
                not_reconciled_datasets
            ),
            "missing_target_datasets": (
                missing_target_datasets
            ),
            "extra_target_datasets": len(
                extra_target_datasets
            ),
            "total_issues": issue_summary[
                "total_issues"
            ],
            "high_severity_issues": (
                issue_summary[
                    "high_severity_issues"
                ]
            ),
            "medium_severity_issues": (
                issue_summary[
                    "medium_severity_issues"
                ]
            ),
            "low_severity_issues": (
                issue_summary[
                    "low_severity_issues"
                ]
            ),
        },
        "datasets": reconciliation_results,
        "extra_target_datasets": (
            extra_target_datasets
        ),
    }

    output_directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            reconciliation_output,
            file,
            indent=4,
            ensure_ascii=False,
        )

    print("=====================================")
    print("DATA RECONCILIATION COMPLETED")
    print("=====================================")
    print(
        f"Expected Datasets      : "
        f"{len(expected_datasets)}"
    )
    print(
        f"Reconciled Datasets    : "
        f"{reconciled_datasets}"
    )
    print(
        f"Not Reconciled         : "
        f"{not_reconciled_datasets}"
    )
    print(
        f"Missing Target Datasets: "
        f"{missing_target_datasets}"
    )
    print(
        f"Extra Target Datasets  : "
        f"{len(extra_target_datasets)}"
    )
    print(
        f"Total Issues           : "
        f"{issue_summary['total_issues']}"
    )
    print(
        f"Output                 : "
        f"{output_file}"
    )
    print()

    return reconciliation_output


# ============================================================
# COMMAND-LINE ARGUMENTS
# ============================================================

def parse_arguments() -> argparse.Namespace:
    """
    Parse command-line arguments.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Reconcile incoming profiling results "
            "with loaded target database data."
        )
    )

    parser.add_argument(
        "--database",
        required=True,
        choices=SUPPORTED_DATABASES,
        help=(
            "Database whose loaded data "
            "should be reconciled."
        ),
    )

    return parser.parse_args()


# ============================================================
# MAIN ENTRY POINT
# ============================================================

def main() -> None:
    """
    Main execution function.
    """

    arguments = parse_arguments()

    try:

        run_reconciliation(
            arguments.database
        )

    except Exception as error:

        print()
        print("=====================================")
        print("DATA RECONCILIATION FAILED")
        print("=====================================")
        print(f"Error: {error}")
        print()

        sys.exit(1)


if __name__ == "__main__":
    main()