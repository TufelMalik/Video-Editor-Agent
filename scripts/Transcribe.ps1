#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$InputVideo,
    [string]$Language = 'auto',
    [ValidateSet('small','medium-q5_0')][string]$Model = 'small'
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$projectRoot = Get-ProjectRoot
$inputPath = (Resolve-Path -LiteralPath $InputVideo).Path
$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'config\toolchain.json') -Raw | ConvertFrom-Json
$modelPin = $pins.models.$Model
$modelPath = Join-Path $projectRoot ('models\' + $modelPin.file)
$whisper = Join-Path $projectRoot 'tools\whisper.cpp\Release\whisper-cli.exe'
if (-not (Test-Path -LiteralPath $whisper) -or -not (Test-Path -LiteralPath $modelPath)) { throw "Run Setup.ps1 -Model $Model first." }
$jobName = [IO.Path]::GetFileNameWithoutExtension($inputPath) + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6)
$jobPath = Join-Path $projectRoot ('work\' + $jobName)
New-Item -ItemType Directory -Path $jobPath -Force | Out-Null
$wav = Join-Path $jobPath 'audio.wav'
Invoke-Checked -File ffmpeg -Arguments @('-hide_banner','-nostdin','-n','-i',$inputPath,'-vn','-ac','1','-ar','16000','-c:a','pcm_s16le',$wav)
Invoke-Checked -File $whisper -Arguments @('-m',$modelPath,'-f',$wav,'-l',$Language,'-ml','1','-sow','-ojf','-osrt','-of',(Join-Path $jobPath 'transcript'),'-ng','-bo','1','-bs','1','-nf')
if (-not (Test-Path -LiteralPath (Join-Path $jobPath 'transcript.json'))) { throw 'No transcript JSON was created.' }
Write-Host "Transcript saved in $jobPath"
Write-Host 'Review wording, word timing and Roman Hinglish captions before rendering; this is an ASR draft.'
