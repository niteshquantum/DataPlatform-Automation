@echo off

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\powershell\mongodb\stop_mongodb.ps1"

pause