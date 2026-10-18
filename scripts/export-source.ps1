param([string]$OutputDirectory='exports')
$ErrorActionPreference='Stop'
$sourceRoot=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$outputRoot=[IO.Path]::GetFullPath((Join-Path $sourceRoot $OutputDirectory))
if(-not $outputRoot.StartsWith($sourceRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Export destination must be a child of the project directory.'
}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$exportName="San_Bong_Source_$stamp"
$exportRoot=Join-Path $outputRoot $exportName
$cleanRoot=Join-Path $exportRoot 'San_Bong'
$zipPath=Join-Path $outputRoot ($exportName+'.zip')
if((Test-Path -LiteralPath $exportRoot) -or (Test-Path -LiteralPath $zipPath)){throw 'Export already exists; originals will not be overwritten.'}
[void](New-Item -ItemType Directory -Path $cleanRoot -Force)
# Explicit allowlist: generated output, runtime configs and evidence cannot enter recursively.
$paths=@('backend/src','backend/scripts','backend/pom.xml','backend/manage-backend.ps1','backend/README.md',
         'frontend','database','docs','scripts','AGENTS.md','.gitignore','.env.example','.env.test.example','deploy.env.example')
foreach($relative in $paths) {
    $from=Join-Path $sourceRoot $relative
    if(-not(Test-Path -LiteralPath $from)){throw "Required source path missing: $relative"}
    $to=Join-Path $cleanRoot $relative
    [void](New-Item -ItemType Directory -Force -Path (Split-Path $to -Parent))
    Copy-Item -LiteralPath $from -Destination $to -Recurse
}
$files=Get-ChildItem -LiteralPath $cleanRoot -Recurse -File -Force
foreach($file in $files) {
    $relative=$file.FullName.Substring($cleanRoot.Length+1)
    if($file.Name -match '(?i)^(?:deploy[.]env|[.]env)$|[.]local$|[.](?:bak|mdf|ldf|trn|jar|class|log|clixml)$' -or
       $relative -match '(?i)(^|[\\/])(?:target|run|logs|releases|[.]playwright-cli)([\\/]|$)') {
        throw "Private/generated file found in export: $relative. Review the allowlist; nothing will be deleted."
    }
}
$files | ForEach-Object {
    [pscustomobject]@{Path=$_.FullName.Substring($cleanRoot.Length+1);Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
} | Export-Csv -LiteralPath (Join-Path $exportRoot 'source-manifest.csv') -NoTypeInformation -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($exportRoot,$zipPath)
[pscustomobject]@{SourceDirectory=$cleanRoot;Zip=$zipPath;Files=$files.Count;SHA256=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash} | ConvertTo-Json
