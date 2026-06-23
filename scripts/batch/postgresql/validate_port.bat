@echo off
setlocal

python "%~dp0..\..\python\postgresql\validate_port.py"

exit /b %ERRORLEVEL%