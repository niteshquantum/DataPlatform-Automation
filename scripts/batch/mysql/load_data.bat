@echo off
setlocal

echo.
echo =====================================
echo MYSQL DATA LOAD
echo =====================================
echo.

python scripts\python\mysql\load_all.py

if errorlevel 1 (
    echo.
    echo DATA LOAD FAILED
    exit /b 1
)

echo.
echo DATA LOAD SUCCESSFUL
echo.

exit /b 0