# HANDOFF 000006

## TASK
Bring dedicated MSSQL Windows Jenkins LOAD pipeline into logical parity with proven local .bat fresh-workspace bootstrap contract.

## DATABASE
MSSQL

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMssql1

## BRANCH
mssql-windows-final-v1

## STARTING_HEAD
`52f9b92` — `fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD`

## ENDING_HEAD
Pending commit — Jenkins Groovy LOAD fresh-workspace bootstrap implemented and statically validated

## GOAL
Make `jenkins/mssql/windows/load_pipeline.groovy` logically equivalent to the proven local .bat fresh-workspace contract so a separate fresh Jenkins workspace can execute LOAD without assuming SETUP artifacts already exist.

## WHAT_WAS_FOUND

### Pre-existing Groovy LOAD
- Missing all fresh-workspace bootstrap stages: Python requirements, Java validation, tool installation, instance resolution.
- CDC exit-100 handling already fixed (f4aefd3) with `returnStatus: true` and `SKIP_DATA_LOAD` guards on Load Data / Validate Loaded Data.
- Bootstrap gap was the remaining major barrier to LOAD running in a fresh workspace.

### Local .bat LOAD (proven, 52f9b92)
- validate Python runtime
- install Python requirements
- validate Python requirements
- validate Java runtime
- install tools (Liquibase, sqlcmd, JDBC driver)
- check_instance + instance-state resolution
- NO_INSTANCE → deploy + configure + start
- INSTALLED_BUT_STOPPED → start
- RUNNING_AND_USABLE → reuse
- start_mssql, validate_mssql
- create_database, download_dataset, run_cdc, load_data, validate_loaded_data, deploy_objects, validate_objects

### Bootstrap dependency classification (from prior local .bat audit)
| Prerequisite | Classification |
|---|---|
| Python runtime | A — required |
| Python requirements | A — required |
| validate_python_requirements | A — required |
| validate_java_runtime | A — required |
| install_tools (Liquibase/sqlcmd/JDBC) | A — required |
| check_instance + resolution | A — required |
| NO_INSTANCE deployment | A — required |
| INSTALLED_BUT_STOPPED start | A — required |
| RUNNING reuse | A — required |
| download_dataset | B — self-provisioning |
| create_database | B — self-provisioning |
| load_data | B — self-provisioning |
| run_cdc | B — self-provisioning |
| deploy_objects | B — self-provisioning |
| validate_objects | B — self-provisioning |

## CHANGES_MADE

### jenkins/mssql/windows/load_pipeline.groovy
Inserted 7 new bootstrap stages after `Initialize Logging` and before `Download Dataset`:
1. **Validate Python Runtime** — `scripts\batch\common\validate_python_runtime.bat` via `runTrackedStage`
2. **Install Python Requirements** — `scripts\batch\mssql\setup\install_python_requirements.bat` via `runTrackedStage`
3. **Validate Python Requirements** — `scripts\batch\mssql\setup\validate_python_requirements.bat` via `runTrackedStage`
4. **Validate Java Runtime** — `scripts\batch\common\validate_java_runtime.bat` via `runTrackedStage`
5. **Install Tools** — `scripts\batch\mssql\setup\install_tools.bat` via `runTrackedStage`
6. **Check Instance** — inline `script` with explicit logging using `bat(returnStatus: true, returnStdout: true)` to capture `INSTANCE_STATE` from `check_instance.bat`:
   - Parses stdout for `INSTANCE_STATE=...`
   - `NO_INSTANCE` → calls `deploy_mssql_gdrive.bat` and `configure_mssql.bat`
   - `INSTANCE_INSTALLED_BUT_STOPPED` → echo, then start via next stage
   - `INSTANCE_RUNNING_AND_USABLE` → echo, then start via next stage (idempotent)
   - Unknown/missing state → fail closed with `set-error`
7. **Start SQL Server** — `scripts\batch\mssql\setup\start_mssql.bat` via `runTrackedStage`
8. **Validate SQL Server** — `scripts\batch\mssql\setup\validate_mssql.bat` via `runTrackedStage`

Existing downstream stages preserved in original order:
- Download Dataset → Create Database → Run CDC → Load Data → Validate Loaded Data → Deploy Database Objects → Validate Database Objects → optional assessment/reporting.

No changes to stage tracking/logging conventions. No changes to PostgreSQL, MySQL, MongoDB, Ubuntu, or main Jenkinsfile.

