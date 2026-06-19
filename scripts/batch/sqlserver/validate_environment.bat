@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo VALIDATE ENVIRONMENT
echo ==================================================

where python >nul 2>&1

if errorlevel 1 (
    echo [FAIL] Python not found
    exit /b 1
)

powershell -Command "$PSVersionTable.PSVersion" >nul 2>&1

if errorlevel 1 (
    echo [FAIL] PowerShell not available
    exit /b 1
)

where terraform >nul 2>&1

if errorlevel 1 (
    echo [WARN] Terraform not found in PATH
)

echo [PASS] Environment validation successful

exit /b 0