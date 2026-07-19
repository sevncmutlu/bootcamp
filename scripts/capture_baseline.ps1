param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$CanonicalZipPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$sourceRoot = (Resolve-Path -LiteralPath $SourcePath).Path.TrimEnd('\')
$canonicalZip = (Resolve-Path -LiteralPath $CanonicalZipPath).Path
$excludedSegments = @(
    '\.dart_tool\',
    '\.git\',
    '\.idea\',
    '\.venv\',
    '\__pycache__\',
    '\build\'
)

$files = Get-ChildItem -LiteralPath $sourceRoot -File -Recurse |
    Where-Object {
        $fullName = $_.FullName
        -not ($excludedSegments | Where-Object { $fullName.Contains($_) })
    } |
    ForEach-Object {
        [ordered]@{
            path = $_.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            size_bytes = $_.Length
        }
    } |
    Sort-Object path

$manifest = [ordered]@{
    schema_version = 1
    canonical_zip = [ordered]@{
        path = $canonicalZip
        sha256 = (Get-FileHash -LiteralPath $canonicalZip -Algorithm SHA256).Hash
    }
    current_source = [ordered]@{
        root = $sourceRoot
        files = @($files)
    }
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$json = $manifest | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
