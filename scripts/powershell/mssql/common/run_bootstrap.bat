@echo off
setlocal

:: Self-elevate: if not already running as Administrator, relaunch this
:: same script elevated (triggers a single UAC "Yes" prompt) and exit.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: At this point we are running elevated. %~dp0 always resolves to THIS
:: script's own folder, regardless of which machine or path the repo lives
:: in - so no manual cd or path copying is ever needed.
echo.
echo =====================================
echo RUNNING ONE-TIME ELEVATED BOOTSTRAP
echo =====================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup_elevated_task.ps1"

echo.
echo =====================================
echo DONE - you can close this window
echo =====================================
pause