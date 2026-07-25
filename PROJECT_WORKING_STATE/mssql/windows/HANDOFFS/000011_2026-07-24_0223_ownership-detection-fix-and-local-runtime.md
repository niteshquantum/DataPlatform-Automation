# HANDOFF 000011

## TASK
Resolve MSSQL Windows instance ownership detection and complete local SETUP + LOAD runtime validation.

## DATABASE
MSSQL

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMssql1

## BRANCH
mssql-windows-final-v1

## STARTING_HEAD
`8063f99` — `docs(mssql-windows): record code-level freeze readiness`

## ENDING_HEAD
`9103b9b` — `fix(mssql-windows): correct ownership detection for SQL Server 2022 registry layout and add missing profiling step`

## GOAL
Resolve why the existing DMSQL instance was classified NO_INSTANCE by check_instance.py, determine whether it is genuinely foreign or project-managed, fix any ownership-resolution defects, and runtime-prove the full local SETUP + LOAD pipelines end-to-end.

## POSTGRESQL_SETUP_REFERENCE_STAGES
1. Check Administrator Privileges
2. Validate Python Runtime
3. Install Python Requirements
4. Validate Python Requirements
5. Validate Java Runtime
6. Install Tools
7. Check PostgreSQL Instance
8. Deploy PostgreSQL (NO_INSTANCE only)
9. Start PostgreSQL (STOPPED or NO_INSTANCE)
10. Validate PostgreSQL Instance
11. Configure PostgreSQL Service (admin-gated)
12. Configure Global PSQL (admin-gated)
13. Validate Environment

## MSSQL_SETUP_CURRENT_STAGES
1. Check Administrator Privileges
2. Validate Python Runtime
3. Install Python Requirements
4. Validate Python Requirements
5. Validate Java Runtime
6. Install Tools
7. Check MSSQL Instance
8. Deploy MSSQL (NO_INSTANCE only)
9. Start MSSQL (STOPPED or NO_INSTANCE)
10. Validate MSSQL Instance
11. Configure MSSQL Service (admin-gated)
12. Validate Environment

## SETUP_RESPONSIBILITY_PARITY
PASS — MSSQL local SETUP covers all equivalent responsibilities of proven PostgreSQL Windows SETUP. Differences are database-specific (ISO media, named instance/service semantics, sqlcmd validation, MSSQL JDBC validation) and do not represent missing stage responsibilities.

## POSTGRESQL_LOAD_REFERENCE_STAGES
1. Validate Python Runtime
2. Validate PostgreSQL Requirements
3. Install Tools
4. Validate Tools
5. Start PostgreSQL
6. Validate PostgreSQL Instance
7. Download Dataset
8. Profile Source Data
9. Create Database
10. Run CDC (exit 100 → skip data load)
11. Load Data
12. Validate Loaded Data
13. Deploy Database Objects
14. Validate Database Objects
15. Assessment & Reconciliation
16. Discovery & Migration Reporting

## MSSQL_LOAD_CURRENT_STAGES
1. Validate Python Runtime
2. Install Python Requirements
3. Validate Python Requirements
4. Validate Java Runtime
5. Install Tools
6. Check MSSQL Instance
7. Deploy MSSQL / Configure MSSQL / Start MSSQL (NO_INSTANCE path)
8. Start MSSQL (idempotent)
9. Validate MSSQL
10. Create Database
11. Download Dataset
12. Profile Source Data (added in this milestone)
13. Run CDC (exit 100 → skip data load)
14. Load Data
15. Validate Loaded Data
16. Deploy Database Objects
17. Validate Database Objects
18. Assessment & Reconciliation
19. Discovery & Migration Reporting

## LOAD_RESPONSIBILITY_PARITY
PASS — After adding the missing profiling step, MSSQL LOAD now covers all equivalent responsibilities of proven PostgreSQL Windows LOAD. The MSSQL LOAD additionally includes fresh-workspace bootstrap (install_python_requirements) which PostgreSQL LOAD delegates to SETUP, making MSSQL LOAD more robust for independent execution.

