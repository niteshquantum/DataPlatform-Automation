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

$arguments = @(

    "--dbpath", $dataPath,

    "--logpath", $logPath,

    "--bind_ip", "127.0.0.1",

    "--port", "27018"

)
 
Start-Process `

    -FilePath "cmd.exe" `

    -ArgumentList "/c start `"`" `"$mongodExe`" $($arguments -join ' ')" `

    -WindowStyle Hidden
 
Start-Sleep -Seconds 5
 
Write-Host "MongoDB Started Successfully"
 
