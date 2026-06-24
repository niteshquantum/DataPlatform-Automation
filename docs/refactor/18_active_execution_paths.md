# Active Execution Paths

Objective: determine actual Windows execution flow reachable from the active Jenkins pipelines for MySQL, MSSQL, and MongoDB.

No source, pipeline, Terraform, Liquibase, config, or script files were modified.

## Scope And Status Rules

- `ACTIVE`: Directly called by one of the analyzed Jenkins pipelines, or by an unconditional nested script call in that path.
- `UNKNOWN`: Referenced through runtime behavior, Terraform provisioner ordering, glob/input discovery, external tool behavior, or conditional fallback.
- `UNUSED`: Not reachable from the analyzed Windows execution paths by static trace.

Analyzed pipeline roots:

- `jenkins/mysql/windows/mysql_setup_pipeline.groovy`
- `jenkins/mysql/windows/mysql_load_pipeline.groovy`
- `jenkins/mssql/windows/mssql_setup_pipeline.groovy`
- `jenkins/mssql/windows/mssql_load_pipeline.groovy`
- `jenkins/mongodb/Jenkinsfile.setup`
- `jenkins/mongodb/Jenkinsfile.load`

MongoDB note: no `jenkins/mongodb/windows/` folder exists. The root MongoDB Jenkinsfiles use Windows `bat` steps, so they are treated as MongoDB Windows pipelines.

## 1. MySQL Windows Setup Execution Tree

Pipeline: `jenkins/mysql/windows/mysql_setup_pipeline.groovy` - ACTIVE

```text
jenkins/mysql/windows/mysql_setup_pipeline.groovy
-> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/install_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
   -> requirements.txt [ACTIVE]
-> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/common/validate_java_runtime.bat [ACTIVE]
-> scripts/batch/common/install_tools.bat [ACTIVE]
   -> scripts/batch/common/install_terraform.bat [ACTIVE]
      -> tools/terraform/terraform.exe [ACTIVE output/dependency]
   -> scripts/batch/common/install_mysql_driver.bat [ACTIVE]
      -> scripts/powershell/download_mysql_driver.ps1 [ACTIVE]
      -> config/mysql.conf [ACTIVE]
      -> tools/drivers/mysql-connector-j-*.jar [ACTIVE output/dependency]
   -> scripts/batch/common/install_liquibase.bat [ACTIVE]
      -> scripts/powershell/download_liquibase.ps1 [ACTIVE]
      -> config/mysql.conf [ACTIVE]
      -> tools/liquibase/liquibase.bat [ACTIVE output/dependency]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
      -> config/mysql.conf [ACTIVE]
      -> tools/liquibase/liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_tools.bat [ACTIVE]
      -> tools/terraform/terraform.exe [ACTIVE]
      -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
      -> scripts/batch/common/validate_mysql_driver.bat [ACTIVE]
         -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/deploy_mysql.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> terraform/mysql/main.tf [ACTIVE]
      -> scripts/powershell/start_mysql.ps1 [UNKNOWN: Terraform local-exec resource]
      -> scripts/bash/install_mysql.sh [UNKNOWN: Linux local-exec in same Terraform file, OS/applicability unclear]
      -> scripts/bash/start_mysql.sh [UNKNOWN: Linux local-exec in same Terraform file, OS/applicability unclear]
-> scripts/batch/mysql/start_mysql.bat [ACTIVE]
   -> scripts/powershell/start_mysql.ps1 [ACTIVE]
      -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/create_database.bat [ACTIVE]
   -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/run_liquibase.bat [ACTIVE]
   -> config/mysql.conf [ACTIVE]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_mysql_driver.bat [ACTIVE]
   -> tools/liquibase/liquibase.bat [ACTIVE]
   -> liquibase/mysql/master.xml [ACTIVE]
      -> no included changelog files found [ACTIVE empty master]
-> scripts/batch/mysql/validate_environment.bat [ACTIVE]
   -> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> scripts/batch/common/validate_tools.bat [ACTIVE]
   -> scripts/batch/mysql/validate_port.bat [ACTIVE]
      -> scripts/python/mysql/validate_port.py [ACTIVE]
      -> config/mysql.conf [ACTIVE]
   -> scripts/batch/mysql/validate_mysql.bat [ACTIVE]
      -> scripts/python/mysql/validate_data.py [ACTIVE]
      -> scripts/python/mysql/db_connection.py [ACTIVE import]
      -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/validate_mysql.bat [ACTIVE]
   -> scripts/python/mysql/validate_data.py [ACTIVE]
   -> scripts/python/mysql/db_connection.py [ACTIVE import]
   -> config/mysql.conf [ACTIVE]
```

