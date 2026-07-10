@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo VALIDATING MYSQL MIGRATION RESULT
echo =====================================
echo.

for %%I in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fI"

set "CONFIG_FILE=%PROJECT_ROOT%\config\windows\mysql.conf"
set "MYSQL_EXE=%PROJECT_ROOT%\databases\mysql\server\bin\mysql.exe"

if not exist "%CONFIG_FILE%" (
    echo ERROR: MySQL config file not found:
    echo %CONFIG_FILE%
    exit /b 1
)

if not exist "%MYSQL_EXE%" (
    echo ERROR: MySQL client not found:
    echo %MYSQL_EXE%
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if not "%%A"=="" (
        set "%%A=%%B"
    )
)

if not defined MYSQL_HOST (
    echo ERROR: MYSQL_HOST not found in config.
    exit /b 1
)

if not defined MYSQL_PORT (
    echo ERROR: MYSQL_PORT not found in config.
    exit /b 1
)

if not defined MYSQL_DB (
    echo ERROR: MYSQL_DB not found in config.
    exit /b 1
)

if not defined MYSQL_USER (
    echo ERROR: MYSQL_USER not found in config.
    exit /b 1
)

if not defined MYSQL_PASSWORD (
    echo ERROR: MYSQL_PASSWORD not found in config.
    exit /b 1
)

"%MYSQL_EXE%" ^
    -h !MYSQL_HOST! ^
    -P !MYSQL_PORT! ^
    -u !MYSQL_USER! ^
    -p!MYSQL_PASSWORD! ^
    -D !MYSQL_DB! ^
    -e "SELECT COUNT(*) AS migration_records FROM DATABASECHANGELOG WHERE ID LIKE 'mysql-v1.0.0-%%'; SHOW TABLES LIKE 'migration_test'; SHOW FULL TABLES WHERE Table_type='VIEW' AND Tables_in_!MYSQL_DB!='vw_active_migration_test'; SHOW FUNCTION STATUS WHERE Db='!MYSQL_DB!' AND Name='fn_migration_test_status'; SHOW PROCEDURE STATUS WHERE Db='!MYSQL_DB!' AND Name='sp_get_active_migration_test'; SHOW TRIGGERS; SELECT * FROM migration_test;"

if errorlevel 1 (
    echo.
    echo MYSQL MIGRATION RESULT VALIDATION FAILED
    exit /b 1
)

echo.
echo MYSQL MIGRATION RESULT VALIDATION SUCCESSFUL
exit /b 0