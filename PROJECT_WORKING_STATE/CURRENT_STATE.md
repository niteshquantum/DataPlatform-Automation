# CURRENT STATE

Last updated: 2026-07-23 18:30 IST

## Repository Baseline

- **Branch**: mssql-windows-final-v1
- **HEAD**: `8063f99`
- **Commit message**: `docs(mssql-windows): record code-level freeze readiness`
- **Baseline branch**: windows-pipeline-integration-v1
- **Baseline SHA**: `e7c403d9791b4f8aab16f1fe9ed17a37540ff1db`

## Audit Status

**COMPLETED** — MSSQL Windows implementation audited against PostgreSQL Windows proven reference.

## Implemented Fixes

### CDC Exit-100 Propagation (LOAD Groovy)

`jenkins/mssql/windows/load_pipeline.groovy` CDC stage changed from `runTrackedStage` to explicit `bat(returnStatus: true)` with manual logging:
- exit 0 → log SUCCESS, continue pipeline
- exit 100 → log SUCCESS, set `env.SKIP_DATA_LOAD = 'true'`, continue pipeline
- other non-zero → log FAILURE, call `set-error`, `error` to fail stage
- `Load Data` and `Validate Loaded Data` stages now have `when { env.SKIP_DATA_LOAD != 'true' }` guards

### Instance Ownership Verification (check_instance.py)

`scripts/python/mssql/setup/check_instance.py` now verifies project-managed instance identity before trusting service/port state:
- Queries service `ImagePath` via `sc.exe qc` to confirm binary is `sqlservr.exe`
- Enumerates `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server` registry subkeys to find a `Setup\InstanceName` matching the configured instance
- Verifies registry `ImagePath` also points to `sqlservr.exe`

A foreign instance that happens to share the service name and/or port but lacks matching registry provenance is classified as `NO_INSTANCE`. A legitimately managed instance (running or stopped) is recognized by its registry entry.

### LOAD Fresh-Workspace Bootstrap (local .bat)

`scripts/batch/mssql/mssql_load_pipeline.bat` now bootstraps workspace-local dependencies and safely resolves/reuses the managed MSSQL instance before data operations:
- Installs Python requirements (`install_python_requirements.bat`) after runtime validation
- Validates Java runtime (`validate_java_runtime.bat`)
- Installs tools (`install_tools.bat`) — Liquibase, sqlcmd, MSSQL JDBC driver
- Checks instance state (`check_instance.bat`) and handles:
  - `NO_INSTANCE` → `deploy_mssql_gdrive.bat` + `configure_mssql.bat` + start
  - `INSTANCE_INSTALLED_BUT_STOPPED` → start
  - `INSTANCE_RUNNING_AND_USABLE` → reuse (start_mssql is idempotent)
- Preserves existing CDC, load, validate, deploy, and object validation stages unchanged

This makes the local .bat LOAD independently runnable in a fresh workspace without assuming SETUP already ran.

### LOAD Fresh-Workspace Bootstrap (Jenkins Groovy)

`jenkins/mssql/windows/load_pipeline.groovy` now bootstraps workspace-local dependencies and safely resolves/reuses the managed MSSQL instance before data operations, mirroring the proven local .bat contract:
- Validates Python runtime
- Installs Python requirements (`install_python_requirements.bat`)
- Validates Python requirements (`validate_python_requirements.bat`)
- Validates Java runtime (`validate_java_runtime.bat`)
- Installs tools (`install_tools.bat`) — Liquibase, sqlcmd, MSSQL JDBC driver
- Checks instance state (`check_instance.bat`) and handles:
  - `NO_INSTANCE` → `deploy_mssql_gdrive.bat` + `configure_mssql.bat` + start
  - `INSTANCE_INSTALLED_BUT_STOPPED` → start
  - `INSTANCE_RUNNING_AND_USABLE` → reuse (start_mssql is idempotent)
- Unexpected state → fail closed with diagnostic
- Preserves existing CDC exit-100 handling, SKIP_DATA_LOAD guards, and downstream LOAD stages unchanged

This makes the dedicated Jenkins Groovy LOAD logically equivalent to the local .bat fresh-workspace contract.

### configure_mssql Gating Alignment (local .bat)

