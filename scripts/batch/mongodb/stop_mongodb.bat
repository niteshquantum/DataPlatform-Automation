@echo off

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\powershell\mongodb\stop_mongodb.ps1"

if errorlevel 1 (
    echo MongoDB Stop Failed
    exit /b 1
)

echo MongoDB Stopped Successfully