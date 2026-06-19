@echo off
setlocal EnableDelayedExpansion

set PROJECT_ROOT=%~dp0..\..\..

pushd "%PROJECT_ROOT%"

call scripts\batch\sqlserver\initialize_logs.bat

set LOGFILE=logs\sqlserver_load.log

echo ================================================== > %LOGFILE%
echo SQL SERVER LOAD STARTED >> %LOGFILE%
echo ================================================== >> %LOGFILE%

call scripts\batch\sqlserver\load_data.bat >> %LOGFILE% 2>&1

if errorlevel 1 (
    echo [FAIL] Load failed
    popd
    exit /b 1
)

echo [PASS] Load completed

popd
exit /b 0