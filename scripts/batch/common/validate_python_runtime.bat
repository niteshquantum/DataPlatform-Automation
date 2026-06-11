@echo off

echo.
echo =====================================
echo VALIDATING PYTHON RUNTIME
echo =====================================
echo.

where python >nul 2>&1
if errorlevel 1 (
    echo PYTHON NOT FOUND IN PATH
    exit /b 1
)

where py >nul 2>&1
if errorlevel 1 (
    echo PYTHON LAUNCHER (py.exe) NOT FOUND
    exit /b 1
)

where pip >nul 2>&1
if errorlevel 1 (
    echo PIP NOT FOUND
    exit /b 1
)

echo Python Path:
where python

echo.
echo Python Launcher Path:
where py

echo.
echo Pip Path:
where pip

echo.
echo Python Version:
python --version

if errorlevel 1 (
    echo PYTHON VERSION CHECK FAILED
    exit /b 1
)

echo.
echo Python Launcher Version:
py --version

if errorlevel 1 (
    echo PYTHON LAUNCHER CHECK FAILED
    exit /b 1
)

echo.
echo =====================================
echo PYTHON RUNTIME VALIDATED
echo =====================================
echo.