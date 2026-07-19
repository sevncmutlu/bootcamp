function Get-FrontendBoundaryHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $content = $utf8.GetString(
            [System.IO.File]::ReadAllBytes($LiteralPath)
        )
    }
    catch {
        throw "Frontend kaynak dosyası geçerli UTF-8 değil: $LiteralPath"
    }

    $normalizedContent = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    $normalizedBytes = $utf8.GetBytes($normalizedContent)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (
            [BitConverter]::ToString($sha256.ComputeHash($normalizedBytes))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}
