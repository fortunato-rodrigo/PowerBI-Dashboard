# Get-DataflowMetadata.ps1
# Descobre automaticamente os Dataflows de qualquer dashboard PBIP,
# busca metadados via Power BI REST API e salva em _documentacao/.
#
# Autenticacao (em ordem de preferencia):
#   1. .env com POWERBI_AUTH_MODE=service_principal  (nao-interativo, recomendado)
#   2. .env com POWERBI_AUTH_MODE=az_cli             (nao-interativo, requer az login previo)
#   3. Login interativo via MicrosoftPowerBIMgmt      (fallback)
#
# Uso:
#   .\tools\Get-DataflowMetadata.ps1 -Dashboard Scorecard
#   .\tools\Get-DataflowMetadata.ps1 -Dashboard Daily-Sales

#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [string]$Dashboard
)

$RepoRoot = Split-Path $PSScriptRoot -Parent
$DashDir  = Join-Path $RepoRoot "dashboards\$Dashboard"
$DocDir   = Join-Path $DashDir "_documentacao"
$OutFile  = Join-Path $DocDir "dataflow-metadata.md"
$EnvFile  = Join-Path $RepoRoot ".env"

# ---------------------------------------------------------------------------
# Validacoes
# ---------------------------------------------------------------------------
if (-not (Test-Path $DashDir)) {
    Write-Error "Dashboard nao encontrado: $DashDir"
    exit 1
}

$SemanticModelDir = Get-ChildItem -Path $DashDir -Directory |
    Where-Object { $_.Name -like "*.SemanticModel" } |
    Select-Object -First 1

if (-not $SemanticModelDir) {
    Write-Error "Pasta .SemanticModel nao encontrada em $DashDir"
    exit 1
}

$TablesDir = Join-Path $SemanticModelDir.FullName "definition\tables"
if (-not (Test-Path $TablesDir)) {
    Write-Error "Pasta definition\tables nao encontrada."
    exit 1
}

if (-not (Test-Path $DocDir)) {
    New-Item -ItemType Directory -Path $DocDir -Force | Out-Null
}

Write-Host ""
Write-Host "Dashboard : $Dashboard" -ForegroundColor Cyan
Write-Host "Tabelas   : $TablesDir" -ForegroundColor Gray
Write-Host ""

# ---------------------------------------------------------------------------
# Ler .env se existir
# ---------------------------------------------------------------------------
$EnvVars = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line.Split("=", 2)
            if ($parts.Count -eq 2) {
                $EnvVars[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }
    Write-Host "Arquivo .env carregado." -ForegroundColor Gray
}

$AuthMode = if ($EnvVars["POWERBI_AUTH_MODE"]) { $EnvVars["POWERBI_AUTH_MODE"] } else { "interactive" }

# ---------------------------------------------------------------------------
# Descobrir Dataflows lendo os .tmdl
# ---------------------------------------------------------------------------
Write-Host "Varrendo .tmdl em busca de Dataflows..." -ForegroundColor Cyan

$TmdlFiles  = Get-ChildItem -Path $TablesDir -Filter "*.tmdl"
$Discovered = [System.Collections.Generic.List[hashtable]]::new()

foreach ($file in $TmdlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -notmatch 'PowerPlatform\.Dataflows') { continue }

    $wsMatch = [regex]::Match($content, 'workspaceId\s*=\s*"([^"]+)"')
    $dfMatch = [regex]::Match($content, 'dataflowId\s*=\s*"([^"]+)"')
    $enMatch = [regex]::Match($content, 'entity\s*=\s*"([^"]+)"')

    if (-not $wsMatch.Success -or -not $dfMatch.Success) {
        Write-Warning "  $($file.Name): IDs nao encontrados."
        continue
    }

    $tableName   = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $workspaceId = $wsMatch.Groups[1].Value
    $dataflowId  = $dfMatch.Groups[1].Value
    $entity      = if ($enMatch.Success) { $enMatch.Groups[1].Value } else { "A definir" }

    $already = $Discovered | Where-Object { $_.DataflowId -eq $dataflowId -and $_.TabelaPBI -eq $tableName }
    if ($already) { continue }

    $Discovered.Add(@{
        TabelaPBI   = $tableName
        WorkspaceId = $workspaceId
        DataflowId  = $dataflowId
        Entidade    = $entity
    })

    Write-Host "  OK $tableName -> $dataflowId" -ForegroundColor Gray
}

