# Final Target Structure

```text
config/
  windows/
    mysql.conf
    mssql.conf
    mongodb.conf
    postgresql.conf
  ubuntu/
    mysql.conf
    mssql.conf
    mongodb.conf
    postgresql.conf
incoming/
  mysql/
  mssql/
  mongodb/
  postgresql/
liquibase/
  mysql/
  mssql/
  postgresql/
jenkins/
  mysql/windows/setup_pipeline.groovy
  mysql/windows/load_pipeline.groovy
  mysql/ubuntu/setup_pipeline.groovy
  mysql/ubuntu/load_pipeline.groovy
  mssql/windows/setup_pipeline.groovy
  mssql/windows/load_pipeline.groovy
  mssql/ubuntu/setup_pipeline.groovy
  mssql/ubuntu/load_pipeline.groovy
  mongodb/windows/setup_pipeline.groovy
  mongodb/windows/load_pipeline.groovy
  mongodb/ubuntu/setup_pipeline.groovy
  mongodb/ubuntu/load_pipeline.groovy
  postgresql/windows/setup_pipeline.groovy
  postgresql/windows/load_pipeline.groovy
  postgresql/ubuntu/setup_pipeline.groovy
  postgresql/ubuntu/load_pipeline.groovy
terraform/
  mysql/windows/
  mysql/ubuntu/
  mssql/windows/
  mssql/ubuntu/
  mongodb/windows/
  mongodb/ubuntu/
  postgresql/windows/
  postgresql/ubuntu/
scripts/
  batch|bash|powershell|python/
    common/
    mysql/setup/
    mysql/load/
    mssql/setup/
    mssql/load/
    mongodb/setup/
    mongodb/load/
    postgresql/setup/
    postgresql/load/
```

## Exclusions From Target Source Tree

- Terraform state, .terraform, and executable downloads.
- Database engine binaries, data directories, and logs.
- Python bytecode and local debug artifacts.
- Cleanup/destroy/debug pipelines in production Jenkins structure.
