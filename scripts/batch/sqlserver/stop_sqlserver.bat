@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo STOP SQL SERVER
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

if not exist logs (
    mkdir logs
)

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\stop_sqlserver.ps1

if errorlevel 1 (
    echo [FAIL] SQL Server stop failed
    popd
    exit /b 1
)

echo [PASS] SQL Server stopped successfully

popd
exit /b 0