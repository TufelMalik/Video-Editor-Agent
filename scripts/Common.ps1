#Requires -Version 7.0
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot { Split-Path $PSScriptRoot -Parent }

function Get-ProjectPython {
    $localPython = Join-Path (Get-ProjectRoot) '.venv\Scripts\python.exe'
    if (Test-Path -LiteralPath $localPython) { return $localPython }
    return (Get-Command python -ErrorAction Stop).Source
}

function Invoke-Checked {
    param([Parameter(Mandatory)][string]$File, [string[]]$Arguments = @())
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$File exited with code $LASTEXITCODE" }
}

function Get-VerifiedFile {
    param([string]$Url, [string]$Destination, [string]$Sha256, [string]$ReuseFile = '')
    if ((Test-Path -LiteralPath $Destination) -and (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -eq $Sha256) {
        Write-Host "Reusing verified $([IO.Path]::GetFileName($Destination))"
        return
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    $temporary = $Destination + '.partial'
    if ($ReuseFile -and (Test-Path -LiteralPath $ReuseFile) -and (Get-FileHash -LiteralPath $ReuseFile -Algorithm SHA256).Hash -eq $Sha256) {
        Copy-Item -LiteralPath $ReuseFile -Destination $temporary -Force
    } else {
        Write-Host "Downloading $([IO.Path]::GetFileName($Destination))"
        Invoke-WebRequest -Uri $Url -OutFile $temporary -TimeoutSec 1800
    }
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $Sha256) {
        throw "Checksum mismatch for $Destination. The temporary download was not installed."
    }
    Move-Item -LiteralPath $temporary -Destination $Destination -Force
}
