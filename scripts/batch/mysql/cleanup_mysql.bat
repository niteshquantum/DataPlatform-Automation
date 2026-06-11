@echo off

echo.
echo =====================================
echo MYSQL CLEANUP
echo =====================================
echo.

call scripts\batch\mysql\validate_environment.bat

if errorlevel 1 (
    echo.
    echo MYSQL CLEANUP FAILED
    exit /b 1
)

py scripts\python\mysql\truncate_tables.py

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