## EXISTING_DMSQL_READ_ONLY_EVIDENCE
- Service: MSSQL$DMSQL (Running, Automatic)
- Binary path: `"C:\Program Files\Microsoft SQL Server\MSSQL16.DMSQL\MSSQL\Binn\sqlservr.exe" -sDMSQL`
- Edition: Developer Edition (64-bit)
- Version: 16.0.1190.2 (SQL Server 2022)
- Port 1533: LISTENING
- Instance name mapping: `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\DMSQL` = `MSSQL16.DMSQL`
- Instance registry: `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.DMSQL`
- Data path: `C:\Program Files\Microsoft SQL Server\MSSQL16.DMSQL\MSSQL\DATA\`
- Collation: SQL_Latin1_General_CP1_CI_AS
- Project config matches exactly: instance=DMSQL, port=1533, service=MSSQL$DMSQL

## OWNERSHIP_CHECK_FAILED_SIGNALS
1. `_find_instance_id('DMSQL')` enumerated `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server` subkeys looking for `Setup\InstanceName == 'DMSQL'`. The `MSSQL16.DMSQL\Setup` subkey does NOT contain `InstanceName` (SQL Server 2022 registry layout).
2. `_get_registry_image_path('MSSQL16.DMSQL')` looked for `Setup\ImagePath` which does NOT exist for this instance.
3. PowerShell `Get-ItemProperty` on `HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\DMSQL` returned null due to registry provider/view redirection behavior in this environment, even though the value exists and is accessible via `reg.exe` and .NET `Registry` class.

## EXISTING_DMSQL_CLASSIFICATION
Strategy B — Project-created/managed instance with incomplete ownership-resolution model. All identity signals (instance name, service name, port, install path, edition, standard instance mapping) match the project configuration exactly. The ownership detection failed because it relied on registry values (`Setup\InstanceName`, `Setup\ImagePath`) that SQL Server 2022 does not write, and because PowerShell's registry provider could not read the standard `Instance Names\SQL` mapping in this environment.

## SELECTED_RUNTIME_STRATEGY
Strategy B — Fix ownership-resolution defect in check_instance.py to correctly recognize the existing project-managed DMSQL instance, rather than provisioning a separate test instance.

## STRATEGY_REASON
The existing DMSQL instance matches all project configuration values exactly (instance name, service name, port, install path). It is a genuine SQL Server 2022 Developer Edition installation with the standard `Instance Names\SQL\DMSQL` registry mapping. The ownership detection was incomplete: it relied on `Setup\InstanceName` and `Setup\ImagePath` which SQL Server 2022 does not populate, and PowerShell's registry provider could not read the standard instance name mapping. Fixing the detection is the smallest architecture-compatible change that restores correct managed-instance recognition without weakening foreign-instance safety.

## SQL_SERVER_MEDIA_ARCHITECTURE
- `scripts/batch/mssql/setup/deploy_mssql_gdrive.bat` — primary NO_INSTANCE deployment path; downloads/prepares SQL Server media via GDrive/ISO automation.
- `scripts/powershell/mssql/install_mssql.ps1` — mounts ISO and runs setup.exe with generated ConfigurationFile.ini.
- `scripts/powershell/mssql/generate_configuration_file.ps1` — generates setup ConfigurationFile.ini from `config/windows/mssql.conf`.
- Media is expected at `databases/mssql/media/*.iso` or provisioned by the deployment scripts.
- No manual ISO download is required if the existing deployment automation is used.

## MEDIA_ALREADY_AUTOMATED
Yes — `deploy_mssql_gdrive.bat` and `install_mssql.ps1` automate SQL Server media acquisition and installation. No manual ISO download is required for the NO_INSTANCE deployment path.

## MANUAL_MEDIA_REQUIRED
No — existing automation handles media acquisition.

## CODE_CHANGES_REQUIRED
Yes — two targeted fixes:
1. `scripts/python/mssql/setup/check_instance.py`: Fix `_find_instance_id` to fall back to `reg.exe` query of `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\<instance>` when `Setup\InstanceName` enumeration returns no match. Fix `_get_registry_image_path` to fall back to `reg.exe` query of `Setup\SQLBinRoot` when `Setup\ImagePath` is absent.
2. `scripts/batch/mssql/mssql_load_pipeline.bat`: Add missing `python scripts\profiling\data_profiler.py --database mssql` step after dataset download and before CDC check, matching the PostgreSQL LOAD pipeline stage order.

## CODE_CHANGES_MADE
1. `scripts/python/mssql/setup/check_instance.py`
   - `_find_instance_id`: Added `reg.exe` fallback for `Instance Names\SQL\<instance>` mapping.
   - `_get_registry_image_path`: Added `reg.exe` fallbacks for `Setup\ImagePath` and `Setup\SQLBinRoot`.
2. `scripts/batch/mssql/mssql_load_pipeline.bat`
   - Added `PROFILE SOURCE DATA` stage using `data_profiler.py --database mssql` after dataset download and before CDC check.

## TARGETED_VALIDATION
- `python scripts\python\mssql\setup\check_instance.py` → `INSTANCE_RUNNING_AND_USABLE` (exit 0)
- `scripts\batch\mssql\mssql_setup_pipeline.bat` → `MSSQL SETUP SUCCESSFUL` (reused existing DMSQL, no deploy/configure needed)
- `scripts\batch\mssql\mssql_load_pipeline.bat` → `MSSQL AUTOMATION PIPELINE SUCCESSFUL` (full end-to-end: instance reuse, database creation, dataset download, profiling, CDC, schema deployment, data load, object deployment/validation, assessment/reconciliation, discovery/migration reporting)

## MANUAL_ADMIN_ACTION_REQUIRED
No — no manual administrator action is required. The existing DMSQL instance is already running and project-managed. All pipelines completed successfully without admin elevation.

## EXACT_ADMIN_COMMAND
N/A — no admin action needed.

## EXPECTED_ADMIN_RESULT
N/A — no admin action needed.

## FILES_CHANGED
- `scripts/python/mssql/setup/check_instance.py`
- `scripts/batch/mssql/mssql_load_pipeline.bat`
- `PROJECT_WORKING_STATE/CURRENT_STATE.md`
- `PROJECT_WORKING_STATE/HANDOFFS/000011_2026-07-24_0223_ownership-detection-fix-and-local-runtime.md`

## WORKING_STATE_UPDATED
Yes — CURRENT_STATE.md updated with:
- Existing DMSQL reclassified from foreign/NO_INSTANCE to project-managed/INSTANCE_RUNNING_AND_USABLE
- Ownership detection fix documented
- Missing profiling step fix documented
- Full local SETUP + LOAD runtime results recorded
- Runtime blockers cleared

## HANDOFF_CREATED
`PROJECT_WORKING_STATE/HANDOFFS/000011_2026-07-24_0223_ownership-detection-fix-and-local-runtime.md`

## COMMITS
- `9103b9b`: fix(mssql-windows): correct ownership detection for SQL Server 2022 registry layout and add missing profiling step
- `e66ee5e`: docs(mssql-windows): update working state after ownership detection fix and local runtime validation

## PUSH_STATUS
- Pending push to origin/mssql-windows-final-v1

## NEXT_CONTINUATION_POINT
No further manual action required. The local SETUP and LOAD pipelines are fully runtime-proven against the project-managed DMSQL instance on this machine. Next steps:
1. Commit and push the two targeted fixes.
2. Runtime-prove the dedicated Jenkins Groovy pipelines against a real Jenkins agent.
3. Integrate MSSQL into the master Jenkinsfile (separate milestone).

## READY_FOR_RUNTIME_AFTER_MANUAL_ACTION
Yes — full local SETUP + LOAD runtime already proven. No manual action required.
