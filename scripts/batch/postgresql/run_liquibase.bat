@echo off
setlocal

echo ===================================
echo RUN LIQUIBASE MIGRATIONS
echo ===================================

set PROJECT_ROOT=%~dp0..\..\..

:: Discover Liquibase executable
set LIQUIBASE_EXE=
if exist "%PROJECT_ROOT%\tools\liquibase\liquibase.bat" (
    set LIQUIBASE_EXE=%PROJECT_ROOT%\tools\liquibase\liquibase.bat
) else (
    where liquibase >nul 2>&1
    if not errorlevel 1 set LIQUIBASE_EXE=liquibase
)

if "%LIQUIBASE_EXE%"=="" (
    echo ERROR: Liquibase not found
    exit /b 1
)

:: Discover PostgreSQL JDBC driver
set DRIVER_JAR=
for %%F in ("%PROJECT_ROOT%\tools\drivers\postgresql*.jar") do (
    set DRIVER_JAR=%%F
)

if "%DRIVER_JAR%"=="" (
    echo ERROR: PostgreSQL JDBC driver not found in tools\drivers\
    exit /b 1
)

:: Read config
set PG_HOST=localhost
set PG_PORT=5432
set PG_DB=DataManagementDB
set PG_USER=postgres
set PG_PASSWORD=

for /f "tokens=1,2 delims==" %%A in (%PROJECT_ROOT%\config\postgresql.conf) do (
    if "%%A"=="POSTGRESQL_HOST"           set PG_HOST=%%B
    if "%%A"=="POSTGRESQL_PORT"           set PG_PORT=%%B
    if "%%A"=="POSTGRESQL_DATABASE"       set PG_DB=%%B
    if "%%A"=="POSTGRESQL_ADMIN_USER"     set PG_USER=%%B
    if "%%A"=="POSTGRESQL_ADMIN_PASSWORD" set PG_PASSWORD=%%B
)

echo Liquibase : %LIQUIBASE_EXE%
echo Driver    : %DRIVER_JAR%
echo Database  : %PG_DB%
echo Host      : %PG_HOST%:%PG_PORT%
echo User      : %PG_USER%
echo.

:: CRITICAL: cd into changelog dir so relative includes resolve correctly
cd /d "%PROJECT_ROOT%\liquibase\postgresql"

"%LIQUIBASE_EXE%" ^
    --classpath="%DRIVER_JAR%" ^
    --driver=org.postgresql.Driver ^
    --changeLogFile=master.xml ^
    --url="jdbc:postgresql://%PG_HOST%:%PG_PORT%/%PG_DB%" ^
    --username="%PG_USER%" ^
    --password="%PG_PASSWORD%" ^
    update

if errorlevel 1 (
    echo FAILED: Liquibase migration failed
    exit /b 1
)

echo.
echo Liquibase Migrations Completed Successfully
exit /b 0