@echo off
setlocal

echo ============================================
echo INSTALL PYTHON REQUIREMENTS
echo ============================================

set PROJECT_ROOT=%~dp0..\..\..

if exist "%PROJECT_ROOT%\requirements.txt" (
    pip install -r "%PROJECT_ROOT%\requirements.txt" --quiet
    if errorlevel 1 (
        echo WARNING: Some packages may not have installed
    ) else (
        echo Python requirements installed successfully
    )
) else (
    echo Installing psycopg2-binary and pandas directly...
    pip install psycopg2-binary pandas --quiet
    if errorlevel 1 exit /b 1
    echo Packages installed successfully
)

exit /b 0