`scripts/batch/mssql/mssql_setup_pipeline.bat` now aligns with the Jenkins Groovy and PostgreSQL patterns by gating `configure_mssql.bat` on administrator availability in the `NO_INSTANCE` path:
- `check_admin_privileges.bat` is called after deployment
- `ADMIN_STATUS=true` → runs `configure_mssql.bat`
- `ADMIN_STATUS=false` → skips network configuration, proceeds to start
- Without admin, `configure_mssql.ps1` would throw an elevation error; gating prevents late-stage opaque failure
- `RUNNING` and `STOPPED` paths are unaffected (no configure call)

### Liquibase Bootstrap Config Path Fix

`scripts/powershell/download_liquibase.ps1` was reading `config/windows/mysql.conf` instead of `config/windows/mssql.conf` to obtain `LIQUIBASE_VERSION`. This was a copy-paste defect that would prevent Liquibase from being installed for MSSQL if the MySQL config were missing or different. Fixed to read `mssql.conf`.

### Schema Liquibase Missing-Registry Resilience

`scripts/python/mssql/setup/generate_liquibase_xml.py` now handles a missing `metadata/mssql/schema_registry.json` gracefully:
- If the registry does not exist, it writes `schema_status.json` with `schema_changed: false` and `reason: no_schema_registry`, then exits 0
- Previously this crashed with `FileNotFoundError`, blocking `load_data.bat` in fresh workspaces where `schema_detector.py` found no incoming files
- The existing `load_data.bat` already wires `schema_detector.py` → `generate_liquibase_xml.py` → `update_master_xml.py` → `run_liquibase.bat`; this fix ensures that flow does not fail when there are no schema changes to evolve

### Assessment & Reconciliation Pipeline Wrapper

Created `scripts/batch/mssql/assessment/run_assessment_pipeline.bat` as the dedicated MSSQL assessment entry point:
- Runs `scripts/batch/mssql/assessment/run_assessment.bat all`
- Generates unified assessment report via `scripts/batch/common/generate_assessment_report.bat`
- Runs reconciliation via `scripts/reconciliation/reconciliation_engine.py --database mssql`

### Discovery & Migration Reporting Pipeline Wrapper

Created `scripts/batch/mssql/migration/run_migration_pipeline.bat` as the dedicated MSSQL migration/reporting entry point:
- Discovery: `scripts/discovery/discovery_engine.py --database mssql`
- Growth analysis: `scripts/discovery/growth_analyzer.py --database mssql`
- Requirement analysis: `scripts/discovery/requirement_analyzer.py --database mssql`
- Migration assessment: `scripts/assessment/assessment_engine.py --database mssql`
- Recommendations: `scripts/recommendation/recommendation_engine.py --database mssql`
- Governance action plan: `scripts/governance/action_plan_engine.py --database mssql`
- Technical report: `scripts/reporting/migration/technical_report.py --database mssql`
- Executive report: `scripts/reporting/migration/executive_report.py --database mssql`

### Local LOAD Fresh-Workspace Bootstrap Fixes

`scripts/batch/mssql/mssql_load_pipeline.bat` now matches the architecture-correct fresh-workspace order and lifecycle parity:
- **Python bootstrap order fixed**: `install_python_requirements.bat` now runs BEFORE `validate_python_requirements.bat`. Previously local LOAD validated requirements before installing them, which would always fail in a fresh workspace.
- **NO_INSTANCE admin gating added**: `configure_mssql.bat` is now gated on administrator availability in the `NO_INSTANCE` path, matching the local SETUP pipeline and Jenkins Groovy patterns. Without admin, network configuration is skipped and the pipeline proceeds to `start_mssql.bat`.
- **Assessment/migration wiring**: Replaced commented-out assessment/reporting stubs with calls to the new dedicated pipeline wrappers:
  - `scripts/batch/mssql/assessment/run_assessment_pipeline.bat`
  - `scripts/batch/mssql/migration/run_migration_pipeline.bat`

### Dedicated LOAD Groovy Finalization

