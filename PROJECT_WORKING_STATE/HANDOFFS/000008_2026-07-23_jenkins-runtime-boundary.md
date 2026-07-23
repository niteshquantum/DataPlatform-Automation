# HANDOFF 000008

## TASK
Finalize dedicated MongoDB Windows Jenkins LOAD runtime readiness and identify exact manual boundary.

## DATABASE
MongoDB

## OS
Windows

## WORKSPACE
F:\Quantumatrix\Projects\DataEng\datarefernce\FinalMongo1

## BRANCH
mongodb-windows-final-v1

## STARTING_HEAD
`42e35600a2ec4532534a49c7fa591eb59fb44831`
- Commit: `feat(mongodb-windows): runtime-prove lifecycle, fix PID fallback ownership, CDC idempotency checkpoint`

## ENDING_HEAD
`42e35600a2ec4532534a49c7fa591eb59fb44831`
- No new code changes; manual boundary documented

## GOAL
Prepare for dedicated MongoDB Windows Jenkins LOAD runtime. Determine exact job, parameters, and manual action required. Local lifecycle already runtime-proven in handoff 000007.

## PRE_JENKINS_READINESS
- Branch: `mongodb-windows-final-v1`
- HEAD: `42e3560`
- Working tree: clean (no uncommitted changes)
- MongoDBAutomation service: Running
- Port 27019: LISTENING (PID 4892, matches service ProcessId)
- `check_instance.py`: returns `INSTANCE_RUNNING_AND_USABLE`
- `validate_mongodb.bat`: PASS
- Dedicated Groovy file: `jenkins/mongodb/windows/load_pipeline.groovy` exists
- All script paths invoked by Groovy verified:
  - `scripts\batch\common\validate_python_runtime.bat` - EXISTS
  - `scripts\batch\mongodb\setup\validate_python_requirements.bat` - EXISTS
  - `scripts\batch\mongodb\setup\check_instance.bat` - EXISTS
  - `scripts\batch\mongodb\setup\start_mongodb.bat` - EXISTS
  - `scripts\batch\mongodb\setup\validate_mongodb.bat` - EXISTS
  - `scripts\batch\common\download_dataset.bat` - EXISTS
  - `scripts\batch\mongodb\load\load_data.bat` - EXISTS
  - `scripts\batch\mongodb\load\validate_loaded_data.bat` - EXISTS
  - `scripts\batch\mongodb\assessment\run_assessment.bat` - EXISTS
  - `scripts\batch\common\generate_assessment_report.bat` - EXISTS

## EXACT_JENKINS_JOB
**Job Name**: `mongodb20`
**Job Type**: Pipeline (`workflow-job`)
**Location**: `C:\Users\Admin\.jenkins\jobs\mongodb20\config.xml`
**Last Build**: #3 - SUCCESS (triggered by user `admin`, duration ~417s)
**SCM**: https://github.com/niteshquantum/DataPlatform-Automation
**Branch**: `*/testing` (IMPORTANT: not `mongodb-windows-final-v1`)
**Script Path**: `jenkins/mongodb/windows/load_pipeline.groovy`

## EXACT_PIPELINE_ENTRY
The `mongodb20` job directly executes:
```groovy
```
jenkins/mongodb/windows/load_pipeline.groovy
```

This is the dedicated MongoDB Windows LOAD pipeline. It does NOT route through `jenkins/Jenkinsfile`.

## EXACT_PARAMETERS
**No parameters are currently defined** in the `mongodb20` job configuration.

However, the Groovy pipeline references:
- `env.BUILD_NUMBER` - provided by Jenkins automatically
- `env.BUILD_URL` - provided by Jenkins automatically
- `env.JOB_NAME` - provided by Jenkins automatically
- `params.RUN_ASSESSMENT` - used in `when` conditions for optional assessment stages

Since no parameters are defined in the job, `params.RUN_ASSESSMENT` will be `null`. The optional assessment stages will be skipped because `null == 'true'` is false.

**RBAC/USERNAME/PASSWORD**: The Groovy pipeline references `params.USERNAME` and `params.PASSWORD`, but these are NOT defined in the `mongodb20` job. This means:
- If the Groovy tries to access `params.USERNAME` or `params.PASSWORD`, it will throw a `MissingPropertyException`
- This is a **directly related defect** that would cause Jenkins runtime failure

## EXPECTED_STAGES
Based on `jenkins/mongodb/windows/load_pipeline.groovy`:
1. Initialize Logging
2. Validate Python Runtime
3. Validate Python Requirements
4. Check Instance State
5. Validate MongoDB
6. Download Dataset
7. Load Data
8. Validate Loaded Data
9. Database Assessment (only if `params.RUN_ASSESSMENT == 'true'`)
10. Assessment Report (only if `params.RUN_ASSESSMENT == 'true'`)
11. Post: finalize logging, generate report/history, archive artifacts

## AUTOMATED_EXECUTION_ATTEMPT
Jenkins HTTP endpoint `http://localhost:8080/` returns **403 Forbidden**.
No Jenkins CLI (`jenkins-cli.jar`) found in workspace.
No API tokens stored for any user (`<tokenList/>` empty for admin user).
No credentials available for automated trigger.

