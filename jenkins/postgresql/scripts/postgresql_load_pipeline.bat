@echo off
setlocal

echo ============================================
echo POSTGRESQL LOAD PIPELINE
echo ============================================

set SCRIPT_DIR=%~dp0

set PROJECT_ROOT=%SCRIPT_DIR%..\..\..\

cd /d "%PROJECT_ROOT%"

echo Project Root: %PROJECT_ROOT%

call scripts\batch\postgresql\postgresql_load_with_logging.bat

exit /b %ERRORLEVEL%
