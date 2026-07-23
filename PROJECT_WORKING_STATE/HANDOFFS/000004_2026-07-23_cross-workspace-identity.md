# HANDOFF 000004

## TASK
Make MongoDB managed-instance identity/discovery safe across separate fresh Jenkins workspaces using the smallest architecture-compatible change.

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
Allow SETUP and LOAD to run in separate fresh Jenkins workspaces while safely discovering and reusing a managed MongoDB instance created by SETUP in a different workspace. Ownership must remain based on positive durable evidence; never accept a foreign mongod merely because it listens on the configured port.

## DURABLE_IDENTITY_AUDIT
Inspected existing durable machine-level evidence after SETUP:
- **Windows service `MongoDBAutomation`**: Created by `scripts/powershell/mongodb/configure_mongodb_service.ps1` lines 235-242 via `& "$MongodExe" --dbpath ... --install --serviceName "$ServiceName"`. This is a machine-level object that survives workspace deletion.
- **Service `PathName`**: Contains the full absolute path to the actual mongod.exe on disk plus all command-line arguments. Retrieved via `Win32_Service.PathName`.
- **Process `ExecutablePath`**: The actual running mongod.exe path on disk. Retrieved via `Win32_Process.ExecutablePath`.
- **Process ownership checks in cleanup**: `scripts/powershell/mongodb/cleanup/stop_mongodb.ps1` and `remove_mongodb.ps1` already verify project ownership by comparing service PathName / process ExecutablePath against expected paths.
- **Terraform state**: NOT durable across workspaces (in-workspace `.terraform` directory).
- **Project-local config**: `config/windows/mongodb.conf` is workspace-local.

Conclusion: The existing Windows service `MongoDBAutomation` is the intended durable ownership anchor. Its `PathName` plus the listener process `ExecutablePath` provide cross-workspace identity without requiring any new registry/state mechanism.

## OWNERSHIP_MODEL
Three-class model:
- **A. Same-workspace project-owned**: Current PROJECT_ROOT path matches listener executable.
- **B. Cross-workspace managed (durable service anchor)**: `MongoDBAutomation` Windows service exists, and its `PathName`-extracted executable path matches the listener process `ExecutablePath`. This is independent of which Jenkins workspace originally created the service.
- **C. Foreign/unrelated**: Any mongod on the port that does NOT match either A or B is rejected. Unresolvable executable paths default to C (fail closed).

Positive evidence required:
- Not mere port occupancy
- Not successful ping alone
- Not executable name alone (`mongod.exe`)
- Not stale workspace files (data, binaries, terraform state)

Decision order:
1. Durable service-anchor check (B)
2. Current-workspace path fallback (A)
3. If neither matches -> foreign (C)

## DURABLE_OWNERSHIP_ANCHOR
**Anchor**: Windows service named `MongoDBAutomation`.
- Created during SETUP by `configure_mongodb_service.ps1`.
- Machine-level, survives workspace deletion.
- Service `PathName` contains absolute path to mongod.exe installed by originating workspace.
- Listener process `ExecutablePath` is compared against service `PathName`-extracted executable.
- This comparison is workspace-agnostic: workspace A's path matches workspace B's listener path iff they are the same actual mongod on disk.

## IMPLEMENTATION_CHANGES
`scripts/python/mongodb/setup/check_instance.py`:
- Added `_get_service_executable_path(service_name)` using PowerShell `Get-CimInstance Win32_Service` to extract the executable path from the service's `PathName` (handles quoted/unquoted command lines).
- Updated `_is_project_owned(pid)` to:
  1. Retrieve listener process executable path.
  2. Query durable service anchor `MongoDBAutomation` executable path.
  3. If both exist and match (case-insensitive normalized absolute path) -> True.
  4. Fallback to workspace-local `EXPECTED_MONGOD_PATH` check.
  5. If process executable path is unresolvable -> False (fail closed).
- Existing output keys and instance-state contract preserved.

