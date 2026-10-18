param([Parameter(Mandatory=$true)][string]$CompilerPath)
$ErrorActionPreference='Stop'
$qaRoot=Split-Path $PSScriptRoot -Parent
$qaCompiler=(Resolve-Path -LiteralPath $CompilerPath).Path
$qaExpected='67F1C5E3F5A03406A7BF5BADF5ADA09B79F3AE78EC43450C15F7E983068DA346'
if((Get-FileHash -LiteralPath $qaCompiler -Algorithm SHA256).Hash -ne $qaExpected){throw 'Expected reviewed official Tailwind3.4.17 Windows x64 compiler'}
Push-Location $qaRoot
try{
 $ErrorActionPreference='Continue'
 & $qaCompiler -c frontend/tailwind.config.cjs -i frontend/css/tailwind.input.css -o frontend/css/tailwind.css --minify
 $qaExit=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 if($qaExit -ne 0){throw 'Static CSS generation failed'}
}finally{Pop-Location}
