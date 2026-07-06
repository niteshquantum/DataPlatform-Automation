@echo off
setlocal enabledelayedexpansion

echo.
echo =====================================
echo INSTALLING SQLCMD
echo =====================================
echo.

where sqlcmd >nul 2>&1
if not errorlevel 1 (
    echo SQLCMD already installed and reachable on PATH.
    exit /b 0
)

winget install Microsoft.Sqlcmd --silent --accept-package-agreements --accept-source-agreements

echo.
echo [PATH] Refreshing PATH for the current session from registry...

for /f "usebackq tokens=2,*" %%A in (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul`) do set "SYS_PATH=%%B"
for /f "usebackq tokens=2,*" %%A in (`reg query "HKCU\Environment" /v Path 2^>nul`) do set "USER_PATH=%%B"

if defined USER_PATH (
    set "PATH=%SYS_PATH%;%USER_PATH%"
) else (
    set "PATH=%SYS_PATH%"
)

where sqlcmd >nul 2>&1
if not errorlevel 1 (
    echo [PATH] SQLCMD found after registry PATH refresh.
    goto :success
)

echo [SEARCH] Not found via registry PATH. Actively searching common winget install locations...

set "FOUND_DIR="

for %%D in (
    "%LocalAppData%\Microsoft\WinGet\Packages"
    "%LocalAppData%\Microsoft\WinGet\Links"
    "%LocalAppData%\Microsoft\WindowsApps"
    "%ProgramFiles%\Sqlcmd"
    "%ProgramFiles(x86)%\Sqlcmd"
    "%ProgramFiles%\Microsoft SQL Server"
) do (
    if not defined FOUND_DIR (
        if exist "%%~D" (
            for /f "delims=" %%F in ('dir /s /b "%%~D\sqlcmd.exe" 2^>nul') do (
                if not defined FOUND_DIR (
                    set "FOUND_DIR=%%~dpF"
                )
            )
        )
    )
)

if defined FOUND_DIR (
    echo [SEARCH] Found sqlcmd.exe under: !FOUND_DIR!
    set "PATH=%PATH%;!FOUND_DIR!"
    where sqlcmd >nul 2>&1
    if not errorlevel 1 (
        echo [PATH] SQLCMD now reachable after adding discovered folder to session PATH.
        goto :success
    )
)

echo ERROR: SQLCMD could not be located after install, registry PATH refresh, and filesystem search.
echo Searched: WinGet Packages/Links, WindowsApps, Program Files\Sqlcmd, Program Files\Microsoft SQL Server
echo ERROR: SQLCMD INSTALLATION FAILED
exit /b 1

:success
echo.
echo SQLCMD INSTALLATION SUCCESSFUL
echo.
exit /b 0