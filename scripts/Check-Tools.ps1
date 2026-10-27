#Requires -Version 7.0
param([ValidateSet('small','medium-q5_0')][string]$Model = 'small')
. (Join-Path $PSScriptRoot 'Common.ps1')
$projectRoot = Get-ProjectRoot
$checks = @(
    @{ Name='FFmpeg'; Exe='ffmpeg'; Args=@('-version') },
    @{ Name='ffprobe'; Exe='ffprobe'; Args=@('-version') },
    @{ Name='Python'; Exe=(Get-ProjectPython); Args=@('--version') },
    @{ Name='yt-dlp'; Exe=(Get-ProjectPython); Args=@('-m','yt_dlp','--version') },
    @{ Name='Node'; Exe='node'; Args=@('--version') },
    @{ Name='Git'; Exe='git'; Args=@('--version') },
    @{ Name='Whisper.cpp'; Exe=(Join-Path $projectRoot 'tools\whisper.cpp\Release\whisper-cli.exe'); Args=@('--version') },
    @{ Name='HyperFrames'; Exe=(Join-Path $projectRoot 'node_modules\.bin\hyperframes.cmd'); Args=@('--version') }
)
foreach ($check in $checks) {
    $exe = $check.Exe; $parameters = $check.Args
    $output = & $exe @parameters 2>&1
    if ($LASTEXITCODE -ne 0) { throw "$($check.Name) check failed: $output" }
    Write-Host "OK: $($check.Name) - $($output | Select-Object -First 1)"
}
$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'config\toolchain.json') -Raw | ConvertFrom-Json
$modelPin = $pins.models.$Model
$modelPath = Join-Path $projectRoot ('models\' + $modelPin.file)
if (-not (Test-Path -LiteralPath $modelPath)) { throw "Missing model: $Model. Run Setup.ps1 -Model $Model." }
if ((Get-FileHash -LiteralPath $modelPath -Algorithm SHA256).Hash -ne $modelPin.sha256) { throw "Invalid checksum for $Model." }
foreach ($skill in @('hyperframes','hyperframes-cli','hyperframes-registry','media-use')) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot ".agents\skills\$skill\SKILL.md"))) { throw "Missing core skill: $skill" }
}
Write-Host 'OK: model checksum and four HyperFrames core skills.'
