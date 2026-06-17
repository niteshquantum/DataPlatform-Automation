@echo off
setlocal

echo.
echo =====================================
echo VALIDATING TOOLS
echo =====================================
echo.

REM =====================================
REM TERRAFORM
REM =====================================

if not exist tools\terraform\terraform.exe (
echo ERROR: TERRAFORM NOT FOUND
exit /b 1
)

tools\terraform\terraform.exe version >nul 2>&1

if errorlevel 1 (
echo ERROR: TERRAFORM EXECUTION FAILED
exit /b 1
)

echo TERRAFORM VALIDATED

REM =====================================
REM LIQUIBASE
REM =====================================

call scripts\batch\common\validate_liquibase.bat

if errorlevel 1 (
exit /b 1
)

REM =====================================
REM MYSQL JDBC DRIVER
REM =====================================

call scripts\batch\common\validate_mysql_driver.bat

if errorlevel 1 (
exit /b 1
)

echo.
echo =====================================
echo TOOLS VALIDATED SUCCESSFULLY
echo =====================================
echo.

exit /b 0
