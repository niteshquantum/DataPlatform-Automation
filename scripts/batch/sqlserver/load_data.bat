@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo LOAD SQL SERVER DATA
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

if not exist logs (
    mkdir logs
)

echo [INFO] Generating datasets

python scripts\python\sqlserver\generate_dataset.py

if errorlevel 1 (
    echo [FAIL] Dataset generation failed
    popd
    exit /b 1
)

echo [INFO] Loading datasets

python scripts\python\sqlserver\load_data.py

if errorlevel 1 (
    echo [FAIL] Data load failed
    popd
    exit /b 1
)

echo [PASS] Data load completed

popd
exit /b 0