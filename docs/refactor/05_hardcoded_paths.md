# Hardcoded Paths

Detected Windows drive paths, Linux absolute paths, user/workspace paths, and temp paths.

| File | Line | Current Path | Recommended Replacement | Impact |
| --- | --- | --- | --- | --- |
| config/python.conf | 2 | C:\Python313\python.exe | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| jenkins/mysql/windows/localwork/mysql_load_pipeline.groovy | 6 | F:\\Quantumatrix\\Projects\\DataEng\\DataPlatform-Automation | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| jenkins/mysql/windows/localwork/mysql_setup_pipeline.groovy | 6 | F:\\Quantumatrix\\Projects\\DataEng\\DataPlatform-Automation | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| jenkins/testing/python_debug_pipeline.groovy | 7 | F:\\Quantumatrix\\Projects\\DataEng\\DataPlatform-Automation | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_mssql.sh | 17 | /opt/mssql/bin/sqlservr | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_mssql.sh | 29 | /usr/share/keyrings/microsoft-prod.gpg | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_mssql.sh | 45 | /opt/mssql/bin/mssql-conf | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 13 | /opt/mssql-tools18/bin/sqlcmd | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 24 | /usr/share/keyrings | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 28 | /usr/share/keyrings/microsoft-prod.gpg | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 42 | /opt/mssql-tools18/bin/sqlcmd | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 42 | /usr/local/bin/sqlcmd | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 44 | /opt/mssql-tools18/bin | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/bash/mssql/install_sqlcmd.sh | 47 | /opt/mssql-tools18/bin | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 79 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 83 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 87 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 89 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 95 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/batch/common/validate_liquibase.bat | 99 | %TEMP% | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/data_loader.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/data_loader_mongodb.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/liquibase_generator.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/metadata_manager.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/powershell/postgresql/install_windows.ps1 | 50 | C:\Program | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/powershell/postgresql/install_windows.ps1 | 51 | C:\Program | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/powershell/postgresql/install_windows.ps1 | 52 | C:\Program | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/run_liquibase.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/schema_detector.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/schema_diff.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| scripts/version_manager.py | 1 | /usr/bin/env | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| tools/liquibase/changelog.txt | 4807 | /usr/bin/liquibase: | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |
| tools/liquibase/README.txt | 20 | /usr/local/opt/liquibase | Use PROJECT_ROOT/config value or workspace-relative path resolved at runtime | Machine/user-specific execution risk; breaks portability across Jenkins agents and OS targets |

## Standard Replacement Pattern

Use PROJECT_ROOT resolution plus database/OS config keys. Dataset paths should come from config/{os}/{database}.conf or database-owned dataset config, then resolve relative to workspace at runtime.
