#Requires -Version 7.0
. (Join-Path $PSScriptRoot 'Common.ps1')
$projectRoot = Get-ProjectRoot
$bundle = Join-Path $projectRoot 'node_modules\hyperframes\dist\skills'
foreach ($skill in @('hyperframes','hyperframes-cli','media-use')) {
    $source = Join-Path $bundle $skill
    if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) { throw "Missing bundled skill: $skill. Run npm ci first." }
    $target = Join-Path $projectRoot ('.agents\skills\' + $skill)
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
}
$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'config\toolchain.json') -Raw | ConvertFrom-Json
$commit = $pins.hyperframesSkillsCommit
if ($commit -notmatch '^[a-f0-9]{40}$') { throw 'Invalid upstream skill commit.' }
$headers = @{ 'User-Agent' = 'Video-Editor-Agent-Setup' }
$tree = Invoke-RestMethod -Uri "https://api.github.com/repos/heygen-com/hyperframes/git/trees/${commit}?recursive=1" -Headers $headers
if ($tree.truncated) { throw 'Upstream skill file listing was truncated; refusing an incomplete installation.' }
$files = @($tree.tree | Where-Object { $_.type -eq 'blob' -and $_.path -like 'skills/hyperframes-registry/*' })
if ($files.Count -eq 0) { throw 'Registry skill files not found in the pinned upstream tree.' }
foreach ($file in $files) {
    if ($file.path -match '(^|/)\.\.(/|$)') { throw 'Invalid upstream relative path.' }
    $destination = Join-Path $projectRoot ('.agents\' + $file.path)
    New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/heygen-com/hyperframes/$commit/$($file.path)" -OutFile $destination -Headers $headers
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/heygen-com/hyperframes/$commit/LICENSE" -OutFile (Join-Path $projectRoot '.agents\skills\THIRD-PARTY-HYPERFRAMES-LICENSE') -Headers $headers
Write-Host 'Installed four project-local HyperFrames core skills and retained the upstream license.'
