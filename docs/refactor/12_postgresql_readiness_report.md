# PostgreSQL Readiness Report

## Current Assets Found

- Python: 21 files under scripts/python/postgresql.
- Batch: 19 files under scripts/batch/postgresql.
- PowerShell: 5 files under scripts/powershell/postgresql.
- Jenkins: 19 files under jenkins/postgresql.
- Terraform: 3 files under terraform/postgresql.
- Liquibase: 7 files under liquibase/postgresql.
- Config: config/postgresql.conf exists; target OS-specific missing files: config/windows/postgresql.conf, config/ubuntu/postgresql.conf.

## Readiness Gaps

| Area | Gap | Risk Level | Recommendation |
| --- | --- | --- | --- |
| Windows setup Jenkins | Target jenkins/postgresql/windows/setup_pipeline.groovy is missing by exact target name; setup exists in localwork/root/Jenkinsfile variants. | High | Promote one proven working setup pipeline to target name after dependency update plan. |
| Windows load Jenkins | Current postgresql_load_pipeline.groovy violates target naming. | Medium | Rename only in a controlled move plan with Jenkins job update. |
| Ubuntu Jenkins | Current files use db-prefixed names, not target names. | Medium | Normalize to setup_pipeline.groovy/load_pipeline.groovy after validation. |
| Terraform OS split | terraform/postgresql is not split into windows/ubuntu. | High | Create self-contained OS folders or confirm one implementation is OS-neutral before duplicating. |
| Config OS split | Only root config/postgresql.conf found. | High | Create config/windows/postgresql.conf and config/ubuntu/postgresql.conf and update references in plan. |
| Common driver scripts | PostgreSQL driver install/validate scripts are in batch common. | Medium | Move to PostgreSQL setup ownership unless shared driver abstraction is made database-neutral. |
| Dataset path config | PostgreSQL sample datasets exist under datasets; future DATASET_PATH should come from config. | Medium | Plan config-driven dataset path resolution. |
| Pipeline duplication | Root, windows/localwork, and ubuntu PostgreSQL Jenkins variants coexist. | High | Select canonical green files and mark others archive/delete candidates. |

## Overall Assessment

PostgreSQL has many required building blocks, but it is not ready for the final target architecture because Jenkins naming/location, Terraform OS isolation, and config OS isolation are incomplete.
