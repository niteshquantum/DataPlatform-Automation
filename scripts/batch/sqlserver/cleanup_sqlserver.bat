@echo off
setlocal EnableDelayedExpansion

echo ==================================================
echo CLEANUP SQL SERVER ARTIFACTS
echo ==================================================

set PROJECT_ROOT=%~dp0..\..\..
pushd "%PROJECT_ROOT%"

if exist datasets\sqlserver\Customers.csv (
    del /f /q datasets\sqlserver\Customers.csv
)

if exist datasets\sqlserver\Products.csv (
    del /f /q datasets\sqlserver\Products.csv
)

if exist datasets\sqlserver\Orders.csv (
    del /f /q datasets\sqlserver\Orders.csv
)

echo [PASS] Cleanup completed

popd
exit /b 0