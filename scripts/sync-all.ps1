<#
.SYNOPSIS
    Sync (fetch + pull) all GitHub repositories listed in repos.txt.
.DESCRIPTION
    For each GitHub repo: git fetch, git pull, then display project name,
    current branch, latest commit, and dirty/clean status.
    Continues even if one repo fails.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# --- Paths ---
$ScriptDir    = $PSScriptRoot
$ReposFile    = Join-Path $ScriptDir 'repos.txt'
$WorkspaceDir = (Resolve-Path (Join-Path $ScriptDir '..\..\' )).Path

if (-not (Test-Path $ReposFile)) {
    Write-Host '[FAIL] repos.txt not found at:' $ReposFile -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  Sync All Repositories'                 -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

$lines = Get-Content $ReposFile | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') }

$results = @()

foreach ($line in $lines) {
    $parts = $line -split '\|'
    if ($parts.Count -lt 3) { continue }

    $projectName = $parts[0].Trim()
    $repoType    = $parts[2].Trim().ToLower()

    if ($repoType -eq 'internal') {
        Write-Host "[SKIP] $projectName (internal)" -ForegroundColor DarkGray
        continue
    }

    if ($repoType -ne 'required' -and $repoType -ne 'optional') {
        continue
    }

    $targetDir = Join-Path $WorkspaceDir $projectName

    if (-not (Test-Path $targetDir)) {
        if ($repoType -eq 'optional') {
            Write-Host "[SKIP] $projectName (optional, not cloned)" -ForegroundColor DarkGray
        } else {
            Write-Host "[MISS] $projectName -- folder not found:" $targetDir -ForegroundColor Red
            $results += [PSCustomObject]@{
                Project = $projectName
                Branch  = '-'
                Commit  = '-'
                Status  = 'NOT FOUND'
            }
        }
        continue
    }

    Write-Host "--- $projectName ---" -ForegroundColor Yellow

    # Fetch
    $fetchOutput = git -C $targetDir fetch --all 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host '  [WARN] fetch failed' -ForegroundColor Red
        Write-Host "  $fetchOutput"
    }

    # Pull
    $pullOutput = git -C $targetDir pull 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host '  [WARN] pull failed' -ForegroundColor Red
        Write-Host "  $pullOutput"
    }

    # Branch
    $branch = (git -C $targetDir branch --show-current 2>$null)
    if (-not $branch) { $branch = '(detached)' }

    # Latest commit
    $commit = (git -C $targetDir log --oneline -1 2>$null)
    if (-not $commit) { $commit = '(no commits)' }

    # Dirty / Clean
    $statusOutput = git -C $targetDir status --porcelain 2>$null
    if ($statusOutput) {
        $dirtyStatus = 'DIRTY'
        $color = 'Yellow'
    } else {
        $dirtyStatus = 'CLEAN'
        $color = 'Green'
    }

    Write-Host "  Branch : $branch"
    Write-Host "  Commit : $commit"
    Write-Host "  Status : $dirtyStatus" -ForegroundColor $color
    Write-Host ''

    $results += [PSCustomObject]@{
        Project = $projectName
        Branch  = $branch
        Commit  = $commit
        Status  = $dirtyStatus
    }
}

# --- Summary table ---
Write-Host '==================== Summary ====================' -ForegroundColor Cyan
$results | Format-Table -AutoSize
Write-Host '==================================================' -ForegroundColor Cyan
