# CURRENT STATE

Last updated: 2026-07-23 16:23 IST

## Repository Baseline

- **Branch**: mssql-windows-final-v1
- **HEAD**: `963840e` (dirty — uncommitted CDC fix)
- **Commit message**: `chore(mssql-windows): initialize final development workspace`
- **Baseline branch**: windows-pipeline-integration-v1
- **Baseline SHA**: `e7c403d9791b4f8aab16f1fe9ed17a37540ff1db`

## Audit Status

**COMPLETED** — MSSQL Windows implementation audited against PostgreSQL Windows proven reference.
**FIX IN PROGRESS** — CDC exit-100 propagation bug being fixed.

## Implemented Fixes

### CDC Exit-100 Propagation (LOAD Groovy)

`jenkins/mssql/windows/load_pipeline.groovy` CDC stage changed from `runTrackedStage` to explicit `bat(returnStatus: true)` with manual logging:
- exit 0 → log SUCCESS, continue pipeline
- exit 100 → log SUCCESS, set `env.SKIP_DATA_LOAD = 'true'`, continue pipeline
- other non-zero → log FAILURE, call `set-error`, `error` to fail stage
- `Load Data` and `Validate Loaded Data` stages now have `when { env.SKIP_DATA_LOAD != 'true' }` guards

Matches proven local .bat semantics and PostgreSQL Groovy pattern.

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

### 1. Instance Ownership Verification (CRITICAL — NOT YET FIXED)

`scripts/python/mssql/setup/check_instance.py` only checks:
- Windows service existence (`MSSQL$DMSQL`)
- TCP port 1533 listening

It does **NOT** verify:
- Project-managed binary path
- Project-managed data directory
- Instance-specific installation provenance
- Service executable identity

**Risk**: Old/foreign SQL Server on port 1533 passes as `INSTANCE_RUNNING_AND_USABLE`. `PORT OPEN != MANAGED INSTANCE OWNERSHIP`.

### 2. Fresh Workspace Safety in Groovy LOAD (CRITICAL — NOT YET FIXED)

Local `.bat` LOAD validates/installs Python requirements, tools, starts MSSQL, and validates MSSQL before data operations. The dedicated Jenkins Groovy LOAD pipeline (`jenkins/mssql/windows/load_pipeline.groovy`) **skips all these steps**.

If SETUP and LOAD execute in different Jenkins workspaces, LOAD will fail because:
- Python requirements not installed
- Tools/liquibase/JDBC driver not installed
- MSSQL instance not started/validated

### 3. SETUP Configure Gating Difference (NOT YET FIXED)

Local `.bat` runs `configure_mssql.bat` for `NO_INSTANCE` unconditionally. Groovy only runs it when `admin_status.txt == true`. Without admin, Groovy may leave MSSQL unconfigured.

### 4. CDC Fix (COMPLETED)

Exit-100 propagation bug fixed in `jenkins/mssql/windows/load_pipeline.groovy`.

### 5. Missing Assessment/Migration Wrappers (NOT YET FIXED)

- No `scripts/batch/mssql/assessment/run_assessment_pipeline.bat` (PostgreSQL has it)
- No `scripts/batch/mssql/migration/` folder entirely
- Groovy LOAD has conditional assessment stages but underlying wrappers are absent

### 6. Schema Liquibase Evolution Not Wired (NOT YET FIXED)

`generate_liquibase_xml.py` and `update_master_xml.py` exist but are **never called** from any `.bat` or Groovy pipeline. `run_liquibase.bat` exists but is not invoked for schema evolution in the current LOAD flow.

### 7. Main Jenkinsfile Not Updated (NOT YET FIXED)

`jenkins/Jenkinsfile` DATABASE parameter only includes `MYSQL` and `POSTGRESQL`. No MSSQL stage.

## Pending Implementation

- Fix `check_instance.py` to verify project instance ownership
- Add fresh-workspace bootstrap to MSSQL Groovy LOAD (validate Python, install tools, start/validate MSSQL)
- Align configure_mssql gating between .bat and Groovy
- Add missing `run_assessment_pipeline.bat` and `run_migration_pipeline.bat` for MSSQL
- Wire schema Liquibase evolution into LOAD flow
- Add MSSQL stages to master Jenkinsfile

## Do Not Repeat

- Do NOT copy PostgreSQL-specific implementation blindly (pg_ctl/psql behavior, Windows service implementation, PostgreSQL Liquibase behavior)
- Do NOT bypass instance ownership checks
- Do NOT assume SETUP workspace tools exist in LOAD workspace
- Do NOT regenerate artifacts without understanding database-specific requirements

## Next Actions

1. Add fresh-workspace bootstrap to MSSQL Groovy LOAD
2. Implement MSSQL instance ownership verification in check_instance.py
3. Align configure_mssql gating between .bat and Groovy
4. Add missing assessment/migration pipeline wrappers
5. Wire schema Liquibase evolution into LOAD
6. Update master Jenkinsfile for MSSQL

## Relevant Commits

- 963840e: chore(mssql-windows): initialize final development workspace
- e7c403d: refactor(main-jenkins): reduce to 4 proven flows and fix MySQL instance-state parsing
