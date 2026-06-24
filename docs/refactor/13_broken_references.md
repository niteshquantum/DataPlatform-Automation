# Broken References

Static path-like references that were not resolved by exact path or basename matching. Review before moving files.

| File | Line | Reference | Issue |
| --- | --- | --- | --- |
| jenkins/postgresql/postgresql_setup_pipeline.groovy | 72 | /scripts/bash/postgresql/install_postgresql.sh | Referenced path not found by exact or basename match. |
| jenkins/postgresql/postgresql_setup_pipeline.groovy | 73 | /scripts/bash/postgresql/start_postgresql.sh | Referenced path not found by exact or basename match. |
| jenkins/postgresql/postgresql_setup_pipeline.groovy | 81 | /scripts/bash/postgresql/validate_postgresql.sh | Referenced path not found by exact or basename match. |
| jenkins/postgresql/ubuntu/postgresql_load_pipeline.groovy | 63 | scripts/bash/postgresql/validate_postgresql.sh | Referenced path not found by exact or basename match. |
| jenkins/postgresql/ubuntu/postgresql_setup_pipeline.groovy | 62 | scripts/bash/postgresql/deploy_postgresql.sh | Referenced path not found by exact or basename match. |
| jenkins/postgresql/ubuntu/postgresql_setup_pipeline.groovy | 68 | scripts/bash/postgresql/validate_postgresql.sh | Referenced path not found by exact or basename match. |
| scripts/bash/mssql/install_sqlcmd.sh | 45 | sudo tee /etc/profile.d/mssql-tools.sh | Referenced path not found by exact or basename match. |
| scripts/batch/postgresql/deploy_postgresql.bat | 39 | dp0..\..\powershell\download_postgresql_driver.ps1 | Referenced path not found by exact or basename match. |
| scripts/data_loader_mongodb.py | 36 | metadata/data_load_history.json | Referenced path not found by exact or basename match. |
| scripts/python/mysql/update_master_xml.py | 60 | \nmaster.xml | Referenced path not found by exact or basename match. |
| tools/liquibase/examples/start-h2.bat | 9 | p0\..\liquibase.bat | Referenced path not found by exact or basename match. |
| tools/liquibase/licenses/oss/README.txt | 45 | 17 and 21 currently. See https://github.com/apache/commons-lang/blob/master/.github/workflows/maven.yml | Referenced path not found by exact or basename match. |
| tools/liquibase/README.txt | 44 | liquibase/liquibase.sh | Referenced path not found by exact or basename match. |

## Moved-File Reference Risk

Every planned move requires updating references in Jenkins, Batch, Bash, PowerShell, Python, Terraform, Liquibase, and config files. Highest-risk areas are Jenkins job paths, script relative paths, Liquibase changelog includes, and Python imports executed from different working directories.
