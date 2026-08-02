param(
    [string]$DeviceId = 'emulator-5554',
    [string]$AvdName = 'Maki_Portrait',
    [int]$ApiPort = 8000,
    [string]$Flutter = '',
    [string]$Adb = ''
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = (Resolve-Path (Join-Path $projectRoot '..')).Path
$runtimeRoot = Join-Path $workspaceRoot 'project\bootcamp-main'
$backendRoot = Join-Path $projectRoot 'backend'
$frontendRoot = Join-Path $projectRoot 'frontend'
$logDir = Join-Path $projectRoot '.local\logs'
$keyDir = Join-Path $projectRoot '.local\dev-auth'

function Resolve-FirstExistingFile {
    param([string[]]$Candidates, [string]$Label)
    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "$Label bulunamadı."
}

function Resolve-FirstExistingDirectory {
    param([string[]]$Candidates, [string]$Label)
    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Container)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "$Label bulunamadı."
}

$python = Resolve-FirstExistingFile -Label 'Maki Python çalışma ortamı' -Candidates @(
    (Join-Path $backendRoot '.venv\Scripts\python.exe'),
    (Join-Path $runtimeRoot 'backend\.venv\Scripts\python.exe')
)

if ([string]::IsNullOrWhiteSpace($Flutter)) {
    $Flutter = Resolve-FirstExistingFile -Label 'Flutter' -Candidates @(
        (Join-Path $workspaceRoot 'flutter-sdk\flutter\bin\flutter.bat')
    )
} else {
    $Flutter = Resolve-FirstExistingFile -Label 'Flutter' -Candidates @($Flutter)
}

if ([string]::IsNullOrWhiteSpace($Adb)) {
    $Adb = Resolve-FirstExistingFile -Label 'Android Debug Bridge' -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
        (Join-Path $workspaceRoot 'toolchains\android-sdk\platform-tools\adb.exe')
    )
} else {
    $Adb = Resolve-FirstExistingFile -Label 'Android Debug Bridge' -Candidates @($Adb)
}

$cacheDir = Resolve-FirstExistingDirectory -Label 'PaddleOCR model önbelleği' -Candidates @(
    (Join-Path $projectRoot '.local\paddle-cache'),
    (Join-Path $runtimeRoot '.local\paddle-cache')
)
$manifest = Join-Path $cacheDir 'maki-ocr-manifest.json'
$modelsDir = Join-Path $cacheDir 'official_models'
$detectionModel = Join-Path $modelsDir 'PP-OCRv6_medium_det'
$recognitionModel = Join-Path $modelsDir 'PP-OCRv6_medium_rec'
foreach ($requiredPath in @($manifest, $detectionModel, $recognitionModel)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "PaddleOCR çalışma dosyası eksik: $requiredPath"
    }
}

$existingListener = Get-NetTCPConnection -LocalPort $ApiPort -State Listen -ErrorAction SilentlyContinue
if ($existingListener) {
    throw "$ApiPort portu kullanımda. Yanlış anahtarlı eski backend'i kullanmamak için işlem durduruldu."
}

New-Item -ItemType Directory -Force -Path $logDir, $keyDir | Out-Null
$sessionJson = & $python (Join-Path $PSScriptRoot 'create_dev_session.py') --key-dir $keyDir
if ($LASTEXITCODE -ne 0) {
    throw 'İmzalı geliştirme oturumu üretilemedi.'
}
$session = $sessionJson | ConvertFrom-Json

$env:MAKI_ENVIRONMENT = 'development'
$env:MAKI_EXECUTION_MODE = 'local'
$env:MAKI_SECURITY__JWT_PUBLIC_KEY = $session.public_key
$env:MAKI_SECURITY__JWT_KEY_ID = 'development'
$env:MAKI_SECURITY__JWT_ISSUER = 'maki'
$env:MAKI_SECURITY__JWT_AUDIENCE = 'maki-mobile'
$env:MAKI_OCR__DETECTION_MODEL_DIR = $detectionModel
$env:MAKI_OCR__RECOGNITION_MODEL_DIR = $recognitionModel
$env:PADDLE_PDX_CACHE_HOME = $cacheDir
$env:PADDLE_PDX_MODEL_SOURCE = 'bos'
$env:PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK = 'True'
$env:PYTHONPATH = Join-Path $backendRoot 'src'
$env:PUB_CACHE = Join-Path $workspaceRoot 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $workspaceRoot 'gradle-home'
$env:ANDROID_USER_HOME = Join-Path $env:USERPROFILE '.android'
$env:ANDROID_SDK_HOME = $env:USERPROFILE

