@echo off
setlocal

powershell -ExecutionPolicy Bypass ^ -File scripts\powershell\sqlserver\validate_sqlserver.ps1

exit /b %ERRORLEVEL%