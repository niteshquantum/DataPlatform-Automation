@echo off
setlocal

set PROJECT_ROOT=%~dp0..\..\..

if not exist "%PROJECT_ROOT%\logs" (
 mkdir "%PROJECT_ROOT%\logs"
)

if not exist "%PROJECT_ROOT%\outputs\logs" (
 mkdir "%PROJECT_ROOT%\outputs\logs"
)

if not exist "%PROJECT_ROOT%\outputs\reports" (
 mkdir "%PROJECT_ROOT%\outputs\reports"
)

echo Log folders initialized

exit /b 0