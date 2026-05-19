# Extract-QueryMetadata.ps1
# Consulta data_quality.tables_in_dashboards_pbix no Databricks e gera
# dashboards/<Dashboard>/_documentacao/07-queries-sql.md com as queries SQL
# reais e linhagem completa de tabelas por camada.
#
# Autenticacao: DATABRICKS_TOKEN no .env (pessoal) ou service principal Power BI
#
# Uso:
#   .\tools\Extract-QueryMetadata.ps1 -Dashboard Scorecard
#   .\tools\Extract-QueryMetadata.ps1 -Dashboard "Daily Sales Dashboard" -Force

#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [string]$Dashboard,

    # Sobrescreve o filtro LIKE usado na busca no Databricks.
    # Util quando o nome da pasta difere do dashboard_name na tabela (ex: acentos).
    # Exemplo: -DashboardFilter "gestão de receita"
    [string]$DashboardFilter = "",

    [switch]$Force
)

$ErrorActionPreference = "Continue"

$RepoRoot   = Split-Path $PSScriptRoot -Parent
$DashDir    = Join-Path $RepoRoot "dashboards\$Dashboard"
$DocDir     = Join-Path $DashDir "_documentacao"
$OutFile    = Join-Path $DocDir "07-queries-sql.md"
$EnvFile    = Join-Path $RepoRoot ".env"

# ---------------------------------------------------------------------------
# Validacoes
# ---------------------------------------------------------------------------
if (-not (Test-Path $DashDir)) {
    Write-Error "Dashboard nao encontrado: $DashDir"
    exit 1
}

if ((Test-Path $OutFile) -and -not $Force) {
    Write-Host ""
    Write-Host "  07-queries-sql.md ja existe. Use -Force para regenerar." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $DocDir)) {
    New-Item -ItemType Directory -Path $DocDir -Force | Out-Null
}

Write-Host ""
Write-Host "Dashboard : $Dashboard" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Ler .env
# ---------------------------------------------------------------------------
$EnvVars = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line.Split("=", 2)
            if ($parts.Count -eq 2) { $EnvVars[$parts[0].Trim()] = $parts[1].Trim() }
        }
    }
    Write-Host "Arquivo .env carregado." -ForegroundColor Gray
} else {
    Write-Error ".env nao encontrado. Execute: .\tools\Setup-Env.ps1"
    exit 1
}

$dbHost      = if ($EnvVars["DATABRICKS_HOST"]) { $EnvVars["DATABRICKS_HOST"] } else { "beetech-prod-analytics.cloud.databricks.com" }
$warehouseId = if ($EnvVars["DATABRICKS_WAREHOUSE_ID"]) { $EnvVars["DATABRICKS_WAREHOUSE_ID"] } else { "e35e97a9319a6fe7" }
$dbToken     = $EnvVars["DATABRICKS_TOKEN"]

# ---------------------------------------------------------------------------
# Autenticar no Databricks
# Prioridade 1: DATABRICKS_TOKEN pessoal (mais simples)
# Prioridade 2: Service principal Power BI via Azure AD
# ---------------------------------------------------------------------------
Write-Host ""