$flutterRoot = Split-Path (Split-Path $Flutter -Parent) -Parent
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = $flutterRoot

$backendOut = Join-Path $logDir 'android-demo-backend.out.log'
$backendErr = Join-Path $logDir 'android-demo-backend.err.log'
$backend = Start-Process `
    -FilePath $python `
    -ArgumentList @(
        '-m', 'uvicorn', 'maki.bootstrap:create_runtime_app', '--factory',
        '--host', '0.0.0.0', '--port', $ApiPort
    ) `
    -WorkingDirectory $backendRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $backendOut `
    -RedirectStandardError $backendErr `
    -PassThru

try {
    $healthUrl = "http://127.0.0.1:$ApiPort/health/live"
    $ready = $false
    foreach ($attempt in 1..120) {
        if ($backend.HasExited) { break }
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
        throw "Maki backend başlatılamadı. Günlükler: $backendOut ve $backendErr"
    }

    $capabilities = Invoke-RestMethod -Uri "http://127.0.0.1:$ApiPort/health/capabilities"
    if (-not $capabilities.fis_tarama) {
        throw 'Backend çalıştı ancak PaddleOCR fiş tarama yeteneği hazır değil.'
    }

    $authHeaders = @{ Authorization = "Bearer $($session.token)" }
    try {
        Invoke-WebRequest `
            -UseBasicParsing `
            -Headers $authHeaders `
            -Uri "http://127.0.0.1:$ApiPort/api/v1/billing/entitlements" `
            -TimeoutSec 10 | Out-Null
    } catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -in @(401, 403)) {
            throw 'Development oturumu korumalı API tarafından doğrulanmadı.'
        }
        # Yerel mağaza servisi yapılandırılmamışsa endpoint 503 dönebilir. Kimlik
        # doğrulaması 401/403 vermediği için development oturumu yine geçerlidir.
    }

    Push-Location $frontendRoot
    try {
        & $Flutter build apk --debug `
            --dart-define='MAKI_ENV=development' `
            --dart-define="BACKEND_URL=http://10.0.2.2:$ApiPort" `
            --dart-define="MAKI_ACCESS_TOKEN=$($session.token)"
        if ($LASTEXITCODE -ne 0) {
            throw 'Debug APK derlenemedi.'
        }
    } finally {
        Pop-Location
    }

    & $Adb start-server | Out-Null
    $deviceLines = & $Adb devices
    $deviceReady = $deviceLines | Where-Object { $_ -match "^$([regex]::Escape($DeviceId))\s+device$" }
    if (-not $deviceReady) {
        $emulator = Resolve-FirstExistingFile -Label 'Android Emulator' -Candidates @(
            (Join-Path $env:LOCALAPPDATA 'Android\Sdk\emulator\emulator.exe')
        )
        Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdName, '-gpu', 'auto') | Out-Null
        & $Adb -s $DeviceId wait-for-device
        foreach ($attempt in 1..180) {
            $booted = (& $Adb -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
            if ($booted -eq '1') { break }
            Start-Sleep -Seconds 1
        }
        if ($booted -ne '1') {
            throw "Android emülatörü zamanında açılmadı: $DeviceId"
        }
    }

    $apk = Join-Path $frontendRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    & $Adb -s $DeviceId install -r $apk
    if ($LASTEXITCODE -ne 0) {
        throw 'Debug APK emülatöre kurulamadı.'
    }

    $packageName = 'com.team120.maki.maki_app.debug'
    & $Adb -s $DeviceId shell am force-stop $packageName | Out-Null
    & $Adb -s $DeviceId shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Maki emülatörde başlatılamadı.'
    }

    Set-Content -LiteralPath (Join-Path $logDir 'android-demo-backend.pid') -Value $backend.Id
    Write-Host 'Maki video demosu hazır.'
    Write-Host "- Emülatör: $DeviceId"
    Write-Host "- Backend: http://127.0.0.1:$ApiPort"
    Write-Host '- Oturum: development, kullanıcı girişi yok'
    Write-Host '- PaddleOCR: hazır'
    Write-Host "- APK: $apk"
} catch {
    if (-not $backend.HasExited) {
        Stop-Process -Id $backend.Id
    }
    throw
}