## BLOCKER
**Jenkins authentication required.** HTTP 403 Forbidden prevents:
- Job triggering
- Console output retrieval
- Build status checking

Additionally, the `mongodb20` job is configured for branch `*/testing`, not `mongodb-windows-final-v1`. Even with authentication, the job would check out the `testing` branch code, not our current validated code.

## EXACT_MANUAL_ACTION

### Step 1: Prepare Jenkins Job
1. Open Jenkins UI at `http://localhost:8080/`
2. Navigate to **job `mongodb20`** (or equivalent MongoDB Windows LOAD job)
3. Click **Configure**
4. Under **Source Code Management > Branches**, change:
   - From: `*/testing`
   - To: `*/mongodb-windows-final-v1`
5. Under **This project is parameterized**, add these parameters:
   - **Choice Parameter**:
     - Name: `RUN_ASSESSMENT`
     - Choices: `true`, `false`
     - Default: `false`
   - **String Parameter** (optional, if RBAC is needed):
     - Name: `USERNAME`
     - Default: `rbackup`
   - **Password Parameter** (optional, if RBAC is needed):
     - Name: `PASSWORD`
     - Default: `<password>`
6. Click **Save**

### Step 2: Trigger Build
1. Click **Build with Parameters**
2. Set parameters:
   - `RUN_ASSESSMENT`: `false` (or `true` to include assessment)
   - `USERNAME`: `rbackup` (if required by RBAC)
   - `PASSWORD`: `<password>` (if required by RBAC)
3. Click **Build**

### Step 3: Monitor
- Wait for build to complete
- Click on build number to view console output
- Expected stages:
  - Initialize Logging
  - Validate Python Runtime
  - Validate Python Requirements
  - Check Instance State (should detect running MongoDBAutomation)
  - Validate MongoDB
  - Download Dataset
  - Load Data
  - Validate Loaded Data
  - (Optional) Database Assessment
  - (Optional) Assessment Report
  - Finalize/Archive
- Expected final result: **SUCCESS** with "MONGODB LOAD SUCCESSFUL"

### Step 4: Return Evidence
Copy and paste the **full console output** back, including:
- Build number and result
- Stage outputs
- Any errors or warnings
- Final status

## WHAT_TO_RETURN_AFTER_RUN
After running the Jenkins job, return:
1. Build number and final result (SUCCESS/FAILURE)
2. Full console output (or at minimum: failing stage name, error message, stack trace if any)
3. Whether `params.RUN_ASSESSMENT` was used and its value
4. Whether `params.USERNAME`/`params.PASSWORD` were required
5. Any directly related failures for autonomous fixing

## REMAINING_BLOCKERS
1. **MANUAL**: Jenkins 403 auth prevents automated execution
2. **BRANCH MISMATCH**: `mongodb20` job points to `*/testing`, not `mongodb-windows-final-v1`
3. **MISSING PARAMETERS**: Job lacks `RUN_ASSESSMENT`, `USERNAME`, `PASSWORD` parameters that Groovy expects
4. **UNPROVEN**: Live stopped-service restart path
5. **LOW**: Same-workspace local binary reuse (binary absent)

## FILES_CHANGED
None for this handoff. No code changes made.

## WORKING_STATE_UPDATED
No changes to CURRENT_STATE.md needed beyond this handoff.

## HANDOFF_CREATED
Yes - this handoff documents the exact Jenkins runtime boundary.

## COMMIT:
None required.

## PUSH_STATUS:
None required.

## NEXT_FINALIZATION_MILESTONE:
After Jenkins runtime is manually proven, integrate MongoDB stages into main `jenkins/Jenkinsfile`.

## READY_TO_FREEZE_DEDICATED_MONGODB_WINDOWS:
No. Dedicated Groovy runtime not yet proven. Local lifecycle fully runtime-proven. Next step is Jenkins manual execution with exact parameters above.
