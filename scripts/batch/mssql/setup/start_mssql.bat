@echo off
setlocal

echo.
echo =====================================
echo STARTING MSSQL
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

powershell -ExecutionPolicy Bypass ^
    -File "%PROJECT_ROOT%\scripts\powershell\mssql\common\invoke_elevated.ps1" ^
    -ScriptPath "%PROJECT_ROOT%\scripts\powershell\mssql\start_mssql.ps1"

if errorlevel 1 (
    echo.
    echo MSSQL START FAILED
    exit /b 1
)

echo.
echo =====================================
echo MSSQL STARTED
echo =====================================
echo.

exit /b 0