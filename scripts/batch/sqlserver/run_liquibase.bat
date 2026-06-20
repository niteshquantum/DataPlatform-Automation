@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo RUNNING SQL SERVER LIQUIBASE
echo =====================================
echo.

set "ROOT=%CD%"

call scripts\batch\common\validate_liquibase.bat
if errorlevel 1 exit /b 1

call scripts\batch\common\validate_sqlserver_driver.bat
if errorlevel 1 exit /b 1

set "LB_BAT=%ROOT%\tools\liquibase\liquibase.bat"

if not exist "%LB_BAT%" (
echo ERROR: Liquibase not found
exit /b 1
)

call "%LB_BAT%" ^
--defaults-file=liquibase\sqlserver\liquibase.properties ^
update

if errorlevel 1 (
echo.
echo ERROR: LIQUIBASE UPDATE FAILED
exit /b 1
)

echo.
echo =====================================
echo LIQUIBASE UPDATE COMPLETED
echo =====================================
echo.

exit /b 0
