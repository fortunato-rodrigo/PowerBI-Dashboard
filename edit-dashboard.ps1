param (
    [string]$DashboardName,
    [string]$UpdatedPBIPPath
)

# Validate paths
if (-not (Test-Path $UpdatedPBIPPath)) {
    Write-Host "ERROR: PBIP file not found at $UpdatedPBIPPath" -ForegroundColor Red
    exit 1
}

# Extract names
$pbipName = [System.IO.Path]::GetFileNameWithoutExtension($UpdatedPBIPPath)
$sourceDir = Split-Path $UpdatedPBIPPath
$targetBasePath = Join-Path -Path "." -ChildPath "reports\$DashboardName"

# Overwrite .pbip file
$ext = [System.IO.Path]::GetExtension($UpdatedPBIPPath)
$destPBIP = Join-Path -Path $targetBasePath -ChildPath "$DashboardName$ext"
Copy-Item -Path $UpdatedPBIPPath -Destination $destPBIP -Force

# Overwrite Report and SemanticModel folders
$reportPath = Join-Path $sourceDir "$pbipName.Report"
$semanticPath = Join-Path $sourceDir "$pbipName.SemanticModel"

if (Test-Path $reportPath) {
    Copy-Item -Recurse -Path $reportPath -Destination (Join-Path $targetBasePath "$DashboardName.Report") -Force
}
if (Test-Path $semanticPath) {
    Copy-Item -Recurse -Path $semanticPath -Destination (Join-Path $targetBasePath "$DashboardName.SemanticModel") -Force
}

Write-Host "✅ Dashboard '$DashboardName' successfully updated with new PBIP version." -ForegroundColor Green
