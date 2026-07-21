@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"

echo.
echo =====================================
echo RECONCILING PERSISTENT MONGODB DEPLOYMENT
echo =====================================
echo.
echo Terraform is not used because workspace-relative resources can replace an existing deployment.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\powershell\mongodb\reconcile_mongodb_windows.ps1"
if errorlevel 1 exit /b 1

echo MONGODB DEPLOYMENT SUCCESSFUL
exit /b 0
