"""
Shared, database-agnostic ORCHESTRATOR for deploying database objects
(views, functions, procedures, triggers).

STRICT CONTRACT (per approved architecture):
  - Does NOT construct or issue any Liquibase command itself.
  - Does NOT know about JDBC drivers, classpaths, or connection URLs.
  - Regenerates master_objects.xml via generate_master_objects.py.
  - Delegates the actual Liquibase execution to the EXISTING, unmodified
    per-database runner script (run_liquibase.sh / run_liquibase.bat),
    passing the objects changelog path as its one optional argument.
  - This script only orchestrates; it never invokes `tools/liquibase/*`
    directly.

Usage:
    python deploy_objects.py <db_name>
    e.g. python deploy_objects.py mysql
"""
import platform
import subprocess
import sys
from pathlib import Path

# scripts/python/common/objects/deploy_objects.py
# parents[1] = scripts/python/common (where config_loader.py lives)
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from config_loader import get_project_root  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_master_objects import generate as generate_master_objects  # noqa: E402

# Existing runner script locations, by database, exactly as they already
# exist in the repository today. This is a lookup table, not a new
# runner - it only tells us WHERE the existing script lives.
#
# NOTE: MSSQL's existing runner does not follow this convention
# (scripts/bash/mssql/run_liquibase.sh, no "setup" segment). MSSQL is out
# of scope for this phase and is intentionally not mapped here yet.
RUNNER_PATHS = {
    "mysql": {
        "sh": "scripts/bash/mysql/setup/run_liquibase.sh",
        "bat": "scripts/batch/mysql/setup/run_liquibase.bat",
    },
    "postgresql": {
        "sh": "scripts/bash/postgresql/setup/run_liquibase.sh",
        "bat": "scripts/batch/postgresql/setup/run_liquibase.bat",
    },
}


def deploy(db_name: str) -> None:
    root = get_project_root()

    if db_name not in RUNNER_PATHS:
        raise ValueError(
            f"No existing runner mapping for '{db_name}'. "
            f"Supported: {list(RUNNER_PATHS)}"
        )

    # Step 1: regenerate master_objects.xml (business logic lives here,
    # not in this orchestrator).
    changelog_path = generate_master_objects(db_name)
    relative_changelog = changelog_path.relative_to(root).as_posix()

    is_windows = platform.system() == "Windows"

    # Step 2: delegate to the EXISTING runner, unmodified except for the
    # new optional changelog argument it now accepts.
    if is_windows:
        runner = root / RUNNER_PATHS[db_name]["bat"]
        windows_changelog = relative_changelog.replace("/", "\\")
        command = [str(runner), windows_changelog]
    else:
        runner = root / RUNNER_PATHS[db_name]["sh"]
        command = ["bash", str(runner), relative_changelog]

    if not runner.exists():
        raise FileNotFoundError(
            f"Existing Liquibase runner not found for '{db_name}': {runner}"
        )

    print(f"Delegating objects deployment to existing runner: {runner}")
    print(f"Changelog: {relative_changelog}")

    subprocess.run(command, cwd=str(root), check=True)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: deploy_objects.py <db_name>")
        sys.exit(1)

    deploy(sys.argv[1])