## 2. MySQL Windows Load Execution Tree

Pipeline: `jenkins/mysql/windows/mysql_load_pipeline.groovy` - ACTIVE

```text
jenkins/mysql/windows/mysql_load_pipeline.groovy
-> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/common/validate_tools.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
      -> config/mysql.conf [ACTIVE]
      -> tools/liquibase/liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_mysql_driver.bat [ACTIVE]
      -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/start_mysql.bat [ACTIVE]
   -> scripts/powershell/start_mysql.ps1 [ACTIVE]
   -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/validate_mysql.bat [ACTIVE]
   -> scripts/python/mysql/validate_data.py [ACTIVE]
   -> scripts/python/mysql/db_connection.py [ACTIVE import]
   -> config/mysql.conf [ACTIVE]
-> scripts/batch/mysql/validate_csv.bat [ACTIVE]
   -> scripts/python/mysql/validate_csv.py [ACTIVE]
   -> config/mysql/datasets.yaml [ACTIVE]
   -> datasets/mysql/*.csv [ACTIVE data dependency]
-> scripts/batch/mysql/load_data.bat [ACTIVE]
   -> scripts/data_loader.py mysql [ACTIVE]
      -> config/mysql.conf [ACTIVE]
      -> incoming/mysql/*.csv and incoming/mysql/*.json [ACTIVE runtime input glob]
      -> metadata/mysql/data_load_history.jsonl [ACTIVE output/dependency]
      -> archive/mysql [ACTIVE output path]
      -> failed/mysql [ACTIVE output path]
-> scripts/batch/mysql/validate_loaded_data.bat [ACTIVE]
   -> scripts/python/mysql/validate_loaded_data.py [ACTIVE]
   -> config/mysql.conf [ACTIVE]
```

## 3. MSSQL Windows Setup Execution Tree

Pipeline: `jenkins/mssql/windows/mssql_setup_pipeline.groovy` - ACTIVE

```text
jenkins/mssql/windows/mssql_setup_pipeline.groovy
-> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/install_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
   -> requirements.txt [ACTIVE]
-> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/common/validate_java_runtime.bat [ACTIVE]
-> scripts/batch/common/install_tools.bat [ACTIVE]
   -> scripts/batch/common/install_terraform.bat [ACTIVE]
   -> scripts/batch/common/install_mysql_driver.bat [ACTIVE: common tool installer still installs MySQL driver]
   -> scripts/batch/common/install_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_tools.bat [ACTIVE]
-> scripts/batch/mssql/install_mssql_tools.bat [ACTIVE]
   -> scripts/batch/mssql/install_sqlcmd.bat [ACTIVE]
   -> scripts/batch/mssql/install_mssql_driver.bat [ACTIVE]
      -> scripts/powershell/download_mssql_driver.ps1 [ACTIVE]
      -> config/windows/mssql.conf [ACTIVE]
   -> scripts/batch/mssql/validate_mssql_tools.bat [ACTIVE]
      -> config/windows/mssql.conf [ACTIVE]
-> scripts/batch/mssql/deploy_mssql.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> terraform/mssql/windows/main.tf [ACTIVE]
   -> terraform/mssql/windows/variables.tf [ACTIVE by Terraform]
   -> terraform/mssql/windows/terraform.tfvars [ACTIVE by Terraform auto-load]
   -> terraform/mssql/windows/outputs.tf [ACTIVE by Terraform]
-> scripts/batch/mssql/start_mssql.bat [ACTIVE]
   -> config/windows/mssql.conf [ACTIVE]
-> scripts/batch/mssql/create_database.bat [ACTIVE]
   -> config/windows/mssql.conf [ACTIVE]
-> scripts/batch/mssql/run_liquibase.bat [ACTIVE]
   -> config/windows/mssql.conf [ACTIVE]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_mssql_driver.bat [ACTIVE]
   -> tools/liquibase/liquibase.bat [ACTIVE]
   -> liquibase/mssql/master.xml [ACTIVE]
      -> liquibase/mssql/001_create_customers.xml [ACTIVE include]
      -> liquibase/mssql/002_create_sellers.xml [ACTIVE include]
      -> liquibase/mssql/003_create_products.xml [ACTIVE include]
      -> liquibase/mssql/004_create_orders.xml [ACTIVE include]
      -> liquibase/mssql/005_create_orderdetails.xml [ACTIVE include]
-> scripts/batch/mssql/validate_environment.bat [ACTIVE]
   -> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> scripts/batch/common/validate_tools.bat [ACTIVE]
   -> scripts/batch/mssql/validate_mssql.bat [ACTIVE]
      -> scripts/python/mssql/validate_mssql.py [ACTIVE]
      -> scripts/python/mssql/db_connection.py [ACTIVE import]
      -> config/windows/mssql.conf [ACTIVE]
-> scripts/batch/mssql/validate_mssql.bat [ACTIVE]
   -> scripts/python/mssql/validate_mssql.py [ACTIVE]
   -> scripts/python/mssql/db_connection.py [ACTIVE import]
   -> config/windows/mssql.conf [ACTIVE]
```

## 4. MSSQL Windows Load Execution Tree

Pipeline: `jenkins/mssql/windows/mssql_load_pipeline.groovy` - ACTIVE

```text
jenkins/mssql/windows/mssql_load_pipeline.groovy
-> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/common/validate_tools.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_mysql_driver.bat [ACTIVE: common validation still checks MySQL driver]
-> scripts/batch/mssql/validate_mssql.bat [ACTIVE]
   -> scripts/python/mssql/validate_mssql.py [ACTIVE]
   -> scripts/python/mssql/db_connection.py [ACTIVE import]
   -> config/windows/mssql.conf [ACTIVE]
-> scripts/batch/mssql/validate_csv.bat [ACTIVE]
   -> scripts/python/mssql/validate_csv.py [ACTIVE]
   -> datasets/mssql/*.csv [ACTIVE data dependency]
-> scripts/batch/mssql/load_data.bat [ACTIVE]
   -> scripts/python/mssql/load_all.py [ACTIVE]
      -> scripts/python/mssql/truncate_tables.py [ACTIVE]
      -> scripts/python/mssql/load_customers.py [ACTIVE]
      -> scripts/python/mssql/load_sellers.py [ACTIVE]
      -> scripts/python/mssql/load_products.py [ACTIVE]
      -> scripts/python/mssql/load_orders.py [ACTIVE]
      -> scripts/python/mssql/load_orderdetails.py [ACTIVE]
      -> scripts/python/mssql/db_connection.py [ACTIVE import]
      -> config/windows/mssql.conf [ACTIVE]
      -> datasets/mssql/customers.csv [ACTIVE]
      -> datasets/mssql/sellers.csv [ACTIVE]
      -> datasets/mssql/products.csv [ACTIVE]
      -> datasets/mssql/orders.csv [ACTIVE]
      -> datasets/mssql/orderdetails.csv [ACTIVE]
-> scripts/batch/mssql/validate_loaded_data.bat [ACTIVE]
   -> scripts/python/mssql/validate_loaded_data.py [ACTIVE]
   -> scripts/python/mssql/db_connection.py [ACTIVE import]
   -> config/windows/mssql.conf [ACTIVE]
```

## 5. MongoDB Windows Setup Execution Tree

Pipeline: `jenkins/mongodb/Jenkinsfile.setup` - ACTIVE Windows Jenkinsfile by `bat` usage.

