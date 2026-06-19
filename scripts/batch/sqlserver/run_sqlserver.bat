@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo SQL SERVER AUTOMATION RUNNER
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

if not exist logs (
    mkdir logs
)

call scripts\batch\sqlserver\deploy_sqlserver.bat
if errorlevel 1 (
    echo [FAIL] Deployment failed
    popd
    exit /b 1
)

call scripts\batch\sqlserver\load_data.bat
if errorlevel 1 (
    echo [FAIL] Data load failed
    popd
    exit /b 1
)

call scripts\python\sqlserver\validate_sqlserver.py >nul 2>&1
if errorlevel 1 (
    python scripts\python\sqlserver\validate_sqlserver.py
    popd
    exit /b 1
)

echo.
echo [PASS] SQL Server workflow completed successfully

popd
exit /b 0