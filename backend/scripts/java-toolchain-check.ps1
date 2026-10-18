$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../scripts/java-toolchain.ps1')
foreach ($version in @('openjdk version "24.0.2" 2025-07-15', 'java version "24" 2025-03-18')) {
    Assert-SanBongJava24Version -VersionOutput $version
}
foreach ($version in @('java version "21.0.8" 2025-07-15', 'openjdk version "17.0.12"', 'java version "240.0.1"', 'unknown')) {
    $rejected = $false
    try { Assert-SanBongJava24Version -VersionOutput $version } catch { $rejected = $true }
    if (-not $rejected) { throw "Unexpected Java version accepted: $version" }
}
foreach ($file in @('manage-backend.ps1', '../scripts/server.ps1')) {
    $location = if ($file -eq 'manage-backend.ps1') { Join-Path $PSScriptRoot '../manage-backend.ps1' } else { Join-Path $PSScriptRoot '../../scripts/server.ps1' }
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path $location).Path, [ref]$tokens, [ref]$errors)
    if ($errors.Count -ne 0) { throw "PowerShell syntax errors in $file" }
}
Write-Output 'JAVA_TOOLCHAIN_POLICY_PASS: Java 24 accepted, incompatible/unknown versions rejected; launcher syntax valid.'
