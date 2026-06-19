@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo DESTROY SQL SERVER
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\stop_sqlserver.ps1

if errorlevel 1 (
    echo [FAIL] stop_sqlserver.ps1 failed
    popd
    exit /b 1
)

powershell -ExecutionPolicy Bypass ^
 -File scripts\powershell\sqlserver\remove_sqlserver.ps1

if errorlevel 1 (
    echo [FAIL] remove_sqlserver.ps1 failed
    popd
    exit /b 1
)

echo [PASS] SQL Server removal completed

popd
exit /b 0