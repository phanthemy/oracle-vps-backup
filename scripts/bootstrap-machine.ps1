<#
.SYNOPSIS
    Bootstrap a new machine by cloning all GitHub repositories from repos.txt.
.DESCRIPTION
    Reads repos.txt (Source of Truth), clones missing GitHub repos into the
    parent Antigravity workspace directory, skips internal repos, and prints
    a summary of folders to manually add to Antigravity.
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# --- Paths ---
$ScriptDir   = $PSScriptRoot
$ReposFile   = Join-Path $ScriptDir 'repos.txt'
$WorkspaceDir = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path   # …\antigravity\

if (-not (Test-Path $ReposFile)) {
    Write-Host "[FAIL] repos.txt not found at: $ReposFile" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  Multi-Machine Bootstrap Toolkit'       -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "Workspace : $WorkspaceDir"
Write-Host "Repos file: $ReposFile"
Write-Host ''

$lines = Get-Content $ReposFile | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') }
$clonedPaths = @()

foreach ($line in $lines) {
    $parts = $line -split '\|'
    if ($parts.Count -lt 3) {
        Write-Host "[WARN] Malformed line, skipping: $line" -ForegroundColor Yellow
        continue
    }

    $projectName = $parts[0].Trim()
    $gitUrl      = $parts[1].Trim()
    $repoType    = $parts[2].Trim().ToLower()

    $targetDir = Join-Path $WorkspaceDir $projectName

    if ($repoType -eq 'internal') {
        Write-Host "[SKIP] $projectName (internal)" -ForegroundColor DarkGray
        continue
    }

    if ($repoType -ne 'required' -and $repoType -ne 'optional') {
        Write-Host "[SKIP] $projectName (unknown type: $repoType)" -ForegroundColor Yellow
        continue
    }

    # GitHub repo
    if (Test-Path $targetDir) {
        Write-Host "[OK]   $projectName  (already exists)" -ForegroundColor Green
    } else {
        if ($DryRun) {
            Write-Host "[DRY]  Would clone $projectName -> $targetDir" -ForegroundColor Magenta
        } else {
            Write-Host "[CLONE] $projectName -> $targetDir" -ForegroundColor Yellow
            git clone $gitUrl $targetDir 2>&1 | ForEach-Object { Write-Host "       $_" }
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[FAIL] Clone failed for $projectName" -ForegroundColor Red
            } else {
                Write-Host "[OK]   $projectName cloned successfully" -ForegroundColor Green
            }
        }
    }

    $clonedPaths += $targetDir
}

# --- Summary: folders to add to Antigravity ---
Write-Host ''
Write-Host '========== Add these folders to Antigravity ==========' -ForegroundColor Cyan
foreach ($p in $clonedPaths) {
    Write-Host "  $p"
}
Write-Host '======================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Done. Open Antigravity and add the folders above as projects.' -ForegroundColor Green
