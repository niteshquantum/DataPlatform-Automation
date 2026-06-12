@echo off

set PROJECT_ROOT=%~dp0......

for %%i in ("%PROJECT_ROOT%") do set PROJECT_ROOT=%%~fi
