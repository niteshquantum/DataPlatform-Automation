# Folder Restructure Plan

This is a planning document only. Do not execute moves until dependency references and green pipeline baselines are captured.

## Phased Strategy

1. Baseline current green pipelines and archive logs externally.
2. Remove generated/runtime artifacts from version control using a separate cleanup PR only after approval.
3. Normalize config layout to config/windows and config/ubuntu.
4. Move database-specific scripts out of common/root script locations into database-owned setup/load folders.
5. Normalize Jenkins names to setup_pipeline.groovy and load_pipeline.groovy under jenkins/{db}/{os}.
6. Normalize Terraform to terraform/{db}/{os} without shared Terraform frameworks.
7. Re-run affected pipeline chains after every small move batch.

## Recommendations

- Current Location: `config/mongodb.conf`
  Target Location: `config/windows/mongodb.conf and config/ubuntu/mongodb.conf`
  Reason: Align configuration with target OS/database layout.
  Risk Level: Medium
  Affected Pipelines: All pipelines using this config
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run setup/load for affected database on both OS targets
- Current Location: `config/mysql.conf`
  Target Location: `config/windows/mysql.conf and config/ubuntu/mysql.conf`
  Reason: Align configuration with target OS/database layout.
  Risk Level: Medium
  Affected Pipelines: All pipelines using this config
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run setup/load for affected database on both OS targets
- Current Location: `config/postgresql.conf`
  Target Location: `config/windows/postgresql.conf and config/ubuntu/postgresql.conf`
  Reason: Align configuration with target OS/database layout.
  Risk Level: Medium
  Affected Pipelines: All pipelines using this config
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run setup/load for affected database on both OS targets
- Current Location: `config/python.conf`
  Target Location: `config/{windows|ubuntu}/common.conf or keep only if truly global`
  Reason: Align configuration with target OS/database layout.
  Risk Level: Medium
  Affected Pipelines: All pipelines using this config
  Affected Databases: common
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run setup/load for affected database on both OS targets
- Current Location: `config/ubuntu/mysql.config`
  Target Location: `config/windows/mysql.conf and config/ubuntu/mysql.conf`
  Reason: Align configuration with target OS/database layout.
  Risk Level: Medium
  Affected Pipelines: All pipelines using this config
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run setup/load for affected database on both OS targets
- Current Location: `config/mongodb.conf`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `config/mysql.conf`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `config/postgresql.conf`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific config is outside target config/{os}/ layout.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/failed/brand table_create.xml`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/failed/customers_create.xml`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `liquibase/master.xml`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Liquibase file not owned by mysql/mssql/postgresql.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/bash/common/install_mssql_driver.sh`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/bash/common/install_mysql_driver.sh`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_mssql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_mysql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/install_postgresql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_mssql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_mysql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/batch/common/validate_postgresql_driver.bat`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific file in common folder.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/data_loader.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/data_loader_mongodb.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/liquibase_generator.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/metadata_manager.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_mssql_driver.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_mysql_driver.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/download_postgresql_driver copy.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: postgresql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/install_mssql.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mssql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/start_mysql.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/powershell/stop_mysql.ps1`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Database-specific PowerShell script is at scripts/powershell root.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: mysql
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/run_liquibase.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/schema_detector.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/schema_diff.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment
- Current Location: `scripts/version_manager.py`
  Target Location: `scripts/{technology}/{database}/{setup|load}/ or database-owned config/liquibase folder`
  Reason: Script is in root scripts folder instead of scripts/{technology}/{common|database}.
  Risk Level: Medium
  Affected Pipelines: Affected by static references and Jenkins job definitions
  Affected Databases: N/A
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run affected setup/load pipelines in lower environment