```text
jenkins/mongodb/Jenkinsfile.setup
-> scripts/batch/common/validate_python_runtime.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/install_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
   -> requirements.txt [ACTIVE]
-> scripts/batch/validate_python_requirements.bat [ACTIVE]
   -> config/python.conf [ACTIVE if present; script has PATH fallback]
-> scripts/batch/common/install_tools.bat [ACTIVE]
   -> scripts/batch/common/install_terraform.bat [ACTIVE]
   -> scripts/batch/common/install_mysql_driver.bat [ACTIVE: common installer still installs MySQL driver]
   -> scripts/batch/common/install_liquibase.bat [ACTIVE: common installer still installs Liquibase even though MongoDB does not need Liquibase]
   -> scripts/batch/common/validate_liquibase.bat [ACTIVE]
   -> scripts/batch/common/validate_tools.bat [ACTIVE]
-> scripts/batch/mongodb/run_mongodb.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> terraform/mongodb/main.tf [ACTIVE]
   -> terraform/mongodb/variables.tf [ACTIVE by Terraform]
   -> terraform/mongodb/terraform.tfvars [ACTIVE by Terraform auto-load]
   -> scripts/powershell/mongodb/install_windows.ps1 [UNKNOWN: Terraform local-exec resource]
-> scripts/batch/mongodb/start_mongodb.bat [ACTIVE]
   -> scripts/powershell/mongodb/start_mongodb.ps1 [ACTIVE]
-> scripts/batch/mongodb/deploy_mongodb.bat [ACTIVE]
   -> scripts/python/mongodb/load_all.py [ACTIVE]
      -> scripts/python/mongodb/create_collections.py [ACTIVE]
      -> scripts/python/mongodb/create_indexes.py [ACTIVE]
      -> scripts/python/mongodb/generate_dataset.py [ACTIVE]
      -> scripts/python/mongodb/load_data.py [ACTIVE]
      -> scripts/python/mongodb/db_connection.py [ACTIVE import]
      -> config/windows/mongodb.conf [ACTIVE on Windows]
      -> datasets/mongodb/*.csv [ACTIVE data dependency]
      -> scripts/schema_detector.py mongodb [ACTIVE]
      -> incoming/mongodb/*.csv and incoming/mongodb/*.json [ACTIVE runtime input glob]
      -> metadata/mongodb/schema_registry.json [ACTIVE output/dependency]
      -> scripts/python/mongodb/validate_data.py [ACTIVE]
-> scripts/batch/mongodb/validate_environment.bat [ACTIVE]
   -> scripts/batch/mongodb/validate_port.bat [ACTIVE]
      -> scripts/python/mongodb/validate_port.py [ACTIVE]
      -> scripts/python/mongodb/db_connection.py [ACTIVE import]
      -> config/windows/mongodb.conf [ACTIVE on Windows]
   -> scripts/batch/mongodb/validate_mongodb.bat [ACTIVE]
      -> scripts/python/mongodb/validate_mongodb.py [ACTIVE]
      -> scripts/python/mongodb/db_connection.py [ACTIVE import]
      -> config/windows/mongodb.conf [ACTIVE on Windows]
   -> scripts/batch/mongodb/validate_data.bat [ACTIVE]
      -> scripts/python/mongodb/validate_data.py [ACTIVE]
      -> scripts/python/mongodb/db_connection.py [ACTIVE import]
      -> metadata/mongodb/schema_registry.json [ACTIVE input]
-> scripts/batch/mongodb/validate_mongodb.bat [ACTIVE]
   -> scripts/python/mongodb/validate_mongodb.py [ACTIVE]
   -> scripts/python/mongodb/db_connection.py [ACTIVE import]
   -> config/windows/mongodb.conf [ACTIVE on Windows]
```

## 6. MongoDB Windows Load Execution Tree

Pipeline: `jenkins/mongodb/Jenkinsfile.load` - ACTIVE Windows Jenkinsfile by `bat` usage.

```text
jenkins/mongodb/Jenkinsfile.load
-> scripts/batch/mongodb/run_mongodb.bat [ACTIVE]
   -> tools/terraform/terraform.exe [ACTIVE]
   -> terraform/mongodb/main.tf [ACTIVE]
   -> terraform/mongodb/variables.tf [ACTIVE by Terraform]
   -> terraform/mongodb/terraform.tfvars [ACTIVE by Terraform auto-load]
   -> scripts/powershell/mongodb/install_windows.ps1 [UNKNOWN: Terraform local-exec resource]
-> python scripts/schema_detector.py mongodb [ACTIVE]
   -> incoming/mongodb/*.csv and incoming/mongodb/*.json [ACTIVE runtime input glob]
   -> metadata/mongodb/schema_registry.json [ACTIVE output/dependency]
-> python scripts/data_loader_mongodb.py [ACTIVE]
   -> config/windows/mongodb.conf [ACTIVE on Windows]
   -> incoming/mongodb/*.csv and incoming/mongodb/*.json [ACTIVE runtime input glob]
   -> archive/mongodb [ACTIVE output path]
   -> failed/mongodb [ACTIVE output path]
   -> metadata/data_load_history.jsonl [ACTIVE output/dependency]
-> scripts/batch/mongodb/validate_data.bat [ACTIVE]
   -> scripts/python/mongodb/validate_data.py [ACTIVE]
   -> scripts/python/mongodb/db_connection.py [ACTIVE import]
   -> config/windows/mongodb.conf [ACTIVE on Windows]
   -> metadata/mongodb/schema_registry.json [ACTIVE input]
-> mongosh --eval "show dbs" [ACTIVE external executable]
```

