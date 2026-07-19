Describe 'check_frontend_boundary.ps1' {
    BeforeEach {
        $projectRoot = Join-Path $TestDrive 'proje'
        $frontendRoot = Join-Path $projectRoot 'frontend\lib'
        New-Item -ItemType Directory -Path $frontendRoot -Force | Out-Null

        $dartPath = Join-Path $frontendRoot 'ornek.dart'
        Set-Content -LiteralPath $dartPath -Value 'void main() {}' -Encoding UTF8

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
