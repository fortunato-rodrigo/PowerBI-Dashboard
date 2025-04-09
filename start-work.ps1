Clear-Host
Write-Host ""
Write-Host ">>> Starting Power BI DevOps environment..." -ForegroundColor Cyan

# Step 1: Check for uncommitted changes
$pendingChanges = git status --porcelain
if ($pendingChanges) {
    Write-Host ""
    Write-Host "WARNING: You have uncommitted changes. Please commit or stash them before continuing." -ForegroundColor Yellow
    $proceed = Read-Host "Do you want to continue anyway? [y/n]"
    if ($proceed -ne "y") {
        Write-Host "Aborted. Please commit or stash your changes first." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Switch to 'dev' and pull latest changes
git checkout dev
git pull origin dev
Write-Host ""
Write-Host "Branch 'dev' is now up to date." -ForegroundColor Green

# Step 3: Choose what to do
Write-Host ""
Write-Host "What do you want to do?"
Write-Host "1. Create a new dashboard"
Write-Host "2. Work on an existing branch"
Write-Host "3. Edit an existing dashboard"
$option = Read-Host "Enter your choice [1/2/3]"

switch ($option) {
    "1" {
        $dashboardName = Read-Host "Enter the name of the new dashboard (e.g., people-analytics)"
        $pbipPath = Read-Host "Enter the full path to the .pbip file (e.g., C:\TempPBIP\people-analytics\PeopleAnalytics.pbip)"

        if (-not (Test-Path $pbipPath)) {
            Write-Host ""
            Write-Host "ERROR: The .pbip file was not found at the provided path." -ForegroundColor Red
            exit 1
        }

        .\new-dashboard.ps1 -DashboardName $dashboardName -PowerBIFilePath $pbipPath
    }

    "2" {
        $branchName = Read-Host "Enter the name of the existing branch (e.g., feature/people-analytics)"
        git fetch
        git checkout $branchName

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: Could not switch to branch '$branchName'." -ForegroundColor Red
            exit 1
        }

        git pull origin $branchName
        Write-Host ""
        Write-Host ("Branch '{0}' is ready for use." -f $branchName) -ForegroundColor Green
    }

    "3" {
        $dashboardName = Read-Host "Enter the name of the dashboard to update (e.g., people-analytics)"
        $branchName = "fix/$dashboardName"

        # Check if the branch already exists remotely or locally
        $existsLocal = git branch --list $branchName
        $existsRemote = git ls-remote --heads origin $branchName

        if ($existsLocal -or $existsRemote) {
            Write-Host "`n[✔] Branch '$branchName' already exists. Switching..." -ForegroundColor Yellow
            git checkout $branchName
            git pull origin $branchName
        } else {
            Write-Host "`n[ℹ️] Branch '$branchName' not found. Creating new branch based on 'dev'..." -ForegroundColor Cyan
            git checkout -b $branchName
            git push -u origin $branchName
        }

        $pbipPath = Read-Host "Enter full path to the updated .pbip file"
        .\edit-dashboard.ps1 -DashboardName $dashboardName -UpdatedPBIPPath $pbipPath

        # Optional: auto-stage and commit (or comment out to do it manually)
        git add .
        git commit -m "fix($dashboardName): update PBIP structure and visuals"
        git push
    }

    default {
        Write-Host ""
        Write-Host "Invalid option. Please run the script again and choose 1 or 2." -ForegroundColor Red
        exit 1
    }
}