if ($Discovered.Count -eq 0) {
    Write-Host "Nenhum Dataflow encontrado em $Dashboard." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Total: $($Discovered.Count) Dataflow(s) encontrado(s)." -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# Autenticacao
# ---------------------------------------------------------------------------
$Token = $null

# Modo 1: Service Principal via client credentials
if ($AuthMode -eq "service_principal") {
    Write-Host "Autenticando via Service Principal..." -ForegroundColor Cyan
    $tenantId     = $EnvVars["POWERBI_TENANT_ID"]
    $clientId     = $EnvVars["POWERBI_CLIENT_ID"]
    $clientSecret = $EnvVars["POWERBI_CLIENT_SECRET"]

    if (-not $tenantId -or -not $clientId -or -not $clientSecret) {
        Write-Error "POWERBI_AUTH_MODE=service_principal mas TENANT_ID, CLIENT_ID ou CLIENT_SECRET ausentes no .env"
        exit 1
    }

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://analysis.windows.net/powerbi/api/.default"
    }
    try {
        $resp  = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
                                   -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        $Token = $resp.access_token
        Write-Host "Autenticado via Service Principal." -ForegroundColor Green
    }
    catch {
        Write-Error "Falha na autenticacao Service Principal: $($_.Exception.Message)"
        exit 1
    }
}

# Modo 2: Azure CLI
elseif ($AuthMode -eq "az_cli") {
    Write-Host "Obtendo token via Azure CLI..." -ForegroundColor Cyan
    try {
        $Token = az account get-access-token `
            --resource "https://analysis.windows.net/powerbi/api" `
            --query "accessToken" -o tsv 2>$null
        if (-not $Token) { throw "Token vazio" }
        Write-Host "Token obtido via Azure CLI." -ForegroundColor Green
    }
    catch {
        Write-Error "Falha ao obter token via Azure CLI. Rode 'az login' primeiro.`n$($_.Exception.Message)"
        exit 1
    }
}

# Modo 3: Interativo via MicrosoftPowerBIMgmt (fallback)
else {
    Write-Host "Autenticando interativamente (fallback)..." -ForegroundColor Yellow
    Write-Host "Dica: configure .env com POWERBI_AUTH_MODE=az_cli ou service_principal para evitar este prompt." -ForegroundColor Gray

    if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
        Write-Host "Instalando MicrosoftPowerBIMgmt..." -ForegroundColor Yellow
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
            Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
        }
        catch {
            Write-Error "Instale manualmente: Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force"
            exit 1
        }
    }
    Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop
    Connect-PowerBIServiceAccount | Out-Null
    $Token = (Get-PowerBIAccessToken -AsString).Replace("Bearer ", "")
    Write-Host "Autenticado." -ForegroundColor Green
}

$Headers = @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" }
$BaseUrl = "https://api.powerbi.com/v1.0/myorg"

Write-Host ""

# ---------------------------------------------------------------------------
# Cache de exports (evita chamar a API multiplas vezes para o mesmo Dataflow)
# ---------------------------------------------------------------------------
$ExportCache = @{}

function Get-DataflowExport {
    param([string]$WorkspaceId, [string]$DataflowId)
    $key = "$WorkspaceId|$DataflowId"
    if ($ExportCache.ContainsKey($key)) { return $ExportCache[$key] }
    try {
        $url    = "$BaseUrl/groups/$WorkspaceId/dataflows/$DataflowId/export"
        $export = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
        $ExportCache[$key] = $export
        return $export
    }
    catch {
        $ExportCache[$key] = $null
        return $null
    }
}

# Extrai codigo M da entidade no CDM export
function Get-EntityMashupCode {
    param($Export, [string]$EntityName)
    if (-not $Export -or -not $Export.entities) { return $null }
    $entity = $Export.entities | Where-Object {
        $_.name -eq $EntityName -or $_.name -ieq $EntityName
    } | Select-Object -First 1
    if (-not $entity) { return $null }
    return $entity.'pbi:mashupCode'
}

