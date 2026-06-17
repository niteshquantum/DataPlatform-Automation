# DataPlatform-Automation Repository Tree

**Inventory date:** 2026-06-12  
**Workspace files excluding `.git`:** 646  
**Workspace size excluding `.git`:** approximately 2.07 GB

## Legend

- `[source]` authored project source/configuration.
- `[data]` sample input data.
- `[vendored]` committed third-party distribution.
- `[generated]` ignored runtime/build state.
- `[empty]` zero-byte file.
- `[missing]` referenced by source but absent.

## Logical Tree

```text
DataPlatform-Automation/
|-- .env                                      [source, tracked]
|-- .env.example                              [source, tracked]
|-- .gitignore                                [source]
|-- README.md                                 [source]
|-- requirements.txt                          [source]
|
|-- config/
|   |-- mysql.conf                            [source]
|   |-- python.conf                           [source]
|   `-- mysql/
|       `-- datasets.yaml                     [source]
|
|-- databases/                                [generated, ignored]
|   `-- mysql/
|       |-- mysql.zip                         [generated, 340,476,547 bytes]
|       |-- server/                           [generated MySQL 9.7.0 distribution]
|       `-- data/                             [generated live MySQL data]
|
|-- datasets/
|   `-- mysql/
|       |-- Customers.csv                     [data, 50 rows]
|       |-- Sellers.csv                       [data, 50 rows]
|       |-- Products.csv                      [data, 50 rows]
|       |-- Orders.csv                        [data, 50 rows]
|       `-- OrderDetails.csv                  [data, 50 rows]
|
|-- docs/
|   `-- README.md                             [source]
|
|-- jenkins/
|   |-- mysql/
|   |   |-- Jenkinsfile.setup                 [source]
|   |   |-- Jenkinsfile.load                  [source]
|   |   |-- mysql_setup_pipeline.groovy       [source]
|   |   |-- mysql_load_pipeline.groovy        [source]
|   |   |-- custom.setup                      [source, invalid Markdown fences]
|   |   |-- custom.load                       [source]
|   |   `-- scripts/
|   |       |-- mysql_setup_pipeline.bat      [source]
|   |       `-- mysql_load_pipeline.bat       [source]
|   `-- testing/
|       |-- python_debug_pipeline.groovy      [source]
|       `-- tools_debug_pipeline.groovy       [source]
|
|-- liquibase/
|   `-- mysql/
|       |-- master.xml                        [source]
|       |-- 001_create_customers.xml          [source]
|       |-- 002_create_sellers.xml            [source]
|       |-- 003_create_products.xml           [source]
|       |-- 004_create_orders.xml             [source]
|       |-- 005_create_orderdetails.xml        [source]
|       `-- liquibase.properties              [source]
|
|-- logs/                                     [generated, ignored]
|   |-- mysql_setup.log                       [empty]
|   `-- mysql_load.log                        [generated historical log]
|
|-- outputs/
|   |-- logs/                                 [empty directory]
|   `-- reports/                              [empty directory]
|
|-- scripts/
|   |-- bash/
|   |   `-- download_mysql_driver.sh          [source]
|   |
|   |-- batch/
|   |   |-- install_python_requirements.bat   [source]
|   |   |-- validate_python_requirements.bat  [source]
|   |   |-- common/
|   |   |   |-- install_terraform.bat         [source]
|   |   |   |-- install_mysql_driver.bat      [source]
|   |   |   |-- install_liquibase.bat         [source]
|   |   |   |-- install_tools.bat             [source]
|   |   |   |-- setup_liquibase.bat           [source]
|   |   |   |-- set_project_root.bat          [source]
|   |   |   |-- validate_java_runtime.bat     [source]
|   |   |   |-- validate_python_runtime.bat   [source]
|   |   |   |-- validate_tools.bat            [source]
|   |   |   |-- validate_liquibase.bat        [empty]
|   |   |   `-- validate_mysql_driver.bat     [empty]
|   |   `-- mysql/
|   |       |-- deploy_mysql.bat              [source]
|   |       |-- create_database.bat           [source]
|   |       |-- run_liquibase.bat             [source]
|   |       |-- start_mysql.bat               [source]
|   |       |-- stop_mysql.bat                [source]
|   |       |-- validate_environment.bat      [source]
|   |       |-- validate_port.bat             [source]
|   |       |-- validate_mysql.bat            [source]
|   |       |-- validate_csv.bat              [source]
|   |       |-- load_data.bat                 [source]
|   |       |-- cleanup_mysql.bat             [source]
|   |       |-- destroy_mysql.bat             [source]
|   |       |-- initialize_logs.bat           [source]
|   |       |-- mysql_setup_with_logging.bat  [source]
|   |       `-- mysql_load_with_logging.bat   [source]
|   |
|   |-- powershell/
|   |   |-- download_liquibase.ps1            [source]
|   |   |-- download_mysql_driver.ps1         [source]
|   |   |-- start_mysql.ps1                   [source]
|   |   `-- stop_mysql.ps1                    [source]
|   |
|   `-- python/
|       |-- common/                            [empty directory]
|       `-- mysql/
|           |-- db_connection.py              [source]
|           |-- load_all.py                   [source]
|           |-- load_customers.py             [source]
|           |-- load_sellers.py               [source]
|           |-- load_products.py              [source]
|           |-- load_orders.py                [source]
|           |-- load_orderdetails.py           [source]
|           |-- truncate_tables.py            [source]
|           |-- validate_csv.py               [source]
|           |-- validate_mysql.py             [source]
|           |-- validate_port.py              [source]
|           |-- test_connection.py            [source]
|           |-- testcsvschema.py              [source]
|           |-- check_port.py                 [empty]
|           |-- validate_customers.py         [empty]
|           `-- __pycache__/                  [generated, ignored]
|
|-- terraform/
|   `-- mysql/
|       |-- main.tf                           [source]
|       |-- .terraform.lock.hcl               [tracked dependency lock]
|       |-- terraform.tfstate                 [generated, ignored]
|       |-- terraform.tfstate.backup          [generated, ignored]
|       `-- .terraform/                       [generated provider cache]
|
`-- tools/                                    [vendored and tracked despite ignore rule]
    |-- drivers/
    |   `-- mysql-connector-j-9.5.0.jar
    |-- terraform/
    |   |-- terraform.exe                     [Terraform 1.13.0 windows_amd64]
    |   `-- LICENSE.txt
    `-- liquibase/                            [Liquibase 5.0.3 distribution]
        |-- liquibase.bat
        |-- ABOUT.txt
        |-- GETTING_STARTED.txt
        |-- LICENSE.txt
        |-- README.txt
        |-- UNINSTALL.txt
        |-- changelog.txt
        |-- internal/lib/                     [9 third-party JARs]
        |-- lib/                              [launcher support/autocomplete]
        |-- licenses/oss/                     [6 license/notice files]
        `-- examples/
            |-- start-h2
            |-- start-h2.bat
            |-- json/                         [4 example files]
            |-- sql/                          [4 example files]
            |-- xml/                          [4 example files]
            `-- yaml/                         [4 example files]
