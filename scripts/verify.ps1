param(
    [switch]$SkipMobile,
    [switch]$SkipContainers,
    [switch]$SkipSecurity
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

function Invoke-Gate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Output "Kapı: $Name"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name başarısız oldu."
    }
}

Push-Location (Join-Path $root 'backend')
try {
    $artifactRoot = Join-Path $root 'artifacts'
    New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
    Invoke-Gate 'Kilit dosyası' { uv lock --check }
    Invoke-Gate 'Python biçimi' { uv run ruff format --check . }
    Invoke-Gate 'Python lint' { uv run ruff check . }
    Invoke-Gate 'Python türleri' { uv run mypy src }
    Invoke-Gate 'Python testleri' {
        uv run pytest `
            --basetemp (Join-Path $artifactRoot 'pytest') `
            --cov=maki `
            --cov-branch `
            --cov-fail-under=70
    }
    $auditRequirements = Join-Path $artifactRoot 'audit-requirements.txt'
    Invoke-Gate 'Bağımlılık listesini üretme' {
        uv export --quiet --frozen --all-extras --no-dev `
            --no-emit-project --output-file $auditRequirements
    }
    Invoke-Gate 'Bağımlılık açıkları' {
        uv run pip-audit --strict --require-hashes -r $auditRequirements
    }
    Invoke-Gate 'OpenAPI sözleşmesi' {
        uv run python (Join-Path $root 'scripts\export_openapi.py') --check
    }

    Invoke-Gate 'Python SBOM' {
        uv run cyclonedx-py environment .venv\Scripts\python.exe `
            --pyproject pyproject.toml `
            --output-reproducible `
            --of JSON `
            -o (Join-Path $artifactRoot 'backend.cdx.json')
    }
}
finally {
    Pop-Location
}

Invoke-Gate 'Frontend sınırı' {
    powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $root 'scripts\check_frontend_boundary.ps1')
}

if (-not $SkipMobile) {
    Push-Location (Join-Path $root 'packages\maki_finance_core')
    try {
        Invoke-Gate 'Finans paketleri' { dart pub get --enforce-lockfile }
        Invoke-Gate 'Finans biçimi' {
            dart format --output=none --set-exit-if-changed lib test
        }
        Invoke-Gate 'Finans analizi' { dart analyze --fatal-infos --fatal-warnings }
        Invoke-Gate 'Finans testleri' { dart test }
    }
    finally {
        Pop-Location
    }

    Push-Location (Join-Path $root 'frontend')
    try {
        Invoke-Gate 'Mobil paketler' { flutter pub get --enforce-lockfile }
        Invoke-Gate 'Mobil yerelleştirme kaynakları' { flutter gen-l10n }
        Invoke-Gate 'Mobil veritabanı kaynakları' {
            dart run build_runner build
        }
        Invoke-Gate 'Mobil test biçimi' {
            dart format --output=none --set-exit-if-changed test
        }
        Invoke-Gate 'Mobil analiz' {
            flutter analyze --fatal-infos --fatal-warnings
        }
        Invoke-Gate 'Mobil testler' { flutter test }
        Invoke-Gate 'Android derleme' { flutter build apk --debug }
    }
    finally {
        Pop-Location
    }
}

if (-not $SkipContainers) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker bulunamadı.'
    }
    foreach ($target in @(
        'api',
        'dispatcher',
        'worker-coach',
        'worker-forecast',
        'worker-ocr',
        'worker-data'
    )) {
        Invoke-Gate "Konteyner: $target" {
            docker build --target $target --tag "maki-$target`:dogrulama" `
                (Join-Path $root 'backend')
        }
    }
}

if (-not $SkipSecurity) {
    if (-not (Get-Command trivy -ErrorAction SilentlyContinue)) {
        throw 'Trivy bulunamadı.'
    }
    Invoke-Gate 'İmaj güvenliği' {
        trivy image `
            --config (Join-Path $root 'security\trivy.yaml') `
            'maki-api:dogrulama'
    }
}

Write-Output 'Tüm seçili üretim kapıları geçti.'
