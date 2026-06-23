@echo off
setlocal

echo.
echo =====================================
echo DESTROY MSSQL ENVIRONMENT
echo =====================================
echo.

REM =====================================
REM STOP MSSQL
REM =====================================

sc query "MSSQL$DMSQL" >nul 2>&1

if not errorlevel 1 (
    echo Stopping MSSQL Service...
    net stop "MSSQL$DMSQL" /y
)

REM =====================================
REM DATABASE CLEAN
REM =====================================

call scripts\batch\mssql\clean_mssql_data.bat

REM =====================================
REM TERRAFORM DESTROY
REM =====================================

set "ROOT=%CD%"

if exist "%ROOT%\tools\terraform\terraform.exe" (

    "%ROOT%\tools\terraform\terraform.exe" ^
    -chdir="%ROOT%\terraform\mssql\windows" ^
    destroy -auto-approve

)

REM =====================================
REM REMOVE MSSQL JDBC DRIVER
REM =====================================

if exist tools\drivers (
    del /q tools\drivers\mssql-jdbc*.jar >nul 2>&1
)

REM =====================================
REM REMOVE LIQUIBASE
REM =====================================

if exist tools\liquibase (
    rmdir /s /q tools\liquibase
)

REM =====================================
REM REMOVE TERRAFORM
REM =====================================

if exist tools\terraform (
    rmdir /s /q tools\terraform
)

echo.
echo =====================================
echo ENVIRONMENT DESTROYED
echo =====================================
echo.

exit /b 0