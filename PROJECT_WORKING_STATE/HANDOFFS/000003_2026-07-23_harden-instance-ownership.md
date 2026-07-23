# HANDOFF 000003

## TASK
Harden MongoDB Windows instance ownership detection in SETUP/LOAD entry points to prevent foreign/old mongod from being mistaken for the project-managed instance.

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
- Read-only audit baseline plus targeted implementation of ownership detection (doc updates pending commit)

## GOAL
Prevent SETUP/LOAD from silently reusing or deploying over a foreign mongod on the configured port. Ownership is determined by matching the listener process executable path to the expected project-managed `databases\mongodb\server\bin\mongod.exe`.

## ROOT_CAUSE_CONFIRMED
`scripts/python/mongodb/setup/check_instance.py` previously classified any port-open + pingable MongoDB as `INSTANCE_RUNNING_AND_USABLE` without inspecting the listener process. `scripts/powershell/mongodb/start_mongodb.ps1` exited 0 upon any port occupancy without ownership verification.

## OWNERSHIP_ALGORITHM
Reused proven ownership concept from cleanup scripts (`scripts/powershell/mongodb/cleanup/stop_mongodb.ps1`, `scripts/powershell/mongodb/cleanup/remove_mongodb.ps1`) and adapted for SETUP/LOAD:

1. **check_instance.py**:
   - Resolve listener PID from `netstat -ano -p TCP` on configured port.
   - Resolve process executable path via `Get-CimInstance Win32_Process -Filter "ProcessId={pid}"`.
   - Compare normalized absolute paths (case-insensitive) against expected `databases\mongodb\server\bin\mongod.exe`.
   - Only classify as `INSTANCE_RUNNING_AND_USABLE` when BOTH port is open/responding AND ownership matches.
   - Foreign/mismatched path -> `PORT_OCCUPIED_BY_NON_MONGODB`.
   - Unresolvable executable -> safe default denied ownership -> `PORT_OCCUPIED_BY_NON_MONGODB`.

2. **start_mongodb.ps1**:
   - Resolve listener PID via `Get-NetTCPConnection -LocalPort`.
   - Resolve process executable path via `Get-CimInstance Win32_Process`.
   - Compare normalized absolute paths (case-insensitive).
   - Project-owned existing listener -> reuse, exit 0.
   - Foreign listener -> throw with diagnostics (expected path, actual path, PID, process name), do NOT kill/alter.
   - Port free -> existing normal startup path.

## CHECK_INSTANCE_CHANGES
`scripts/python/mongodb/setup/check_instance.py`:
- Added `_get_listener_pid(port)` using `subprocess.run(["netstat", "-ano", "-p", "TCP"])` parsing.
- Added `_get_process_executable(pid)` using PowerShell `Get-CimInstance Win32_Process`.
- Added `_is_project_owned(pid)` comparing resolved executable path to `EXPECTED_MONGOD_PATH` (case-insensitive ordinal comparison).
- Added ownership gate after TCP_OPEN detection before MongoDB ping.
- Returns `PORT_OCCUPIED_BY_NON_MONGODB` with descriptive ERROR when ownership fails.
- Existing 4-state consumer contract preserved in structure; added 5th state `PORT_OCCUPIED_BY_NON_MONGODB` already accepted by Groovy `allowedStates` and safely rejected by local .bat.

## START_MONGODB_CHANGES
`scripts/powershell/mongodb/start_mongodb.ps1`:
- Replaced simple `netstat -ano | Select-String` with `Get-NetTCPConnection -LocalPort $MongoPort -State Listen`.
- Added ownership verification using `Get-CimInstance Win32_Process` + `[System.IO.Path]::GetFullPath` + case-insensitive comparison against `$ExpectedMongodPath`.
- Foreign process detected -> rich error diagnostics and `throw` (non-zero exit), not `exit 0`.
- Project-owned existing listener -> `Write-Host` reuse message + `exit 0`.
- Port free -> unchanged existing startup behavior.

## CALLER_COMPATIBILITY
- Local .bat (`scripts/batch/mongodb/mongodb_setup_pipeline.bat`): handles `PORT_OCCUPIED_BY_NON_MONGODB` via existing fallthrough to `ERROR: Unexpected instance state` -> `exit /b 1`. SAFE.
- Jenkins Groovy (`jenkins/mongodb/windows/setup_pipeline.groovy`): `PORT_OCCUPIED_BY_NON_MONGODB` is already in `allowedStates` array (line 76). Deploy/Start stages are skipped. Validation stages run next; note that `validate_instance.py` currently only pings and does not re-check ownership, so a healthy foreign mongod would still pass validation in Groovy. This is a pre-existing Groovy validation gap outside current task scope.
- LOAD Groovy (`jenkins/mongodb/windows/load_pipeline.groovy`): does not invoke `check_instance.py` or `start_mongodb.ps1` directly; calls `load_data.bat` only. No direct impact.
- LOAD .bat (`scripts/batch/mongodb/mongodb_load_pipeline.bat`): unchanged; future LOAD hardening is out of scope.

