param(
    [string]$ProjectRoot = (Join-Path $PSScriptRoot '..'),
    [string]$BaselinePath = (Join-Path $PSScriptRoot '..\docs\evidence\baseline.json')
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'frontend_boundary_hash.ps1')

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path.TrimEnd('\')
$baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
$expected = @(
    $baseline.current_source.files |
        Where-Object {
            $_.path -like 'frontend/lib/*' -and
            $_.path -ne 'frontend/lib/database/database.g.dart' -and
            $_.path -notlike 'frontend/lib/l10n/app_localizations*.dart'
        } |
        ForEach-Object {
            '{0}|{1}' -f $_.path, $_.sha256.ToUpperInvariant()
        } |
        Sort-Object
)

$libRoot = Join-Path $root 'frontend\lib'
$actual = @(
    Get-ChildItem -LiteralPath $libRoot -File -Recurse |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            if (
                $relativePath -ne 'frontend/lib/database/database.g.dart' -and
                $relativePath -notlike 'frontend/lib/l10n/app_localizations*.dart'
            ) {
                $sha256 = Get-FrontendBoundaryHash -LiteralPath $_.FullName
                '{0}|{1}' -f $relativePath, $sha256
            }
        } |
        Sort-Object
)

$difference = @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual)
if ($difference.Count -gt 0) {
    $details = $difference |
        ForEach-Object { '{0} {1}' -f $_.SideIndicator, $_.InputObject } |
        Out-String
    throw "frontend/lib sınırı değiştirildi.`n$details"
}

Write-Output "frontend/lib sınırı doğrulandı: $($actual.Count) dosya."