if ($dbToken) {
    Write-Host "Usando DATABRICKS_TOKEN pessoal do .env." -ForegroundColor Green
} else {
    Write-Host "DATABRICKS_TOKEN nao encontrado - tentando service principal..." -ForegroundColor Cyan

    $tenantId     = $EnvVars["POWERBI_TENANT_ID"]
    $clientId     = $EnvVars["POWERBI_CLIENT_ID"]
    $clientSecret = $EnvVars["POWERBI_CLIENT_SECRET"]

    if (-not $tenantId -or -not $clientId -or -not $clientSecret) {
        Write-Error "Nenhuma autenticacao disponivel. Adicione ao .env:"
        Write-Host "  DATABRICKS_TOKEN=<seu-token>" -ForegroundColor Gray
        Write-Host "  ou POWERBI_TENANT_ID + CLIENT_ID + CLIENT_SECRET" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Como obter o token pessoal:" -ForegroundColor Gray
        Write-Host "    1. Acesse https://$dbHost" -ForegroundColor Gray
        Write-Host "    2. Settings > Developer > Access tokens > Generate new token" -ForegroundColor Gray
        exit 1
    }

    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d/.default"
    }

    try {
        $tokenResp = Invoke-RestMethod `
            -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -Method Post `
            -Body $tokenBody `
            -ContentType "application/x-www-form-urlencoded"
        $dbToken = $tokenResp.access_token
        Write-Host "  Autenticado via service principal." -ForegroundColor Green
    } catch {
        Write-Error "Falha na autenticacao: $($_.Exception.Message)"
        Write-Host "  Adicione DATABRICKS_TOKEN ao .env para autenticacao direta." -ForegroundColor Gray
        exit 1
    }
}

$dbHeaders = @{
    Authorization  = "Bearer $dbToken"
    "Content-Type" = "application/json"
}
$dbBaseUrl = "https://$dbHost"

# ---------------------------------------------------------------------------
# Consultar data_quality.tables_in_dashboards_pbix
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Consultando data_quality.tables_in_dashboards_pbix..." -ForegroundColor Cyan

$dashFilter = if ($DashboardFilter) { $DashboardFilter.ToLower() } else { $Dashboard.ToLower() }
$sql = "SELECT name, power_query_formatted, tables_from_power_query, dashboard_name, update_date FROM data_quality.tables_in_dashboards_pbix WHERE lower(dashboard_name) LIKE '%$dashFilter%' QUALIFY ROW_NUMBER() OVER (PARTITION BY name, dashboard_name ORDER BY update_date DESC) = 1 ORDER BY name"

$stmtBody = @{
    warehouse_id    = $warehouseId
    statement       = $sql
    wait_timeout    = "50s"
    on_wait_timeout = "CANCEL"
} | ConvertTo-Json -Depth 3

try {
    $stmtResp = Invoke-RestMethod `
        -Uri "$dbBaseUrl/api/2.0/sql/statements" `
        -Method Post `
        -Headers $dbHeaders `
        -Body $stmtBody
} catch {
    Write-Error "Falha ao executar query no Databricks: $($_.Exception.Message)"
    exit 1
}

# Aguardar resultado se ainda processando
$stmtId  = $stmtResp.statement_id
$maxWait = 12
$waited  = 0
while ($stmtResp.status.state -in @("PENDING", "RUNNING") -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited++
    $elapsed = $waited * 5
    Write-Host "  Aguardando resultado (${elapsed}s)..." -ForegroundColor Gray
    $stmtResp = Invoke-RestMethod `
        -Uri "$dbBaseUrl/api/2.0/sql/statements/$stmtId" `
        -Method Get `
        -Headers $dbHeaders
}

if ($stmtResp.status.state -ne "SUCCEEDED") {
    Write-Error "Query nao completou. Estado: $($stmtResp.status.state)"
    if ($stmtResp.status.error) { Write-Error $stmtResp.status.error.message }
    exit 1
}

$columns = $stmtResp.manifest.schema.columns | ForEach-Object { $_.name }
$rows    = $stmtResp.result.data_array

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host ""
    Write-Host "Nenhuma tabela encontrada para '$Dashboard' em data_quality.tables_in_dashboards_pbix." -ForegroundColor Yellow
    Write-Host "Verifique o nome exato do dashboard na tabela Databricks." -ForegroundColor Gray
    exit 0
}

Write-Host "  $($rows.Count) tabela(s) encontrada(s)." -ForegroundColor Green

# Mapear colunas por indice
$colIdx = @{}
for ($i = 0; $i -lt $columns.Count; $i++) { $colIdx[$columns[$i]] = $i }

# ---------------------------------------------------------------------------
# Processar cada linha - extrair tabelas Databricks por camada
# ---------------------------------------------------------------------------
$LayerPatterns = [ordered]@{
    diamond   = [regex]'(?i)\bdiamond\.[a-z0-9_]+\b'
    gold      = [regex]'(?i)\bgold\.[a-z0-9_]+\b'
    silver    = [regex]'(?i)\bsilver\.[a-z0-9_]+\b'
    bronze    = [regex]'(?i)\bbronze\.[a-z0-9_]+\b'
    beecambio = [regex]'(?i)\bbeecambio\.[a-z0-9_]+\b'
}

$LayerLabel = @{
    diamond   = "[D]"
    gold      = "[G]"
    silver    = "[S]"
    bronze    = "[!]"
    beecambio = "[B]"
}

$Tables = [System.Collections.Generic.List[hashtable]]::new()