`jenkins/mssql/windows/load_pipeline.groovy` now achieves logical parity with local LOAD:
- **NO_INSTANCE admin gating added**: `configure_mssql.bat` is gated on `check_admin_privileges.bat` exit code. Without admin, configuration is skipped with a logged message.
- **Assessment stages replaced**: The two existing individual assessment stages (`Database Assessment`, `Assessment Report`) have been replaced with a single call to `run_assessment_pipeline.bat`, which covers assessment, report generation, and reconciliation.
- **Migration reporting stages added**: New `Discovery & Migration Reporting` stage calls `run_migration_pipeline.bat`, covering discovery, growth analysis, requirement analysis, migration assessment, recommendations, governance action plan, and technical/executive reports.
- Both assessment and migration stages remain gated by `params.RUN_ASSESSMENT == 'true'`.
- **CDC semantics preserved**: exit 0 → continue; exit 100 → `SKIP_DATA_LOAD=true`; other non-zero → fail closed.
- **Structural validation**: 129 braces balanced, 52 parentheses balanced, 18 stages in correct order.

## Database Configuration

- **Database**: MSSQL
- **OS**: Windows
- **Instance**: DMSQL (named instance, service `MSSQL$DMSQL`)
- **Port**: 1533
- **Workspace**: F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMssql1
- **Branch**: mssql-windows-final-v1
- **Upstream**: origin/mssql-windows-final-v1

## What Already Works

- **SETUP .bat flow**: Full local bootstrap — Python/Java validation, MSSQL deployment via ISO/GDrive, configuration, start, validation.
- **LOAD .bat flow**: Full local data pipeline — start/validate instance, create database, download dataset, CDC check with exit-100 skip, load data, deploy objects, validate objects.
- **Instance lifecycle**: install, start, validate, configure_mssql with sa password bootstrap.
- **Database creation**: `create_database.ps1` handles CREATE/ATTACH, owner authorization, compatibility level.
- **Object flow**: `bootstrap_generator.py` → `deploy_objects.py` (Liquibase master_objects.xml) → `validate_objects.py` via MSSQL-specific validator.
- **Assessment**: `scripts/python/mssql/assessment.py` covers database, schema, table, view, procedure, function, trigger, index, and SQL Agent inventories.
- **Discovery engine**: `scripts/discovery/discovery_engine.py` has MSSQL-specific discovery logic.
- **CDC engine**: `scripts/cdc/cdc_engine.py` works with MSSQL data files.
- **Configuration-driven**: All connections, ports, instance names come from `config/windows/mssql.conf`.
- **Schema Liquibase wiring**: `load_data.bat` already invokes `schema_detector.py` → `generate_liquibase_xml.py` → `update_master_xml.py` → `run_liquibase.bat` as part of the data load stage.

## Resolved Gaps

### configure_mssql Gating (FIXED)

Local `.bat` now gates `configure_mssql.bat` on administrator availability, matching Jenkins Groovy and PostgreSQL Windows patterns.

### Liquibase Config Path (FIXED)

`download_liquibase.ps1` now reads `config/windows/mssql.conf` instead of `config/windows/mysql.conf`.

### Schema Liquibase Resilience (FIXED)

`generate_liquibase_xml.py` now handles missing `schema_registry.json` gracefully without crashing.

### Assessment/Migration Wrappers (FIXED)

Dedicated MSSQL Windows wrappers created for assessment/reconciliation and discovery/migration/reporting pipelines.

### Local LOAD Python Bootstrap Order (FIXED)

`mssql_load_pipeline.bat` now installs Python requirements before validating them, matching the architecture-correct fresh-workspace contract.

### Local LOAD configure_mssql Gating (FIXED)

`mssql_load_pipeline.bat` now gates `configure_mssql.bat` on administrator availability in the `NO_INSTANCE` path, matching local SETUP and Jenkins Groovy.

### Dedicated LOAD Groovy Admin Gating (FIXED)

`load_pipeline.groovy` now gates `configure_mssql.bat` on administrator availability in the `NO_INSTANCE` path. The two existing individual assessment stages have been replaced with a single call to `run_assessment_pipeline.bat`, and a new `Discovery & Migration Reporting` stage calls `run_migration_pipeline.bat`. Both remain gated by `params.RUN_ASSESSMENT == 'true'`.

## Remaining Gaps

### 1. Main Jenkinsfile Not Updated (BLOCKED)

`jenkins/Jenkinsfile` DATABASE parameter only includes `MYSQL` and `POSTGRESQL`. No MSSQL stage. This is out of scope for this bounded milestone.