## TARGETED_TESTS
Executed `scripts/python/mongodb/setup/test_ownership.py` directly against live runtime.

### SCENARIO_PORT_FREE
- `_get_listener_pid(FREE_PORT)` -> None
- Result: PASS
- Expected: `check_instance.py` would classify as `NO_INSTANCE` or `INSTANCE_INSTALLED_BUT_STOPPED` depending on binary/data existence. `start_mongodb.ps1` proceeds to normal start.

### SCENARIO_OWNED_RUNNING
- Status: UNPROVEN
- Reason: `databases/mongodb/server/bin/mongod.exe` is absent from workspace; cannot start a real project-managed instance for live validation.
- Expected behavior if binary were present: `_get_listener_pid` returns project PID, `_is_project_owned` returns True, `check_instance.py` returns `INSTANCE_RUNNING_AND_USABLE`, `start_mongodb.ps1` exits 0 safely.

### SCENARIO_FOREIGN_LISTENER
- Port 27019 has foreign mongod (PID 4908, executable path unresolvable due to permission/context).
- `_get_listener_pid(27019)` -> 4908
- `_get_process_executable(4908)` -> None (permission/context limitation)
- `_is_project_owned(4908)` -> False (safe default when ownership cannot be proven)
- `check_instance.py` output:
  - `INSTANCE_STATE=PORT_OCCUPIED_BY_NON_MONGODB`
  - `ERROR=Port 27019 occupied by foreign process (PID=4908, path=Unknown). Expected project-managed mongod: F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMongo1\databases\mongodb\server\bin\mongod.exe`
- Result: PASS
- `start_mongodb.ps1`: same PID resolution; if invoked on port 27019, would throw clear diagnostics and abort.

### SCENARIO_STALE_ARTIFACTS
- Created dummy `databases/mongodb/server/bin/mongod.exe` and `databases/mongodb/data`.
- No mongod running on free port 65432.
- `_get_listener_pid(FREE_PORT)` -> None
- `PROJECT_BINARIES_EXIST` and `PROJECT_DATA_EXISTS` flags reflect filesystem truth.
- `_is_project_owned(None)` -> False
- Result: PASS
- `check_instance.py` correctly classifies as `INSTANCE_INSTALLED_BUT_STOPPED` when binaries exist but port is free, not `NO_INSTANCE`.

## FILES_CHANGED
- `scripts/python/mongodb/setup/check_instance.py` (MODIFIED)
- `scripts/powershell/mongodb/start_mongodb.ps1` (MODIFIED)
- `scripts/python/mongodb/setup/test_ownership.py` (ADDED - targeted test, not part of production pipeline yet)
- `PROJECT_WORKING_STATE/CURRENT_STATE.md` (MODIFIED)
- `PROJECT_WORKING_STATE/HANDOFFS/000003_...` (ADDED - this handoff)

## WORKING_STATE_UPDATED
Yes - `PROJECT_WORKING_STATE/CURRENT_STATE.md` updated to reflect hardened ownership detection and current state.

## HANDOFF_CREATED
Yes - `PROJECT_WORKING_STATE/HANDOFFS/000003_2026-07-23_harden-instance-ownership.md` created.

## REMAINING_RISKS
1. **UNPROVEN**: Owned-instance reuse path requires actual running project mongod.exe for live validation. Not exercised in targeted tests because binary is absent.
2. **MEDIUM**: Groovy `setup_pipeline.groovy` validation stages (`Validate MongoDB Port`, `Validate MongoDB Instance`) do not re-check ownership after `check_instance.py`. A healthy foreign mongod on the port would still pass validation in Groovy after `PORT_OCCUPIED_BY_NON_MONGODB` is correctly detected at the check stage. This is pre-existing and out of current scope.
3. **MEDIUM**: `start_mongodb.ps1` is unchanged when port is free; if binaries are missing it throws at validation step, which is correct.
4. **LOW**: `_get_process_executable` may return None due to permissions or process termination timing; safe fallback is foreign denial.
5. **LOW**: LOAD .bat and Groovy hardening deferred. Local LOAD still unconditionally calls `start_mongodb.bat` without instance-state check.

## RECOMMENDED_NEXT_SINGLE_TASK
Align fresh-workspace safety in the local LOAD pipeline by adding instance-state verification before calling `start_mongodb.bat` in `scripts/batch/mongodb/mongodb_load_pipeline.bat`, and adding tool/instance validation stages so LOAD can execute safely in a Jenkins workspace that was not used by SETUP.

## READY_FOR_NEXT_STAGE:
No - ownership hardening is complete, but fresh-workspace LOAD safety gap remains unaddressed.
