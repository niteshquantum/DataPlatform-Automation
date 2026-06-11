@echo off

echo.
echo =====================================
echo VALIDATING PYTHON REQUIREMENTS
echo =====================================
echo.

py -c "import yaml"
if errorlevel 1 (
    echo PyYAML Missing
    exit /b 1
)

py -c "import dotenv"
if errorlevel 1 (
    echo python-dotenv Missing
    exit /b 1
)

py -c "import mysql.connector"
if errorlevel 1 (
    echo mysql-connector-python Missing
    exit /b 1
)

py -c "import pandas"
if errorlevel 1 (
    echo pandas Missing
    exit /b 1
)

echo.
echo =====================================
echo PYTHON REQUIREMENTS VALIDATED
echo =====================================
echo.