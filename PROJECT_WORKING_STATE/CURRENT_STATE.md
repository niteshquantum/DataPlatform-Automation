# CURRENT STATE

Last updated: 2026-07-23 17:22 IST

## Repository Baseline

- **Branch**: mssql-windows-final-v1
- **HEAD**: `52f9b92` (dirty — uncommitted Groovy parity fix)
- **Commit message**: `fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD`
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

## Proven Gaps

### 1. SETUP Configure Gating Difference (NOT YET FIXED)

Local `.bat` runs `configure_mssql.bat` for `NO_INSTANCE` unconditionally. Groovy only runs it when `admin_status.txt == true`. Without admin, Groovy may leave MSSQL unconfigured.

### 2. Missing Assessment/Migration Wrappers (NOT YET FIXED)

Local `.bat` runs `configure_mssql.bat` for `NO_INSTANCE` unconditionally. Groovy only runs it when `admin_status.txt == true`. Without admin, Groovy may leave MSSQL unconfigured.

### 3. Missing Assessment/Migration Wrappers (NOT YET FIXED)

- No `scripts/batch/mssql/assessment/run_assessment_pipeline.bat` (PostgreSQL has it)
- No `scripts/batch/mssql/migration/` folder entirely
- Groovy LOAD has conditional assessment stages but underlying wrappers are absent

### 6. Schema Liquibase Evolution Not Wired (NOT YET FIXED)

`generate_liquibase_xml.py` and `update_master_xml.py` exist but are **never called** from any `.bat` or Groovy pipeline. `run_liquibase.bat` exists but is not invoked for schema evolution in the current LOAD flow.

### 7. Main Jenkinsfile Not Updated (NOT YET FIXED)

`jenkins/Jenkinsfile` DATABASE parameter only includes `MYSQL` and `POSTGRESQL`. No MSSQL stage.

## Pending Implementation

- Align configure_mssql gating between .bat and Groovy
- Add missing `run_assessment_pipeline.bat` and `run_migration_pipeline.bat` for MSSQL
- Wire schema Liquibase evolution into LOAD flow
- Add MSSQL stages to master Jenkinsfile

## Do Not Repeat

- Do NOT copy PostgreSQL-specific implementation blindly (pg_ctl/psql behavior, Windows service implementation, PostgreSQL Liquibase behavior)
- Do NOT bypass instance ownership checks
- Do NOT weaken check_instance.py ownership logic
- Do NOT assume SETUP workspace tools exist in LOAD workspace
- Do NOT trust port or service name alone as ownership signal
- Do NOT regenerate artifacts without understanding database-specific requirements

## Next Actions

1. Align configure_mssql gating between .bat and Groovy
2. Add missing assessment/migration pipeline wrappers
3. Wire schema Liquibase evolution into LOAD flow
4. Update master Jenkinsfile for MSSQL

## Relevant Commits

- 52f9b92: fix(mssql-windows): bootstrap fresh-workspace dependencies and instance resolution in local LOAD
- f4aefd3: fix(mssql-windows-groovy): handle CDC exit-100 skip without failing stage
- 19806e1: fix(mssql-windows): verify managed instance ownership via registry/service path
- 963840e: chore(mssql-windows): initialize final development workspace
- e7c403d: refactor(main-jenkins): reduce to 4 proven flows and fix MySQL instance-state parsing
