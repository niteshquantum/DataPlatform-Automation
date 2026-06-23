@echo off
setlocal

python "%~dp0..\..\python\postgresql\validate_loaded_data.py"

exit /b %ERRORLEVEL%