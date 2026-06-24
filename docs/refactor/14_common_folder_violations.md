# Common Folder Violations

Common folders should contain only truly reusable components and database-neutral tool installation/validation.

| File | Database Keyword | Violation |
| --- | --- | --- |
| scripts/bash/common/install_mssql_driver.sh | mssql | Database-specific file in common folder. |
| scripts/bash/common/install_mysql_driver.sh | mysql | Database-specific file in common folder. |
| scripts/batch/common/install_mssql_driver.bat | mssql | Database-specific file in common folder. |
| scripts/batch/common/install_mysql_driver.bat | mysql | Database-specific file in common folder. |
| scripts/batch/common/install_postgresql_driver.bat | postgresql | Database-specific file in common folder. |
| scripts/batch/common/validate_mssql_driver.bat | mssql | Database-specific file in common folder. |
| scripts/batch/common/validate_mysql_driver.bat | mysql | Database-specific file in common folder. |
| scripts/batch/common/validate_postgresql_driver.bat | postgresql | Database-specific file in common folder. |

## Recommendation

Move database-specific driver installers and validators to the owning database setup folder, or replace them with a database-neutral helper whose database-specific values are supplied by config.
