@echo off
setlocal EnableDelayedExpansion

set PROJECT_ROOT=%~dp0..\..\..

pushd "%PROJECT_ROOT%"

call scripts\batch\sqlserver\initialize_logs.bat

set LOGFILE=logs\sqlserver_setup.log

echo ================================================== > %LOGFILE%
echo SQL SERVER SETUP STARTED >> %LOGFILE%
echo ================================================== >> %LOGFILE%

call scripts\batch\sqlserver\deploy_sqlserver.bat >> %LOGFILE% 2>&1

if errorlevel 1 (
    echo [FAIL] Setup failed
    popd
    exit /b 1
)

echo [PASS] Setup completed

popd
exit /b 0