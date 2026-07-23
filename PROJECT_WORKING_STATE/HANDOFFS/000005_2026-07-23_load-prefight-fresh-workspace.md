# HANDOFF 000005

## TASK
Make the local MongoDB Windows LOAD .bat flow safe for separate/fresh workspaces by adding correct instance preflight/discovery before load execution.

## DATABASE
MongoDB

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMongo1

## BRANCH
mongodb-windows-final-v1

## STARTING_HEAD
`12162169e75a86ae14de103f70387f21bd2cd6eb`
- Commit: `chore(mongodb-windows): initialize final development workspace`

## ENDING_HEAD
`12162169e75a86ae14de103f70387f21bd2cd6eb`
- Read-only audit baseline plus targeted implementation (doc updates pending commit)

## GOAL
Allow LOAD to run in a fresh Jenkins workspace that did not run SETUP, while safely discovering and reusing a managed MongoDB instance created by SETUP in another workspace. LOAD must never blindly call a missing local mongod.exe.

## LOAD_PREFLIGHT_ROOT_CAUSE
`scripts/batch/mongodb/mongodb_load_pipeline.bat` unconditionally called `start_mongodb.bat` at line 52 without first checking instance state. In a fresh workspace without `databases\mongodb\server\bin\mongod.exe`, this would fail immediately. Additionally, `check_instance.py` previously returned `NO_INSTANCE` when local binaries were absent, even if a durable `MongoDBAutomation` service from another workspace existed but was stopped.

## STATE_CONTRACT_AUDIT
Existing states expected by consumers:
- `INSTANCE_RUNNING_AND_USABLE` — SETUP reuses, LOAD reuses
- `INSTANCE_INSTALLED_BUT_STOPPED` — SETUP starts, LOAD starts
- `NO_INSTANCE` — SETUP deploys, LOAD fails
- `PORT_OCCUPIED_BY_NON_MONGODB` — both fail safely

Gap found: In a fresh workspace, `INSTANCE_INSTALLED_BUT_STOPPED` was unreachable when local binaries were absent, because the old logic only checked `PROJECT_BINARIES_EXIST`. This meant a stopped durable service from another workspace would be misclassified as `NO_INSTANCE`, causing LOAD to fail instead of safely starting the managed service.

Fix applied: `check_instance.py` now checks durable service existence first when port is closed. Service presence alone is sufficient to return `INSTANCE_INSTALLED_BUT_STOPPED`, making the stateFresh-workspace-safe without breaking existing same-workspace behavior.

## LOAD_PREFLIGHT_STATE_MACHINE
`scripts/batch/mongodb/mongodb_load_pipeline.bat` now implements:

```
CHECK INSTANCE STATE
  |
  +-- INSTANCE_RUNNING_AND_USABLE --> skip start --> validate_mongodb --> load --> validate_loaded_data --> exit 0
  |
  +-- INSTANCE_INSTALLED_BUT_STOPPED --> call start_mongodb.bat --> validate_mongodb --> load --> validate_loaded_data --> exit 0
  |
  +-- NO_INSTANCE --> ERROR "Run SETUP first" --> exit /b 1
  |
  +-- PORT_OCCUPIED_BY_NON_MONGODB --> ERROR "Foreign process detected" --> exit /b 1
  |
  +-- unexpected --> ERROR "Unexpected instance state" --> exit /b 1
```

## RUNNING_MANAGED_BEHAVIOR
When `check_instance.py` returns `INSTANCE_RUNNING_AND_USABLE`:
- LOAD .bat skips `start_mongodb.bat` entirely.
- No duplicate mongod process is started.
- Flow proceeds directly to `validate_mongodb.bat`.
- This is safe for both same-workspace and cross-workspace managed instances because ownership was already verified by `check_instance.py` using the durable service anchor.

## STOPPED_DURABLE_SERVICE_BEHAVIOR
When `check_instance.py` returns `INSTANCE_INSTALLED_BUT_STOPPED`:
- LOAD .bat calls `start_mongodb.bat`.
- `start_mongodb.bat` invokes `start_mongodb.ps1`.
- `start_mongodb.ps1` detects that port is free and `MongoDBAutomation` service exists.
- If service is `Stopped`: calls `Start-Service -Name MongoDBAutomation`, waits for service status `Running`, waits for port to listen, exits 0.
- If service is `Running` but port not listening: waits briefly, rechecks port, fails with diagnostics if still not ready.
- If service is in unexpected state (Disabled, Paused, etc.): throws clear error.
- This path does NOT require `databases\mongodb\server\bin\mongod.exe` to exist in the current workspace. It uses the service's own configured binary path.

