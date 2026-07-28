@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"
if errorlevel 1 exit /b 1

set "ROOT=%PROJECT_ROOT%"
set "TF=%ROOT%\tools\terraform\terraform.exe"

if not exist "%TF%" (
    echo ERROR: Terraform not found.
    exit /b 1
)

cd /d "%ROOT%\terraform\mongodb"

echo.
echo =====================================
echo TERRAFORM INIT
echo =====================================
echo.

"%TF%" init
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo TERRAFORM APPLY
echo =====================================
echo.

for /f "tokens=1* delims==" %%A in ('findstr /R "^MONGODB_PORT=" "%ROOT%\config\windows\mongodb.conf"') do set "MONGO_PORT=%%B"

if not defined MONGO_PORT (
    echo ERROR: MONGODB_PORT not found in config\windows\mongodb.conf.
    exit /b 1
)

"%TF%" validate
if errorlevel 1 exit /b 1

"%TF%" apply -auto-approve -var="mongodb_port=%MONGO_PORT%"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MONGODB DEPLOYMENT SUCCESSFUL
echo =====================================
echo.

exit /b 0
