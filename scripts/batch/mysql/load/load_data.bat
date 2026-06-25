@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"

echo.
echo =====================================
echo MYSQL DATA LOAD
echo =====================================
echo.

python "%PROJECT_ROOT%\scripts\python\mysql\load\load_data.py"

if errorlevel 1 (
    echo.
    echo DATA LOAD FAILED
    exit /b 1
)

echo.
echo DATA LOAD SUCCESSFUL
echo.

exit /b 0