## NO_INSTANCE_BEHAVIOR
When `check_instance.py` returns `NO_INSTANCE`:
- LOAD .bat prints: `ERROR: No managed MongoDB instance found. Run SETUP first to deploy and configure MongoDB.`
- If `INST_ERROR` is populated, prints details.
- Exits `/b 1`.
- No deployment, no terraform, no installation is attempted. LOAD never silently performs SETUP work.

## FOREIGN_LISTENER_BEHAVIOR
When `check_instance.py` returns `PORT_OCCUPIED_BY_NON_MONGODB`:
- LOAD .bat prints: `ERROR: Foreign process detected on MongoDB port <port>.`
- Prints `INST_ERROR` details if present.
- Prints: `Aborting LOAD to avoid deploying over or reusing an unmanaged listener.`
- Exits `/b 1`.
- Foreign process is never killed, stopped, or modified.

## STALE_ARTIFACT_BEHAVIOR
- Stale `databases\mongodb\server\bin\mongod.exe` or `data` directory alone do not create false ownership.
- `check_instance.py` only returns `INSTANCE_INSTALLED_BUT_STOPPED` for stale artifacts if no durable service exists AND local binaries exist (same-workspace legacy behavior preserved).
- In fresh workspace with stale artifacts but no service: `NO_INSTANCE` (because `PROJECT_BINARIES_EXIST` is FALSE in fresh workspace).

## LOCAL_NON_SERVICE_MODE
If a managed mongod is running directly (no Windows service) and its executable path matches the current workspace's `databases\mongodb\server\bin\mongod.exe`:
- `check_instance.py` returns `INSTANCE_RUNNING_AND_USABLE` via the workspace-local fallback path check.
- `start_mongodb.ps1` would also recognize and reuse it via the same fallback.
- This preserves existing non-service local behavior.

If a managed mongod is running from a different path with no service:
- Rejected as foreign. This is intentional: without durable service evidence, cross-path trust is unsafe.

## RUNTIME_ARTIFACT_AUDIT
Artifacts required BEFORE LOAD data stages begin:
- `config/windows/mongodb.conf` — git-tracked, read by `check_instance.py` and `start_mongodb.ps1` for host/port. No runtime generation needed.
- `MongoDBAutomation` Windows service — created by SETUP, machine-level durable anchor. Not runtime-generated per-workspace.
- No `schema_registry.json` or `cdc_status.json` required for preflight. These are generated later by `schema_detector.py` during `load_data.bat`.
- Dataset/incoming files are downloaded/validated inside `load_data.bat` or Groovy's Download Dataset stage.

Downstream fresh-workspace artifacts (out of scope for this task):
- `metadata/mongodb/schema_registry.json`
- `metadata/mongodb/cdc_status.json`
- `datasets/mongodb/*.csv`
- These are generated by existing load flow once instance preflight passes.

## IMPLEMENTATION_CHANGES
`scripts/python/mongodb/setup/check_instance.py`:
- Added `_get_service_status(service_name)` helper using PowerShell `Get-Service`.
- Updated port-closed branch in `check()`: when `_get_service_status("MongoDBAutomation")` returns any status, classify as `INSTANCE_INSTALLED_BUT_STOPPED` regardless of local binary existence.
- Existing keys and state contract preserved.

`scripts/powershell/mongodb/start_mongodb.ps1`:
- Added durable service discovery block after port-free detection.
- If `MongoDBAutomation` service exists:
  - `Running` but port not listening -> wait + recheck, fail with diagnostics if still down.
  - `Stopped` -> `Start-Service`, wait for `Running`, wait for port, exit 0.
  - Other status -> throw clear error.
- Does NOT require local `mongod.exe` to exist when starting via service.
- Existing direct-start path preserved when no service exists.

`scripts/batch/mongodb/mongodb_load_pipeline.bat`:
- Added instance preflight using `check_instance.bat` before `start_mongodb.bat`.
- Parses `INST_INSTANCE_STATE` and branches:
  - `INSTANCE_RUNNING_AND_USABLE` -> skip start, go to `:validate_mongodb`
  - `INSTANCE_INSTALLED_BUT_STOPPED` -> call `start_mongodb.bat`, then validate
  - `NO_INSTANCE` -> clear failure message, exit 1
  - `PORT_OCCUPIED_BY_NON_MONGODB` -> clear failure with diagnostics, exit 1
  - unexpected -> error, exit 1
- Existing validation, load, and post-load validation stages preserved after preflight.

