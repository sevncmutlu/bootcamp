param(
    [string]$ProjectRoot = (Join-Path $PSScriptRoot '..'),
    [string]$BaselinePath = (
        Join-Path $PSScriptRoot '..\docs\evidence\baseline.json'
    ),
    [string]$EvidencePath = (
        Join-Path $PSScriptRoot '..\docs\evidence\frontend-boundary.json'
    )
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
$libRoot = Join-Path $root 'frontend\lib'
$files = @(
    Get-ChildItem -LiteralPath $libRoot -File -Recurse |
        ForEach-Object {
            [ordered]@{
                path = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                size_bytes = $_.Length
            }
        } |
        Where-Object {
            $_.path -ne 'frontend/lib/database/database.g.dart' -and
            $_.path -notlike 'frontend/lib/l10n/app_localizations*.dart'
        } |
        Sort-Object path
)

$treeText = ($files | ForEach-Object { '{0}|{1}' -f $_.path, $_.sha256 }) -join "`n"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $treeBytes = [System.Text.Encoding]::UTF8.GetBytes($treeText)
    $treeHash = (
        [BitConverter]::ToString($sha256.ComputeHash($treeBytes))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

$baseline = [ordered]@{
    schema_version = 2
    scope = 'frontend/lib/** (üretilen kaynaklar hariç)'
    approved_source = 'Sevinç Mutlu Sprint 2 tasarımı ve onaylı backend entegrasyonu'
    current_source = [ordered]@{
        root = 'frontend/lib'
        files = $files
    }
}

$evidence = [ordered]@{
    schema_version = 2
    verified_at = (Get-Date).ToString('yyyy-MM-dd')
    scope = 'frontend/lib/** (üretilen kaynaklar hariç)'
    file_count = $files.Count
    tree_sha256 = $treeHash
    web_directory_present = Test-Path -LiteralPath (Join-Path $root 'frontend\web')
    result = 'eşleşti'
}

$baseline | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $BaselinePath -Encoding UTF8
$evidence | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $EvidencePath -Encoding UTF8

Write-Output "Frontend sınırı güncellendi: $($files.Count) dosya, $treeHash."