## FILES_CHANGED
- jenkins/mssql/windows/load_pipeline.groovy
- PROJECT_WORKING_STATE/CURRENT_STATE.md
- PROJECT_WORKING_STATE/HANDOFFS/000006_2026-07-23_1730_groovy-fresh-workspace-bootstrap-parity.md (this file)

## TESTS_PERFORMED

### A. Groovy/static integrity
- Brace balance: 127 open / 127 close = BALANCED
- Stage order verified: 18 stages in correct sequence
- All referenced .bat/.ps1 script paths resolved and exist in repository

### B. Fresh-workspace dependency ordering
- Static trace confirms Python requirements → Java validation → tool installation → instance resolution → MSSQL start/validate occur BEFORE Create Database, CDC, and Load Data.

### C. Instance state branching (static/logic)
- `checkResult` captures both exit code and stdout
- `instanceState` parsed via `output.readLines().find { line -> line.startsWith('INSTANCE_STATE=') }`
- All four branches verified: `NO_INSTANCE`, `INSTANCE_INSTALLED_BUT_STOPPED`, `INSTANCE_RUNNING_AND_USABLE`, unknown → fail closed

### D. CDC regression
- `Run CDC` stage unchanged from prior fix
- `returnStatus: true` intact
- `SKIP_DATA_LOAD = 'true'` on exit 100 intact
- `when { env.SKIP_DATA_LOAD != 'true' }` guards on Load Data and Validate Loaded Data intact

### E. Existing batch state-machine test
- Re-ran `tests/test_load_bootstrap_sm.bat` for RUNNING, STOPPED, NOINSTANCE states.
- All three pass.

## TEST_RESULTS
- PASS: Groovy brace balance
- PASS: Stage order matches local .bat contract after bootstrap block
- PASS: All referenced batch script paths exist
- PASS: Check Instance captures both exit code and stdout
- PASS: Check Instance branches correctly on all three states + unknown
- PASS: CDC exit-100 handling preserved (returnStatus: true, SKIP_DATA_LOAD guards)
- PASS: Jenkins bootstrap stage count = 8 new stages (Initialize Logging + 7 bootstrap = 8; plus existing 10 = 18 total)
- NOT PERFORMED: Runtime Jenkins pipeline execution (not technically feasible without live Jenkins agent)
- NOT PERFORMED: Full fresh-workspace end-to-end LOAD runtime

## PROVEN_WORKING
- Structural/logical equivalence between local .bat and Jenkins Groovy bootstrap blocks established via static analysis.
- CDC regression prevented (exit-100 handling unchanged).
- Ownership-hardened `check_instance.py` is reused via standard bat invocation; output parsing preserves all instances of `INSTANCE_STATE=...`.

## STILL_UNVERIFIED
- Runtime Jenkins behavior with actual Python/Java/tool install steps
- Runtime Jenkins behavior when `check_instance.bat` returns `NO_INSTANCE` (deploy + configure)
- Runtime Jenkins behavior when `deploy_mssql_gdrive.bat` or `configure_mssql.bat` fail
- Full fresh-workspace LOAD end-to-end in Jenkins
- Behavior when admin privileges are unavailable for `configure_mssql.bat` in NO_INSTANCE path

## KNOWN_ISSUES
- configure_mssql Groovy gating mismatch remains
- Missing assessment/migration pipeline wrappers
- Schema Liquibase evolution still unwired
- Master Jenkinsfile still lacks MSSQL stages
- Ownership detection is service/registry-based; not unique beyond configured instance identity (residual risk)

## DO_NOT_REPEAT
- Do NOT modify PostgreSQL, MySQL, MongoDB, Ubuntu, or main Jenkinsfile
- Do NOT weaken check_instance.py ownership logic
- Do NOT run full pipeline for isolated bootstrap validation
- Do NOT begin schema Liquibase/reporting/main Jenkins integration in this task
- Do NOT expand this into broad SETUP redesign

## NEXT_EXACT_ACTIONS
1. Commit and push Groovy fresh-workspace bootstrap parity fix.
2. Perform targeted runtime Jenkins validation if feasible.
3. Align configure_mssql gating between .bat and Groovy.
4. Add missing assessment/migration wrappers.
5. Wire schema Liquibase evolution into LOAD.
6. Update master Jenkinsfile for MSSQL.

## COMMITS
- `52f9b92` (parent): `fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD`
- Pending: `fix(mssql-windows-groovy): add fresh-workspace bootstrap stages to dedicated LOAD pipeline`

## PUSH_STATUS
- Pending push to origin/mssql-windows-final-v1