`scripts/python/mongodb/setup/test_ownership.py`:
- Added Scenario 7: `_get_service_status` real tests (service present/absent).
- Added Scenario 8: fresh workspace stopped service state logic documented and verified via code inspection.
- Added Scenario 9: LOAD preflight state machine documented.

## TARGETED_TESTS

### SCENARIO_RUNNING_MANAGED:
REAL + SIMULATED (PASS).
- Real: foreign listener on 27019 correctly rejected.
- Real: free port 65432 correctly detected.
- Simulated: cross-workspace service-anchor acceptance/rejection verified via mocks.
- UNPROVEN: actual live running managed instance (binary absent).
- LOAD preflight: documented that `INSTANCE_RUNNING_AND_USABLE` skips start and proceeds to validation.

### SCENARIO_STOPPED_CROSS_WORKSPACE:
SIMULATED + DOCUMENTED (PASS).
- `_get_service_status` returns `None` when service absent (REAL PASS).
- Code inspection verified: when `_get_service_status("MongoDBAutomation")` returns `"Stopped"` and port is closed, `check_instance.py` returns `INSTANCE_INSTALLED_BUT_STOPPED`.
- `start_mongodb.ps1` service-start path is PowerShell-trivial (`Start-Service` + wait loop) but not executed live (UNPROVEN).
- LOAD .bat would call `start_mongodb.bat` for `INSTANCE_INSTALLED_BUT_STOPPED`, which would start the service.

### SCENARIO_NO_INSTANCE:
REAL + SIMULATED (PASS).
- Real: stale artifacts on free port do not fake ownership.
- Simulated/Documented: when no service exists and no local binaries exist, `check_instance.py` returns `NO_INSTANCE`.
- LOAD .bat aborts with clear `ERROR: No managed MongoDB instance found. Run SETUP first...`

### SCENARIO_FOREIGN_LISTENER:
REAL (PASS).
- Port 27019 PID 4908 correctly identified as foreign.
- `check_instance.py` returns `PORT_OCCUPIED_BY_NON_MONGODB`.
- LOAD .bat would abort with diagnostics.

### SCENARIO_STALE_ARTIFACTS:
REAL (PASS).
- Dummy binaries/data on free port.
- `_is_project_owned(None)` returns False.
- `check_instance.py` classifies based on actual runtime evidence, not stale files.

## FILES_CHANGED:
- `scripts/python/mongodb/setup/check_instance.py` (MODIFIED)
- `scripts/powershell/mongodb/start_mongodb.ps1` (MODIFIED)
- `scripts/batch/mongodb/mongodb_load_pipeline.bat` (MODIFIED)
- `scripts/python/mongodb/setup/test_ownership.py` (MODIFIED - targeted validation)
- `PROJECT_WORKING_STATE/CURRENT_STATE.md` (MODIFIED)
- `PROJECT_WORKING_STATE/HANDOFFS/000005_2026-07-23_load-prefight-fresh-workspace.md` (ADDED)

## WORKING_STATE_UPDATED:
Yes - `PROJECT_WORKING_STATE/CURRENT_STATE.md` updated with LOAD preflight state machine, fresh workspace safety status, and updated next actions.

## HANDOFF_CREATED:
Yes - `PROJECT_WORKING_STATE/HANDOFFS/000005_2026-07-23_load-prefight-fresh-workspace.md` created.

## REMAINING_RISKS:
1. **UNPROVEN**: Same-workspace owned-instance reuse with actual running mongod.exe binary live test.
2. **UNPROVEN**: `start_mongodb.ps1` service-start path (`Start-Service MongoDBAutomation`) not executed live. Requires actual installed service for proof.
3. **MEDIUM**: Pre-existing Groovy `setup_pipeline.groovy` validation stages do not re-check ownership after `check_instance.py`.
4. **MEDIUM**: LOAD Groovy (`jenkins/mongodb/windows/load_pipeline.groovy`) still does not invoke `check_instance.py` or `start_mongodb.ps1`. Groovy-side LOAD preflight is out of scope but remains a gap.
5. **LOW**: `_get_service_status` could return unexpected states (Disabled, Paused). `start_mongodb.ps1` handles these with clear errors.
6. **LOW**: Downstream fresh-workspace artifacts (schema_registry.json, datasets) still need attention but are out of scope for this task.

## RECOMMENDED_NEXT_SINGLE_TASK:
Close the remaining BAT/Groovy parity gap by aligning the Groovy LOAD pipeline's instance preflight with the local .bat, or verify that Groovy LOAD can safely reuse the managed instance without local binary dependencies.

## READY_FOR_NEXT_STAGE:
No - local LOAD preflight is now safe for fresh workspaces, but Groovy-side LOAD parity remains out of scope and unaddressed.
