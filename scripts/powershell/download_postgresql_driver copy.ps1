@echo off
setlocal

echo ===================================
echo DEPLOY POSTGRESQL
echo ===================================

call "%~dp0initialize_logs.bat"

echo.
echo [1/5] Installing / Validating PostgreSQL...
powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\postgresql\install_windows.ps1"
if errorlevel 1 (
    echo FAILED: PostgreSQL installation failed
    exit /b 1
)

echo.
echo [2/5] Starting PostgreSQL service...
powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\postgresql\start_postgresql.ps1"
if errorlevel 1 (
    echo FAILED: PostgreSQL service start failed
    exit /b 1
)

echo.
echo [3/5] Creating database...
call "%~dp0create_database.bat"
if errorlevel 1 (
    echo FAILED: Database creation failed
    exit /b 1
)

echo.
echo [4/5] Installing PostgreSQL JDBC Driver...
powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\download_postgresql_driver.ps1"
if errorlevel 1 (
    echo FAILED: PostgreSQL JDBC driver download failed
    exit /b 1
)

echo.
echo [5/5] Running Liquibase migrations...
call "%~dp0run_liquibase.bat"
if errorlevel 1 (
    echo FAILED: Liquibase failed
    exit /b 1
)

echo.
echo ===================================
echo DEPLOYMENT SUCCESSFUL
echo ===================================
exit /b 0