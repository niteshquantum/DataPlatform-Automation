@echo off

for %%I in ("%~dp0..\..\..\..") do set "PROJECT_ROOT=%%~fI"

set "CONFIG_FILE=%PROJECT_ROOT%\config\windows\mysql.conf"

if not exist "%CONFIG_FILE%" (
    echo ERROR: MySQL config file not found:
    echo %CONFIG_FILE%
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if not "%%A"=="" (
        set "%%A=%%B"
    )
)

if not defined MYSQL_HOST (
    echo ERROR: MYSQL_HOST missing.
    exit /b 1
)

if not defined MYSQL_PORT (
    echo ERROR: MYSQL_PORT missing.
    exit /b 1
)

if not defined MYSQL_DB (
    echo ERROR: MYSQL_DB missing.
    exit /b 1
)

if not defined MYSQL_USER (
    echo ERROR: MYSQL_USER missing.
    exit /b 1
)

if not defined MYSQL_PASSWORD (
    echo ERROR: MYSQL_PASSWORD missing.
    exit /b 1
)

if not defined MYSQL_DRIVER_VERSION (
    echo ERROR: MYSQL_DRIVER_VERSION missing.
    exit /b 1
)

set "LIQUIBASE=%PROJECT_ROOT%\tools\liquibase\liquibase.bat"
set "DRIVER=%PROJECT_ROOT%\tools\drivers\mysql-connector-j-%MYSQL_DRIVER_VERSION%.jar"
set "CHANGELOG_FILE=%PROJECT_ROOT%\liquibase\mysql\migration-master.xml"
set "CHANGELOG=liquibase/mysql/migration-master.xml"
set "LIQUIBASE_VERSION="
set "DB_URL=jdbc:mysql://%MYSQL_HOST%:%MYSQL_PORT%/%MYSQL_DB%"

if not exist "%LIQUIBASE%" (
    echo ERROR: Liquibase not found:
    echo %LIQUIBASE%
    exit /b 1
)

if not exist "%DRIVER%" (
    echo ERROR: MySQL JDBC driver not found:
    echo %DRIVER%
    exit /b 1
)

if not exist "%CHANGELOG_FILE%" (
    echo ERROR: Migration changelog not found:
    echo %CHANGELOG_FILE%
    exit /b 1
)

exit /b 0