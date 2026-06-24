# Configuration Centralization Report

Generated from config, Batch, Bash, PowerShell, Python, Jenkins, Liquibase, and Terraform files. No source files were modified.

## Scope

Included paths: `config/`, `scripts/`, `jenkins/`, `liquibase/`, and `terraform/` with config/script/IaC extensions.

Excluded paths: generated reports, Git metadata, runtime tools, database data directories, metadata, datasets, incoming, failed, and archive folders.

## Summary

- Files scanned: 289
- Total findings: 136
- database_name: 17
- dataset_path: 46
- host: 27
- password: 4
- port: 26
- username: 16

## Findings

| Type | Current Value | Current File | Current Line | Target Config Key | Risk | Migration Plan |
| --- | --- | --- | --- | --- | --- | --- |
| password | TerraformSA@2022! | config/ubuntu/mssql.conf | 9 | config.ubuntu.mssql.connection.password_secret_ref | Critical - secret literal must move to credentials manager or secret reference. | Create a Jenkins/secret-manager credential; store only password_secret_ref in config; update scripts to resolve it at runtime. |
| password | root123 | config/ubuntu/mysql.config | 5 | config.ubuntu.mysql.connection.password_secret_ref | Critical - secret literal must move to credentials manager or secret reference. | Create a Jenkins/secret-manager credential; store only password_secret_ref in config; update scripts to resolve it at runtime. |
| password | TerraformSA@2022! | config/windows/mssql.conf | 7 | config.windows.mssql.connection.password_secret_ref | Critical - secret literal must move to credentials manager or secret reference. | Create a Jenkins/secret-manager credential; store only password_secret_ref in config; update scripts to resolve it at runtime. |
| password | TerraformSA@2022! | terraform/mssql/windows/terraform.tfvars | 7 | config.windows.mssql.connection.password_secret_ref | Critical - secret literal must move to credentials manager or secret reference. | Create a Jenkins/secret-manager credential; store only password_secret_ref in config; update scripts to resolve it at runtime. |
| username | root | config/mysql.conf | 4 | config.{os}.mysql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | config/postgresql.conf | 11 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | sa | config/ubuntu/mssql.conf | 7 | config.ubuntu.mssql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | rootuser | config/ubuntu/mysql.config | 4 | config.ubuntu.mysql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | sa | config/windows/mssql.conf | 6 | config.windows.mssql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | root | liquibase/mysql/liquibase.properties | 5 | config.{os}.mysql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | liquibase/postgresql/liquibase.properties | 5 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | scripts/batch/postgresql/run_liquibase.bat | 39 | config.windows.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | root | scripts/data_loader.py | 88 | config.{os}.mysql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | scripts/data_loader.py | 98 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | sa | scripts/data_loader.py | 110 | config.{os}.mssql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | scripts/python/postgresql/create_database.py | 11 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | root | scripts/run_liquibase.py | 69 | config.{os}.mysql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | scripts/run_liquibase.py | 78 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | sa | scripts/run_liquibase.py | 87 | config.{os}.mssql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| username | postgres | terraform/postgresql/terraform.tfvars | 5 | config.{os}.postgresql.connection.username | High - identity is environment-specific and should not be embedded in executable files. | Move service account name to config and allow Jenkins/environment override per database and OS. |
| host | 127.0.0.1 | config/mongodb.conf | 1 | config.{os}.mongodb.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | config/mysql.conf | 1 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | config/postgresql.conf | 5 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | config/ubuntu/mongodb.conf | 1 | config.ubuntu.mongodb.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | config/ubuntu/mssql.conf | 1 | config.ubuntu.mssql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | config/ubuntu/mysql.config | 1 | config.ubuntu.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | config/windows/mongodb.conf | 1 | config.windows.mongodb.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | config/windows/mssql.conf | 1 | config.windows.mssql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | liquibase/mysql/liquibase.properties | 3 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | liquibase/postgresql/liquibase.properties | 3 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/batch/postgresql/run_liquibase.bat | 36 | config.windows.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/data_loader.py | 86 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/data_loader.py | 96 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/data_loader.py | 108 | config.{os}.mssql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/data_loader_mongodb.py | 64 | config.{os}.mongodb.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/powershell/postgresql/start_postgresql.ps1 | 57 | config.windows.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/powershell/postgresql/validate_postgresql.ps1 | 49 | config.windows.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/powershell/postgresql/validate_postgresql.ps1 | 68 | config.windows.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/powershell/postgresql/validate_postgresql.ps1 | 81 | config.windows.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | 127.0.0.1 | scripts/python/mysql/validate_port.py | 18 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/python/postgresql/check_port.py | 11 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/python/postgresql/create_database.py | 12 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/python/postgresql/db_connection.py | 47 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/run_liquibase.py | 66 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/run_liquibase.py | 75 | config.{os}.postgresql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/run_liquibase.py | 84 | config.{os}.mssql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| host | localhost | scripts/run_liquibase.py | 213 | config.{os}.mysql.connection.host | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint host to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27018 | config/mongodb.conf | 3 | config.{os}.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3306 | config/mysql.conf | 2 | config.{os}.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | config/postgresql.conf | 7 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27018 | config/ubuntu/mongodb.conf | 3 | config.ubuntu.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 1533 | config/ubuntu/mssql.conf | 3 | config.ubuntu.mssql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3306 | config/ubuntu/mysql.config | 2 | config.ubuntu.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27018 | config/windows/mongodb.conf | 3 | config.windows.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 1533 | config/windows/mssql.conf | 2 | config.windows.mssql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3307 | liquibase/mysql/liquibase.properties | 3 | config.{os}.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | liquibase/postgresql/liquibase.properties | 3 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/batch/postgresql/run_liquibase.bat | 37 | config.windows.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3306 | scripts/data_loader.py | 87 | config.{os}.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/data_loader.py | 97 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 1433 | scripts/data_loader.py | 108 | config.{os}.mssql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27017 | scripts/data_loader_mongodb.py | 65 | config.{os}.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27018 | scripts/powershell/mongodb/start_mongodb.ps1 | 32 | config.windows.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/powershell/postgresql/start_postgresql.ps1 | 22 | config.windows.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/python/postgresql/create_database.py | 13 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/python/postgresql/db_connection.py | 48 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3306 | scripts/run_liquibase.py | 67 | config.{os}.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | scripts/run_liquibase.py | 76 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 1433 | scripts/run_liquibase.py | 85 | config.{os}.mssql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 3306 | scripts/run_liquibase.py | 214 | config.{os}.mysql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 27018 | terraform/mongodb/terraform.tfvars | 10 | config.{os}.mongodb.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 1433 | terraform/mssql/windows/terraform.tfvars | 3 | config.windows.mssql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| port | 5432 | terraform/postgresql/terraform.tfvars | 7 | config.{os}.postgresql.connection.port | High - endpoint literal can break Jenkins agents, OS targets, or environment promotion. | Move endpoint port to config/{os}/{database}.conf and read through the shared config loader. |
| database_name | EcommerceMongoDB | config/mongodb.conf | 5 | config.{os}.mongodb.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMySQL | config/mysql.conf | 3 | config.{os}.mysql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | DataManagementDB | config/postgresql.conf | 9 | config.{os}.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMongoDB | config/ubuntu/mongodb.conf | 5 | config.ubuntu.mongodb.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMSSQL | config/ubuntu/mssql.conf | 5 | config.ubuntu.mssql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMySQL | config/ubuntu/mysql.config | 3 | config.ubuntu.mysql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMongoDB | config/windows/mongodb.conf | 5 | config.windows.mongodb.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMSSQL | config/windows/mssql.conf | 4 | config.windows.mssql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMySQL | liquibase/mysql/liquibase.properties | 3 | config.{os}.mysql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | DataManagementDB | liquibase/postgresql/liquibase.properties | 3 | config.{os}.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | DataManagementDB | scripts/batch/postgresql/run_liquibase.bat | 38 | config.windows.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | test | scripts/data_loader_mongodb.py | 66 | config.{os}.mongodb.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | DataManagementDB | scripts/python/postgresql/create_database.py | 10 | config.{os}.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | postgres | scripts/run_liquibase.py | 77 | config.{os}.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | ecommerce | scripts/run_liquibase.py | 215 | config.{os}.mysql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | EcommerceMSSQL | terraform/mssql/windows/terraform.tfvars | 5 | config.windows.mssql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| database_name | DataManagementDB | terraform/postgresql/terraform.tfvars | 1 | config.{os}.postgresql.connection.database_name | Medium - database naming should be per database/OS/environment config. | Move database name to config/{os}/{database}.conf and stop deriving it from script literals. |
| dataset_path | *.csv | scripts/data_loader.py | 404 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | *.json | scripts/data_loader.py | 404 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | *.csv | scripts/data_loader_mongodb.py | 298 | config.{os}.mongodb.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | *.json | scripts/data_loader_mongodb.py | 298 | config.{os}.mongodb.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_changes.json | scripts/liquibase_generator.py | 184 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | metadata_schema.json | scripts/metadata_manager.py | 103 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/python/mongodb/validate_data.py | 19 | config.{os}.mongodb.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | customers.csv | scripts/python/mssql/load_customers.py | 9 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | orderdetails.csv | scripts/python/mssql/load_orderdetails.py | 8 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | orders.csv | scripts/python/mssql/load_orders.py | 8 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | products.csv | scripts/python/mssql/load_products.py | 8 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | sellers.csv | scripts/python/mssql/load_sellers.py | 8 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Customers.csv | scripts/python/mssql/validate_csv.py | 9 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Sellers.csv | scripts/python/mssql/validate_csv.py | 10 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Products.csv | scripts/python/mssql/validate_csv.py | 11 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Orders.csv | scripts/python/mssql/validate_csv.py | 12 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | OrderDetails.csv | scripts/python/mssql/validate_csv.py | 13 | config.{os}.mssql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/python/mysql/generate_liquibase_xml.py | 7 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Customers.csv | scripts/python/mysql/load_customers.py | 9 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | OrderDetails.csv | scripts/python/mysql/load_orderdetails.py | 8 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Orders.csv | scripts/python/mysql/load_orders.py | 8 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Products.csv | scripts/python/mysql/load_products.py | 8 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Sellers.csv | scripts/python/mysql/load_sellers.py | 8 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | datasets/mysql/Customers.csv | scripts/python/mysql/testcsvschema.py | 3 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | datasets/mysql/Sellers.csv | scripts/python/mysql/testcsvschema.py | 4 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | datasets/mysql/Products.csv | scripts/python/mysql/testcsvschema.py | 5 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | datasets/mysql/Orders.csv | scripts/python/mysql/testcsvschema.py | 6 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | datasets/mysql/OrderDetails.csv | scripts/python/mysql/testcsvschema.py | 7 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/python/mysql/validate_data.py | 30 | config.{os}.mysql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Customers.csv | scripts/python/postgresql/generate_dataset.py | 71 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Sellers.csv | scripts/python/postgresql/generate_dataset.py | 83 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Products.csv | scripts/python/postgresql/generate_dataset.py | 98 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Orders.csv | scripts/python/postgresql/generate_dataset.py | 115 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | OrderDetails.csv | scripts/python/postgresql/generate_dataset.py | 131 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Customers.csv | scripts/python/postgresql/load_all.py | 24 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Sellers.csv | scripts/python/postgresql/load_all.py | 25 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Products.csv | scripts/python/postgresql/load_all.py | 26 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | Orders.csv | scripts/python/postgresql/load_all.py | 27 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | OrderDetails.csv | scripts/python/postgresql/load_all.py | 28 | config.{os}.postgresql.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/schema_detector.py | 131 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | *.csv | scripts/schema_detector.py | 144 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | *.json | scripts/schema_detector.py | 161 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/schema_diff.py | 133 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_changes.json | scripts/schema_diff.py | 135 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_registry.json | scripts/version_manager.py | 86 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |
| dataset_path | schema_versions.json | scripts/version_manager.py | 87 | config.{os}.{database}.paths.dataset_path | Medium - load pipeline portability depends on config-driven dataset paths. | Move dataset location to config/{os}/{database}.conf or database-owned datasets.yaml; resolve relative to PROJECT_ROOT. |

