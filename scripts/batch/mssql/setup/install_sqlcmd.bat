@echo off
setlocal enabledelayedexpansion

echo.
echo =====================================
echo INSTALLING SQLCMD
echo =====================================
echo.

where sqlcmd >nul 2>&1

if not errorlevel 1 (
    echo SQLCMD already installed.
    exit /b 0
)

winget install Microsoft.Sqlcmd --silent --accept-package-agreements --accept-source-agreements

if errorlevel 1 (
    echo ERROR: SQLCMD INSTALLATION FAILED
    exit /b 1
)

echo.
echo [PATH] Refreshing PATH for the current session from registry...

for /f "usebackq tokens=2,*" %%A in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul`) do set "SYS_PATH=%%B"
for /f "usebackq tokens=2,*" %%A in (`reg query "HKCU\Environment" /v Path 2^>nul`) do set "USER_PATH=%%B"

if defined USER_PATH (
    set "PATH=%SYS_PATH%;%USER_PATH%"
) else (
    set "PATH=%SYS_PATH%"
)

echo [PATH] Session PATH refreshed.

where sqlcmd >nul 2>&1
if errorlevel 1 (
    echo ERROR: SQLCMD installed but still not found on PATH after refresh.
    echo Expected sqlcmd.exe to be reachable via PATH - check the winget install location.
    exit /b 1
)

echo.
echo SQLCMD INSTALLATION SUCCESSFUL
echo.

exit /b 0