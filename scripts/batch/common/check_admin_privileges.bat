@echo off
setlocal

echo.
echo =====================================
echo CHECKING ADMINISTRATOR PRIVILEGES
echo =====================================
echo.

net session >nul 2>&1

if %errorlevel% equ 0 (
    echo Administrator privileges detected.
    exit /b 0
)

echo Administrator privileges not available.
exit /b 1
