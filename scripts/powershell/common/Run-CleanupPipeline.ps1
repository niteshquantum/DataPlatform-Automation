param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("full","partial","dryrun")]
    [string]$CleanupMode,

    [Parameter(Mandatory=$true)]
    [ValidateSet("mysql","mssql","postgresql","mongodb")]
    [string]$Database
)

$commonParams = @{
    CleanupMode = $CleanupMode
    Database    = $Database
}

Write-Output "[INFO] Common cleanup runner invoked"
Write-Output "[INFO] Cleanup mode: $($commonParams.CleanupMode)"
Write-Output "[INFO] Database: $($commonParams.Database)"
Write-Output "[INFO] Operating system: Windows"

exit 0
