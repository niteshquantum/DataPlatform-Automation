@echo off
setlocal

echo.
echo =====================================
echo VALIDATING JAVA RUNTIME
echo =====================================
echo.

where java >nul 2>&1

if errorlevel 1 (
    echo JAVA NOT FOUND
    exit /b 1
)

echo Java Path:
where java

echo.
echo JAVA_HOME:
echo %JAVA_HOME%

echo.
echo Java Version:
java -version

if errorlevel 1 (
    echo JAVA EXECUTION FAILED
    exit /b 1
)

echo.
echo =====================================
echo JAVA RUNTIME VALIDATED
echo =====================================
echo.