```

## Generated MySQL Tree

The MySQL runtime tree is too large and binary-heavy to usefully reproduce file-by-file as source documentation. It was recursively inventoried and contains:

```text
databases/mysql/server/
|-- bin/                 53 direct files plus 2 SASL files
|-- docs/                INFO_BIN, INFO_SRC
|-- include/             C/C++ headers
|-- lib/                 client libraries, plugins, debug symbols, ICU, MeCab
|-- share/               SQL helpers, charsets, dictionaries, localized errors
|-- LICENSE
`-- README

databases/mysql/data/
|-- #innodb_redo/        32 redo files
|-- #innodb_temp/        10 temporary tablespace files
|-- ecommercemysql/      7 table/metadata .ibd files
|-- mysql/               system log-table files
|-- performance_schema/  116 serialized dictionary files
|-- sys/                 sys_config.ibd
|-- binlog.000001 ... binlog.000006
|-- TLS keys/certificates
|-- InnoDB system/temp/buffer files
|-- server PID/error files
`-- metadata/configuration files
```

These files are generated database state. Reading them as text would be invalid or destructive; the review instead used names, sizes, build metadata, and cryptographic hashes for key binaries.

## Extension Inventory

The most significant recursive file groups are:

| Type | Count | Classification |
|---|---:|---|
| `.sdi` | 118 | Generated MySQL dictionary metadata |
| `.dll` | 94 | Vendored MySQL binaries/plugins |
| Extensionless | 48 | Runtime/data/license/launcher files |
| `.pdb` | 38 | Vendored debug symbols |
| `.xml` | 33 | 6 project Liquibase files plus vendored examples/share files |
| `.bat` | 32 | Project automation plus vendored launchers/examples |
| `.exe` | 26 | MySQL and Terraform binaries |
| `.txt` | 23 | Licenses, docs, changelogs, MySQL metadata |
| `.py` | 15 | Project Python source |
| `.jar` | 10 | Connector/J and Liquibase dependencies |
| `.ibd` | 9 | Generated InnoDB tablespaces |
| `.pem` | 8 | Generated TLS/private key material |
| `.CSV`/`.csv` | 7 | Five project datasets plus MySQL system log tables |
| `.groovy` | 4 | Jenkins pipelines |
| `.ps1` | 4 | PowerShell automation |

## Zero-Byte Files

| Path | Impact |
|---|---|
| `scripts/batch/common/validate_liquibase.bat` | Named validation is unimplemented |
| `scripts/batch/common/validate_mysql_driver.bat` | Named validation is unimplemented |
| `scripts/python/mysql/check_port.py` | Duplicate/placeholder port check |
| `scripts/python/mysql/validate_customers.py` | Customer data validation unimplemented |
| `logs/mysql_setup.log` | No recorded setup execution |
| `databases/mysql/data/mysql/general_log.CSV` | MySQL runtime system table file |
| `databases/mysql/data/mysql/slow_log.CSV` | MySQL runtime system table file |

## Missing Referenced Files

| Missing path | Referenced from | Effect |
|---|---|---|
| `scripts/bash/install_mysql.sh` | `terraform/mysql/main.tf` | Linux install resource always fails |
| `scripts/bash/start_mysql.sh` | `terraform/mysql/main.tf` | Linux start resource always fails |

## Git and Ignore Status

Tracked source includes `.env`, `.terraform.lock.hcl`, Connector/J, the full Liquibase distribution, and Terraform executable. The following workspace artifacts are ignored:

- `databases/`
- `logs/`
- `terraform/mysql/.terraform/`
- `terraform/mysql/terraform.tfstate`
- `terraform/mysql/terraform.tfstate.backup`

`tools/` is listed in `.gitignore` but remains tracked because it was committed previously.

The initial inventory reported `jenkins/mysql/mysql_setup_pipeline.groovy` as modified, although the final status no longer showed that modification. The review did not edit that pipeline file.

## Key Binary Fingerprints

| Path | Size (bytes) | SHA-256 |
|---|---:|---|
| `databases/mysql/mysql.zip` | 340,476,547 | `7FD8559058E6E132F275971A6A0A058C7A6705F14112DF84FCF2617067EC5358` |
| `tools/terraform/terraform.exe` | 102,691,720 | `1B6F5E3CCBC9EC75C9D2D34CF7E7CD80FD452BFED380A7440E5973D0C64A7D0F` |
| `tools/drivers/mysql-connector-j-9.5.0.jar` | 2,602,851 | `F2CA3DFAF00D4AA311470DB7EA3051962944BA0CB60005A2F75467549C39F425` |
| `tools/liquibase/internal/lib/liquibase-core.jar` | 3,127,117 | `3CCD4608829836B4C0F7FB1D23A4619BAC16C68CA725D623AAE0838BCE734156` |
| `databases/mysql/server/bin/mysqld.exe` | 53,346,432 | `A0B7D7D2DD1F7554D0594593BB8C4982018E5B9586DAC6A327A36863E85F5418` |
| `databases/mysql/server/bin/mysql.exe` | 7,342,712 | `97D459B146AF020629CAE5E62B1C211BDD6282EA59D5D7AB0EE6607766A97027` |

These hashes document the reviewed workspace artifacts. The current automation does not verify them against publisher-provided checksums.