foreach ($row in $rows) {
    $tableName    = $row[$colIdx["name"]]
    $sqlFormatted = $row[$colIdx["power_query_formatted"]]
    $ctes         = $row[$colIdx["tables_from_power_query"]]
    $dashName     = $row[$colIdx["dashboard_name"]]
    $updateDate   = $row[$colIdx["update_date"]]

    $layerTables = [ordered]@{}
    foreach ($layer in $LayerPatterns.Keys) {
        $found = $LayerPatterns[$layer].Matches($sqlFormatted) |
                 ForEach-Object { $_.Value.ToLower() } |
                 Select-Object -Unique | Sort-Object
        if ($found) { $layerTables[$layer] = @($found) }
    }

    $bronzeAlert = $layerTables.Contains("bronze") -and $layerTables["bronze"].Count -gt 0

    $Tables.Add(@{
        Name        = $tableName
        SQL         = $sqlFormatted
        CTEs        = $ctes
        DashName    = $dashName
        UpdateDate  = $updateDate
        Layers      = $layerTables
        BronzeAlert = $bronzeAlert
    })

    $layerSummary = ($layerTables.Keys | ForEach-Object { "$_($($layerTables[$_].Count))" }) -join ", "
    $alert = if ($bronzeAlert) { " [!] bronze" } else { "" }
    Write-Host "  $tableName -> $layerSummary$alert" -ForegroundColor Gray
}

# ---------------------------------------------------------------------------
# Gerar markdown
# ---------------------------------------------------------------------------
$now   = Get-Date -Format "dd/MM/yyyy HH:mm"
$lines = [System.Collections.Generic.List[string]]::new()

$bronzeTotal = @($Tables | Where-Object { $_.BronzeAlert }).Count

$lines.Add("# Queries SQL -- $Dashboard")
$lines.Add("> Gerado em: $now | Script: tools/Extract-QueryMetadata.ps1 -Dashboard $Dashboard")
$lines.Add("> Fonte: ``data_quality.tables_in_dashboards_pbix``")
if ($bronzeTotal -gt 0) {
    $lines.Add("")
    $lines.Add("> **ALERTA:** $bronzeTotal tabela(s) com conexao em camada ``bronze``. Dados brutos sem transformacao -- validar antes de usar em KPIs.")
}
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## Resumo de linhagem")
$lines.Add("")
$lines.Add("| Tabela Power BI | Camadas Databricks | Tabelas referenciadas | Alertas |")
$lines.Add("|---|---|---|---|")

foreach ($t in $Tables) {
    $layerList  = $t.Layers.Keys -join ", "
    $tableCount = ($t.Layers.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    $alert      = if ($t.BronzeAlert) { "ALERTA bronze" } else { "--" }
    $lines.Add("| ``$($t.Name)`` | $layerList | $tableCount tabelas | $alert |")
}

$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## Detalhamento por tabela")

foreach ($t in $Tables) {
    $lines.Add("")
    $lines.Add("### ``$($t.Name)``")
    $lines.Add("")
    $lines.Add("**Dashboard:** $($t.DashName)")
    $lines.Add("**Ultima atualizacao na tabela Databricks:** $($t.UpdateDate)")
    $lines.Add("")

    if ($t.Layers.Count -gt 0) {
        $lines.Add("**Tabelas Databricks referenciadas:**")
        $lines.Add("")
        foreach ($layer in $t.Layers.Keys) {
            $label = $LayerLabel[$layer]
            foreach ($tbl in $t.Layers[$layer]) {
                $lines.Add("- ``$tbl`` $label")
            }
        }
    }

    if ($t.BronzeAlert) {
        $lines.Add("")
        $lines.Add("> **ALERTA:** Esta tabela acessa a camada ``bronze`` -- dado bruto, sem transformacao DBT. Verificar se e intencional.")
    }

    $lines.Add("")
    $lines.Add("**SQL completo:**")
    $lines.Add("")
    $lines.Add('```sql')
    $lines.Add($t.SQL.Trim())
    $lines.Add('```')
}

$lines.Add("")
$lines.Add("---")
$lines.Add("*Gerado por tools/Extract-QueryMetadata.ps1 | Remessa Online*")

[System.IO.File]::WriteAllLines($OutFile, $lines, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Salvo em: $OutFile" -ForegroundColor Green
Write-Host "$($Tables.Count) tabela(s) documentada(s)." -ForegroundColor Green
$alertCount = @($Tables | Where-Object { $_.BronzeAlert }).Count
if ($alertCount -gt 0) {
    Write-Host "$alertCount tabela(s) com alerta bronze -- revisar 05-fontes.md." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Proximo passo: rode /pbi-documentacao $Dashboard para incorporar" -ForegroundColor Yellow
Write-Host "as queries ao 05-fontes.md e 01-tabelas.md." -ForegroundColor Yellow
Write-Host ""
