@echo off
setlocal

echo.
echo =====================================
echo CHECKING MYSQL MIGRATION STATUS
echo =====================================
echo.

call "%~dp0load_migration_config.bat"
if errorlevel 1 exit /b 1

pushd "%PROJECT_ROOT%"

call "%LIQUIBASE%" ^
    --classpath="%DRIVER%" ^
    --url="%DB_URL%" ^
    --username="%MYSQL_USER%" ^
    --password="%MYSQL_PASSWORD%" ^
    --changelog-file="%CHANGELOG%" ^
    status --verbose

set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
    echo MYSQL MIGRATION STATUS CHECK FAILED
    exit /b %EXIT_CODE%
)

echo.
echo MYSQL MIGRATION STATUS CHECK SUCCESSFUL
exit /b 0