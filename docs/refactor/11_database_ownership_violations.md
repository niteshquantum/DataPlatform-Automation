# Database Ownership Violations

Database-specific files must belong to that database. Common folders are only for reusable utilities and database-neutral tool installation/validation.

| File | Violation |
| --- | --- |
| config/mongodb.conf | Database-specific config is outside target config/{os}/ layout. |
| config/mysql.conf | Database-specific config is outside target config/{os}/ layout. |
| config/postgresql.conf | Database-specific config is outside target config/{os}/ layout. |
| liquibase/failed/brand table_create.xml | Liquibase file not owned by mysql/mssql/postgresql. |
| liquibase/failed/customers_create.xml | Liquibase file not owned by mysql/mssql/postgresql. |
| liquibase/master.xml | Liquibase file not owned by mysql/mssql/postgresql. |
| scripts/bash/common/install_mssql_driver.sh | Database-specific file in common folder. |
| scripts/bash/common/install_mysql_driver.sh | Database-specific file in common folder. |
| scripts/batch/common/install_mssql_driver.bat | Database-specific file in common folder. |
| scripts/batch/common/install_mysql_driver.bat | Database-specific file in common folder. |
| scripts/batch/common/install_postgresql_driver.bat | Database-specific file in common folder. |
| scripts/batch/common/validate_mssql_driver.bat | Database-specific file in common folder. |
| scripts/batch/common/validate_mysql_driver.bat | Database-specific file in common folder. |
| scripts/batch/common/validate_postgresql_driver.bat | Database-specific file in common folder. |
| scripts/data_loader.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/data_loader_mongodb.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/liquibase_generator.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/metadata_manager.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/powershell/download_mssql_driver.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/powershell/download_mysql_driver.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/powershell/download_postgresql_driver copy.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/powershell/install_mssql.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/powershell/start_mysql.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/powershell/stop_mysql.ps1 | Database-specific PowerShell script is at scripts/powershell root. |
| scripts/run_liquibase.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/schema_detector.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/schema_diff.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |
| scripts/version_manager.py | Script is in root scripts folder instead of scripts/{technology}/{common\|database}. |

## Required Recommendation Fields

- Current Location: `config/mongodb.conf`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `config/mysql.conf`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `config/postgresql.conf`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/failed/brand table_create.xml`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/failed/customers_create.xml`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/master.xml`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/bash/common/install_mssql_driver.sh`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/bash/common/install_mysql_driver.sh`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_mssql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_mysql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_postgresql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_mssql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_mysql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_postgresql_driver.bat`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/data_loader.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/data_loader_mongodb.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/liquibase_generator.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/metadata_manager.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_mssql_driver.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_mysql_driver.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_postgresql_driver copy.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/install_mssql.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/start_mysql.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/stop_mysql.ps1`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/run_liquibase.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/schema_detector.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/schema_diff.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/version_manager.py`
  Target Location: `database-owned folder under config, liquibase, jenkins, terraform, or scripts/{technology}/{database}/{setup|load}`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: TBD by dependency map
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment