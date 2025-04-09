param (
    [string]$DashboardName,
    [string]$PowerBIFilePath = ""
)

# Validate input
if (-not $DashboardName) {
    Write-Host "❌ Please provide a DashboardName. Example:"
    Write-Host ".\new-dashboard.ps1 -DashboardName 'people-analytics' -PowerBIFilePath 'C:\Path\PeopleAnalytics.pbip'"
    exit 1
}

# Format branch name (kebab-case)
$BranchName = "feature/$DashboardName"

# Create feature branch
git checkout -b $BranchName

# Define target paths in repository
$basePath = Join-Path -Path "." -ChildPath "reports\$DashboardName"
$dataModelPath = Join-Path $basePath "DataModel"
$visualsPath = Join-Path $basePath "Visuals"
$resourcesPath = Join-Path $basePath "Resources"

# Create folders
New-Item -ItemType Directory -Path $basePath, $dataModelPath, $visualsPath, $resourcesPath -Force | Out-Null

# Create README files
"# $DashboardName Dashboard" | Out-File -Encoding utf8 "$basePath\README.md"
"# Resources" | Out-File -Encoding utf8 "$resourcesPath\README.md"

# If PBIP path is provided, copy .pbip and PBIP folders
if ($PowerBIFilePath -ne "") {
    if (-not (Test-Path $PowerBIFilePath)) {
        Write-Host "❌ File not found: $PowerBIFilePath"
        exit 1
    }

    $ext = [System.IO.Path]::GetExtension($PowerBIFilePath)
    $pbipName = [System.IO.Path]::GetFileNameWithoutExtension($PowerBIFilePath)
    $destFile = Join-Path -Path $basePath -ChildPath "$DashboardName$ext"
    Copy-Item -Path $PowerBIFilePath -Destination $destFile -Force

    # Copy .SemanticModel folder
    $sourceDir = Split-Path $PowerBIFilePath
    $semanticPath = Join-Path $sourceDir "$pbipName.SemanticModel"
    $reportPath = Join-Path $sourceDir "$pbipName.Report"

    if (Test-Path $semanticPath) {
        Copy-Item -Recurse -Path $semanticPath -Destination (Join-Path $basePath "$DashboardName.SemanticModel") -Force
    }

    if (Test-Path $reportPath) {
        Copy-Item -Recurse -Path $reportPath -Destination (Join-Path $basePath "$DashboardName.Report") -Force
    }
}
else {
    # If no file provided, create empty PBIP placeholder
    "{}" | Out-File -Encoding utf8 "$basePath\$DashboardName.pbip"
}

# Git stage, commit, push
git add .
git commit -m "Add $DashboardName dashboard structure"
git push -u origin $BranchName

Write-Host "`n✅ Dashboard '$DashboardName' successfully created and pushed to branch '$BranchName'."
