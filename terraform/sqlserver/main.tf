terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# ================================================================
# CONFIG â€” Sirf yahan badlo, kahin aur nahi
# ================================================================
locals {
  sql_instance     = var.sql_instance
  sql_port         = var.sql_port
  sql_sa_password  = var.sql_sa_password
  sql_database     = var.sql_database
  sql_installer    = var.sql_installer
  sql_download_url = var.sql_download_url
}

# ================================================================
# STEP 0 â€” OS Detection
# Windows: $env:OS = "Windows_NT" â€” always set, no PS version issue
# Linux:   uname = Linux
# ================================================================
resource "null_resource" "detect_os" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = "if ($env:OS -eq 'Windows_NT') { Write-Host 'OS_DETECTED: Windows' }"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    on_failure  = continue
    command     = "[ \"$(uname)\" = 'Linux' ] && echo 'OS_DETECTED: Linux' || true"
  }
}


# ================================================================
# WINDOWS CHAIN
# OS check: $env:OS -eq 'Windows_NT'  (works on ALL Windows versions)
# Root path: 3 levels up from terraform/ folder â€” fully dynamic
# No external config file â€” all vars inline
# ================================================================

# W-1 â€” sqlcmd check / install
resource "null_resource" "w1_sqlcmd_windows" {
  depends_on = [null_resource.detect_os]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = <<-PSEOF
if ($env:OS -ne 'Windows_NT') { Write-Host '[W1] Not Windows - skip'; exit 0 }

Write-Host '[W1] Checking sqlcmd...'

# Check PATH
if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
  Write-Host '[W1] sqlcmd in PATH already'
  exit 0
}

# Search known install locations
$found = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Recurse -Filter 'sqlcmd.exe' -ErrorAction SilentlyContinue |
         Select-Object -First 1
if ($found) {
  Write-Host "[W1] sqlcmd found: $($found.FullName)"
  exit 0
}

# Try winget
Write-Host '[W1] Installing sqlcmd via winget...'
$r = Start-Process 'winget' -ArgumentList 'install Microsoft.SQLCMDUtilities --silent --accept-source-agreements --accept-package-agreements' -Wait -PassThru -ErrorAction SilentlyContinue
Write-Host "[W1] winget exit: $($r.ExitCode)"
PSEOF
  }
}

# W-2 â€” Download installer
resource "null_resource" "w2_download_windows" {
  depends_on = [null_resource.w1_sqlcmd_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = <<-PSEOF
if ($env:OS -ne 'Windows_NT') { Write-Host '[W2] Not Windows - skip'; exit 0 }

# Dynamic root â€” 3 levels up from terraform/
$root        = Split-Path (Split-Path (Split-Path $PWD.Path))
$dlDir       = Join-Path $root 'databases\sqlserver\downloads'
$installer   = Join-Path $dlDir '${local.sql_installer}'

if (!(Test-Path $dlDir)) { New-Item -ItemType Directory -Path $dlDir -Force | Out-Null }

if (Test-Path $installer) {
  Write-Host "[W2] Installer exists - skip download: $installer"
  exit 0
}

Write-Host '[W2] Downloading SQL Server 2022 Developer (~1.5GB)...'
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri '${local.sql_download_url}' -OutFile $installer -UseBasicParsing

if (!(Test-Path $installer)) { throw "[W2] Download failed: $installer" }
Write-Host "[W2] Download complete: $installer"
PSEOF
  }
}