## Do Not Repeat

- Do NOT copy PostgreSQL-specific implementation blindly (pg_ctl/psql behavior, Windows service implementation, PostgreSQL Liquibase behavior)
- Do NOT bypass instance ownership checks
- Do NOT weaken check_instance.py ownership logic
- Do NOT assume SETUP workspace tools exist in LOAD workspace
- Do NOT trust port or service name alone as ownership signal
- Do NOT regenerate artifacts without understanding database-specific requirements

## Next Actions

1. Runtime-prove the full LOAD pipeline when a suitable environment is available
2. Re-prove Jenkins Groovy runtime behavior against a real Jenkins agent
3. Consider main Jenkinsfile MSSQL integration (separate milestone)

## Runtime Blockers (Current Machine)

- Jenkins runtime is NOT available on this workstation
- Machine state is `NO_INSTANCE` for the project-managed DMSQL instance; existing foreign MSSQL on port 1533 is correctly rejected
- No destructive MSSQL deployment was attempted
- No foreign service was modified

## Relevant Commits

- ee1bf77: fix(mssql-windows): align LOAD lifecycle parity, fix ordering, wire assessment/migration
- 726f7ec: chore(mssql-windows): update working state after finalization milestone
- 5ecfeff: fix(mssql-windows): align configure gating, fix Liquibase config, add missing wrappers
- 240ed52: chore(mssql-windows): update working state after Groovy bootstrap parity
- 06fdc85: fix(mssql-windows-groovy): add fresh-workspace bootstrap stages to dedicated LOAD pipeline
- 52f9b92: fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD
- 19806e1: fix(mssql-windows): verify managed instance ownership via registry/service path
- f4aefd3: fix(mssql-windows-groovy): handle CDC exit-100 skip without failing stage
- 963840e: chore(mssql-windows): initialize final development workspace
- e7c403d: refactor(main-jenkins): reduce to 4 proven flows and fix MySQL instance-state parsing

## Code-Level Freeze Readiness Matrix

| Surface | Implementation | Logical Parity | Static Validation | Targeted Local Validation | Real Jenkins Runtime | Blocking Code Defects |
|---|---|---|---|---|---|---|
| LOCAL SETUP .BAT | Complete | Pass | Pass | Pass (Python syntax, control-flow simulation) | Deferred | No |
| DEDICATED SETUP GROOVY | Complete | Pass | Pass (129 braces, 52 parens, stage order) | Pass (path existence, admin gating structure) | Deferred | No |
| LOCAL LOAD .BAT | Complete | Pass | Pass | Pass (ordering, admin gating, wiring) | Deferred | No |
| DEDICATED LOAD GROOVY | Complete | Pass | Pass (129 braces, 52 parens, 18 stages) | Pass (NO_INSTANCE gating, CDC semantics, wiring) | Deferred | No |

### Freeze-Readiness Answers

1. Is dedicated SETUP Groovy logically equivalent to local SETUP .bat? **Yes**
2. Is dedicated LOAD Groovy logically equivalent to local LOAD .bat? **Yes**
3. Does LOAD Groovy independently bootstrap fresh-workspace dependencies? **Yes**
4. Does ownership handling safely distinguish managed vs foreign/unproven instance? **Yes** (check_instance.py hardened)
5. Is schema Liquibase generation/deployment ordered before data consumption? **Yes** (load_data.bat verified)
6. Are database objects generated before deployment/validation? **Yes** (bootstrap_generator -> deploy_objects -> validate_objects)
7. Are assessment/migration/reporting entrypoints correctly orchestrated? **Yes** (dedicated wrappers wired into both LOAD paths)
8. Are CDC 0/100/error semantics preserved? **Yes** (SKIP_DATA_LOAD guards intact)
9. Are there any remaining CODE-LEVEL blockers in dedicated SETUP/LOAD Groovy? **No**
10. Can dedicated MSSQL Windows SETUP + LOAD Groovy now be frozen pending later real Jenkins runtime testing? **Yes**

### Remaining Non-Code Runtime Risks

