# DataPlatform-Automation Execution Flow

**Scope:** Actual implemented flow as of 2026-06-12.

## 1. Preconditions

The functioning path requires:

- Windows x64 Jenkins agent or interactive Windows host.
- Repository checked out at the expected path for hard-coded pipeline variants, or at the current directory for relative variants.
- PowerShell and outbound HTTPS.
- Java available on `PATH`; Liquibase was verified locally with Java 21.0.11.
- Python available through `python`, `py`, or configured executable.
- Permission to create processes and write `databases`, `terraform/mysql`, and `logs`.
- Port 3307 available.

## 2. Fresh Clone

```text
git clone
  |
  +-> Source/config/datasets/changelogs are present
  +-> tools/* is present because it is tracked
  +-> databases/mysql is absent because ignored
  +-> terraform state/provider cache is absent because ignored
  +-> logs are absent because ignored
```

The repository does not contain a bootstrap entry point that selects setup/load automatically. A user or Jenkins job must choose a pipeline or batch script.

## 3. Recommended Existing Setup Entry Point

The most complete current pipeline is:

`jenkins/mysql/mysql_setup_pipeline.groovy`

```text
Validate Python Runtime
  |
Install Python Requirements
  |
Validate Python Requirements
  |
Validate Java Runtime
  |
Install Tools
  |
Deploy MySQL
  |
Create Database
  |
Run Liquibase
  |
Validate Environment
  |
Validate MySQL
```

### Stage details

#### Validate Python Runtime

Calls `scripts/batch/common/validate_python_runtime.bat`.

1. Attempts to read `config/python.conf`, but its calculated root points to `scripts`, so this path is wrong.
2. Falls back to the first `where python` result.
3. Runs `--version`.
4. Does not enforce Python 3.12+.

#### Install Python Requirements

Calls `scripts/batch/install_python_requirements.bat`.

1. Attempts configuration-based interpreter selection with an unreliable `ROOT` expression.
2. Falls back to `where python`.
3. Runs `python -m pip install -r requirements.txt`.
4. Installs unpinned packages into the selected interpreter environment.

#### Validate Python Requirements

Calls `scripts/batch/validate_python_requirements.bat`.

Imports:

- `yaml`
- `dotenv`
- `mysql.connector`
- `pandas`

No versions are validated.

#### Validate Java Runtime

Calls `scripts/batch/common/validate_java_runtime.bat`.

1. Uses `where java`.
2. Prints `JAVA_HOME`.
3. Runs `java -version`.
4. Does not enforce Java 21.

#### Install Tools

Calls `scripts/batch/common/install_tools.bat`.

```text
install_terraform.bat
  -> tools/terraform/terraform.exe

install_mysql_driver.bat
  -> download_mysql_driver.ps1
  -> tools/drivers/mysql-connector-j-9.5.0.jar

install_liquibase.bat
  -> download_liquibase.ps1
  -> tools/liquibase/*
```

Existing files cause downloads to be skipped. No file integrity checks occur.

## 4. MySQL Deployment

Entry: `scripts/batch/mysql/deploy_mysql.bat`

```text
Locate tools/terraform/terraform.exe
  |
cd terraform/mysql
  |
terraform init
  |
terraform apply with four Windows targets
```

### Terraform resource sequence

```text
null_resource.download_mysql_windows
  |
  | Invoke-WebRequest
  | URL: https://cdn.mysql.com/Downloads/MySQL-9.7/mysql-9.7.0-winx64.zip
  v
databases/mysql/mysql.zip
  |
null_resource.extract_mysql_windows
  |
  | delete databases/mysql/server if present
  | Expand-Archive
  | rename first mysql-* directory to server
  v
databases/mysql/server
  |
null_resource.init_mysql_windows
  |
  | create databases/mysql/data
  | mysqld.exe --initialize-insecure
  | validate ibdata1 exists
  v
databases/mysql/data
  |
null_resource.start_mysql_windows
  |
  | scripts/powershell/start_mysql.ps1
  | Start-Process mysqld.exe
  | poll netstat up to 30 seconds
  v
TCP listener on port 3307
```

### Deployment failure behavior

- Download/extract/init PowerShell errors fail the Terraform provisioner.
- `deploy_mysql.bat` does not provide stage-specific checks after `terraform init`.
- Existing Terraform state can cause resources to be considered complete even if local files/processes were manually removed.
- An untargeted apply also attempts missing Linux scripts.
- A failure after extraction can leave a partially initialized directory.

## 5. Database Creation

Entry: `scripts/batch/mysql/create_database.bat`

Inputs from `config/mysql.conf`:

- `MYSQL_PORT`
- `MYSQL_DB`
- `MYSQL_USER`
- `MYSQL_PASSWORD` is read but unused.

Actual command shape:

```bat
mysql.exe -u root -P 3307 -e "CREATE DATABASE IF NOT EXISTS EcommerceMySQL;"
```

The host defaults to the MySQL client default. A future non-empty password is not passed, so this script would fail unless authentication is changed.

## 6. Liquibase Execution

Entry: `scripts/batch/mysql/run_liquibase.bat`

```text
Read mysql.conf
  |
Find tools/drivers/*.jar
  |
Check java -version
  |
Run tools/liquibase/liquibase.bat update
  |
master.xml
  +-> Customers
  +-> Sellers
  +-> Products + FK Sellers
  +-> OrdersTable + FK Customers
  +-> OrderDetails + FKs OrdersTable/Products
```

Liquibase connection:

```text
jdbc:mysql://127.0.0.1:3307/EcommerceMySQL
user=root
password=<empty>
driver=com.mysql.cj.jdbc.Driver
```

