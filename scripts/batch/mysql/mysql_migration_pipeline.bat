@echo off
setlocal

echo.
echo =====================================
echo MYSQL MIGRATION AUTOMATION PIPELINE
echo =====================================
echo.

call "%~dp0migration\validate_migration.bat"
if errorlevel 1 (
    echo.
    echo MYSQL MIGRATION PIPELINE FAILED AT VALIDATION
    exit /b 1
)

call "%~dp0migration\migration_status.bat"
if errorlevel 1 (
    echo.
    echo MYSQL MIGRATION PIPELINE FAILED AT STATUS CHECK
    exit /b 1
)

call "%~dp0migration\run_migration.bat"
if errorlevel 1 (
    echo.
    echo MYSQL MIGRATION PIPELINE FAILED AT MIGRATION
    exit /b 1
)

call "%~dp0migration\validate_migration_result.bat"
if errorlevel 1 (
    echo.
    echo MYSQL MIGRATION PIPELINE FAILED AT RESULT VALIDATION
    exit /b 1
)

echo.
echo =====================================
echo MYSQL MIGRATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0