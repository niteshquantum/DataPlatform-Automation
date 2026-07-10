@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"

echo.
echo =====================================
echo MYSQL WINDOWS CLEANUP
echo =====================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\powershell\mysql\cleanup\cleanup_mysql.ps1"

if errorlevel 1 (
    echo.
    echo MYSQL CLEANUP FAILED
    exit /b 1
)

echo.
echo =====================================
echo MYSQL CLEANUP SUCCESSFUL
echo =====================================
echo.

exit /b 0