@echo off
setlocal

powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\postgresql\validate_postgresql.ps1"

exit /b %ERRORLEVEL%