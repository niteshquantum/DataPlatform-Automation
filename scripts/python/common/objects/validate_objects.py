import sys
import json
from pathlib import Path

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent)
)

from config_loader import get_project_root
from database_capabilities import supports_object


def get_expected_objects(
    root,
    database,
    object_type
):

    folder = (
        root
        / "objects"
        / database
        / "generated"
        / object_type
    )

    if not folder.exists():
        return set()

    names = set()

    for sql_file in folder.glob("*.sql"):

        name = sql_file.stem

        # Remove numeric prefix:
        # 001_v_orders -> v_orders
        parts = name.split("_", 1)

        if (
            len(parts) == 2
            and parts[0].isdigit()
        ):
            name = parts[1]

        names.add(name.lower())

    return names


def validate_type(
    object_type,
    expected,
    actual
):

    missing = expected - actual

    print()
    print(
        f"{object_type.upper()}: "
        f"Expected={len(expected)} "
        f"Found={len(expected - missing)}"
    )

    if missing:

        for name in sorted(missing):
            print(f"  MISSING : {name}")

        return False

    print("  STATUS  : PASS")

    return True


def validate_objects(database):

    database = database.lower()

    root = get_project_root()

    if database == "mysql":

        from validators.mysql_validator import (
            MySQLObjectValidator
        )

        validator = MySQLObjectValidator()

    else:

        raise ValueError(
            f"No validator implemented for: {database}"
        )

    print()
    print("=====================================")
    print("DATABASE OBJECT VALIDATION")
    print("=====================================")
    print(f"Database : {database}")

    results = {}

    try:

        validator.connect()

        getters = {
            "views": validator.get_views,
            "functions": validator.get_functions,
            "procedures": validator.get_procedures,
            "triggers": validator.get_triggers,
            "events": validator.get_events,
            "indexes": validator.get_indexes,
        }

        for object_type, getter in getters.items():

            if not supports_object(
                database,
                object_type
            ):
                continue

            expected = get_expected_objects(
                root,
                database,
                object_type
            )

            actual = getter()

            missing = sorted(
                expected - actual
            )

            passed = validate_type(
                object_type,
                expected,
                actual
            )

            results[object_type] = {
                "expected": len(expected),
                "found": (
                    len(expected)
                    - len(missing)
                ),
                "missing": missing,
                "status": (
                    "PASS"
                    if passed
                    else "FAIL"
                )
            }

    finally:

        validator.close()

    report = (
        root
        / "metadata"
        / database
        / "object_validation_report.json"
    )

    report.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(
        report,
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            results,
            file,
            indent=4
        )

    failed = [
        name
        for name, result in results.items()
        if result["status"] == "FAIL"
    ]

    print()
    print("=====================================")

    if failed:

        print("OBJECT VALIDATION FAILED")
        print(
            "Failed types: "
            + ", ".join(failed)
        )

        raise RuntimeError(
            "Database object validation failed."
        )

    print("ALL DATABASE OBJECTS VALIDATED")
    print("=====================================")


if __name__ == "__main__":

    if len(sys.argv) != 2:

        print(
            "Usage: validate_objects.py <database>"
        )

        sys.exit(1)

    validate_objects(
        sys.argv[1]
    )