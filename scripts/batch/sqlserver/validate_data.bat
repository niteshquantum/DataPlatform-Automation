@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo VALIDATE DATA
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

python scripts\python\sqlserver\validate_data.py

if errorlevel 1 (
    echo [FAIL] Data validation failed
    popd
    exit /b 1
)

echo [PASS] Data validation successful

popd
exit /b 0