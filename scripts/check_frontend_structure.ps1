param(
    [string]$ProjectRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path

$pageLimits = @{
    'frontend/lib/features/gamification/presentation/pages/forest_screen.dart' = 450
    'frontend/lib/features/transactions/presentation/pages/expense_entry_screen.dart' = 450
    'frontend/lib/features/transactions/presentation/widgets/personalized_finance_overview.dart' = 450
    'frontend/lib/features/simulator/presentation/pages/debt_simulator_screen.dart' = 450
    'frontend/lib/features/insights/presentation/pages/inflation_screen.dart' = 450
}

$partPatterns = @(
    'frontend/lib/features/gamification/presentation/pages/forest_*.dart'
    'frontend/lib/features/gamification/presentation/widgets/forest_*.dart'
    'frontend/lib/features/transactions/presentation/forms/*_entry_form.dart'
    'frontend/lib/features/transactions/presentation/pages/expense_entry_*.dart'
    'frontend/lib/features/transactions/presentation/widgets/personalized_finance_*.dart'
    'frontend/lib/features/simulator/presentation/pages/debt_*forms.dart'
    'frontend/lib/features/simulator/presentation/pages/debt_entry_form.dart'
    'frontend/lib/features/simulator/presentation/widgets/debt_simulator_components.dart'
    'frontend/lib/features/insights/presentation/pages/inflation_breakdown_section.dart'
    'frontend/lib/features/insights/presentation/widgets/inflation_*.dart'
)

$controllerLimits = @{
    'frontend/lib/features/transactions/presentation/controllers/expense_entry_view_controller.dart' = 500
    'frontend/lib/features/simulator/presentation/controllers/debt_simulator_view_controller.dart' = 500
}

function Assert-LineLimit {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][int]$Limit
    )
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Yapısal sınır dosyası bulunamadı: $RelativePath"
    }
    $count = (Get-Content -LiteralPath $path).Count
    if ($count -gt $Limit) {
        throw "Yapısal sınır aşıldı: $RelativePath ($count > $Limit)"
    }
}

foreach ($entry in $pageLimits.GetEnumerator()) {
    Assert-LineLimit -RelativePath $entry.Key -Limit $entry.Value
    $page = Get-Content -LiteralPath (Join-Path $root $entry.Key) -Raw
    if ($page -match 'di\.sl|AppDatabase\.instance|MakiApiClient\(') {
        throw "Sayfa doğrudan servis locator/DB/ağ erişimi taşıyor: $($entry.Key)"
    }
}

$partFiles = foreach ($pattern in $partPatterns) {
    Get-ChildItem -Path (Join-Path $root $pattern) -File -ErrorAction SilentlyContinue
}
foreach ($file in ($partFiles | Sort-Object FullName -Unique)) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($pageLimits.ContainsKey($relative)) { continue }
    Assert-LineLimit -RelativePath $relative -Limit 350
}

foreach ($entry in $controllerLimits.GetEnumerator()) {
    Assert-LineLimit -RelativePath $entry.Key -Limit $entry.Value
}

Write-Output 'Frontend mega-widget yapısal sınırları doğrulandı.'
