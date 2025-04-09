# start-work.ps1
Clear-Host
Write-Host "`n🚀 Iniciando ambiente Power BI DevOps..." -ForegroundColor Cyan

# Etapa 1: Verifica se há alterações não salvas
$pendingChanges = git status --porcelain
if ($pendingChanges) {
    Write-Host "`n⚠️ Atenção: Você tem alterações não salvas. Faça commit ou stash antes de continuar." -ForegroundColor Yellow
    $proceed = Read-Host "Deseja continuar mesmo assim? [s/n]"
    if ($proceed -ne "s") {
        Write-Host "❌ Operação cancelada. Salve suas alterações antes de continuar." -ForegroundColor Red
        exit 1
    }
}

# Etapa 2: Garante que está na branch dev e atualiza
git checkout dev
git pull origin dev
Write-Host "`n✅ Branch 'dev' atualizada com sucesso." -ForegroundColor Green

# Etapa 3: Escolha entre criar novo dashboard ou trabalhar em um existente
Write-Host "`nO que deseja fazer agora?"
Write-Host "1. Criar um novo dashboard"
Write-Host "2. Continuar trabalhando em um dashboard existente"
$option = Read-Host "Digite a opção [1/2]"

switch ($option) {
    "1" {
        $dashboardName = Read-Host "`n🆕 Nome do novo dashboard (ex: people-analytics)"
        $pbipPath = Read-Host "📂 Caminho completo do arquivo .pbip (ex: C:\TempPBIP\people-analytics\PeopleAnalytics.pbip)"

        if (-not (Test-Path $pbipPath)) {
            Write-Host "`n❌ Caminho inválido. O arquivo .pbip não foi encontrado." -ForegroundColor Red
            exit 1
        }

        # Executar script de criação
        .\new-dashboard.ps1 -DashboardName $dashboardName -PowerBIFilePath $pbipPath
    }

    "2" {
        $branchName = Read-Host "`n🛠 Nome da branch existente (ex: feature/people-analytics)"
        git fetch
        git checkout $branchName

        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n❌ Não foi possível trocar para a branch '$branchName'." -ForegroundColor Red
            exit 1
        }

        git pull origin $branchName
        Write-Host "`n✅ Branch '$branchName' pronta para uso!" -ForegroundColor Green
    }

    default {
        Write-Host "`n❌ Opção inválida. Execute novamente e escolha 1 ou 2." -ForegroundColor Red
        exit 1
    }
}
