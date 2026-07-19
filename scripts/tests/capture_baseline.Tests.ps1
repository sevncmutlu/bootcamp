Describe 'capture_baseline.ps1' {
    It 'kaynak ve kanonik ZIP özetlerini üretir' {
        $scriptPath = Join-Path $PSScriptRoot '..\capture_baseline.ps1'
        $outputPath = Join-Path $TestDrive 'baseline.json'

        & $scriptPath `
            -SourcePath 'C:\Users\emirh\Downloads\bootcamp-main (2)\bootcamp-main' `
            -CanonicalZipPath 'C:\Users\emirh\Downloads\bootcamp-32bf51051bf157a6367135c2db49a1ea9b309249.zip' `
            -OutputPath $outputPath

        $manifest = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json

        $manifest.schema_version | Should Be 1
        $manifest.canonical_zip.sha256 | Should Match '^[A-F0-9]{64}$'
        $manifest.current_source.files.Count | Should BeGreaterThan 0
    }
}
