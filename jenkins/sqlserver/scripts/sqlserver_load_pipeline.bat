@echo off
setlocal EnableDelayedExpansion

set PROJECT_ROOT=%~dp0\..\..\..\..

pushd "%PROJECT_ROOT%"

echo ==================================================
echo SQL SERVER LOAD PIPELINE
echo ==================================================

call scripts\batch\sqlserver\initialize_logs.bat

if errorlevel 1 (
    echo [FAIL] Log initialization failed
    popd
    exit /b 1
)

echo [INFO] Generating Datasets

python scripts\python\sqlserver\generate_dataset.py

if errorlevel 1 (
    echo [FAIL] Dataset generation failed
    popd
    exit /b 1
)

echo [INFO] Loading Data

python scripts\python\sqlserver\load_data.py

if errorlevel 1 (
    echo [FAIL] Data load failed
    popd
    exit /b 1
)

echo [INFO] Validating Data

python scripts\python\sqlserver\validate_data.py

if errorlevel 1 (
    echo [FAIL] Data validation failed
    popd
    exit /b 1
)

echo [PASS] Load pipeline completed successfully

popd

exit /b 0