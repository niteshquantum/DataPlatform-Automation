@echo off
setlocal

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
echo SQLCMD INSTALL FAILED
exit /b 1
)

echo SQLCMD INSTALLED

exit /b 0
