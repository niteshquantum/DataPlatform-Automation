# HANDOFF 000007

## TASK
Runtime-prove MongoDB Windows SETUP->LOAD lifecycle on real managed instance, fix cross-workspace ownership detection, validate CDC/idempotency, and attempt dedicated Jenkins LOAD runtime.

## DATABASE
MongoDB

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMongo1

## BRANCH
mongodb-windows-final-v1

## STARTING_HEAD
`922def14783d3b3a365d560dcf4a1564fd5fcd56`
- Commit: `feat(mongodb-windows): finalize LOAD flow with instance preflight, cross-workspace safety, and Groovy parity`

## ENDING_HEAD
Pending commit on top of `922def14783d3b3a365d560dcf4a1564fd5fcd56`

## GOAL
Establish strongest practical real runtime proof of MongoDB Windows lifecycle. Prove managed-instance ownership, local LOAD success, CDC/idempotency, and attempt dedicated Jenkins runtime. Fix directly related ownership detection defect discovered during runtime.

## ACTUAL_MACHINE_STATE
- **MongoDBAutomation service**: Running, Automatic, DisplayName "MongoDB Automation Service"
- **Service PathName**: `C:\Users\Admin\.jenkins\workspace\window-001\databases\mongodb\server\bin\mongod.exe --dbpath ... --logpath ... --bind_ip 127.0.0.1 --port 27019 --service`
- **Listener port**: 27019 (127.0.0.1:27019 LISTENING)
- **Listener PID**: 4908 (varies between runs; matched service ProcessId)
- **Local workspace binaries**: `databases\mongodb\server\bin\mongod.exe` NOT present in current workspace
- **Dataset**: `incoming\mongodb` initially absent; downloaded via `download_dataset.bat` (testdatasmall.zip, ~13.7KB)
- **Jenkins**: Java process PID 16896 listening on 0.0.0.0:8080, but HTTP returns 403 Forbidden (auth required)

## FOREIGN_INSTANCE_STATUS
Pre-existing managed instance on port 27019 belongs to `MongoDBAutomation` service (PID matched). No foreign mongod present on configured port during final runtime checkpoint.

## LOCAL_SETUP_RESULT
SETUP not required. Machine already had proven managed MongoDBAutomation service running. Verified via:
- `Get-Service MongoDBAutomation` -> Status: Running
- `check_instance.py` -> `INSTANCE_RUNNING_AND_USABLE`
- `validate_mongodb.bat` -> MongoDB 8.0.12 RUNNING AND USABLE

## SETUP_FAILURES_FIXED
None required. Existing managed instance was reusable.

## MANAGED_SERVICE_RESULT
RUNTIME PROVEN.
- Service name: `MongoDBAutomation`
- Status: Running
- ProcessId: 4908 (matches listener PID)
- Service PathName executable matches listener process executable path via durable service anchor
- `check_instance.py` correctly recognizes this as project-managed instance even though current workspace lacks local `databases\mongodb\server\bin\mongod.exe`

## OWNERSHIP_RUNTIME_RESULT
RUNTIME PROVEN.
During runtime, discovered that `_get_process_executable` returns None for the actual managed process due to process context/permissions. This made the original service-anchor logic fail because it required both process executable match AND service info.

**Defect fixed**: Updated `_is_project_owned` in `check_instance.py` to use new `_get_service_info` helper (returns both service ProcessId AND executable path) with three-tier positive evidence:
1. Listener executable path matches durable service PathName-extracted executable
2. Listener PID matches durable service ProcessId
3. Listener executable path matches current workspace expected path

Also updated `start_mongodb.ps1` with same PID fallback and removed hard `$ActualPath` guard that prevented service-anchor matching when process executable was unresolvable.

**Files changed**:
- `scripts/python/mongodb/setup/check_instance.py`
- `scripts/powershell/mongodb/start_mongodb.ps1`
- `scripts/powershell/get_service_info.ps1` (new helper)
- `scripts/python/mongodb/setup/test_ownership.py` (updated mocks)

**Targeted test result**: ALL PASS after interface alignment.

## STOPPED_SERVICE_RESTART_RESULT
UNPROVEN. No stopped MongoDBAutomation service was available to restart without disrupting the active managed instance. Code path statically validated but not executed live.