## Guaranteed To Execute

These files are guaranteed to be invoked if their parent Jenkins pipeline reaches the stage and all previous stages succeed.

### Jenkins

- `jenkins/mysql/windows/mysql_setup_pipeline.groovy`
- `jenkins/mysql/windows/mysql_load_pipeline.groovy`
- `jenkins/mssql/windows/mssql_setup_pipeline.groovy`
- `jenkins/mssql/windows/mssql_load_pipeline.groovy`
- `jenkins/mongodb/Jenkinsfile.setup`
- `jenkins/mongodb/Jenkinsfile.load`

### Batch

- `scripts/batch/common/validate_python_runtime.bat`
- `scripts/batch/install_python_requirements.bat`
- `scripts/batch/validate_python_requirements.bat`
- `scripts/batch/common/validate_java_runtime.bat`
- `scripts/batch/common/install_tools.bat`
- `scripts/batch/common/install_terraform.bat`
- `scripts/batch/common/install_mysql_driver.bat`
- `scripts/batch/common/install_liquibase.bat`
- `scripts/batch/common/validate_liquibase.bat`
- `scripts/batch/common/validate_tools.bat`
- `scripts/batch/common/validate_mysql_driver.bat`
- `scripts/batch/common/validate_mssql_driver.bat`
- `scripts/batch/mysql/deploy_mysql.bat`
- `scripts/batch/mysql/start_mysql.bat`
- `scripts/batch/mysql/create_database.bat`
- `scripts/batch/mysql/run_liquibase.bat`
- `scripts/batch/mysql/validate_environment.bat`
- `scripts/batch/mysql/validate_port.bat`
- `scripts/batch/mysql/validate_mysql.bat`
- `scripts/batch/mysql/validate_csv.bat`
- `scripts/batch/mysql/load_data.bat`
- `scripts/batch/mysql/validate_loaded_data.bat`
- `scripts/batch/mssql/install_mssql_tools.bat`
- `scripts/batch/mssql/install_sqlcmd.bat`
- `scripts/batch/mssql/install_mssql_driver.bat`
- `scripts/batch/mssql/validate_mssql_tools.bat`
- `scripts/batch/mssql/deploy_mssql.bat`
- `scripts/batch/mssql/start_mssql.bat`
- `scripts/batch/mssql/create_database.bat`
- `scripts/batch/mssql/run_liquibase.bat`
- `scripts/batch/mssql/validate_environment.bat`
- `scripts/batch/mssql/validate_mssql.bat`
- `scripts/batch/mssql/validate_csv.bat`
- `scripts/batch/mssql/load_data.bat`
- `scripts/batch/mssql/validate_loaded_data.bat`
- `scripts/batch/mongodb/run_mongodb.bat`
- `scripts/batch/mongodb/start_mongodb.bat`
- `scripts/batch/mongodb/deploy_mongodb.bat`
- `scripts/batch/mongodb/validate_environment.bat`
- `scripts/batch/mongodb/validate_port.bat`
- `scripts/batch/mongodb/validate_mongodb.bat`
- `scripts/batch/mongodb/validate_data.bat`

### PowerShell

- `scripts/powershell/download_mysql_driver.ps1`
- `scripts/powershell/download_mssql_driver.ps1`
- `scripts/powershell/download_liquibase.ps1`
- `scripts/powershell/start_mysql.ps1`
- `scripts/powershell/mongodb/start_mongodb.ps1`

### Python

