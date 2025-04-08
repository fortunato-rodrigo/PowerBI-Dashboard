param (
    [string]$DashboardName,
    [string]$PowerBIFilePath = ""
)

# Format branch name
$BranchName = "feature/$DashboardName"

# Create feature branch
git checkout -b $BranchName

# Paths
$basePath = Join-Path -Path "." -ChildPath "reports\$DashboardName"
$dataModelPath = Join-Path $basePath "DataModel"
$visualsPath = Join-Path $basePath "Visuals"
$resourcesPath = Join-Path $basePath "Resources"

# Create folders
New-Item -ItemType Directory -Path $basePath, $dataModelPath, $visualsPath, $resourcesPath -Force | Out-Null

# Create README files
"# $DashboardName Dashboard" | Out-File -Encoding utf8 "$basePath\README.md"
"# Resources" | Out-File -Encoding utf8 "$resourcesPath\README.md"

# Copy Power BI file if provided
if ($PowerBIFilePath -ne "") {
    $ext = [System.IO.Path]::GetExtension($PowerBIFilePath)
    $destFile = Join-Path -Path $basePath -ChildPath "$DashboardName$ext"
    Copy-Item -Path $PowerBIFilePath -Destination $destFile
}
else {
    "{}" | Out-File -Encoding utf8 "$basePath\$DashboardName.pbip"
}

# Git stage, commit, push
git add .
git commit -m "Add $DashboardName dashboard structure"
git push -u origin $BranchName
