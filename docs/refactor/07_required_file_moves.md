# Required File Moves

No moves were performed. This report lists planned moves and required updates.

## Config Moves

| Current Location | Target Location | Reason | Risk Level |
| --- | --- | --- | --- |
| config/mongodb.conf | config/windows and config/ubuntu db-specific .conf | Target config structure compliance | Medium |
| config/mysql.conf | config/windows and config/ubuntu db-specific .conf | Target config structure compliance | Medium |
| config/postgresql.conf | config/windows and config/ubuntu db-specific .conf | Target config structure compliance | Medium |
| config/python.conf | Review | Target config structure compliance | Medium |
| config/ubuntu/mysql.config | config/windows and config/ubuntu db-specific .conf | Target config structure compliance | Medium |

## Ownership Moves

| Current Location | Target Location | Reason | Risk Level |
| --- | --- | --- | --- |
| config/mongodb.conf | scripts/{technology}/{database}/{setup\|load}/ | Database-specific config is outside target config/{os}/ layout. | Medium |
| config/mysql.conf | scripts/{technology}/{database}/{setup\|load}/ | Database-specific config is outside target config/{os}/ layout. | Medium |
| config/postgresql.conf | scripts/{technology}/{database}/{setup\|load}/ | Database-specific config is outside target config/{os}/ layout. | Medium |
| liquibase/failed/brand table_create.xml | scripts/{technology}/{database}/{setup\|load}/ | Liquibase file not owned by mysql/mssql/postgresql. | Medium |
| liquibase/failed/customers_create.xml | scripts/{technology}/{database}/{setup\|load}/ | Liquibase file not owned by mysql/mssql/postgresql. | Medium |
| liquibase/master.xml | scripts/{technology}/{database}/{setup\|load}/ | Liquibase file not owned by mysql/mssql/postgresql. | Medium |
| scripts/bash/common/install_mssql_driver.sh | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/bash/common/install_mysql_driver.sh | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/install_mssql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/install_mysql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/install_postgresql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/validate_mssql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/validate_mysql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/batch/common/validate_postgresql_driver.bat | scripts/{technology}/{database}/{setup\|load}/ | Database-specific file in common folder. | Medium |
| scripts/data_loader.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/data_loader_mongodb.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/liquibase_generator.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/metadata_manager.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/powershell/download_mssql_driver.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/powershell/download_mysql_driver.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/powershell/download_postgresql_driver copy.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/powershell/install_mssql.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/powershell/start_mysql.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/powershell/stop_mysql.ps1 | scripts/{technology}/{database}/{setup\|load}/ | Database-specific PowerShell script is at scripts/powershell root. | Medium |
| scripts/run_liquibase.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/schema_detector.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/schema_diff.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |
| scripts/version_manager.py | scripts/{technology}/{database}/{setup\|load}/ | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. | Medium |

## Jenkins Moves/Renames

| Current Location | Target Location | Reason | Risk Level |
| --- | --- | --- | --- |
| jenkins/Jenkinsfile | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/Jenkinsfile.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/Jenkinsfile.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/custom.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/custom.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/scripts/mongodb_load_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/scripts/mongodb_setup_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mongodb/ubuntu/mongodb_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mongodb/ubuntu/mongodb_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mssql/ubuntu/mssql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mssql/ubuntu/mssql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mssql/windows/mssql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mssql/windows/mssql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mysql/ubuntu/mysql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mysql/ubuntu/mysql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mysql/windows/Jenkinsfile.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/Jenkinsfile.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/custom.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/custom.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/localwork/mysql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/localwork/mysql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/mysql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mysql/windows/mysql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/mysql/windows/scripts/mysql_load_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/mysql/windows/scripts/mysql_setup_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/Jenkinsfile.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/Jenkinsfile.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/custom.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/custom.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/postgresql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/postgresql/postgresql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/postgresql/scripts/postgresql_load_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/scripts/postgresql_setup_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/ubuntu/postgresql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/postgresql/ubuntu/postgresql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/postgresql/windows/Jenkinsfile.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/Jenkinsfile.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/custom.load | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/custom.setup | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/localwork/postgresql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/localwork/postgresql_setup_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/postgresql_load_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Pipeline naming violation; target names are setup_pipeline.groovy and load_pipeline.groovy. | High |
| jenkins/postgresql/windows/scripts/postgresql_load_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/postgresql/windows/scripts/postgresql_setup_pipeline.bat | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/testing/python_debug_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/testing/python_debug_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Disallowed cleanup/destroy/validation/debug Jenkins pipeline category. | High |
| jenkins/testing/tools_debug_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Non-target Jenkins artifact; target permits only setup/load pipeline groovy files under db/os folders. | High |
| jenkins/testing/tools_debug_pipeline.groovy | jenkins/{db}/{os}/setup_pipeline.groovy or load_pipeline.groovy | Disallowed cleanup/destroy/validation/debug Jenkins pipeline category. | High |

## Terraform Moves

| Current Location | Target Location | Reason | Risk Level |
| --- | --- | --- | --- |
| terraform/mongodb/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mongodb/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mongodb/terraform.tfstate | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mongodb/terraform.tfstate.backup | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mssql/windows/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mssql/windows/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mssql/windows/terraform.tfstate | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mssql/windows/terraform.tfstate.backup | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mysql/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mysql/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mysql/terraform.tfstate | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mysql/terraform.tfstate.backup | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Runtime Terraform artifact must not be committed. | High |
| terraform/mysql/windows/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/mysql/ubuntu/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/mssql/ubuntu/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/mongodb/windows/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/mongodb/ubuntu/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/postgresql/windows/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
| terraform/postgresql/ubuntu/ | terraform/{db}/{os}/ or DELETE CANDIDATE for runtime state | Missing target self-contained Terraform folder. | High |
