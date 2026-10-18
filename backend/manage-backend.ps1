param([ValidateSet('build','run')][string]$Action='run',[string]$EnvFile,[ValidateSet('runtime','fixtures')][string]$VerificationSuite='runtime')
$ErrorActionPreference='Stop'
# Local .env is ignored by source control; environment values take precedence.
$explicitEnvFile=-not [string]::IsNullOrWhiteSpace($EnvFile)
$configFile=if($explicitEnvFile){$EnvFile}else{Join-Path (Split-Path $PSScriptRoot -Parent) '.env'}
if($explicitEnvFile -and -not(Test-Path -LiteralPath $configFile -PathType Leaf)){throw 'The specified environment file does not exist.'}
if(Test-Path -LiteralPath $configFile) {
    foreach($line in Get-Content -LiteralPath $configFile -Encoding UTF8) {
        if($line -match '^([A-Z][A-Z0-9_]*)=(.*)$') {
            if($explicitEnvFile -or -not [Environment]::GetEnvironmentVariable($matches[1],'Process')) {
                [Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process')
            }
        }
    }
}
foreach($key in @('APP_DB_USER','APP_DB_PASSWORD','JAVA_HOME')) {
    if(-not [Environment]::GetEnvironmentVariable($key,'Process')) { throw "Set $key before running." }
}
foreach($key in @('APP_DB_URL','APP_DB_USER','APP_DB_PASSWORD')) {
    $value=[Environment]::GetEnvironmentVariable($key,'Process')
    if($value -match '^(your_database_user|your_dedicated_runtime_login|fill_privately|provide_privately|your_database_password)$' -or
       ($key -eq 'APP_DB_URL' -and $value -match 'databaseName=your_reviewed_test_database(?:;|$)')) {
        throw "$key still contains a template placeholder. Fill the reviewed DEV/test database configuration locally before running."
    }
}
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/java-toolchain.ps1')
Assert-SanBongJava24 -JavaPath (Join-Path $env:JAVA_HOME 'bin/java.exe')
Push-Location $PSScriptRoot
try {
    if($Action -eq 'build') {
        if($env:SAN_BONG_TEST_MODE -notin @('dev','test')) { throw 'Set SAN_BONG_TEST_MODE=dev/test explicitly; never build fixture tests against internal.' }
        . (Join-Path $PSScriptRoot 'verification-suites.ps1')
        Assert-SanBongVerificationProfile -Suite $VerificationSuite
        $selectedTests=Get-SanBongVerificationTests -Suite $VerificationSuite
        $mavenCommand=Get-Command mvn.cmd -ErrorAction SilentlyContinue
        $portable=Join-Path $env:TEMP 'san-bong-build-tools/apache-maven-3.9.9/bin/mvn.cmd'
        if($env:MAVEN_HOME) { $maven=Join-Path $env:MAVEN_HOME 'bin/mvn.cmd' }
        elseif($mavenCommand) { $maven=$mavenCommand.Source }
        elseif(Test-Path -LiteralPath $portable) { $maven=$portable }
        else { throw 'Install Maven or set MAVEN_HOME to a portable Maven directory.' }
        $ErrorActionPreference='Continue'
        # Never implicitly run committed cleanup suites using the protected web runtime.
        & $maven -B "-Dtest=$selectedTests" clean verify
        $commandExit=$LASTEXITCODE
        $ErrorActionPreference='Stop'
    } else {
        $ErrorActionPreference='Continue'
        & (Join-Path $env:JAVA_HOME 'bin/java.exe') -jar target/san-bong-backend-1.0.0.jar
        $commandExit=$LASTEXITCODE
        $ErrorActionPreference='Stop'
    }
    if($commandExit -ne 0) { throw "Backend command failed: $commandExit" }
} finally { Pop-Location }
