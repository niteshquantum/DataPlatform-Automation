$ErrorActionPreference = 'Stop'
function Log([string]$message) { Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message" }
function Read-Settings([string]$path) { $settings=@{}; Get-Content -LiteralPath $path | ForEach-Object { $line=$_.Trim(); if($line -and -not $line.StartsWith('#') -and $line.Contains('=')){ $key,$value=$line.Split('=',2);$settings[$key.Trim()]=$value.Trim() } }; $settings }
function Required([hashtable]$settings,[string]$key) { if([string]::IsNullOrWhiteSpace($settings[$key])){throw "$key is required in mongodb.conf."};$settings[$key] }
function Mongo-Services { @(Get-CimInstance Win32_Service | Where-Object { $_.PathName -match '(?i)mongod\.exe' -or $_.Name -match '(?i)^mongodb' }) }
function Parse-Service([object]$service) {
 $cmd=$service.PathName;$exe=[regex]::Match($cmd,'(?i)^\s*"?([^"]*mongod\.exe)"?').Groups[1].Value;$cfg=[regex]::Match($cmd,'(?i)--config\s+(?:"([^"]+)"|(\S+))');$port=[regex]::Match($cmd,'(?i)--port\s+(\d+)').Groups[1].Value;$data=[regex]::Match($cmd,'(?i)--dbpath\s+(?:"([^"]+)"|(\S+))')
 $cp=if($cfg.Success){if($cfg.Groups[1].Success){$cfg.Groups[1].Value}else{$cfg.Groups[2].Value}}else{$null};$dp=if($data.Success){if($data.Groups[1].Success){$data.Groups[1].Value}else{$data.Groups[2].Value}}else{$null}
 $lp=$null;if($cp -and (Test-Path -LiteralPath $cp)){$lines=Get-Content -LiteralPath $cp;if(-not $port){$port=(($lines|Select-String '^\s*port\s*:\s*(\d+)'|Select-Object -First 1).Matches.Groups[1].Value)};if(-not $dp){$dp=(($lines|Select-String '^\s*dbPath\s*:\s*(.+?)\s*$'|Select-Object -First 1).Matches.Groups[1].Value).Trim(' ','"',"'")};$lp=(($lines|Select-String '^\s*path\s*:\s*(.+?)\s*$'|Select-Object -First 1).Matches.Groups[1].Value).Trim(' ','"',"'")}
 [pscustomobject]@{Executable=$exe;ConfigFile=$cp;Port=$port;DataPath=$dp;LogPath=$lp}
}
function Wait-ServiceRunning([string]$name){for($i=0;$i -lt 30;$i++){if((Get-Service -Name $name -ErrorAction SilentlyContinue).Status -eq 'Running'){return};Start-Sleep 1};throw "Service $name did not start."}
function Wait-Port([string]$hostName,[int]$port){for($i=0;$i -lt 30;$i++){try{$tcp=[Net.Sockets.TcpClient]::new();$tcp.Connect($hostName,$port);$tcp.Dispose();return}catch{Start-Sleep 1}};throw "MongoDB port $port is not listening on host $hostName."}
function Install-RequiredBinary([string]$url,[string]$archive,[string]$destination,[string]$expected){New-Item -ItemType Directory -Force -Path (Split-Path -Parent $archive),(Split-Path -Parent $destination)|Out-Null;if(-not(Test-Path -LiteralPath $archive)){Log 'Downloading required MongoDB archive.';Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing};$stage=Join-Path (Split-Path -Parent $archive) ([guid]::NewGuid());Expand-Archive -LiteralPath $archive -DestinationPath $stage -Force;$source=Get-ChildItem -LiteralPath $stage -Directory|Select-Object -First 1;if(-not $source){throw "Archive did not contain a deployment directory: $archive"};Move-Item -LiteralPath $source.FullName -Destination $destination;if(-not(Test-Path -LiteralPath $expected)){throw "Expected executable was not extracted: $expected"}}
function Same-Path([string]$left,[string]$right){$left -and $right -and ([IO.Path]::GetFullPath($left)).TrimEnd('\') -eq ([IO.Path]::GetFullPath($right)).TrimEnd('\')}
function Move-PreservedDirectory([string]$source,[string]$destination,[string]$label){if(-not(Test-Path -LiteralPath $source) -or(Same-Path $source $destination)){return};if((Test-Path -LiteralPath $destination) -and (Get-ChildItem -LiteralPath $destination -Force|Measure-Object).Count -gt 0){throw "Cannot safely migrate $label from $source to non-empty destination $destination."};New-Item -ItemType Directory -Force -Path $destination|Out-Null;Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force;Log "$label copied from $source to $destination; source and existing contents preserved."}
function Test-ListenerOwnedByDeployment([object]$listener,[object]$service,[object]$deployment){
    if(-not $listener){return $false}
    if($service -and $service.ProcessId -and $listener.OwningProcess -eq $service.ProcessId){return $true}
    $owner=Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    if(-not $owner -or $owner.ProcessName -ne 'mongod'){return $false}
    return $deployment -and $deployment.Executable -and $owner.Path -and (Same-Path $owner.Path $deployment.Executable)
}

$root=(Resolve-Path "$PSScriptRoot\..\..\..").Path;$sourceConfig=Join-Path $root 'config\windows\mongodb.conf';if(-not(Test-Path -LiteralPath $sourceConfig)){throw "Config file not found: $sourceConfig"};$s=Read-Settings $sourceConfig
$hostName=Required $s 'MONGODB_HOST';$port=[int](Required $s 'MONGODB_PORT');$serviceName=Required $s 'MONGODB_SERVICE_NAME';$displayName=Required $s 'MONGODB_SERVICE_DISPLAY_NAME';$installDir=Required $s 'MONGODB_INSTALL_DIR';$dataDir=Required $s 'MONGODB_DATA_DIR';$logDir=Required $s 'MONGODB_LOG_DIR';$configFile=Required $s 'MONGODB_CONFIG_FILE';$mongod=Required $s 'MONGODB_EXECUTABLE';$mongosh=Required $s 'MONGOSH_EXECUTABLE';$logPath=Join-Path $logDir (Required $s 'MONGODB_LOG_FILE')
Log 'MongoDB Windows setup reconciliation started.';Log "Desired service: $serviceName; desired port: $port";$services=Mongo-Services;$service=$services|Where-Object Name -eq $serviceName|Select-Object -First 1;if(-not $service){$service=$services|Select-Object -First 1};$existing=if($service){Parse-Service $service}else{$null};if($service){Log "Existing Windows service detected: $($service.Name)."}else{Log 'No existing MongoDB Windows service detected.'};if($existing){Log "Existing deployment detected. Executable: $($existing.Executable); data: $($existing.DataPath); log: $($existing.LogPath); config: $($existing.ConfigFile); port: $($existing.Port)"}
foreach($item in @(@('installation directory',$installDir),@('data directory',$dataDir),@('configuration file',$configFile),@('executable',$mongod))){if(Test-Path -LiteralPath $item[1]){Log "Existing $($item[0]) detected: $($item[1])"}}
$needsDataMigration=$existing -and $existing.DataPath -and -not(Same-Path $existing.DataPath $dataDir)
$existingLogDir=if($existing -and $existing.LogPath){Split-Path -Parent $existing.LogPath}else{$null}
$needsLogMigration=$existingLogDir -and -not(Same-Path $existingLogDir $logDir)
if(($needsDataMigration -or $needsLogMigration) -and $service -and $service.State -ne 'Stopped'){Log 'Stopping existing service before preserving and migrating deployment directories.';Stop-Service -Name $service.Name -Force}
if(-not(Test-Path -LiteralPath $mongod)){
    if($existing -and $existing.Executable -and(Test-Path -LiteralPath $existing.Executable)){
        $existingInstall=Split-Path -Parent (Split-Path -Parent $existing.Executable)
        New-Item -ItemType Directory -Force -Path $installDir|Out-Null
        Copy-Item -Path (Join-Path $existingInstall '*') -Destination $installDir -Recurse -Force
        Log "Existing MongoDB binaries copied from $existingInstall to desired installation directory $installDir."
        if(-not(Test-Path -LiteralPath $mongod)){throw "Existing MongoDB binary migration did not produce configured executable: $mongod"}
    }else{Install-RequiredBinary (Required $s 'MONGODB_DOWNLOAD_URL') (Join-Path (Split-Path -Parent $installDir) 'downloads\mongodb.zip') $installDir $mongod}
}else{Log 'Existing mongod executable detected; reusing binaries.'}
if(-not(Test-Path -LiteralPath $mongosh)){$mongoshRoot=Split-Path -Parent (Split-Path -Parent $mongosh);Install-RequiredBinary (Required $s 'MONGOSH_DOWNLOAD_URL') (Join-Path (Split-Path -Parent $mongoshRoot) 'downloads\mongosh.zip') $mongoshRoot $mongosh}
if($needsDataMigration){Move-PreservedDirectory $existing.DataPath $dataDir 'MongoDB data directory'}
if($needsLogMigration){Move-PreservedDirectory $existingLogDir $logDir 'MongoDB log directory'}
New-Item -ItemType Directory -Force -Path $dataDir,$logDir,(Split-Path -Parent $configFile)|Out-Null
@"
systemLog:
  destination: file
  path: "$($logPath.Replace('\','/'))"
  logAppend: true
storage:
  dbPath: "$($dataDir.Replace('\','/'))"
net:
  bindIp: $hostName
  port: $port
"@|Set-Content -LiteralPath $configFile -Encoding utf8
Log "Configuration updated: $configFile"
$reRegister=-not $service -or $service.Name -ne $serviceName -or $existing.Port -ne "$port" -or $existing.ConfigFile -ne $configFile -or $existing.Executable -ne $mongod
$listener=Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue|Select-Object -First 1
if($listener -and -not(Test-ListenerOwnedByDeployment $listener $service $existing)){
    $owner=Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    throw "Desired MongoDB port $port is already occupied by unrelated process $($owner.ProcessName) (PID $($listener.OwningProcess))."
}
if($listener){Log "Desired port $port is already listening by PID $($listener.OwningProcess), which belongs to the existing MongoDB deployment."}
if($reRegister -and $service -and $service.State -ne 'Stopped'){Log "Stopping existing service $($service.Name) for configuration reconciliation.";Stop-Service -Name $service.Name -Force}
if($reRegister -and $service){Log 'Service configuration mismatch detected; re-registering service. Existing databases are preserved.';& sc.exe delete $service.Name|Out-Null;for($i=0;$i -lt 30 -and(Get-Service -Name $service.Name -ErrorAction SilentlyContinue);$i++){Start-Sleep 1};if(Get-Service -Name $service.Name -ErrorAction SilentlyContinue){throw "Unable to remove existing service $($service.Name)."}}
if($reRegister){& $mongod --config $configFile --serviceName $serviceName --serviceDisplayName $displayName --install;if($LASTEXITCODE -ne 0){throw "MongoDB service registration failed with exit code $LASTEXITCODE."};& sc.exe config $serviceName start= auto|Out-Null;if($LASTEXITCODE -ne 0){throw "Unable to set automatic startup for $serviceName."};if($existing -and $existing.Port -ne "$port"){Log "Port migration performed: $($existing.Port) -> $port."}}else{Log 'Existing service matches the desired configuration; no restart is required.'}
if((Get-Service -Name $serviceName -ErrorAction Stop).Status -ne 'Running'){Start-Service -Name $serviceName -ErrorAction Stop};Wait-ServiceRunning $serviceName;Wait-Port $hostName $port
$listener=Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop|Select-Object -First 1
$owner=Get-Process -Id $listener.OwningProcess -ErrorAction Stop
if($owner.ProcessName -ne 'mongod'){throw "Configured port $port is not owned by mongod (found $($owner.ProcessName))."}
$databases=& $mongosh --quiet --host $hostName --port $port --eval "db.adminCommand({listDatabases:1}).databases.map(function(d){return d.name}).join(',')" 2>&1;if($LASTEXITCODE -ne 0){throw "mongosh validation failed: $databases"};Log "Existing databases preserved and accessible: $databases";Log 'Validation successful: service exists and is running; mongod and mongosh work; configured port, data directory, and log directory are valid.'
