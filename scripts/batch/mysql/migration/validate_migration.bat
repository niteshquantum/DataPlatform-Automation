@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MYSQL MIGRATION
echo =====================================
echo.

call "%~dp0load_migration_config.bat"

if errorlevel 1 (
    echo MYSQL MIGRATION CONFIGURATION FAILED
    exit /b 1
)

pushd "%PROJECT_ROOT%"

call "%LIQUIBASE%" ^
    --classpath="%DRIVER%" ^
    --url="%DB_URL%" ^
    --username="%MYSQL_USER%" ^
    --password="%MYSQL_PASSWORD%" ^
    --changelog-file="%CHANGELOG%" ^
    validate

set "EXIT_CODE=%ERRORLEVEL%"

popd

if not "%EXIT_CODE%"=="0" (
    echo.
    echo MYSQL MIGRATION VALIDATION FAILED
    exit /b %EXIT_CODE%
)

echo.
echo MYSQL MIGRATION VALIDATION SUCCESSFUL
exit /b 0