Liquibase creates:

- `DATABASECHANGELOG`
- `DATABASECHANGELOGLOCK`
- `Customers`
- `Sellers`
- `Products`
- `OrdersTable`
- `OrderDetails`

The trailing `pause` is an automation defect and may mask Liquibase's return code.

## 7. Environment Validation

Entry: `scripts/batch/mysql/validate_environment.bat`

```text
validate_python_runtime.bat
  |
validate_python_requirements.bat
  |
validate_tools.bat
  |
validate_port.bat -> validate_port.py
  |
validate_mysql.bat -> validate_mysql.py
  |
validate_csv.bat -> validate_csv.py
```

This validator is a **post-deployment** validator. It fails before deployment because it requires:

- A listener on port 3307.
- A connectable target database.
- All five business tables and two Liquibase tables.

Therefore, documentation or pipelines that place it before deployment are logically inconsistent.

## 8. Data Loading

Primary entry: `scripts/batch/mysql/load_data.bat`  
Python orchestrator: `scripts/python/mysql/load_all.py`

```text
truncate_tables.py
  |
load_customers.py      Customers.csv
  |
load_sellers.py        Sellers.csv
  |
load_products.py       Products.csv
  |
load_orders.py         Orders.csv
  |
load_orderdetails.py   OrderDetails.csv
```

### Truncation

1. Connects to configured database.
2. Executes `SET FOREIGN_KEY_CHECKS = 0`.
3. Reads every table from `SHOW TABLES`.
4. Truncates all except `databasechangelog` and `databasechangeloglock`.
5. Re-enables FK checks.

### Load behavior

Each loader:

1. Reads one complete CSV with pandas.
2. Opens a new database connection.
3. Inserts one row at a time with parameterized SQL.
4. Commits its own table.
5. Closes the cursor/connection on success.

### Transaction boundary

```text
TRUNCATE commits independently
Customers commit
Sellers commit
Products commit
Orders commit
OrderDetails commit
```

There is no all-or-nothing transaction. Failure leaves partial data.

## 9. Validation

### Pre-load CSV validation

`validate_csv.py` checks:

- YAML can be read.
- Required files exist.
- DataFrames are not empty.
- Required headers exist.

It does not check:

- Duplicate keys.
- Nulls.
- Data types.
- Date formats.
- Numeric ranges.
- Foreign-key references.
- Exact/extra columns.
- Encoding or delimiter.

### Database validation

`validate_mysql.py` checks:

- Connection succeeds.
- Selected database matches configured name case-insensitively.
- Server port and version can be queried.
- Seven required table names exist.

It does not validate loaded records or schema definitions.

### Current dataset facts

Static review found:

| Dataset | Data rows | Duplicate declared keys | Orphan references |
|---|---:|---:|---:|
| Customers.csv | 50 | 0 | N/A |
| Sellers.csv | 50 | 0 | N/A |
| Products.csv | 50 | 0 | 0 seller references |
| Orders.csv | 50 | 0 | 0 customer references |
| OrderDetails.csv | 50 | 0 | 0 order/product references |

These checks are review-time evidence, not current pipeline functionality.

## 10. Jenkins Success Path

```text
All bat steps return 0
  |
All setup/load stages complete
  |
post.success message
  |
post.always completion message
```

No reports or logs are archived by Jenkins.

## 11. Jenkins Failure Path

```text
Any bat step returns nonzero
  |
Current stage fails
  |
Subsequent normal stages are skipped
  |
post.failure message
  |
post.always completion message
```

There is no rollback or cleanup. Possible retained state includes:

- Downloaded/extracted server.
- Initialized passwordless database.
- Running MySQL process.
- Partially applied Liquibase schema.
- Empty or partially loaded business tables.
- Local Terraform state claiming completed resources.

## 12. Logging Flows

### Load wrapper

`mysql_load_with_logging.bat`:

```text
initialize logs
  -> append timestamp
  -> validate environment
  -> load data
  -> append completion
```

It does not invoke final database/data validation.

### Setup wrapper defect

`mysql_setup_with_logging.bat`:

```text
initialize logs
  -> append timestamp
  -> validate environment
  -> append completion
```

Despite its name, it does not install tools, deploy MySQL, create the database, or run Liquibase.

## 13. Shutdown, Cleanup, and Destroy

### Stop

`stop_mysql.ps1` finds a TCP owner for configured port and force-kills it. It does not verify the process is `mysqld.exe`.

### Cleanup

`cleanup_mysql.bat` runs full environment validation and then truncates all business tables.

### Destroy

`destroy_mysql.bat`:

1. Calls stop script.
2. Recursively deletes `databases/mysql`.
3. Recursively deletes `logs`.

It does not run `terraform destroy` or remove `terraform/mysql/terraform.tfstate`, so stale state remains.

## 14. Operational Dependency Graph

```text
Jenkins job configuration
  -> workspace/path correctness
  -> Windows agent
     -> PowerShell
     -> Java
     -> Python + pip packages
     -> Terraform + null provider
     -> Liquibase + Connector/J
     -> network access for missing artifacts
     -> local port 3307
     -> writable local filesystem
```

## 15. Safe Enterprise Target Flow

```text
Checkout
  -> static validation/tests/security scans
  -> resolve signed, checksummed dependencies
  -> provision isolated database
  -> wait for authenticated DB readiness
  -> Liquibase validate/status/updateSQL approval/update
  -> stage and validate source data
  -> transactional/bulk load
  -> row-count and quality reconciliation
  -> publish reports/metrics
  -> backup/tag/release
  -> guaranteed cleanup for ephemeral environments
```