## Highest-Volume Files

| File | Finding Count |
| --- | --- |
| scripts/run_liquibase.py | 13 |
| scripts/data_loader.py | 11 |
| config/ubuntu/mssql.conf | 5 |
| config/ubuntu/mysql.config | 5 |
| config/windows/mssql.conf | 5 |
| scripts/data_loader_mongodb.py | 5 |
| scripts/python/mssql/validate_csv.py | 5 |
| scripts/python/mysql/testcsvschema.py | 5 |
| scripts/python/postgresql/generate_dataset.py | 5 |
| scripts/python/postgresql/load_all.py | 5 |
| config/mysql.conf | 4 |
| config/postgresql.conf | 4 |
| liquibase/mysql/liquibase.properties | 4 |
| liquibase/postgresql/liquibase.properties | 4 |
| scripts/batch/postgresql/run_liquibase.bat | 4 |
| scripts/python/postgresql/create_database.py | 4 |
| terraform/mssql/windows/terraform.tfvars | 3 |
| terraform/postgresql/terraform.tfvars | 3 |
| config/mongodb.conf | 3 |
| config/ubuntu/mongodb.conf | 3 |
| config/windows/mongodb.conf | 3 |
| scripts/powershell/postgresql/validate_postgresql.ps1 | 3 |
| scripts/schema_detector.py | 3 |
| scripts/powershell/postgresql/start_postgresql.ps1 | 2 |
| scripts/python/postgresql/db_connection.py | 2 |


## Centralization Target

Use OS and database scoped keys in the target config structure:

```text
config/{os}/{database}.conf
  connection.username
  connection.password_secret_ref
  connection.host
  connection.port
  connection.database_name
  paths.dataset_path
```

Passwords should not be stored as plaintext config values. Store them in Jenkins credentials or the chosen enterprise secret manager, and place only the secret reference name in configuration.

## Migration Controls

1. Add missing config keys without changing behavior.
2. Update one database/OS pipeline at a time to read keys from config.
3. Keep old literals during a short compatibility window only if needed for rollback.
4. Validate setup and load pipelines for the affected database/OS pair.
5. Remove literals only after successful pipeline evidence is captured.
