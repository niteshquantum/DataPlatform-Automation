@echo off
call "%~dp0..\..\common\set_project_root.bat"
python "%PROJECT_ROOT%\scripts\python\postgresql\rbac\rbac.py" configure
