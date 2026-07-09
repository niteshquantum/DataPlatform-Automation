# Risk Assessment

## Highest Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Working pipeline regression | Current MySQL, MongoDB, and MSSQL green pipelines may rely on non-target paths. | Baseline job configs and update references in small batches. |
| Committed runtime state | Terraform state, DB data, logs, and downloaded tools can mask environment assumptions and leak machine state. | Remove only through approved cleanup PR after backup/signoff. |
| Path portability | Hardcoded absolute/user/temp paths break on Jenkins agents and OS variants. | Centralize path resolution through config and project root helpers. |
| Database ownership drift | DB-specific scripts in common/root folders create hidden coupling. | Move by database ownership while preserving shared utility boundaries. |
| Jenkins naming/location drift | Multiple root/localwork/custom/testing pipeline files make job ownership ambiguous. | Choose canonical green files, archive/delete candidates only after job audit. |
| PostgreSQL partial readiness | Assets exist but target OS split/naming/config are incomplete. | Finish PostgreSQL as a new database-scoped implementation without redesigning existing green DBs. |

## Change Control Recommendation

Use separate PRs for generated artifact cleanup, config normalization, script moves, Jenkins normalization, Terraform normalization, and PostgreSQL readiness. Each PR should include affected pipeline validation evidence.
