@echo off
setlocal EnableDelayedExpansion

set PROJECT_ROOT=%~dp0\..\..\..\..

pushd "%PROJECT_ROOT%"

echo ==================================================
echo SQL SERVER SETUP PIPELINE
echo ==================================================

call scripts\batch\sqlserver\initialize_logs.bat

if errorlevel 1 (
    echo [FAIL] Log initialization failed
    popd
    exit /b 1
)

echo [INFO] Executing Terraform

cd terraform\sqlserver

terraform init

if errorlevel 1 (
    echo [FAIL] Terraform init failed
    popd
    exit /b 1
)

terraform apply -auto-approve

if errorlevel 1 (
    echo [FAIL] Terraform apply failed
    popd
    exit /b 1
)

cd ..\..

echo [INFO] Deploying SQL Server

call scripts\batch\sqlserver\deploy_sqlserver.bat

if errorlevel 1 (
    echo [FAIL] Deployment failed
    popd
    exit /b 1
)

echo [INFO] Running Validation

call scripts\batch\sqlserver\validate_sqlserver.bat

if errorlevel 1 (
    echo [FAIL] Validation failed
    popd
    exit /b 1
)

echo [PASS] Setup pipeline completed successfully

popd

exit /b 0