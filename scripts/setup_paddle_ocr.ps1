$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backendRoot = Join-Path $projectRoot 'backend'
$python = Join-Path $backendRoot '.venv\Scripts\python.exe'
$cacheDir = Join-Path $projectRoot '.local\paddle-cache'

if (-not (Test-Path -LiteralPath $python)) {
    throw 'Backend sanal ortamı bulunamadı: backend\.venv'
}

Push-Location $backendRoot
try {
    & $python -c 'import paddle, paddleocr, cv2'
    if ($LASTEXITCODE -ne 0) {
        & $python -m pip install -e '.[ocr]'
        if ($LASTEXITCODE -ne 0) { throw 'PaddleOCR paketleri kurulamadı.' }
    }
} finally {
    Pop-Location
}

& $python (Join-Path $PSScriptRoot 'setup_paddle_ocr.py') --cache-dir $cacheDir
if ($LASTEXITCODE -ne 0) { throw 'PaddleOCR modeli hazırlanamadı.' }
