@echo off
setlocal

set PROJECT_ROOT=%~dp0..\..\..

dir /b "%PROJECT_ROOT%\tools\drivers\postgresql-*.jar" >nul 2>&1

if errorlevel 1 (
    echo PostgreSQL JDBC Driver not found
    exit /b 1
)

echo PostgreSQL JDBC Driver validated

exit /b 0