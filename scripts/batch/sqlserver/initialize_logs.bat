@echo off
setlocal EnableDelayedExpansion

set PROJECT_ROOT=%~dp0..\..\..

pushd "%PROJECT_ROOT%"

if not exist logs (
    mkdir logs
)

if not exist outputs (
    mkdir outputs
)

if not exist outputs\logs (
    mkdir outputs\logs
)

if not exist outputs\reports (
    mkdir outputs\reports
)

echo Log directories initialized

popd
exit /b 0