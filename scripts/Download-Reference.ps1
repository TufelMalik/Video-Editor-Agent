#Requires -Version 7.0
param([Parameter(Mandatory)][string]$Url)
. (Join-Path $PSScriptRoot 'Common.ps1')
$uri = [uri]$Url
if (-not $uri.IsAbsoluteUri -or $uri.Scheme -notin @('https','http')) { throw 'Use an absolute HTTP or HTTPS reference URL.' }
$destination = Join-Path (Get-ProjectRoot) 'references'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Invoke-Checked -File (Get-ProjectPython) -Arguments @('-m','yt_dlp','--ignore-config','--no-playlist','--windows-filenames','--no-overwrites','--write-info-json','--merge-output-format','mp4','-P',$destination,'-o','%(id)s-%(title).100B.%(ext)s','--',$Url)
Write-Host 'If login is required, provide a permitted local copy in references/.'
