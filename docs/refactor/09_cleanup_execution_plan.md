# Cleanup Execution Plan

Planning only; do not execute automatically.

| Area | Action | Risk Level |
| --- | --- | --- |
| terraform state/runtime artifacts | DELETE CANDIDATE after confirming no state recovery requirement | High |
| tools/terraform/terraform.exe | DELETE CANDIDATE; install/download at runtime or cache outside repo | Medium |
| tools/liquibase distribution | DELETE CANDIDATE or external tool cache; keep installer script only | Medium |
| databases/mysql/server and databases/*/data | DELETE CANDIDATE; generated DB engine/data runtime | High |
| logs and failed files | DELETE CANDIDATE/archive outside repo; evidence files should not drive pipeline code | Low |
| __pycache__ and .pyc | DELETE CANDIDATE; generated Python bytecode | Low |
| jenkins/testing and localwork | docs/archive/ or DELETE CANDIDATE after confirming no job uses it | Medium |
| liquibase/failed | docs/archive/ or DELETE CANDIDATE after schema owner review | Medium |

## Safe Execution Gates

1. Export current Jenkins job definitions and last successful build numbers.
2. Tag or branch current green state.
3. Clean generated artifacts in a dedicated PR with no script refactors.
4. Run MySQL, MongoDB, and MSSQL Windows/Ubuntu setup and load pipelines.
5. Proceed to folder restructuring in small database-scoped batches only after cleanup validation.