- `scripts/data_loader.py`
- `scripts/data_loader_mongodb.py`
- `scripts/schema_detector.py`
- `scripts/python/mysql/db_connection.py`
- `scripts/python/mysql/validate_port.py`
- `scripts/python/mysql/validate_data.py`
- `scripts/python/mysql/validate_csv.py`
- `scripts/python/mysql/validate_loaded_data.py`
- `scripts/python/mssql/db_connection.py`
- `scripts/python/mssql/validate_mssql.py`
- `scripts/python/mssql/validate_csv.py`
- `scripts/python/mssql/load_all.py`
- `scripts/python/mssql/truncate_tables.py`
- `scripts/python/mssql/load_customers.py`
- `scripts/python/mssql/load_sellers.py`
- `scripts/python/mssql/load_products.py`
- `scripts/python/mssql/load_orders.py`
- `scripts/python/mssql/load_orderdetails.py`
- `scripts/python/mssql/validate_loaded_data.py`
- `scripts/python/mongodb/db_connection.py`
- `scripts/python/mongodb/load_all.py`
- `scripts/python/mongodb/create_collections.py`
- `scripts/python/mongodb/create_indexes.py`
- `scripts/python/mongodb/generate_dataset.py`
- `scripts/python/mongodb/load_data.py`
- `scripts/python/mongodb/validate_port.py`
- `scripts/python/mongodb/validate_mongodb.py`
- `scripts/python/mongodb/validate_data.py`

### Config, Terraform, Liquibase

- `config/python.conf`
- `config/mysql.conf`
- `config/mysql/datasets.yaml`
- `config/windows/mssql.conf`
- `config/windows/mongodb.conf`
- `requirements.txt`
- `terraform/mysql/main.tf`
- `terraform/mssql/windows/main.tf`
- `terraform/mssql/windows/variables.tf`
- `terraform/mssql/windows/terraform.tfvars`
- `terraform/mssql/windows/outputs.tf`
- `terraform/mongodb/main.tf`
- `terraform/mongodb/variables.tf`
- `terraform/mongodb/terraform.tfvars`
- `liquibase/mysql/master.xml`
- `liquibase/mssql/master.xml`
- `liquibase/mssql/001_create_customers.xml`
- `liquibase/mssql/002_create_sellers.xml`
- `liquibase/mssql/003_create_products.xml`
- `liquibase/mssql/004_create_orders.xml`
- `liquibase/mssql/005_create_orderdetails.xml`

## Never Executed From These Active Windows Paths

These are not reachable from the six analyzed Windows pipelines by static trace.

### Jenkins

- `jenkins/Jenkinsfile`
- `jenkins/testing/*.groovy`
- `jenkins/mysql/windows/Jenkinsfile.*`
- `jenkins/mysql/windows/custom.*`
- `jenkins/mysql/windows/localwork/*.groovy`
- `jenkins/mysql/windows/scripts/*.bat`
- `jenkins/mysql/ubuntu/*.groovy`
- `jenkins/mssql/ubuntu/*.groovy`
- `jenkins/mongodb/custom.*`
- `jenkins/mongodb/scripts/*.bat`
- `jenkins/mongodb/ubuntu/*.groovy`
- all `jenkins/postgresql/**`

### Script Families

- all `scripts/bash/**`
- all `scripts/batch/postgresql/**`
- `scripts/batch/mysql/cleanup_mysql.bat`
- `scripts/batch/mysql/destroy_mysql.bat`
- `scripts/batch/mysql/initialize_logs.bat`
- `scripts/batch/mysql/mysql_load_with_logging.bat`
- `scripts/batch/mysql/mysql_setup_with_logging.bat`
- `scripts/batch/mysql/stop_mysql.bat`
- `scripts/batch/mssql/clean_mssql_data.bat`
- `scripts/batch/mssql/destroy_mssql_environment.bat`
- `scripts/batch/mssql/install_mssql.bat`
- `scripts/batch/mssql/stop_mssql.bat`
- `scripts/batch/mongodb/cleanup_mongodb.bat`
- `scripts/batch/mongodb/destroy_mongodb.bat`
- `scripts/batch/mongodb/initialize_logs.bat`
- `scripts/batch/mongodb/load_data.bat`
- `scripts/batch/mongodb/mongodb_load_with_logging.bat`
- `scripts/batch/mongodb/mongodb_setup_with_logging.bat`
- `scripts/batch/mongodb/stop_mongodb.bat`
- `scripts/batch/common/install_postgresql_driver.bat`
- `scripts/batch/common/validate_postgresql_driver.bat`
- `scripts/batch/common/setup_liquibase.bat`
- `scripts/batch/common/set_project_root.bat`
- `scripts/batch/common/tools.bat`
- `scripts/run_liquibase.py`
- `scripts/liquibase_generator.py`
- `scripts/metadata_manager.py`
- `scripts/schema_diff.py`
- `scripts/version_manager.py`

