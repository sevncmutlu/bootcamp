param(
    [int]$WebPort = 4180,
    [int]$ApiPort = 8000,
    [string]$Flutter = ''
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendRoot = Join-Path $projectRoot 'backend'
$frontendRoot = Join-Path $projectRoot 'frontend'
$python = Join-Path $backendRoot '.venv\Scripts\python.exe'
$cacheDir = Join-Path $projectRoot '.local\paddle-cache'
$modelsDir = Join-Path $cacheDir 'official_models'
$keyDir = Join-Path $projectRoot '.local\dev-auth'
$logDir = Join-Path $projectRoot '.local\logs'

if ([string]::IsNullOrWhiteSpace($Flutter)) {
    $workspaceFlutter = Join-Path $projectRoot '..\..\flutter-sdk\flutter\bin\flutter.bat'
    $Flutter = if (Test-Path -LiteralPath $workspaceFlutter) {
        (Resolve-Path $workspaceFlutter).Path
    } else {
        'flutter'
    }
}

$flutterRoot = Split-Path (Split-Path $Flutter -Parent) -Parent
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = $flutterRoot

if (-not (Test-Path -LiteralPath (Join-Path $cacheDir 'maki-ocr-manifest.json'))) {
    & (Join-Path $PSScriptRoot 'setup_paddle_ocr.ps1')
}

$sessionJson = & $python (Join-Path $PSScriptRoot 'create_dev_session.py') --key-dir $keyDir
if ($LASTEXITCODE -ne 0) { throw 'İmzalı geliştirme oturumu üretilemedi.' }
$session = $sessionJson | ConvertFrom-Json

$env:MAKI_ENVIRONMENT = 'development'
$env:MAKI_EXECUTION_MODE = 'local'
$env:MAKI_SECURITY__JWT_PUBLIC_KEY = $session.public_key
$env:MAKI_SECURITY__JWT_KEY_ID = 'development'
$env:MAKI_SECURITY__JWT_ISSUER = 'maki'
$env:MAKI_SECURITY__JWT_AUDIENCE = 'maki-mobile'
$env:MAKI_OCR__DETECTION_MODEL_DIR = Join-Path $modelsDir 'PP-OCRv6_medium_det'
$env:MAKI_OCR__RECOGNITION_MODEL_DIR = Join-Path $modelsDir 'PP-OCRv6_medium_rec'
$env:PADDLE_PDX_CACHE_HOME = $cacheDir
$env:PADDLE_PDX_MODEL_SOURCE = 'bos'
$env:PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK = 'True'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$backend = Start-Process `
    -FilePath $python `
    -ArgumentList @(
        '-m', 'uvicorn', 'maki.bootstrap:create_runtime_app', '--factory',
        '--host', '127.0.0.1', '--port', $ApiPort
    ) `
    -WorkingDirectory $backendRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logDir 'backend.out.log') `
    -RedirectStandardError (Join-Path $logDir 'backend.err.log') `
    -PassThru

try {
    $healthUrl = "http://127.0.0.1:$ApiPort/health/live"
    $ready = $false
    foreach ($attempt in 1..60) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    if (-not $ready) {
        throw "Maki backend başlatılamadı. Günlük: $logDir"
    }

    Write-Host "Maki hazır: http://127.0.0.1:$WebPort"
    Push-Location $frontendRoot
    try {
        & $Flutter run -d web-server `
            --web-hostname 127.0.0.1 `
            --web-port $WebPort `
            --dart-define="MAKI_ENV=preview" `
            --dart-define="WEB_DEMO_MODE=true" `
            --dart-define="BACKEND_URL=http://127.0.0.1:$ApiPort" `
            --dart-define="MAKI_ACCESS_TOKEN=$($session.token)"
    } finally {
        Pop-Location
    }
} finally {
    if (-not $backend.HasExited) {
        Stop-Process -Id $backend.Id
    }
}
