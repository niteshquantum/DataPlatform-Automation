# HANDOFF 000005

## TASK
Make local MSSQL Windows LOAD entrypoint safe for a separate fresh workspace by adding minimum workspace-local dependency bootstrapping and instance resolution to `scripts/batch/mssql/mssql_load_pipeline.bat`.

## DATABASE
MSSQL

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMssql1

## BRANCH
mssql-windows-final-v1

## STARTING_HEAD
`19806e1` — `fix(mssql-windows): verify managed instance ownership via registry/service path`

## ENDING_HEAD
Pending commit — fresh-workspace LOAD bootstrap implemented and validated

## GOAL
Allow `scripts/batch/mssql/mssql_load_pipeline.bat` to execute correctly in a fresh workspace that has not already run SETUP, by provisioning local Python/tool dependencies and safely resolving the managed MSSQL instance using the hardened `check_instance.py` ownership detection.

## WHAT_WAS_FOUND
- Local .bat LOAD (`mssql_load_pipeline.bat`) validated/started/used MSSQL but assumed Python requirements, Liquibase, sqlcmd, JDBC driver, and a resolved MSSQL instance already existed from a prior SETUP run.
- A fresh workspace would fail at:
  - `validate_python_requirements.bat` (pyodbc/pandas missing)
  - `start_mssql.bat` / `validate_mssql.bat` (sqlcmd missing)
  - `deploy_objects.bat` (Liquibase + JDBC driver missing)
  - `start_mssql.bat` with NO_INSTANCE (service doesn't exist)
- Instance state (`check_instance.py`) was not inspected in LOAD, so NO_INSTANCE caused an opaque failure.
- PostgreSQL SETUP/LOAD patterns were used for principles only, not copied verbatim.

## ROOT_CAUSE
LOAD was written for an already-prepared environment. No fresh-workspace bootstrap path existed, and instance resolution was absent.

## CHANGES_MADE

### scripts/batch/mssql/mssql_load_pipeline.bat
Added bootstrap block before `START SQL SERVER`:
1. `install_python_requirements.bat` — installs `pyodbc`, `pandas`, etc. idempotently
2. `validate_java_runtime.bat` — ensures Java 17+ is present for Liquibase
3. `install_tools.bat` — installs Liquibase, sqlcmd, MSSQL JDBC driver (Terraform is extra but idempotent)
4. `check_instance.bat` — captures `INSTANCE_STATE=...` from hardened `check_instance.py`
5. Instance-state resolution:
   - `NO_INSTANCE` → `deploy_mssql_gdrive.bat` + `configure_mssql.bat` + start
   - `INSTANCE_INSTALLED_BUT_STOPPED` → start
   - `INSTANCE_RUNNING_AND_USABLE` → reuse (start_mssql is idempotent)
6. Explicit STATUS messages for each path

Preserved existing LOAD stage order unchanged after bootstrap:
- start_mssql, validate_mssql, create_database, download_dataset, run_cdc, load_data, validate_loaded_data, deploy_objects, validate_objects.

No changes to CDC skip logic (already correct in .bat), no schema Liquibase wiring, no assessment/migration additions.

## Fresh-Workspace Dependency Audit (classification)

| Prerequisite | Classification | Reasoning |
|---|---|---|
| Python runtime | A — required | Needed by all Python orchestration |
| Python requirements (pyodbc, pandas) | A — required | Not guaranteed in fresh workspace |
| validate_python_requirements | A — required | Catches missing deps after install |
| validate_java_runtime | A — required | Liquibase needs Java 17+ |
| install_tools (Liquibase/sqlcmd/JDBC) | A — required | Not present in fresh workspace |
| validate_tools | A — required downstream | `validate_mssql` and `deploy_objects` will surface missing tools; explicit validation adds clearer early failure |
| check_instance + resolution | A — required | Ownership-hardened instance detection before start |
| NO_INSTANCE deployment | A — required | LOAD must be independently runnable |
| INSTALLED_BUT_STOPPED start | A — required | Valid managed instance must start |
| RUNNING reuse | A — required | Valid running instance must not be redeployed |
| Terraform | C — unnecessary for LOAD | Installed by `install_tools.bat`; harmless |
| configure_mssql | A — required for NO_INSTANCE | Deployment sets sa password/configuration |
| download_dataset | B — self-provisioning | Downloads if absent, rerun-safe |
| create_database | B — self-provisioning | CREATE IF NOT EXISTS |
| load_data | B — self-provisioning | Idempotent |
| run_cdc | B — self-provisioning | Exit-100 skip already proven |
| deploy_objects | B — self-provisioning | Regenerates each run |
| validate_objects | B — self-provisioning | Idempotent |

## FILES_CHANGED
- scripts/batch/mssql/mssql_load_pipeline.bat
- PROJECT_WORKING_STATE/CURRENT_STATE.md
- PROJECT_WORKING_STATE/HANDOFFS/000005_2026-07-23_1715_fresh-workspace-local-load-bootstrap.md (this file)

## TESTS_PERFORMED
- Static batch syntax validation: edited file reviewed for balanced parentheses, correct `for /f` syntax, correct `if /I` syntax.
- Targeted batch state-machine validation (`tests/test_load_bootstrap_sm.bat`):
  - RUNNING → captures `INSTANCE_RUNNING_AND_USABLE`, echoes reuse message
  - STOPPED → captures `INSTANCE_INSTALLED_BUT_STOPPED`, echoes start message
  - NO_INSTANCE → captures `NO_INSTANCE`, echoes deploy message
- All three ownership-state branches pass the simulated check-instance output.

## TEST_RESULTS
- PASS: State machine captures INSTANCE_STATE correctly under `setlocal EnableDelayedExpansion`
- PASS: All three ownership states route to the correct message/action
- PASS: Existing LOAD stage order is preserved
- NOT PERFORMED: Full LOAD pipeline runtime (too expensive for isolated bootstrap test)
- NOT PERFORMED: Live MSSQL service manipulation

## PROVEN_WORKING
- Bootstrap block state-machine behavior under batch `setlocal EnableDelayedExpansion`
- Existing .bat LOAD stages are untouched and remain in proven order
- `check_instance.py` ownership logic hardened in prior commit

## STILL_UNVERIFIED
- Runtime execution of the complete fresh LOAD end-to-end
- Behavior when `install_tools.bat` needs admin (winget/PS download)
- Behavior when MSSQL deployment fails (network, media)

## KNOWN_ISSUES
- Local .bat LOAD bootstrap fixed; Jenkins Groovy LOAD still lacks equivalent bootstrap
- configure_mssql Groovy gating mismatch remains
- Missing assessment/migration wrappers
- Schema Liquibase evolution unwired
- Master Jenkinsfile lacks MSSQL stages
- Ownership detection is service/registry-based; not unique beyond configured instance identity

## DO_NOT_REPEAT
- Do NOT modify PostgreSQL, MySQL, MongoDB, Ubuntu, or main Jenkinsfile
- Do NOT weaken check_instance.py ownership logic
- Do NOT add schema Liquibase wiring in this task
- Do NOT modify Jenkins Groovy in this task
- Do NOT rerun full expensive pipeline for this isolated test

## NEXT_EXACT_ACTIONS
1. Commit and push fresh-workspace local .bat bootstrap fix.
2. Mirror exact local .bat bootstrap contract into `jenkins/mssql/windows/load_pipeline.groovy`.
3. Align configure_mssql gating between .bat and Groovy.
4. Add missing assessment/migration wrappers.
5. Wire schema Liquibase evolution into LOAD.
6. Update master Jenkinsfile for MSSQL.

## COMMITS
- `19806e1` (parent): `fix(mssql-windows): verify managed instance ownership via registry/service path`
- Pending: `fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD`

## PUSH_STATUS
- Pending push to origin/mssql-windows-final-v1