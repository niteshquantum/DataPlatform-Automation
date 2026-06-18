Write-Host "==================================="
Write-Host "Starting MongoDB"
Write-Host "==================================="

$root = Resolve-Path "$PSScriptRoot\..\..\.."

$mongoHome = "$root\databases\mongodb"

$mongodExe = "$mongoHome\server\bin\mongod.exe"

$dataPath = "$mongoHome\data"

$logPath = "$mongoHome\logs\mongodb.log"

if (!(Test-Path $mongodExe)) {

Write-Host "mongod.exe not found"

exit 1


}

Start-Process -FilePath $mongodExe `
-ArgumentList "--dbpath `"$dataPath`" --logpath `"$logPath`" --bind_ip 127.0.0.1 --port 27018"

Write-Host "MongoDB Started Successfully"
