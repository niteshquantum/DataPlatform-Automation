@echo off

echo.
echo =====================================
echo PYTHON VERSION
echo =====================================
echo.

py --version


echo.
echo =====================================
echo INSTALLING PYTHON REQUIREMENTS
echo =====================================
echo.

python -m pip install -r requirements.txt

if errorlevel 1 (
    echo.
    echo INSTALL FAILED
    exit /b 1
)

echo.
echo =====================================
echo PYTHON REQUIREMENTS INSTALLED
echo =====================================
echo.