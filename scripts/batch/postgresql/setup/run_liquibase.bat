@echo off


echo.
echo =====================================
echo RUNNING POSTGRESQL LIQUIBASE
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"

set "ROOT=%PROJECT_ROOT%"

set "CONFIG_FILE=%ROOT%\config\windows\postgresql.conf"

REM =====================================
REM VALIDATE CONFIG
REM =====================================

if not exist "%CONFIG_FILE%" (
    echo ERROR: CONFIG FILE NOT FOUND
    echo Expected: %CONFIG_FILE%
    exit /b 1
)

REM =====================================
REM READ CONFIG
REM =====================================

for /f "tokens=1,* delims==" %%A in (%CONFIG_FILE%) do (
    if /I "%%A"=="POSTGRESQL_HOST" set "POSTGRESQL_HOST=%%B"
    if /I "%%A"=="POSTGRESQL_PORT" set "POSTGRESQL_PORT=%%B"
    if /I "%%A"=="POSTGRESQL_DB" set "POSTGRESQL_DB=%%B"
    if /I "%%A"=="POSTGRESQL_USER" set "POSTGRESQL_USER=%%B"
    if /I "%%A"=="POSTGRESQL_PASSWORD" set "POSTGRESQL_PASSWORD=%%B"
    if /I "%%A"=="POSTGRESQL_DRIVER_VERSION" set "POSTGRESQL_DRIVER_VERSION=%%B"
)

REM =====================================
REM VALIDATE REQUIRED CONFIG
REM =====================================

if not defined POSTGRESQL_HOST (
    echo ERROR: POSTGRESQL_HOST NOT FOUND IN CONFIG
    exit /b 1
)

if not defined POSTGRESQL_PORT (
    echo ERROR: POSTGRESQL_PORT NOT FOUND IN CONFIG
    exit /b 1
)

if not defined POSTGRESQL_DB (
    echo ERROR: POSTGRESQL_DB NOT FOUND IN CONFIG
    exit /b 1
)

if not defined POSTGRESQL_USER (
    echo ERROR: POSTGRESQL_USER NOT FOUND IN CONFIG
    exit /b 1
)

if not defined POSTGRESQL_DRIVER_VERSION (
    echo ERROR: POSTGRESQL_DRIVER_VERSION NOT FOUND IN CONFIG
    exit /b 1
)

REM =====================================
REM VALIDATE LIQUIBASE
REM =====================================

call "%ROOT%\scripts\batch\common\validate_liquibase.bat"

if errorlevel 1 (
    exit /b 1
)

REM =====================================
REM VALIDATE POSTGRESQL JDBC DRIVER
REM =====================================

call "%ROOT%\scripts\batch\postgresql\setup\validate_postgresql_driver.bat"

if errorlevel 1 (
    exit /b 1
)

echo.
echo ===== AFTER DRIVER =====
echo JAVA_HOME=%JAVA_HOME%
echo PATH=%PATH%
echo ========================
echo.

REM =====================================
REM PATHS
REM =====================================
set JAVA_HOME

set "LB_BAT=%ROOT%\tools\liquibase\liquibase.bat"

set "DRIVER=%ROOT%\tools\drivers\postgresql-%POSTGRESQL_DRIVER_VERSION%.jar"

if not exist "%DRIVER%" (
    echo ERROR: POSTGRESQL JDBC DRIVER NOT FOUND
    echo Expected: %DRIVER%
    exit /b 1
)

cd /d "%ROOT%"

set "CHANGELOG=%~1"
if "%CHANGELOG%"=="" set "CHANGELOG=liquibase\postgresql\master.xml"

if not exist "%CHANGELOG%" (
    echo ERROR: CHANGELOG NOT FOUND
    echo Expected: %ROOT%\%CHANGELOG%
    exit /b 1
)

REM =====================================
REM REPORT
REM =====================================

echo.
echo Database : %POSTGRESQL_DB%
echo Host     : %POSTGRESQL_HOST%
echo Port     : %POSTGRESQL_PORT%
echo User     : %POSTGRESQL_USER%
echo Driver   : %DRIVER%
echo Changelog: %CHANGELOG%
echo.

echo JAVA_HOME : %JAVA_HOME%
echo.

java -version

if errorlevel 1 (
    echo ERROR: JAVA EXECUTION FAILED
    exit /b 1
)

echo.

REM =====================================
REM PASSWORD OPTION
REM =====================================

set "PASSWORD_OPTION="

if defined POSTGRESQL_PASSWORD (
    set "PASSWORD_OPTION=--password=%POSTGRESQL_PASSWORD%"
)

REM =====================================
REM RUN LIQUIBASE
REM =====================================

call "%LB_BAT%" ^
--classpath="%DRIVER%" ^
--driver=org.postgresql.Driver ^
--search-path="%ROOT%" ^
--changeLogFile="%CHANGELOG%" ^
--url="jdbc:postgresql://%POSTGRESQL_HOST%:%POSTGRESQL_PORT%/%POSTGRESQL_DB%" ^
--username=%POSTGRESQL_USER% ^
%PASSWORD_OPTION% ^
update

if errorlevel 1 (
    echo.
    echo ERROR: POSTGRESQL LIQUIBASE UPDATE FAILED
    exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL LIQUIBASE UPDATE COMPLETED
echo =====================================
echo.

exit /b 0
