Write-Host "==================================="
Write-Host "Starting MongoDB"
Write-Host "==================================="

try {

    Start-Service MongoDB

    Write-Host "MongoDB Started Successfully"

}
catch {

    Write-Host "MongoDB Service already running or not installed"

}