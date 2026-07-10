@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"

echo.
echo ==========================================
echo MONGODB WINDOWS CLEANUP PIPELINE
echo ==========================================
echo.

REM ==========================================
REM VALIDATE CLEANUP MODE
REM ==========================================

if "%CLEANUP_MODE%"=="" (
    echo ERROR: CLEANUP_MODE is not set.
    echo.
    echo Supported modes:
    echo   PRESERVE_DATA
    echo   DELETE_DATA
    echo.
    exit /b 1
)

if /I "%CLEANUP_MODE%"=="PRESERVE_DATA" goto CLEANUP_MODE_VALID

if /I "%CLEANUP_MODE%"=="DELETE_DATA" goto CLEANUP_MODE_VALID

echo ERROR: Invalid CLEANUP_MODE: %CLEANUP_MODE%
echo.
echo Supported modes:
echo   PRESERVE_DATA
echo   DELETE_DATA
echo.
exit /b 1


:CLEANUP_MODE_VALID

echo Project Root : %PROJECT_ROOT%
echo Cleanup Mode : %CLEANUP_MODE%
echo.

REM ==========================================
REM STEP 1 - STOP MONGODB
REM ==========================================

echo.
echo ==========================================
echo STEP 1 - STOP PROJECT-MANAGED MONGODB
echo ==========================================
echo.

call "%PROJECT_ROOT%\scripts\batch\mongodb\cleanup\stop_mongodb.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo MONGODB CLEANUP PIPELINE FAILED
    echo ==========================================
    echo.
    echo Failed Stage : STOP MONGODB
    echo Cleanup Mode : %CLEANUP_MODE%
    echo.
    exit /b 1
)

REM ==========================================
REM STEP 2 - REMOVE MONGODB DEPLOYMENT
REM ==========================================

echo.
echo ==========================================
echo STEP 2 - REMOVE MONGODB DEPLOYMENT
echo ==========================================
echo.

call "%PROJECT_ROOT%\scripts\batch\mongodb\cleanup\remove_mongodb.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo MONGODB CLEANUP PIPELINE FAILED
    echo ==========================================
    echo.
    echo Failed Stage : REMOVE MONGODB
    echo Cleanup Mode : %CLEANUP_MODE%
    echo.
    exit /b 1
)

REM ==========================================
REM STEP 3 - RESET TERRAFORM STATE
REM ==========================================

echo.
echo ==========================================
echo STEP 3 - RESET MONGODB TERRAFORM STATE
echo ==========================================
echo.

call "%PROJECT_ROOT%\scripts\batch\mongodb\cleanup\reset_terraform_state.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo MONGODB CLEANUP PIPELINE FAILED
    echo ==========================================
    echo.
    echo Failed Stage : RESET TERRAFORM STATE
    echo Cleanup Mode : %CLEANUP_MODE%
    echo.
    exit /b 1
)

REM ==========================================
REM STEP 4 - VALIDATE CLEANUP
REM ==========================================

echo.
echo ==========================================
echo STEP 4 - VALIDATE MONGODB CLEANUP
echo ==========================================
echo.

call "%PROJECT_ROOT%\scripts\batch\mongodb\cleanup\validate_cleanup.bat"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo MONGODB CLEANUP PIPELINE FAILED
    echo ==========================================
    echo.
    echo Failed Stage : VALIDATE CLEANUP
    echo Cleanup Mode : %CLEANUP_MODE%
    echo.
    exit /b 1
)

REM ==========================================
REM CLEANUP SUCCESS
REM ==========================================

echo.
echo ==========================================
echo MONGODB WINDOWS CLEANUP SUCCESSFUL
echo ==========================================
echo.
echo Cleanup Mode : %CLEANUP_MODE%
echo.
echo All cleanup stages completed successfully.
echo.

exit /b 0