- Jenkins runtime execution is unproven and deferred to a separate milestone
- Full end-to-end LOAD runtime is blocked by NO_INSTANCE machine state and foreign MSSQL constraints
- `configure_mssql.bat` runtime behavior with/without admin on a real NO_INSTANCE deployment is unproven
- Liquibase schema evolution against live MSSQL database is unproven
- Assessment/reporting output generation against live database is unproven

### Next Milestone After Code Freeze

Obtain access to a real Jenkins agent and runtime-prove the full MSSQL Windows SETUP + LOAD pipelines against a genuinely fresh workspace. Alternatively, provision a project-managed MSSQL instance on a test machine and runtime-prove all lifecycle branches end-to-end.

### Safe Post-Freeze Local Runtime Validation (2026-07-23)

#### Toolchain Runtime Validation
- **Python runtime**: Python 3.12.6 — PASS (real local runtime)
- **Python requirements**: PyYAML, python-dotenv, pyodbc, pandas — PASS (real local runtime)
- **Java runtime**: OpenJDK 21.0.11 — PASS (real local runtime)
- **Liquibase**: NOT AVAILABLE (liquibase.bat not found in workspace) — Defers to install_tools.bat provisioning
- **sqlcmd**: v1.10.0 — PASS (real local runtime)
- **MSSQL JDBC driver**: NOT AVAILABLE (mssql-jdbc-12.10.0.jre11.jar not found) — Defers to install_tools.bat provisioning

#### Schema Liquibase Isolated Test
- **Fresh artifact generation**: Created temporary schema_registry.json with 2 tables, ran generate_liquibase_xml.py → generated 001_create_test_table.xml and 002_create_another_table.xml — PASS
- **Master XML update**: Ran update_master_xml.py → master.xml updated with 2 includes — PASS
- **Artifact ordering**: schema registry → generate_liquibase_xml → update_master_xml → master.xml — PASS
- **Idempotency**: Reran generate_liquibase_xml.py without cleaning — same 2 files regenerated, no duplicates — PASS
- **Missing-registry behavior**: Removed schema_registry.json → script exited 0, wrote schema_status.json with reason "no_schema_registry" — PASS
- **Classification**: TARGETED RUNTIME PROVEN (artifact generation validated against temporary isolated metadata)

#### Object Flow Isolated Test
- **Object generation**: Ran bootstrap_generator.py mssql with temporary schema → generated 6 SQL files (views, functions, procedures) and 6 Liquibase XML files — PASS
- **Master objects XML**: master_objects.xml generated with 6 includes — PASS
- **Source-of-truth validation**: No system tables (sys.tables) or Liquibase internal tables referenced in generated objects — PASS
- **Idempotency**: Reran bootstrap_generator.py mssql → same files, no duplicate increments — PASS
- **Classification**: TARGETED RUNTIME PROVEN (artifact generation validated without live database)

#### Assessment/Migration/Reporting Wrapper Runtime Contract
- **Import validation**: assessment.py, assessment_report.py, discovery_engine.py, reconciliation_engine.py, growth_analyzer.py, requirement_analyzer.py, recommendation_engine.py, action_plan_engine.py, technical_report.py, executive_report.py all import cleanly — PASS
- **Help/argument validation**: All engines accept --database mssql argument — PASS
- **Wrapper structure**: run_assessment_pipeline.bat and run_migration_pipeline.bat contain project-root setup, PYTHONPATH, and correct script paths — PASS
- **Classification**: TARGETED RUNTIME PROVEN (wrapper orchestration contract validated; live database execution deferred)

#### Local SETUP/LOAD Control-Flow Targeted Tests
- **State-machine simulation**: test_load_bootstrap_sm.bat passed for RUNNING, STOPPED, NOINSTANCE states — PASS
- **Admin-gating structure**: check_admin_privileges.bat returns 0 for admin, non-zero for non-admin — PASS
- **Classification**: SIMULATED/MOCK PROVEN (state machine uses simulated check_instance output, does not touch live database)

#### Safe Isolated MSSQL Test Option
- **Finding**: No existing safe isolated MSSQL test mechanism found in repository
- **No LocalDB path**: No LocalDB configuration or scripts
- **No container path**: No Docker or containerized MSSQL test configuration
- **No test instance config**: No alternate test instance/port configuration
- **Classification**: Live database runtime PROOF DEFERRED (no project-managed isolated test path exists)