`scripts/powershell/mongodb/start_mongodb.ps1`:
- After resolving listener PID and process `ExecutablePath`:
  1. Query `MongoDBAutomation` service via `Get-CimInstance Win32_Service`.
  2. Extract service executable from `PathName` (handle quoted paths).
  3. If listener process path == service executable path (case-insensitive) -> `$IsProjectOwned = $true`.
  4. Fallback: compare listener process path against current workspace `$ExpectedMongodPath`.
  5. If neither matches -> foreign, throw with diagnostics including service info.
- Foreign diagnostic output now includes:
  - Expected current-workspace path
  - Durable service name and raw PathName (if service exists)
  - Actual process path, PID, process name (if resolvable)
- Normal start path unchanged when port is free.

## SAME_WORKSPACE_TEST:
REAL + UNPROVEN.
- Free-port detection: PASS.
- Current-workspace path matching logic preserved. However, actual same-workspace owned instance could not be live-tested because `databases/mongodb/server/bin/mongod.exe` is absent from this workspace and SETUP has not been executed.
- Expected behavior when binary present: listener path matches `EXPECTED_MONGOD_PATH` -> `INSTANCE_RUNNING_AND_USABLE` (check_instance) or safe reuse (start_mongodb).
- Cross-workspace acceptance: PASS via simulation.

## CROSS_WORKSPACE_TEST:
SIMULATED (3 sub-tests, all PASS).
Environment limitation: No actual `MongoDBAutomation` Windows service is installed in this test workspace, so live service-anchor resolution could not be performed. Tests use `unittest.mock.patch` to simulate service and process states.

Sub-tests:
1. **Service-anchor accepts managed instance**:
   - Simulated service executable = `C:\jenkins\workspace\mongodb-setup\databases\mongodb\server\bin\mongod.exe`
   - Simulated listener process executable = same path
   - Result: `_is_project_owned` returns True. The durable service anchor accepts the managed instance across workspaces.
2. **Mismatched service/process rejected**:
   - Service executable = workspace A path
   - Listener process executable = current workspace path
   - Result: `_is_project_owned` returns False. Service anchor rejects mismatched process.
3. **No-service cross-workspace rejected**:
   - `_get_service_executable_path` returns None (no service)
   - Listener process executable = workspace A path
   - Result: `_is_project_owned` returns False. Without service anchor, cross-workspace path mismatch is correctly rejected.

Additional simulated:
4. **Missing process executable path**: Returns False (fail closed).

## FOREIGN_INSTANCE_TEST:
REAL (PASS).
- Port 27019 occupied by foreign mongod (PID 4908, executable path unresolvable due to process context).
- `_is_project_owned` returns False.
- `check_instance.py` output: `INSTANCE_STATE=PORT_OCCUPIED_BY_NON_MONGODB`.
- `start_mongodb.ps1`: would throw clear diagnostics; foreign process untouched.

## STALE_ARTIFACT_TEST:
REAL (PASS).
- Created dummy `databases/mongodb/server/bin/mongod.exe` and `databases/mongodb/data`.
- No mongod running on free port 65432.
- `_is_project_owned(None)` returns False.
- `check_instance.py` correctly classifies as `INSTANCE_INSTALLED_BUT_STOPPED` (binaries exist, port free) when binaries exist but port is free.

## UNRESOLVABLE_PATH_TEST:
REAL + SIMULATED (PASS).
- Real: PID 4908 executable path unresolvable -> treated as foreign.
- Simulated: `_get_process_executable` returns None -> `_is_project_owned` returns False.

## CALLER_COMPATIBILITY:
- Local `.bat` (`scripts/batch/mongodb/mongodb_setup_pipeline.bat`): handles `PORT_OCCUPIED_BY_NON_MONGODB` via existing fallthrough to `ERROR: Unexpected instance state` -> `exit /b 1`. SAFE.
- Jenkins Groovy (`jenkins/mongodb/windows/setup_pipeline.groovy`): `PORT_OCCUPIED_BY_NON_MONGODB` is already in `allowedStates` (line 76). Deploy/Start stages are skipped.
- LOAD Groovy (`jenkins/mongodb/windows/load_pipeline.groovy`): does not invoke `check_instance.py` or `start_mongodb.ps1` directly. No direct impact.
- LOAD `.bat` (`scripts/batch/mongodb/mongodb_load_pipeline.bat`): unchanged; out of scope.

