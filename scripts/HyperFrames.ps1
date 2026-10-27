#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$previousWhisper = $env:HYPERFRAMES_WHISPER_PATH
try {
    $env:HYPERFRAMES_WHISPER_PATH = Join-Path $projectRoot 'tools\whisper.cpp\Release\whisper-cli.exe'
    $cli = Join-Path $projectRoot 'node_modules\.bin\hyperframes.cmd'
    if (-not (Test-Path -LiteralPath $cli)) { throw 'Run scripts/Setup.ps1 first.' }
    & $cli @args
    if ($LASTEXITCODE -ne 0) { throw "HyperFrames failed with exit code $LASTEXITCODE" }
} finally { $env:HYPERFRAMES_WHISPER_PATH = $previousWhisper }