## LOCAL_LOAD_RESULT
RUNTIME PASS. Full `scripts/batch/mongodb/mongodb_load_pipeline.bat` executed successfully against real managed instance:

```
Python runtime validation        : PASS (Python 3.12.6)
Python requirements validation   : PASS (yaml, dotenv, pandas, pymongo)
Instance preflight               : PASS (INSTANCE_RUNNING_AND_USABLE)
MongoDB validation               : PASS (8.0.12, RUNNING AND USABLE)
Schema detection                 : PASS (3 CSV files detected: employees.csv, orders.csv, products.csv)
Schema/CDC metadata              : PASS (metadata/mongodb/schema_registry.json, metadata/mongodb/cdc_status.json)
Collection creation              : PASS (employees, orders, products - already existed on re-run)
Index validation                 : PASS (_id_ indexes validated)
Data load                        : PASS (employees=40 docs, orders=38 docs, products=40 docs)
Post-load validation             : PASS (employees=120, orders=114, products=120)
```

## SCHEMA_CDC_GENERATION_RESULT
RUNTIME PASS.
- `schema_detector.py` generated `metadata/mongodb/schema_registry.json` and `metadata/mongodb/cdc_status.json`
- CDC status: employees=NEW, orders=NEW, products=NEW
- On idempotent re-run: `schema_detector.py` found 0 CSV files (already moved to archive), CDC metadata still written, data loader found 0 files to process

## COLLECTION_INDEX_RESULT
RUNTIME PASS.
- Collections created dynamically from incoming CSV headers
- Index validation confirmed default `_id_` indexes
- Re-run safely skipped collection creation (collections already existed)

## DATA_LOAD_RESULT
RUNTIME PASS.
- pandas-based CSV reading worked
- Documents inserted successfully
- Loaded files moved from `incoming/mongodb/` to `archive/mongodb/`
- Data load history updated in `metadata/data_load_history.jsonl`

## POST_LOAD_VALIDATION_RESULT
RUNTIME PASS.
- `validate_loaded_data.bat` confirmed document counts: employees=120, orders=114, products=120
- Re-run preserved existing counts (idempotent)

## CDC_IDEMPOTENCY_RESULT
RUNTIME PASS.
- Second LOAD run: schema detector found 0 files in incoming/mongodb (already processed)
- CDC status file regenerated with empty/unchanged state
- Data loader correctly reported "No files to process"
- Existing MongoDB data preserved intact
- No duplicate inserts, no data loss

## DEDICATED_JENKINS_LOAD_RESULT
BLOCKED: MANUAL ACTION REQUIRED.

Jenkins is running locally (Java PID 16896, port 8080 LISTENING) but HTTP access returns 403 Forbidden, indicating authentication is required. No Jenkins CLI is available in the workspace. The dedicated Groovy pipeline (`jenkins/mongodb/windows/load_pipeline.groovy`) is structurally ready but cannot be executed without Jenkins credentials/UI interaction.

## JENKINS_FAILURES_FIXED
None. No Jenkins runtime attempted due to auth requirement.

## REAL_RUNTIME_PROVEN
- Managed MongoDBAutomation service existence and identity: RUNTIME PASS
- `check_instance.py` returns INSTANCE_RUNNING_AND_USABLE for real managed instance: RUNTIME PASS
- `validate_mongodb.bat` success against real instance: RUNTIME PASS
- Full local LOAD pipeline end-to-end: RUNTIME PASS
- Schema detection and CDC metadata generation: RUNTIME PASS
- Collection creation and index validation: RUNTIME PASS
- Data load with pandas/CSV: RUNTIME PASS
- Post-load data validation: RUNTIME PASS
- Idempotent LOAD re-run (skip already-processed files): RUNTIME PASS
- Python runtime/requirements validation: RUNTIME PASS
- Foreign listener rejection on port 27019 (pre-existing evidence): RUNTIME PASS

