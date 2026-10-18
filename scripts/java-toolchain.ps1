function Assert-SanBongJava24Version {
    param([Parameter(Mandatory)][string]$VersionOutput)
    if ($VersionOutput -notmatch '(?m)^(?:openjdk|java) version "24(?:[.\"]|$)') {
        throw 'San_Bong requires Java 24. Configure JAVA_HOME/PATH to a JDK 24 installation before building or starting.'
    }
}

function Assert-SanBongJava24 {
    param([Parameter(Mandatory)][string]$JavaPath)
    if (-not (Test-Path -LiteralPath $JavaPath -PathType Leaf)) {
        throw 'Java executable does not exist. Review JAVA_HOME/PATH.'
    }
    $previousPreference = $ErrorActionPreference
    try {
        # Java prints version information to stderr even on success (Windows PowerShell 5.1).
        $ErrorActionPreference = 'Continue'
        $javaInfo = & $JavaPath '-XshowSettings:properties' '-version' 2>&1
        $javaExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    if ($javaExit -ne 0) { throw 'Cannot inspect the configured Java executable.' }
    $javaText = $javaInfo -join "`n"
    Assert-SanBongJava24Version -VersionOutput $javaText
    if ($javaText -notmatch '(?m)^\s*java.home\s*=\s*(.+)\s*$') {
        throw 'Cannot determine the configured Java installation.'
    }
    # Pin Maven to the same inspected installation, rather than a different java.exe on PATH.
    $env:JAVA_HOME = $matches[1].Trim()
}
