@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo DEPLOY SQL SERVER
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

if not exist logs (
    mkdir logs
)

echo [INFO] Installing SQL Server

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\install_windows.ps1

if errorlevel 1 (
    echo [FAIL] install_windows.ps1 failed
    popd
    exit /b 1
)

echo [INFO] Configuring SQL Server

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\configure_sqlserver.ps1

if errorlevel 1 (
    echo [FAIL] configure_sqlserver.ps1 failed
    popd
    exit /b 1
)

echo [INFO] Starting SQL Server

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\start_sqlserver.ps1

if errorlevel 1 (
    echo [FAIL] start_sqlserver.ps1 failed
    popd
    exit /b 1
)

echo [INFO] Creating Database

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\create_database.ps1

if errorlevel 1 (
    echo [FAIL] create_database.ps1 failed
    popd
    exit /b 1
)

echo [INFO] Creating Tables

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\create_tables.ps1

if errorlevel 1 (
    echo [FAIL] create_tables.ps1 failed
    popd
    exit /b 1
)

echo [PASS] SQL Server deployment completed

popd
exit /b 0