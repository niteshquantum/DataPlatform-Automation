@echo off
setlocal

echo.
echo =====================================
echo STARTING POSTGRESQL
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

powershell -ExecutionPolicy Bypass ^
-File "%PROJECT_ROOT%\scripts\powershell\postgresql\start_postgresql.ps1"

if errorlevel 1 (
    echo.
    echo POSTGRESQL START FAILED
    exit /b 1
)

echo.
echo POSTGRESQL START SUCCESSFUL
echo.

exit /b 0