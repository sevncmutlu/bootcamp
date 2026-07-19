[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Compose = Join-Path $Root "infra\compose\compose.yaml"
$Override = Join-Path $Root "infra\compose\compose.override.yaml"
$Project = "maki-smoke"
$env:MAKI_POSTGRES_PASSWORD = [Guid]::NewGuid().ToString("N")

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & docker compose --project-name $Project -f $Compose -f $Override @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose komutu başarısız oldu."
    }
}

function Invoke-HttpStatus {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Body = ""
    )
    $output = New-TemporaryFile
    try {
        $arguments = @(
            "--silent",
            "--show-error",
            "--output", $output.FullName,
            "--write-out", "%{http_code}",
            "--request", $Method
        )
        if ($Body) {
            $arguments += @(
                "--header", "Content-Type: application/json",
                "--header", "Idempotency-Key: smoke-test-anahtari",
                "--data", $Body
            )
        }
        $arguments += $Url
        $status = & curl.exe @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "HTTP isteği başarısız oldu."
        }
        return [int]$status
    }
    finally {
        Remove-Item -LiteralPath $output.FullName -Force -ErrorAction SilentlyContinue
    }
}

function Wait-Healthy {
    $deadline = [DateTime]::UtcNow.AddMinutes(3)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            if ((Invoke-HttpStatus -Method "GET" -Url "http://127.0.0.1:8000/health/ready") -eq 200) {
                return
            }
        }
        catch {
            Start-Sleep -Seconds 3
            continue
        }
        Start-Sleep -Seconds 3
    }
    throw "API hazırlık süresini aştı."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker bulunamadı."
}
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    throw "curl.exe bulunamadı."
}

try {
    Invoke-Compose build api dispatcher worker-data
    Invoke-Compose up --detach postgres redis otel migration api dispatcher worker-data
    Wait-Healthy

    if ((Invoke-HttpStatus -Method "GET" -Url "http://127.0.0.1:8000/health/live") -ne 200) {
        throw "Canlılık kontrolü başarısız."
    }

    $privacyBody = '{"question":"test","merchant_name":"SMOKE_GIZLI_MAGAZA"}'
    $privacyStatus = Invoke-HttpStatus `
        -Method "POST" `
        -Url "http://127.0.0.1:8000/api/v1/coach/queries" `
        -Body $privacyBody
    if ($privacyStatus -ne 422) {
        throw "Gizlilik reddi beklenen 422 durumunu üretmedi."
    }

    $billingBody = '{"store":"google_play","package_name":"com.team120.maki.maki_app","purchase_token":"SMOKE_GIZLI_TOKEN"}'
    $billingStatus = Invoke-HttpStatus `
        -Method "POST" `
        -Url "http://127.0.0.1:8000/api/v1/billing/verifications" `
        -Body $billingBody
    if ($billingStatus -ne 503) {
        throw "Eksik sağlayıcı güvenli kapalı davranmadı."
    }

    $logs = & docker compose --project-name $Project -f $Compose -f $Override logs --no-color
    if ($logs -match "SMOKE_GIZLI_MAGAZA|SMOKE_GIZLI_TOKEN") {
        throw "Konteyner logunda hassas test değeri bulundu."
    }
    Write-Host "Konteyner smoke kontrolleri geçti."
}
finally {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        & docker compose --project-name $Project -f $Compose -f $Override down --volumes --remove-orphans
    }
}
