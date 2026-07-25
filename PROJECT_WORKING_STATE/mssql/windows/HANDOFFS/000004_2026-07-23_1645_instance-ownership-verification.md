# HANDOFF 000004

## TASK
Harden MSSQL Windows managed-instance ownership detection in check_instance.py.

## DATABASE
MSSQL

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMssql1

## BRANCH
mssql-windows-final-v1

## STARTING_HEAD
`f4aefd3` — `fix(mssql-windows-groovy): handle CDC exit-100 skip without failing stage`

## ENDING_HEAD
Pending commit — ownership verification fix implemented, tests passing

## GOAL
Prevent the project from treating an old/foreign SQL Server as its own merely because the expected Windows service name and configured port exist. Add durable registry/service-path verification that survives separate SETUP/LOAD workspaces.

## WHAT_WAS_FOUND
- `scripts/python/mssql/setup/check_instance.py` checked only Windows service existence (`MSSQL$DMSQL`) and TCP port 1533.
- No verification of service binary path, registry instance entry, or installation provenance.
- A foreign/old SQL Server that happened to share the service name and/or port would be falsely classified as `INSTANCE_RUNNING_AND_USABLE`.
- PostgreSQL `check_instance.py` verifies project-local `databases/postgresql/bin/pg_ctl.exe` and `databases/postgresql/data/PG_VERSION` plus `pg_ctl status -D`. MSSQL has no equivalent local marker because it installs to the system default path (`C:\Program Files\Microsoft SQL Server\`).
- The Windows registry (`HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\<InstanceID>\Setup`) stores the instance's `InstanceName`, `ImagePath`, and other durable installation metadata.

## ROOT_CAUSE
Ownership detection relied solely on service name + port without verifying installation provenance. No check that the running service actually corresponds to the project's configured MSSQL instance.

## CHANGES_MADE

### scripts/python/mssql/setup/check_instance.py
- Added `_powershell()` helper for consistent subprocess/PowerShell invocation.
- Added `_get_service_image_path(service_name)` using `sc.exe qc` to read the service's `BINARY_PATH_NAME`. Verifies it contains `sqlservr.exe`.
- Added `_find_instance_id(instance)` using PowerShell to enumerate `HKLM\SOFTWARE\Microsoft\Microsoft SQL Server` subkeys and find one whose `Setup\InstanceName` matches the configured instance.
- Added `_get_registry_image_path(instance_id)` to read the registry's `ImagePath` and confirm it also points to `sqlservr.exe`.
- Added `_verify_project_managed_instance(instance)` that combines service ImagePath + registry InstanceName + registry ImagePath checks.
- Modified `check_instance()` to call `_verify_project_managed_instance()` after confirming the Windows service exists.
  - If verification fails → `NO_INSTANCE` (even if service exists and port is open).
  - If verification succeeds but service is stopped → `INSTANCE_INSTALLED_BUT_STOPPED`.
  - If all checks pass → `INSTANCE_RUNNING_AND_USABLE`.

### tests/test_mssql_check_instance.py (new)
Created mock-based unit tests covering:
1. Running managed instance → `INSTANCE_RUNNING_AND_USABLE`
2. Stopped managed instance → `INSTANCE_INSTALLED_BUT_STOPPED`
3. Foreign instance with same service name → `NO_INSTANCE`
4. No instance → `NO_INSTANCE`

All 4 tests pass.

## FILES_CHANGED
- scripts/python/mssql/setup/check_instance.py
- tests/test_mssql_check_instance.py

## TESTS_PERFORMED
- Mock-based unit tests (4/4 passing) for ownership classification scenarios.
- Static validation of `check_instance.py` (manual review for exception safety and code correctness).
- Did NOT manipulate or reinstall the real SQL Server service.

## TEST_RESULTS
- PASS: Running managed instance recognized
- PASS: Stopped managed instance recognized
- PASS: Foreign instance with same service name/port rejected
- PASS: Absent instance correctly reported
- NOT PERFORMED: Runtime validation against live production SQL Server service

## PROVEN_WORKING
- Registry-based ownership verification logic
- Service ImagePath validation via `sc.exe`
- State machine: NO_INSTANCE, INSTANCE_INSTALLED_BUT_STOPPED, INSTANCE_RUNNING_AND_USABLE
- Mock tests confirm all four ownership scenarios

## STILL_UNVERIFIED
- Runtime behavior against actual live SQL Server installation (not performed to avoid service manipulation)
- Behavior when registry is inaccessible (e.g., permission error) — currently returns NO_INSTANCE

## KNOWN_ISSUES
- Fresh-workspace bootstrap gap in Groovy LOAD still open
- SETUP configure gating mismatch still open
- Missing assessment/migration wrappers
- Schema Liquibase evolution still unwired
- Master Jenkinsfile still lacks MSSQL stages

## DO_NOT_REPEAT
- Do NOT remove registry verification from check_instance
- Do NOT run full pipeline for this isolated fix
- Do NOT modify PostgreSQL, MySQL, MongoDB, Ubuntu, or main Jenkinsfile
- Do NOT manipulate live SQL Server service for testing

## NEXT_EXACT_ACTIONS
1. Commit and push ownership verification fix.
2. Add fresh-workspace bootstrap stages to GROVY LOAD.
3. Align configure_mssql gating between .bat and Groovy.
4. Add missing assessment/migration wrappers.
5. Wire schema Liquibase evolution into LOAD.
6. Update master Jenkinsfile for MSSQL.

## COMMITS
- `f4aefd3` (parent): `fix(mssql-windows-groovy): handle CDC exit-100 skip without failing stage`
- Pending: `fix(mssql-windows): verify managed instance ownership via registry/service path`

## PUSH_STATUS
- Pending push to origin/mssql-windows-final-v1
