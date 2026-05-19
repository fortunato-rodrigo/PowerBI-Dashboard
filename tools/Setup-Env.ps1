# Setup-Env.ps1
# Busca as credenciais Power BI no AWS SSM Parameter Store e cria o .env local.
#
# Pre-requisitos:
#   - AWS CLI instalado e configurado (aws configure / aws sso login)
#   - Permissao IAM: ssm:GetParameter nos paths /prod/data/variables/PBI_*
#
# Uso:
#   .\tools\Setup-Env.ps1
#   .\tools\Setup-Env.ps1 -Force                   # sobrescreve .env existente
#   .\tools\Setup-Env.ps1 -Profile meu-perfil       # usa perfil AWS especifico
#   .\tools\Setup-Env.ps1 -Region us-east-1         # regiao AWS (padrao: us-east-1)

#Requires -Version 5.1

param(
    [string]$Profile = "",
    [string]$Region  = "us-east-1",
    [switch]$Force
)

$ErrorActionPreference = "Continue"

$RepoRoot = Split-Path $PSScriptRoot -Parent
$EnvFile  = Join-Path $RepoRoot ".env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  OK $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "  ERRO $msg" -ForegroundColor Red }

function Invoke-Aws {
    param([string[]]$Args)
    $cmd = @("aws") + $Args
    if ($Profile) { $cmd += @("--profile", $Profile) }
    if ($Region)  { $cmd += @("--region",  $Region) }
    & $cmd[0] $cmd[1..($cmd.Length - 1)]
}

# ---------------------------------------------------------------------------
# Verificacoes iniciais
# ---------------------------------------------------------------------------
Write-Host ""
Write-Step "Verificando pre-requisitos..."

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Fail "AWS CLI nao encontrado."
    Write-Host "  Instale em: https://aws.amazon.com/cli/" -ForegroundColor Gray
    exit 1
}
Write-Ok "AWS CLI encontrado"

$callerIdentity = Invoke-Aws @("sts", "get-caller-identity", "--output", "json")
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Credenciais AWS nao configuradas ou expiradas."
    Write-Host "  Execute: aws configure" -ForegroundColor Gray
    Write-Host "  Ou SSO : aws sso login --profile <perfil>" -ForegroundColor Gray
    exit 1
}

try {
    $identity = ($callerIdentity -join "") | ConvertFrom-Json
    Write-Ok "Autenticado como: $($identity.Arn)"
} catch {
    Write-Ok "Autenticado (ARN nao disponivel)"
}

# ---------------------------------------------------------------------------
# Verificar se .env ja existe
# ---------------------------------------------------------------------------
if ((Test-Path $EnvFile) -and -not $Force) {
    Write-Host ""
    Write-Host "  .env ja existe em $EnvFile" -ForegroundColor Yellow
    Write-Host "  Use -Force para sobrescrever: .\tools\Setup-Env.ps1 -Force" -ForegroundColor Gray
    exit 0
}

# ---------------------------------------------------------------------------
# Buscar parametros no SSM
# ---------------------------------------------------------------------------
Write-Host ""
Write-Step "Buscando credenciais no AWS SSM Parameter Store..."

$Parameters = [ordered]@{
    "POWERBI_TENANT_ID"     = "/prod/data/variables/PBI_TENANT_ID"
    "POWERBI_CLIENT_ID"     = "/prod/data/variables/PBI_CLIENT_ID"
    "POWERBI_CLIENT_SECRET" = "/prod/data/variables/PBI_CLIENT_SECRET"
}

$Values = @{}

foreach ($key in $Parameters.Keys) {
    $path = $Parameters[$key]
    Write-Host "  $path" -NoNewline -ForegroundColor Gray

    $result = Invoke-Aws @(
        "ssm", "get-parameter",
        "--name", $path,
        "--with-decryption",
        "--query", "Parameter.Value",
        "--output", "text"
    ) 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host " ERRO" -ForegroundColor Red
        Write-Host ""
        Write-Fail "Falha ao buscar '$path'."
        Write-Host "  Verifique:" -ForegroundColor Gray
        Write-Host "    1. O path existe no Parameter Store" -ForegroundColor Gray
        Write-Host "    2. Sua role IAM tem permissao ssm:GetParameter nesse path" -ForegroundColor Gray
        Write-Host "    3. A regiao esta correta (atual: $Region)" -ForegroundColor Gray
        exit 1
    }

    $Values[$key] = $result.ToString().Trim()
    Write-Host " OK" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Gravar .env
# ---------------------------------------------------------------------------
Write-Host ""
Write-Step "Gravando .env..."

$timestamp  = Get-Date -Format "dd/MM/yyyy HH:mm"
$envContent = @"
# Gerado automaticamente por tools/Setup-Env.ps1 em $timestamp
# NAO commite este arquivo — contem credenciais sensiveis
#
# Fonte: AWS SSM Parameter Store
#   /prod/data/variables/PBI_TENANT_ID
#   /prod/data/variables/PBI_CLIENT_ID
#   /prod/data/variables/PBI_CLIENT_SECRET
#
# Para regenerar: .\tools\Setup-Env.ps1 -Force

POWERBI_AUTH_MODE=service_principal
POWERBI_TENANT_ID=$($Values["POWERBI_TENANT_ID"])
POWERBI_CLIENT_ID=$($Values["POWERBI_CLIENT_ID"])
POWERBI_CLIENT_SECRET=$($Values["POWERBI_CLIENT_SECRET"])
"@

[System.IO.File]::WriteAllText($EnvFile, $envContent, [System.Text.UTF8Encoding]::new($false))

Write-Ok ".env criado em $EnvFile"

# ---------------------------------------------------------------------------
# Verificar .gitignore
# ---------------------------------------------------------------------------
$GitIgnore = Join-Path $RepoRoot ".gitignore"
if (Test-Path $GitIgnore) {
    $gitIgnoreContent = Get-Content $GitIgnore -Raw
    if ($gitIgnoreContent -notmatch '(^|\n)\.env(\r?\n|$)') {
        Write-Host ""
        Write-Host "  ATENCAO: .env nao esta no .gitignore!" -ForegroundColor Red
        Write-Host "  Adicione a linha '.env' ao .gitignore antes de qualquer commit." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Pronto! Credenciais configuradas." -ForegroundColor Green
Write-Host ""
Write-Host "Proximo passo:" -ForegroundColor Gray
Write-Host "  .\tools\Get-DataflowMetadata.ps1 -Dashboard <NomeDoDashboard>" -ForegroundColor White
Write-Host ""
