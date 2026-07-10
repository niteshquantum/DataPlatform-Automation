@echo off
setlocal EnableDelayedExpansion

call "%~dp0..\..\common\set_project_root.bat"

if errorlevel 1 (
exit /b 1
)

cd /d "%PROJECT_ROOT%"

set "PYTHONPATH=%PROJECT_ROOT%;%PYTHONPATH%"

echo.
echo =====================================
echo POSTGRESQL OBJECTS DEPLOYMENT
echo =====================================
echo.

python scripts\python\common\objects\deploy_objects.py postgresql

if errorlevel 1 (
echo ERROR: POSTGRESQL OBJECTS DEPLOYMENT FAILED
exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL OBJECTS DEPLOYMENT SUCCESSFUL
echo =====================================
echo.

exit /b 0
