# Setup-Python.ps1
# Cria a venv e instala as dependencias Python do repositorio.
#
# Uso:
#   .\tools\Setup-Python.ps1
#   .\tools\Setup-Python.ps1 -Force    # recria a venv do zero
#
# Apos rodar, ative a venv antes de executar scripts Python:
#   .\.venv\Scripts\Activate.ps1

#Requires -Version 5.1

param([switch]$Force)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$VenvPath = Join-Path $RepoRoot ".venv"
$ReqFile  = Join-Path $RepoRoot "requirements.txt"

function Write-Step([string]$msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "  OK $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "  ERRO $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Step "Verificando pre-requisitos..."

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Fail "Python nao encontrado. Instale em: https://python.org"
}

$pythonVersion = python --version 2>&1
Write-Ok $pythonVersion

if (-not (Test-Path $ReqFile)) {
    Write-Fail "requirements.txt nao encontrado em $RepoRoot"
}

# ---------------------------------------------------------------------------
# Criar (ou recriar) a venv
# ---------------------------------------------------------------------------
Write-Host ""
Write-Step "Configurando venv em .venv/ ..."

if ((Test-Path $VenvPath) -and $Force) {
    Write-Host "  Removendo venv existente..." -ForegroundColor Yellow
    Remove-Item $VenvPath -Recurse -Force
}

if (-not (Test-Path $VenvPath)) {
    python -m venv $VenvPath
    Write-Ok "venv criada"
} else {
    Write-Ok "venv ja existe (use -Force para recriar)"
}

# ---------------------------------------------------------------------------
# Instalar dependencias
# ---------------------------------------------------------------------------
Write-Host ""
Write-Step "Instalando dependencias de requirements.txt..."

$pip = Join-Path $VenvPath "Scripts\pip.exe"
& $pip install --quiet --upgrade pip
& $pip install --quiet -r $ReqFile

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Falha ao instalar dependencias"
}

Write-Ok "Dependencias instaladas"

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Pronto!" -ForegroundColor Green
Write-Host ""
Write-Host "Para ativar a venv:" -ForegroundColor Gray
Write-Host "  .\.venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Para rodar os scripts Python:" -ForegroundColor Gray
Write-Host "  python tools/export-genie-to-sql-examples.py" -ForegroundColor White
Write-Host ""
