#Requires -Version 7.0
param(
    [ValidateSet('small','medium-q5_0')][string]$Model = 'small',
    [string]$RuntimeSource = ''
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$projectRoot = Get-ProjectRoot
if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -ne 'X64') {
    throw 'The supplied installer supports Windows x64. Install equivalent tools manually on other platforms.'
}
foreach ($name in @('python','git','node','npm.cmd','ffmpeg','ffprobe')) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing prerequisite: $name. See README.md, then reopen your terminal." }
}
$nodeVersion = (& node --version).TrimStart('v')
if ([version]$nodeVersion -lt [version]'22.0.0') { throw 'Node.js 22+ is required.' }
$pythonVersion = (& python -c 'import sys; print(".".join(map(str,sys.version_info[:3])))')
if ([version]$pythonVersion -lt [version]'3.10.0') { throw 'Python 3.10+ is required.' }
foreach ($folder in @('raw','references','exports','work','uploads','models','tools','.agents\skills')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot $folder) | Out-Null
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.venv\Scripts\python.exe'))) {
    Invoke-Checked -File python -Arguments @('-m','venv',(Join-Path $projectRoot '.venv'))
}
Invoke-Checked -File (Get-ProjectPython) -Arguments @('-m','pip','install','--disable-pip-version-check','-r',(Join-Path $projectRoot 'requirements.txt'))
Invoke-Checked -File npm.cmd -Arguments @('ci','--prefix',$projectRoot)
$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'config\toolchain.json') -Raw | ConvertFrom-Json
$archive = Join-Path $projectRoot 'tools\whisper-bin-x64.zip'
$reuseArchive = if ($RuntimeSource) { Join-Path $RuntimeSource 'tools\whisper-bin-x64.zip' } else { '' }
Get-VerifiedFile -Url $pins.whisper.archiveUrl -Destination $archive -Sha256 $pins.whisper.sha256 -ReuseFile $reuseArchive
$whisper = Join-Path $projectRoot 'tools\whisper.cpp'
Expand-Archive -LiteralPath $archive -DestinationPath $whisper -Force
$modelPin = $pins.models.$Model
$reuseModel = if ($RuntimeSource) { Join-Path $RuntimeSource ('models\' + $modelPin.file) } else { '' }
Get-VerifiedFile -Url $modelPin.url -Destination (Join-Path $projectRoot ('models\' + $modelPin.file)) -Sha256 $modelPin.sha256 -ReuseFile $reuseModel
& (Join-Path $PSScriptRoot 'Install-HyperFramesSkills.ps1')
Push-Location $projectRoot
try {
    if (Test-Path -LiteralPath '.git') { Invoke-Checked -File git -Arguments @('config','core.hooksPath','.githooks') }
} finally { Pop-Location }
& (Join-Path $PSScriptRoot 'Check-Tools.ps1') -Model $Model
Write-Host 'Setup complete. Open this folder in your local AI agent and read AGENTS.md.'
