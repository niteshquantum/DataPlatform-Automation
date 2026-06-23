@echo off
setlocal

python "%~dp0..\..\python\postgresql\validate_csv.py"

exit /b %ERRORLEVEL%