# Extrai queries SQL do codigo M (padrao Value.NativeQuery ou strings SQL inline)
function Get-SqlFromMashup {
    param([string]$MashupCode)
    if (-not $MashupCode) { return @() }
    $queries = [System.Collections.Generic.List[string]]::new()

    # Padrao 1: Value.NativeQuery(source, "SQL aqui", ...)
    $matches1 = [regex]::Matches($MashupCode, 'Value\.NativeQuery\s*\([^,]+,\s*"((?:[^"\\]|\\.)*)"\s*[,\)]')
    foreach ($m in $matches1) {
        $sql = $m.Groups[1].Value -replace '\\n', "`n" -replace '\\"', '"'
        if ($sql.Trim()) { $queries.Add($sql.Trim()) }
    }

    # Padrao 2: bloco SQL em aspas duplas multiplas linhas (#"...")
    $matches2 = [regex]::Matches($MashupCode, '#"((?:SELECT|WITH|FROM)[^"]*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches2) {
        $sql = $m.Groups[1].Value.Trim()
        if ($sql -and -not ($queries | Where-Object { $_ -eq $sql })) { $queries.Add($sql) }
    }

    return $queries
}

# ---------------------------------------------------------------------------
# Buscar metadados
# ---------------------------------------------------------------------------
$Results = [System.Collections.Generic.List[hashtable]]::new()

