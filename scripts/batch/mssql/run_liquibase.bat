@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo RUNNING LIQUIBASE
echo =====================================
echo.

set "ROOT=%CD%"
set "CONFIG_FILE=%ROOT%\config\windows\mssql.conf"

if not exist "%CONFIG_FILE%" (
echo ERROR: CONFIG FILE NOT FOUND
echo Expected: %CONFIG_FILE%
exit /b 1
)

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_HOST" set "MSSQL_HOST=%%B"
if /I "%%A"=="MSSQL_PORT" set "MSSQL_PORT=%%B"
if /I "%%A"=="MSSQL_DB" set "MSSQL_DB=%%B"
if /I "%%A"=="MSSQL_USER" set "MSSQL_USER=%%B"
if /I "%%A"=="MSSQL_PASSWORD" set "MSSQL_PASSWORD=%%B"
if /I "%%A"=="MSSQL_DRIVER_VERSION" set "MSSQL_DRIVER_VERSION=%%B"
)

call scripts\batch\common\validate_liquibase.bat
if errorlevel 1 exit /b 1

call scripts\batch\common\validate_mssql_driver.bat
if errorlevel 1 exit /b 1

set "LB_BAT=%ROOT%\tools\liquibase\liquibase.bat"

set "DRIVER=%ROOT%\tools\drivers\mssql-jdbc-%MSSQL_DRIVER_VERSION%.jre11.jar"

set "CHANGELOG=liquibase\mssql\master.xml"

call "%LB_BAT%" ^
--classpath="%DRIVER%" ^
--driver=com.microsoft.sqlserver.jdbc.SQLServerDriver ^
--search-path="%ROOT%" ^
--changeLogFile="%CHANGELOG%" ^
--url="jdbc:sqlserver://%MSSQL_HOST%:%MSSQL_PORT%;databaseName=%MSSQL_DB%;encrypt=true;trustServerCertificate=true" ^
--username=%MSSQL_USER% ^
--password=%MSSQL_PASSWORD% ^
update

if errorlevel 1 (
echo LIQUIBASE UPDATE FAILED
exit /b 1
)

echo.
echo =====================================
echo LIQUIBASE UPDATE COMPLETED
echo =====================================
echo.

exit /b 0