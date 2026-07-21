# Compatibility entry point for direct and legacy setup invocations.
& "$PSScriptRoot\reconcile_mongodb_windows.ps1"
exit $LASTEXITCODE