foreach ($df in $Discovered) {
    Write-Host "Buscando: $($df.TabelaPBI)" -ForegroundColor Cyan

    $result = @{
        TabelaPBI   = $df.TabelaPBI
        WorkspaceId = $df.WorkspaceId
        DataflowId  = $df.DataflowId
        Entidade    = $df.Entidade
        Nome        = "A definir"
        Descricao   = "A definir"
        Fontes      = [System.Collections.Generic.List[string]]::new()
        Refresh     = "A definir"
        MashupCode  = $null
        SqlQueries  = [System.Collections.Generic.List[string]]::new()
    }

    try {
        $url    = "$BaseUrl/groups/$($df.WorkspaceId)/dataflows/$($df.DataflowId)"
        $dfInfo = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
        if ($dfInfo.name)        { $result.Nome      = $dfInfo.name }
        if ($dfInfo.description) { $result.Descricao = $dfInfo.description }
        Write-Host "  Nome   : $($result.Nome)" -ForegroundColor Gray
    }
    catch { Write-Warning "  Info basica: $($_.Exception.Message)" }

    try {
        $url    = "$BaseUrl/groups/$($df.WorkspaceId)/dataflows/$($df.DataflowId)/datasources"
        $dsResp = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
        foreach ($ds in $dsResp.value) {
            $str = $ds.datasourceType
            if ($ds.connectionDetails) {
                $det = ($ds.connectionDetails.PSObject.Properties |
                        Where-Object { $_.Value } |
                        ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", "
                if ($det) { $str = "$str ($det)" }
            }
            $result.Fontes.Add($str)
        }
        if ($result.Fontes.Count -eq 0) { $result.Fontes.Add("A definir") }
        Write-Host "  Fontes : $($result.Fontes -join ' | ')" -ForegroundColor Gray
    }
    catch {
        $result.Fontes.Add("Erro: $($_.Exception.Message)")
        Write-Warning "  Datasources: $($_.Exception.Message)"
    }

    try {
        $url   = "$BaseUrl/groups/$($df.WorkspaceId)/dataflows/$($df.DataflowId)/refreshSchedule"
        $sched = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
        if ($sched.enabled -eq $true) {
            $dias  = if ($sched.days)  { $sched.days  -join ", " } else { "todos os dias" }
            $horas = if ($sched.times) { $sched.times -join ", " } else { "A definir" }
            $tz    = if ($sched.localTimeZoneId) { $sched.localTimeZoneId } else { "UTC" }
            $result.Refresh = "$dias as $horas ($tz)"
        }
        elseif ($sched.enabled -eq $false) {
            $result.Refresh = "Desabilitado"
        }
        Write-Host "  Refresh: $($result.Refresh)" -ForegroundColor Gray
    }
    catch {
        $result.Refresh = if ($_.Exception.Response -and
                              $_.Exception.Response.StatusCode -eq 404) {
            "Sem agendamento configurado"
        } else { "Erro: $($_.Exception.Message)" }
        Write-Warning "  Refresh: $($result.Refresh)"
    }

    # Export: codigo M + SQL da entidade
    Write-Host "  Query  : buscando codigo M..." -NoNewline -ForegroundColor Gray
    $export = Get-DataflowExport -WorkspaceId $df.WorkspaceId -DataflowId $df.DataflowId
    if ($export) {
        $mashup = Get-EntityMashupCode -Export $export -EntityName $df.Entidade
        if ($mashup) {
            $result.MashupCode = $mashup
            $sqls = Get-SqlFromMashup -MashupCode $mashup
            foreach ($sql in $sqls) { $result.SqlQueries.Add($sql) }
            $label = if ($result.SqlQueries.Count -gt 0) { "$($result.SqlQueries.Count) SQL(s) extraida(s)" } else { "M encontrado, sem SQL inline" }
            Write-Host " $label" -ForegroundColor Green
        } else {
            Write-Host " entidade nao encontrada no export" -ForegroundColor Yellow
        }
    } else {
        Write-Host " sem acesso ao export" -ForegroundColor Yellow
    }

    $Results.Add($result)
    Write-Host ""
}

if ($AuthMode -eq "interactive" -and (Get-Module MicrosoftPowerBIMgmt)) {
    Disconnect-PowerBIServiceAccount | Out-Null
}

# ---------------------------------------------------------------------------
# Gerar markdown
# ---------------------------------------------------------------------------
$now   = Get-Date -Format "dd/MM/yyyy HH:mm"
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add("# Dataflow Metadata -- $Dashboard")
$lines.Add("> Gerado em: $now | Script: tools/Get-DataflowMetadata.ps1 -Dashboard $Dashboard")
$lines.Add("> Workspace: $($Results[0].WorkspaceId)")
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## Resumo")
$lines.Add("")
$lines.Add("| Tabela Power BI | Dataflow | Fontes | SQL extraida | Refresh |")
$lines.Add("|----------------|----------|--------|--------------|---------|")

foreach ($r in $Results) {
    $f    = $r.Fontes -join " / "
    $hasSql = if ($r.SqlQueries.Count -gt 0) { "Sim ($($r.SqlQueries.Count))" } else { "Nao" }
    $lines.Add("| $($r.TabelaPBI) | $($r.Nome) | $f | $hasSql | $($r.Refresh) |")
}

$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## Detalhamento por Dataflow")

foreach ($r in $Results) {
    $lines.Add("")
    $lines.Add("### $($r.TabelaPBI)")
    $lines.Add("")
    $lines.Add("| Campo | Valor |")
    $lines.Add("|-------|-------|")
    $lines.Add("| Nome do Dataflow | $($r.Nome) |")
    $lines.Add("| Descricao | $($r.Descricao) |")
    $lines.Add("| Workspace ID | $($r.WorkspaceId) |")
    $lines.Add("| Dataflow ID | $($r.DataflowId) |")
    $lines.Add("| Entidade carregada | $($r.Entidade) |")
    $lines.Add("| Fontes externas | $($r.Fontes -join ' / ') |")
    $lines.Add("| Refresh agendado | $($r.Refresh) |")

    # SQL extraida
    if ($r.SqlQueries.Count -gt 0) {
        $lines.Add("")
        $lines.Add("#### Query(s) SQL extraida(s) do Dataflow")
        $lines.Add("")
        $lines.Add("> Queries reais executadas no Databricks por este Dataflow.")
        $idx = 1
        foreach ($sql in $r.SqlQueries) {
            $lines.Add("")
            if ($r.SqlQueries.Count -gt 1) { $lines.Add("**Query $idx**") }
            $lines.Add('```sql')
            $lines.Add($sql)
            $lines.Add('```')
            $idx++
        }
    }

    # Codigo M completo
    if ($r.MashupCode) {
        $lines.Add("")
        $lines.Add("#### Codigo M (Power Query) completo")
        $lines.Add("")
        $lines.Add("> Logica completa de transformacao executada dentro do Dataflow.")
        $lines.Add('```powerquery')
        $lines.Add($r.MashupCode)
        $lines.Add('```')
    }
}

$lines.Add("")
$lines.Add("---")
$lines.Add("*Gerado por tools/Get-DataflowMetadata.ps1 | Remessa Online*")

[System.IO.File]::WriteAllLines($OutFile, $lines, [System.Text.UTF8Encoding]::new($false))

Write-Host "Salvo em: $OutFile" -ForegroundColor Green
Write-Host "$($Results.Count) Dataflow(s) documentado(s)." -ForegroundColor Green
Write-Host ""
Write-Host "Proximo passo: revise o dataflow-metadata.md gerado." -ForegroundColor Yellow
Write-Host "As queries SQL extraidas alimentam o cerebro do chatbot analitico." -ForegroundColor Yellow
