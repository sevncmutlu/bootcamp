Describe 'check_frontend_boundary.ps1' {
    BeforeEach {
        $projectRoot = Join-Path $TestDrive 'proje'
        $frontendRoot = Join-Path $projectRoot 'frontend\lib'
        New-Item -ItemType Directory -Path $frontendRoot -Force | Out-Null

        $dartPath = Join-Path $frontendRoot 'ornek.dart'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText(
            $dartPath,
            "void main() {}`n",
            $utf8NoBom
        )

        $manifestPath = Join-Path $TestDrive 'baseline.json'
        $manifest = @{
            schema_version = 1
            current_source = @{
                files = @(
                    @{
                        path = 'frontend/lib/ornek.dart'
                        sha256 = (Get-FileHash -LiteralPath $dartPath -Algorithm SHA256).Hash
                        size_bytes = (Get-Item -LiteralPath $dartPath).Length
                    }
                )
            }
        }
        $manifest | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath $manifestPath -Encoding UTF8

        $script:boundaryScript = Join-Path $PSScriptRoot '..\check_frontend_boundary.ps1'
        $script:projectRoot = $projectRoot
        $script:manifestPath = $manifestPath
    }

    It 'değişmemiş frontend alanını kabul eder' {
        {
            & $script:boundaryScript `
                -ProjectRoot $script:projectRoot `
                -BaselinePath $script:manifestPath
        } | Should Not Throw
    }

    It 'satır sonu farkını kaynak değişikliği saymaz' {
        $dartPath = Join-Path $script:projectRoot 'frontend\lib\ornek.dart'
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $lfContent = "void main() {`n  print('aynı');`n}`n"
        [System.IO.File]::WriteAllText($dartPath, $lfContent, $utf8NoBom)

        $manifest = Get-Content -LiteralPath $script:manifestPath -Raw |
            ConvertFrom-Json
        $manifest.current_source.files[0].sha256 = (
            Get-FileHash -LiteralPath $dartPath -Algorithm SHA256
        ).Hash
        $manifest | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath $script:manifestPath -Encoding UTF8

        $crlfContent = $lfContent.Replace("`n", "`r`n")
        [System.IO.File]::WriteAllText($dartPath, $crlfContent, $utf8NoBom)

        {
            & $script:boundaryScript `
                -ProjectRoot $script:projectRoot `
                -BaselinePath $script:manifestPath
        } | Should Not Throw
    }

    It 'değiştirilmiş frontend alanını reddeder' {
        Set-Content `
            -LiteralPath (Join-Path $script:projectRoot 'frontend\lib\ornek.dart') `
            -Value 'void main() { print("değişti"); }' `
            -Encoding UTF8

        {
            & $script:boundaryScript `
                -ProjectRoot $script:projectRoot `
                -BaselinePath $script:manifestPath
        } | Should Throw
    }

    It 'eklenmiş frontend dosyasını reddeder' {
        Set-Content `
            -LiteralPath (Join-Path $script:projectRoot 'frontend\lib\yeni.dart') `
            -Value 'final yeni = true;' `
            -Encoding UTF8

        {
            & $script:boundaryScript `
                -ProjectRoot $script:projectRoot `
                -BaselinePath $script:manifestPath
        } | Should Throw
    }
}