### Database-Specific Python Outside Active Paths

- `scripts/python/mysql/load_all.py`
- `scripts/python/mysql/load_customers.py`
- `scripts/python/mysql/load_sellers.py`
- `scripts/python/mysql/load_products.py`
- `scripts/python/mysql/load_orders.py`
- `scripts/python/mysql/load_orderdetails.py`
- `scripts/python/mysql/truncate_tables.py`
- `scripts/python/mysql/generate_liquibase_xml.py`
- `scripts/python/mysql/update_master_xml.py`
- `scripts/python/mysql/test_connection.py`
- `scripts/python/mysql/testcsvschema.py`
- `scripts/python/mysql/check_port.py`
- `scripts/python/mysql/validate_customers.py`
- `scripts/python/mssql/load_data.py`
- `scripts/python/mssql/validate_port.py`
- `scripts/python/mongodb/cleanup_collections.py`
- `scripts/python/mongodb/test_connection.py`
- all `scripts/python/postgresql/**`

### Config, Terraform, Liquibase Outside Active Paths

- `config/ubuntu/**`
- `config/mongodb.conf`
- `config/mongodb/datasets.yaml`
- `config/postgresql.conf`
- `config/postgresql/datasets.yaml`
- `config/metadata_schema.json`
- `terraform/postgresql/**`
- `liquibase/postgresql/**`
- `liquibase/failed/**`
- `liquibase/master.xml`
- `liquibase/mysql/liquibase.properties`
- `liquibase/postgresql/liquibase.properties`

## Outside Every Active Execution Path

High-confidence outside-active-path areas for the analyzed Windows pipelines:

- Ubuntu Jenkins and Bash implementation trees.
- PostgreSQL Jenkins, Batch, PowerShell, Python, Terraform, Liquibase, and config assets.
- Cleanup/destroy/stop/logging wrapper scripts not called by active Jenkins stages.
- Root helper scripts not called by active paths: `scripts/run_liquibase.py`, `scripts/schema_diff.py`, `scripts/version_manager.py`, `scripts/metadata_manager.py`, `scripts/liquibase_generator.py`.
- Root/localwork/custom Jenkins variants not selected by the six active pipeline roots.

## SAFE TO ARCHIVE

Archive means move to `docs/archive/` or equivalent only after confirming no external Jenkins jobs reference the files.

- `jenkins/testing/*.groovy`
- `jenkins/mysql/windows/localwork/*.groovy`
- `jenkins/mysql/windows/custom.*`
- `jenkins/mongodb/custom.*`
- `jenkins/mongodb/scripts/*.bat`
- `liquibase/failed/**`
- `scripts/batch/*/*_with_logging.bat`
- Ubuntu-only Jenkins/Bash files if the current release scope is Windows only.

## SAFE TO DELETE (after validation)

Delete only after a cleanup PR, external Jenkins job audit, and successful rerun of the six analyzed pipelines.

- Runtime artifacts and generated outputs already identified in prior reports: `.terraform`, `terraform.tfstate*`, `tools/terraform/terraform.exe`, database data/log folders, Python bytecode.
- Cleanup/destroy scripts not referenced by active paths if operations confirms they are not manually used:
  - `scripts/batch/mysql/cleanup_mysql.bat`
  - `scripts/batch/mysql/destroy_mysql.bat`
  - `scripts/batch/mssql/clean_mssql_data.bat`
  - `scripts/batch/mssql/destroy_mssql_environment.bat`
  - `scripts/batch/mongodb/cleanup_mongodb.bat`
  - `scripts/batch/mongodb/destroy_mongodb.bat`
- `scripts/run_liquibase.py` after confirming no external job uses it; active MySQL/MSSQL pipelines use database-owned batch Liquibase runners instead.

## HIGH RISK TO MODIFY

