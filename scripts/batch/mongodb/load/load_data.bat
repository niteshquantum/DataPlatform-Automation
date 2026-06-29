@echo off

echo ===================================
echo Deploying MongoDB
echo ===================================

python "%~dp0..\..\python\mongodb\load_all.py"

if errorlevel 1 (
    echo MongoDB Deployment Failed
    exit /b 1
)

echo ===================================
echo MongoDB Deployment Successful
echo ===================================