# W-3 â€” Silent install
resource "null_resource" "w3_install_windows" {
  depends_on = [null_resource.w2_download_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = <<-PSEOF
if ($env:OS -ne 'Windows_NT') { Write-Host '[W3] Not Windows - skip'; exit 0 }

$svcName = if ('${local.sql_instance}' -eq 'MSSQLSERVER') { 'MSSQLSERVER' } else { 'MSSQL$${local.sql_instance}' }

if (Get-Service $svcName -ErrorAction SilentlyContinue) {
  Write-Host "[W3] SQL Server already installed (service: $svcName) - skip"
  exit 0
}

$root      = Split-Path (Split-Path (Split-Path $PWD.Path))
$installer = Join-Path $root 'databases\sqlserver\downloads\${local.sql_installer}'

if (!(Test-Path $installer)) { throw "[W3] Installer not found: $installer" }

Write-Host "[W3] Installing SQL Server (instance: ${local.sql_instance}, port: ${local.sql_port})..."

$args = "/ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /QS " +
        "/FEATURES=SQLEngine /INSTANCENAME=${local.sql_instance} " +
        "/SECURITYMODE=SQL /SAPWD=`"${local.sql_sa_password}`" " +
        "/SQLSVCACCOUNT=`"NT AUTHORITY\SYSTEM`" " +
        "/SQLSYSADMINACCOUNTS=`"BUILTIN\Administrators`" " +
        "/TCPENABLED=1 /NPENABLED=0 /SQLSVCSTARTUPTYPE=Automatic /UPDATEENABLED=FALSE"

$p = Start-Process -FilePath $installer -ArgumentList $args -Wait -PassThru
if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { throw "[W3] Install failed, exit code: $($p.ExitCode)" }

Write-Host "[W3] Install complete (ExitCode: $($p.ExitCode))"
PSEOF
  }
}

# W-4 â€” Enable Mixed Mode Auth + Set TCP port + Start/Restart service
resource "null_resource" "w4_start_windows" {
  depends_on = [null_resource.w3_install_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = <<-PSEOF
if ($env:OS -ne 'Windows_NT') { Write-Host '[W4] Not Windows - skip'; exit 0 }

$instance = '${local.sql_instance}'
$port     = '${local.sql_port}'
$svcName  = if ($instance -eq 'MSSQLSERVER') { 'MSSQLSERVER' } else { "MSSQL`$$instance" }

# Enable Mixed Mode Auth â€” search registry dynamically (works for any SQL version)
$regBase = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server'
$instKey = Get-ChildItem $regBase -ErrorAction SilentlyContinue |
           Where-Object { $_.PSChildName -match "^MSSQL\d+\.$instance$" } |
           Select-Object -First 1

if ($instKey) {
  # Mixed Mode
  $authPath = "$($instKey.PSPath)\MSSQLServer"
  if (Test-Path $authPath) {
    Set-ItemProperty -Path $authPath -Name 'LoginMode' -Value 2
    Write-Host '[W4] Mixed Mode Auth enabled'
  }
  # TCP Port
  $tcpPath = "$($instKey.PSPath)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
  if (Test-Path $tcpPath) {
    Set-ItemProperty -Path $tcpPath -Name 'TcpPort' -Value $port
    Set-ItemProperty -Path $tcpPath -Name 'TcpDynamicPorts' -Value ''
    Write-Host "[W4] TCP port set to: $port"
  }
} else {
  Write-Host '[W4] WARN: Registry key not found - using install defaults'
}

# Restart service
$svc = Get-Service $svcName -ErrorAction SilentlyContinue
if (!$svc) { throw "[W4] Service '$svcName' not found" }

Write-Host "[W4] Restarting service: $svcName"
Restart-Service $svcName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# Wait for Running
$timeout = 90; $elapsed = 0
while ($elapsed -lt $timeout) {
  $status = (Get-Service $svcName).Status
  if ($status -eq 'Running') { break }
  Write-Host "[W4] Waiting... ($elapsed s) $status"
  Start-Sleep -Seconds 5
  $elapsed += 5
}

if ((Get-Service $svcName).Status -ne 'Running') { throw "[W4] Service did not start in $timeout s" }

# Enable SA login via Windows Auth (runs before SA login works)
$sqlcmd = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Recurse -Filter 'sqlcmd.exe' -ErrorAction SilentlyContinue |
          Select-Object -First 1 | ForEach-Object { $_.FullName }
if ($sqlcmd) {
  & $sqlcmd -S "localhost,$port" -E -Q "ALTER LOGIN SA ENABLE; ALTER LOGIN SA WITH PASSWORD='${local.sql_sa_password}';" 2>&1 | Out-Null
  Write-Host '[W4] SA login enabled'
  # Restart again so SA auth works
  Restart-Service $svcName -Force
  Start-Sleep -Seconds 10
}

Write-Host "[W4] SQL Server Running on port $port"
PSEOF
  }
}


# W-8 â€” Full Verification
resource "null_resource" "w8_verify_windows" {
  depends_on = [null_resource.w4_start_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    command     = <<-PSEOF
if ($env:OS -ne 'Windows_NT') { Write-Host '[W8] Not Windows - skip'; exit 0 }

$instance = '${local.sql_instance}'
$port     = '${local.sql_port}'
$saPassword = '${local.sql_sa_password}'
$db       = '${local.sql_database}'
$server   = "localhost,$port"
$svcName  = if ($instance -eq 'MSSQLSERVER') { 'MSSQLSERVER' } else { "MSSQL`$$instance" }

$sqlcmd = Get-ChildItem 'C:\Program Files\Microsoft SQL Server' -Recurse -Filter 'sqlcmd.exe' -ErrorAction SilentlyContinue |
          Select-Object -First 1 | ForEach-Object { $_.FullName }

$allPassed = $true
function chk($label, $ok) {
  if ($ok) {
      Write-Host "  [PASS] $label"
  }
  else {
      Write-Host "  [FAIL] $label"
      $script:allPassed = $false
  }
}

Write-Host ''
Write-Host '================================================='
Write-Host '   WINDOWS - Full Verification'
Write-Host '================================================='

$svc = Get-Service $svcName -ErrorAction SilentlyContinue
chk "Service '$svcName' Running" ($svc -and $svc.Status -eq 'Running')
chk 'sqlcmd available' ($null -ne $sqlcmd)

& $sqlcmd -S "localhost" -E -Q 'SELECT 1' 2>&1 | Out-Null
chk "Windows Auth connection" ($LASTEXITCODE -eq 0)

$cnt = & $sqlcmd -S "localhost" -E -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='DataManagementDB'" 2>&1 | Where-Object {$_ -match "[0-9]"} | Select-Object -First 1
chk "Database DataManagementDB exists" ($cnt -match "[1-9]")

$r = & $sqlcmd -S $server -U SA -P $saPassword -d $db -Q 'SET NOCOUNT ON; SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE=''BASE TABLE''' 2>&1
chk 'Tables exist' ($r -match '[1-9]')

$r = & $sqlcmd -S $server -U SA -P $saPassword -d $db -Q 'SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.Customers' 2>&1
chk 'Seed data (Customers)' ($r -match '[1-9]')

& $sqlcmd -S "localhost" -E -d "DataManagementDB" -Q 'SELECT COUNT(*) FROM dbo.Orders o JOIN dbo.Customers c ON o.CustomerID=c.CustomerID' 2>&1 | Out-Null
chk 'JOIN query works' ($LASTEXITCODE -eq 0)

Write-Host ''
if ($pass) {
  Write-Host '================================================='
  Write-Host '   ALL CHECKS PASSED'
  Write-Host "   Server   : $server"
  Write-Host "   Instance : $instance"
  Write-Host "   Database : $db"
  Write-Host '================================================='
} else {
  Write-Host '   VERIFICATION FAILED'
  exit 1
}
PSEOF
  }
}
