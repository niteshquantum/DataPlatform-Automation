@echo off
setlocal

echo.
echo =====================================
echo ROLLING BACK MYSQL MIGRATION
echo =====================================
echo.

if "%~1"=="" (
    echo ERROR: Rollback count is required.
    exit /b 1
)

set "ROLLBACK_COUNT=%~1"

call "%~dp0load_migration_config.bat"
if errorlevel 1 exit /b 1

pushd "%PROJECT_ROOT%"

call "%LIQUIBASE%" ^
    --classpath="%DRIVER%" ^
    --url="%DB_URL%" ^
    --username="%MYSQL_USER%" ^
    --password="%MYSQL_PASSWORD%" ^
    --changelog-file="%CHANGELOG%" ^
    rollback-count %ROLLBACK_COUNT%

set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
    echo MYSQL MIGRATION ROLLBACK FAILED
    exit /b %EXIT_CODE%
)

echo.
echo MYSQL MIGRATION ROLLBACK SUCCESSFUL
exit /b 0