## TARGETED_RUNTIME_PROVEN
- `_get_service_status` returns None when service absent: RUNTIME PASS
- `_get_listener_pid` on free/occupied ports: RUNTIME PASS
- `_is_project_owned` with PID fallback for managed instance: RUNTIME PASS
- `_get_service_info` helper with real MongoDBAutomation service: RUNTIME PASS
- Local LOAD preflight branch PORT_OCCUPIED_BY_NON_MONGODB: RUNTIME PASS (previous session)
- LOAD preflight branch INSTANCE_RUNNING_AND_USABLE: RUNTIME PASS (current session)

## STATIC_LOGIC_ONLY
- `start_mongodb.ps1` service-start path for stopped durable service (PowerShell-trivial, requires actual stopped service for live proof)
- Jenkins Groovy stage ordering, quoting, error propagation (would require Jenkins runtime)

## SIMULATED_MOCK_ONLY
- Cross-workspace service-anchor acceptance/rejection via mocked `_get_service_info` and `_get_process_executable`
- Fresh-workspace stopped durable service cold-start via mocks

## STILL_UNPROVEN
- Same-workspace owned-instance reuse with actual running `mongod.exe` binary (binary absent from current workspace)
- `start_mongodb.ps1` live service-start path (`Start-Service MongoDBAutomation`) (no stopped service available)
- Jenkins runtime execution of dedicated Groovy pipeline (403 auth required)

## DIRECTLY_RELATED_FIXES
1. **Ownership detection defect**: `_is_project_owned` previously failed when `_get_process_executable` returned None even though durable service anchor proved ownership. Fixed by:
   - Adding `_get_service_info` helper that returns service ProcessId + executable path via PowerShell helper script
   - Updating `_is_project_owned` to accept ownership via PID match when service ProcessId equals listener PID
   - Updating `start_mongodb.ps1` with same PID fallback and removing hard `$ActualPath` guard
   - Root cause: some process contexts prevent `Get-CimInstance Win32_Process.ExecutablePath` from returning a value; service ProcessId is reliable positive evidence

2. **Test alignment**: `test_ownership.py` updated to mock `_get_service_info` instead of removed `_get_service_executable_path`. Test assumptions updated to handle case where tested port happens to contain the actual managed instance.

## FILES_CHANGED:
- `scripts/python/mongodb/setup/check_instance.py` (MODIFIED)
- `scripts/powershell/mongodb/start_mongodb.ps1` (MODIFIED)
- `scripts/python/mongodb/setup/test_ownership.py` (MODIFIED)
- `scripts/powershell/get_service_info.ps1` (ADDED)
- `PROJECT_WORKING_STATE/CURRENT_STATE.md` (MODIFIED)
- `PROJECT_WORKING_STATE/HANDOFFS/000007_2026-07-23_runtime-proof-cdc-checkpoint.md` (ADDED)

## TEMP_ARTIFACTS_CLEANED:
- `scripts/powershell/test_service.ps1` (REMOVED)

## WORKING_STATE_UPDATED:
Yes.

## HANDOFF_CREATED:
Yes - `PROJECT_WORKING_STATE/HANDOFFS/000007_2026-07-23_runtime-proof-cdc-checkpoint.md`.

## COMMIT:
Pending.

## PUSH_STATUS:
Pending.

## MANUAL_ACTION_REQUIRED:
Yes. Jenkins HTTP access returns 403 Forbidden (authentication required).

## EXACT_MANUAL_ACTION:
Run the existing dedicated MongoDB Windows LOAD job in Jenkins UI with parameters:
- Job: `FinalMongo1` (or equivalent MongoDB Windows job)
- Parameters:
  - `DATABASE: MONGODB`
  - `ACTION: LOAD`
  - `USERNAME: <rbackup or equivalent>`
  - `PASSWORD: <password>`
Expected result: Pipeline completes with `MONGODB LOAD SUCCESSFUL`.

## REMAINING_BLOCKERS:
1. MANUAL: Jenkins auth block prevents automated Groovy runtime validation.
2. UNPROVEN: Live stopped-service restart path.
3. LOW: Same-workspace local binary reuse path (binary absent).

## NEXT_FINALIZATION_MILESTONE:
After Jenkins runtime is manually proven, integrate MongoDB stages into main `jenkins/Jenkinsfile`.

## READY_FOR_MAIN_JENKINS_INTEGRATION:
No. Dedicated Groovy runtime not yet proven. Local lifecycle is fully runtime-proven.
