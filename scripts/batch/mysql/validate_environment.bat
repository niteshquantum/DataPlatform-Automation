@echo off

echo.
echo =====================================
echo ENVIRONMENT VALIDATION STARTED
echo =====================================
echo.

call scripts\batch\validate_python_requirements.bat

if errorlevel 1 (
    exit /b 1
)

call scripts\batch\common\validate_tools.bat

if errorlevel 1 (
    exit /b 1
)

call scripts\batch\mysql\validate_port.bat

if errorlevel 1 (
    exit /b 1
)

call scripts\batch\mysql\validate_mysql.bat

if errorlevel 1 (
    exit /b 1
)

call scripts\batch\mysql\validate_csv.bat

if errorlevel 1 (
    exit /b 1
)

echo.
echo =====================================
echo ENVIRONMENT VALIDATION SUCCESSFUL
echo =====================================
echo.