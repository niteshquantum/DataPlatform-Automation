@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo VALIDATING MSSQL TOOLS
echo =====================================
echo.

where sqlcmd >nul 2>&1

if errorlevel 1 (
echo ERROR: SQLCMD NOT FOUND
exit /b 1
)

set CONFIG_FILE=config\windows\mssql.conf

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_DRIVER_VERSION" set DRIVER_VERSION=%%B
)

set DRIVER_FILE=tools\drivers\mssql-jdbc-%DRIVER_VERSION%.jre11.jar

if not exist "%DRIVER_FILE%" (
echo ERROR: MSSQL JDBC DRIVER NOT FOUND
echo Expected: %DRIVER_FILE%
exit /b 1
)

echo SQLCMD FOUND
echo MSSQL JDBC DRIVER FOUND

echo.
echo =====================================
echo MSSQL TOOLS VALIDATED
echo =====================================
echo.

exit /b 0