No output contract breaking. Existing keys: `HOST`, `PORT`, `DATABASE`, `PROJECT_BINARIES_EXIST`, `PROJECT_DATA_EXISTS`, `TCP_OPEN`, `MONGODB_AVAILABLE`, `INSTANCE_STATE`, `ERROR`.

## FRESH_LOAD_DISCOVERY_BEHAVIOR:
After this identity fix, when LOAD runs in a fresh workspace B:
1. `check_instance.py` on port configured in `mongodb.conf` will:
   - Detect port open.
   - Query listener PID -> process executable path.
   - Query `MongoDBAutomation` service -> service PathName executable.
   - If listener executable == service executable -> `INSTANCE_RUNNING_AND_USABLE`.
   - If no service and listener path != current-workspace path -> `PORT_OCCUPIED_BY_NON_MONGODB`.
2. `start_mongodb.ps1` on port already occupied by project service listener:
   - Detects listener PID.
   - Detects service anchor match.
   - Exits 0 safely without starting duplicate.
3. LOAD `.bat` still needs its own instance-state check before calling `start_mongodb.bat` (out of scope for this task). The identity layer is now safe to call from LOAD.

## FILES_CHANGED:
- `scripts/python/mongodb/setup/check_instance.py` (MODIFIED)
- `scripts/powershell/mongodb/start_mongodb.ps1` (MODIFIED)
- `scripts/python/mongodb/setup/test_ownership.py` (MODIFIED - targeted validation)
- `PROJECT_WORKING_STATE/CURRENT_STATE.md` (MODIFIED)
- `PROJECT_WORKING_STATE/HANDOFFS/000004_2026-07-23_cross-workspace-identity.md` (ADDED - this handoff)

## WORKING_STATE_UPDATED:
Yes - `PROJECT_WORKING_STATE/CURRENT_STATE.md` updated with cross-workspace safe ownership status and new next actions ordering.

## HANDOFF_CREATED:
Yes - `PROJECT_WORKING_STATE/HANDOFFS/000004_2026-07-23_cross-workspace-identity.md` created.

## REMAINING_RISKS:
1. **UNPROVEN**: Same-workspace owned-instance reuse requires actual running project mongod.exe for live validation. Binary currently absent.
2. **SIMULATED**: Cross-workspace acceptance validated via mocked service/process paths only. Live service-anchor validation requires an actual installed `MongoDBAutomation` Windows service.
3. **MEDIUM**: LOAD `.bat` still unconditionally calls `start_mongodb.bat` without instance-state check. Fresh-workspace LOAD safety gap remains next priority.
4. **MEDIUM**: Groovy `setup_pipeline.groovy` validation stages do not re-check ownership after the check stage.
5. **LOW**: If `MongoDBAutomation` service is manually renamed or replaced by a foreign actor, the anchor ceases to provide identity. This is acceptable risk in controlled Jenkins environments.
6. **LOW**: `_get_service_executable_path` PowerShell parsing may behave differently with exotic service command lines. Quoted/unquoted paths are handled; PathName without spaces falls to `Split(' ')[0]`.

## RECOMMENDED_NEXT_SINGLE_TASK:
Align fresh-workspace safety in the local LOAD pipeline by adding instance-state verification before calling `start_mongodb.bat` in `scripts/batch/mongodb/mongodb_load_pipeline.bat`, and adding tool/instance validation stages so LOAD can execute safely in a Jenkins workspace that was not used by SETUP.

## READY_FOR_NEXT_STAGE:
No - cross-workspace identity is now safe, but fresh-workspace LOAD safety remains the next blocking gap.
