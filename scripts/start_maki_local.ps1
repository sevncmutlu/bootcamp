$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendRoot = Join-Path $projectRoot 'backend'
$python = Join-Path $backendRoot '.venv\Scripts\python.exe'
$cacheDir = Join-Path $projectRoot '.local\paddle-cache'
$modelsDir = Join-Path $cacheDir 'official_models'
$keyDir = Join-Path $projectRoot '.local\dev-auth'

if (-not (Test-Path -LiteralPath (Join-Path $cacheDir 'maki-ocr-manifest.json'))) {
    & (Join-Path $PSScriptRoot 'setup_paddle_ocr.ps1')
}

$sessionJson = & $python (Join-Path $PSScriptRoot 'create_dev_session.py') --key-dir $keyDir
if ($LASTEXITCODE -ne 0) { throw 'Geliştirme oturumu üretilemedi.' }
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

Write-Host ''
Write-Host 'Maki backend: http://127.0.0.1:8000'
Write-Host 'Flutter için geçici oturum tanımı:'
Write-Host "--dart-define=MAKI_ACCESS_TOKEN=$($session.token)"
Write-Host ''

Push-Location $backendRoot
try {
    & $python -m uvicorn 'maki.bootstrap:create_runtime_app' --factory --host 0.0.0.0 --port 8000
} finally {
    Pop-Location
}
