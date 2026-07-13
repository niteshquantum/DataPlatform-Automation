@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

echo.
echo =====================================
echo MSSQL LOAD PIPELINE
echo =====================================
echo.

REM =====================================================
REM Validate Python Runtime
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Python Requirements
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Start SQL Server
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\setup\start_mssql.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate SQL Server
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_mssql.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Download Dataset
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\common\download_dataset.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Load Data
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\load_data.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Loaded Data
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\validate_loaded_data.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Deploy Views
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\deploy_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Views
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\validate_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Deploy Functions
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\deploy_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Functions
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\validate_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Deploy Stored Procedures
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\deploy_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Stored Procedures
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\validate_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Deploy Triggers
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\deploy_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Validate Triggers
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\objects\validate_objects.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Database Inventory
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\database_inventory.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM Table Inventory
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\table_inventory.bat"
if errorlevel 1 exit /b 1

REM =====================================================
REM SQL Agent Inventory
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\sql_agent.bat" inventory
if errorlevel 1 exit /b 1

REM =====================================================
REM SQL Agent Validation
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\sql_agent.bat" validation
if errorlevel 1 exit /b 1

REM =====================================================
REM SQL Agent History
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\sql_agent.bat" history
if errorlevel 1 exit /b 1

REM =====================================================
REM SQL Agent Assessment
REM =====================================================
call "%PROJECT_ROOT%\scripts\batch\mssql\load\sql_agent.bat" assessment
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MSSQL LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0