- `jenkins/mysql/windows/mysql_setup_pipeline.groovy`
- `jenkins/mysql/windows/mysql_load_pipeline.groovy`
- `jenkins/mssql/windows/mssql_setup_pipeline.groovy`
- `jenkins/mssql/windows/mssql_load_pipeline.groovy`
- `jenkins/mongodb/Jenkinsfile.setup`
- `jenkins/mongodb/Jenkinsfile.load`
- all active `scripts/batch/common/*` used by multiple pipelines
- `scripts/batch/mysql/*` active setup/load scripts
- `scripts/batch/mssql/*` active setup/load scripts
- `scripts/batch/mongodb/run_mongodb.bat`, `start_mongodb.bat`, `deploy_mongodb.bat`, `validate_environment.bat`, `validate_mongodb.bat`, `validate_data.bat`
- `scripts/data_loader.py` because it is actively used by MySQL Windows load.
- `scripts/data_loader_mongodb.py` because it is actively used by MongoDB Windows load.
- `scripts/python/mssql/load_all.py` and child loaders because they are actively used by MSSQL Windows load.
- `terraform/mysql/main.tf`, `terraform/mssql/windows/main.tf`, `terraform/mongodb/main.tf`
- `config/mysql.conf`, `config/windows/mssql.conf`, `config/windows/mongodb.conf`, `config/python.conf`
- `liquibase/mssql/master.xml` and included MSSQL changelogs
- `liquibase/mysql/master.xml` even though currently empty, because the active MySQL setup pipeline calls it.

## MISSION CRITICAL FILES

Mission critical means required for at least one active setup/load pipeline to complete.

- `requirements.txt`
- `config/python.conf`
- `config/mysql.conf`
- `config/mysql/datasets.yaml`
- `config/windows/mssql.conf`
- `config/windows/mongodb.conf`
- `jenkins/mysql/windows/mysql_setup_pipeline.groovy`
- `jenkins/mysql/windows/mysql_load_pipeline.groovy`
- `jenkins/mssql/windows/mssql_setup_pipeline.groovy`
- `jenkins/mssql/windows/mssql_load_pipeline.groovy`
- `jenkins/mongodb/Jenkinsfile.setup`
- `jenkins/mongodb/Jenkinsfile.load`
- `scripts/batch/common/validate_python_runtime.bat`
- `scripts/batch/install_python_requirements.bat`
- `scripts/batch/validate_python_requirements.bat`
- `scripts/batch/common/install_tools.bat`
- `scripts/batch/common/validate_tools.bat`
- `scripts/batch/mysql/deploy_mysql.bat`
- `scripts/batch/mysql/start_mysql.bat`
- `scripts/batch/mysql/create_database.bat`
- `scripts/batch/mysql/run_liquibase.bat`
- `scripts/batch/mysql/validate_mysql.bat`
- `scripts/batch/mysql/load_data.bat`
- `scripts/batch/mssql/deploy_mssql.bat`
- `scripts/batch/mssql/start_mssql.bat`
- `scripts/batch/mssql/create_database.bat`
- `scripts/batch/mssql/run_liquibase.bat`
- `scripts/batch/mssql/load_data.bat`
- `scripts/batch/mongodb/run_mongodb.bat`
- `scripts/batch/mongodb/start_mongodb.bat`
- `scripts/batch/mongodb/deploy_mongodb.bat`
- `scripts/batch/mongodb/validate_data.bat`
- `scripts/data_loader.py`
- `scripts/data_loader_mongodb.py`
- `scripts/schema_detector.py`
- active database Python `db_connection.py`, validation, and load scripts listed in the guaranteed execution section
- `terraform/mysql/main.tf`
- `terraform/mssql/windows/main.tf`
- `terraform/mongodb/main.tf`
- `liquibase/mysql/master.xml`
- `liquibase/mssql/master.xml`
- `liquibase/mssql/001_create_customers.xml`
- `liquibase/mssql/002_create_sellers.xml`
- `liquibase/mssql/003_create_products.xml`
- `liquibase/mssql/004_create_orders.xml`
- `liquibase/mssql/005_create_orderdetails.xml`

## Key Corrections From Active Trace

- `scripts/data_loader.py` is ACTIVE for MySQL Windows load through `scripts/batch/mysql/load_data.bat`.
- `scripts/data_loader_mongodb.py` is ACTIVE for MongoDB Windows load through `jenkins/mongodb/Jenkinsfile.load`.
- `scripts/run_liquibase.py` is UNUSED by the analyzed Windows paths; active Liquibase execution is through database-owned Batch scripts.
- MongoDB setup unexpectedly executes data load logic through `scripts/batch/mongodb/deploy_mongodb.bat -> scripts/python/mongodb/load_all.py`.
- Common tool installation executes MySQL driver and Liquibase steps even in MSSQL and MongoDB setup paths.
