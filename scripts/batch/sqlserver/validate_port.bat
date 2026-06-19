@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo VALIDATE PORT
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

python scripts\python\sqlserver\validate_port.py

if errorlevel 1 (
    echo [FAIL] Port validation failed
    popd
    exit /b 1
)

echo [PASS] Port validation successful

popd
exit /b 0