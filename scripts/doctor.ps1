<#
.SYNOPSIS
    Health-check all repositories listed in repos.txt.
.DESCRIPTION
    Read-only diagnostics. Checks: git installed, each repo exists, has origin
    remote, working tree clean, current branch, local vs remote sync status.
    Displays PASS / WARN / FAIL for each check. Never modifies data.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# --- Helpers ---
function Write-Check {
    param(
        [string]$Level,
        [string]$Message
    )
    switch ($Level) {
        'PASS' { $c = 'Green'  }
        'WARN' { $c = 'Yellow' }
        'FAIL' { $c = 'Red'    }
        default { $c = 'White' }
    }
    Write-Host "  [$Level] $Message" -ForegroundColor $c
}

# --- Paths ---
$ScriptDir    = $PSScriptRoot
$ReposFile    = Join-Path $ScriptDir 'repos.txt'
$WorkspaceDir = (Resolve-Path (Join-Path $ScriptDir '..\..\' )).Path

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  Doctor -- Repository Health Check'     -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# --- 1. Git installed? ---
Write-Host '--- Prerequisites ---' -ForegroundColor Yellow
$gitVersion = git --version 2>$null
if ($LASTEXITCODE -eq 0 -and $gitVersion) {
    Write-Check 'PASS' "git installed: $gitVersion"
} else {
    Write-Check 'FAIL' 'git is NOT installed or not in PATH'
    Write-Host ''
    Write-Host 'Cannot continue without git. Aborting.' -ForegroundColor Red
    exit 1
}

# --- 2. repos.txt ---
if (-not (Test-Path $ReposFile)) {
    Write-Check 'FAIL' "repos.txt not found at: $ReposFile"
    exit 1
} else {
    Write-Check 'PASS' 'repos.txt found'
}

Write-Host ''

# --- 3. Per-repo checks ---
$lines = Get-Content $ReposFile | Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') }

$summaryRows = @()

foreach ($line in $lines) {
    $parts = $line -split '\|'
    if ($parts.Count -lt 3) {
        Write-Check 'WARN' "Malformed line: $line"
        continue
    }

    $projectName = $parts[0].Trim()
    $repoType    = $parts[2].Trim().ToLower()

    Write-Host "--- $projectName ---" -ForegroundColor Yellow

    if ($repoType -eq 'internal') {
        Write-Check 'WARN' 'type=internal -- skipped'
        $summaryRows += [PSCustomObject]@{
            Project  = $projectName
            Exists   = '-'
            Origin   = '-'
            Branch   = '-'
            Clean    = '-'
            Synced   = '-'
            Result   = 'SKIP'
        }
        Write-Host ''
        continue
    }

    if ($repoType -ne 'required' -and $repoType -ne 'optional') {
        Write-Check 'WARN' "unknown type: $repoType -- skipped"
        Write-Host ''
        continue
    }

    $targetDir = Join-Path $WorkspaceDir $projectName

    # Exists?
    $exists = Test-Path $targetDir
    if ($exists) {
        Write-Check 'PASS' "Folder exists: $targetDir"
    } else {
        if ($repoType -eq 'optional') {
            Write-Check 'PASS' 'Not cloned (optional)'
            $summaryRows += [PSCustomObject]@{
                Project  = $projectName
                Exists   = 'NO'
                Origin   = '-'
                Branch   = '-'
                Clean    = '-'
                Synced   = '-'
                Result   = 'SKIP'
            }
        } else {
            Write-Check 'FAIL' "Folder NOT found: $targetDir"
            $summaryRows += [PSCustomObject]@{
                Project  = $projectName
                Exists   = 'NO'
                Origin   = '-'
                Branch   = '-'
                Clean    = '-'
                Synced   = '-'
                Result   = 'FAIL'
            }
        }
        Write-Host ''
        continue
    }

    # Has origin remote?
    $originUrl = git -C $targetDir remote get-url origin 2>$null
    $hasOrigin = ($LASTEXITCODE -eq 0 -and $originUrl)
    if ($hasOrigin) {
        Write-Check 'PASS' "origin = $originUrl"
    } else {
        Write-Check 'FAIL' 'No origin remote configured'
    }

    # Branch
    $branch = git -C $targetDir branch --show-current 2>$null
    if (-not $branch) { $branch = '(detached)' }
    Write-Check 'PASS' "Branch: $branch"

    # Working tree clean?
    $statusOutput = git -C $targetDir status --porcelain 2>$null
    $isClean = (-not $statusOutput)
    if ($isClean) {
        Write-Check 'PASS' 'Working tree: CLEAN'
    } else {
        Write-Check 'WARN' 'Working tree: DIRTY'
    }

    # Local == Remote?
    $synced = '-'
    if ($hasOrigin -and $branch -and $branch -ne '(detached)') {
        # Fetch to get latest remote ref (read-only network call)
        git -C $targetDir fetch origin $branch --quiet 2>$null | Out-Null

        $localHash  = git -C $targetDir rev-parse HEAD 2>$null
        $remoteHash = git -C $targetDir rev-parse "origin/$branch" 2>$null

        if ($localHash -and $remoteHash) {
            if ($localHash -eq $remoteHash) {
                Write-Check 'PASS' 'Local == Remote (synced)'
                $synced = 'YES'
            } else {
                $lShort = $localHash.Substring(0,7)
                $rShort = $remoteHash.Substring(0,7)
                Write-Check 'WARN' "Local != Remote (local: $lShort / remote: $rShort)"
                $synced = 'NO'
            }
        } else {
            Write-Check 'WARN' 'Could not compare local/remote hashes'
            $synced = '?'
        }
    }

    # Row result
    $rowResult = 'PASS'
    if (-not $hasOrigin) { $rowResult = 'FAIL' }
    elseif (-not $isClean -or $synced -eq 'NO') { $rowResult = 'WARN' }

    # Build origin/clean display values
    if ($hasOrigin) { $originVal = 'YES' } else { $originVal = 'NO' }
    if ($isClean)   { $cleanVal  = 'YES' } else { $cleanVal  = 'NO' }

    $summaryRows += [PSCustomObject]@{
        Project  = $projectName
        Exists   = 'YES'
        Origin   = $originVal
        Branch   = $branch
        Clean    = $cleanVal
        Synced   = $synced
        Result   = $rowResult
    }

    Write-Host ''
}

# --- Summary table ---
Write-Host '==================== Summary ====================' -ForegroundColor Cyan
$summaryRows | Format-Table -AutoSize
Write-Host '==================================================' -ForegroundColor Cyan

$failCount = @($summaryRows | Where-Object { $_.Result -eq 'FAIL' }).Count
$warnCount = @($summaryRows | Where-Object { $_.Result -eq 'WARN' }).Count

if ($failCount -gt 0) {
    Write-Host "$failCount FAIL(s), $warnCount WARN(s). Please fix issues above." -ForegroundColor Red
} elseif ($warnCount -gt 0) {
    Write-Host "All repos reachable. $warnCount WARN(s) -- review above." -ForegroundColor Yellow
} else {
    Write-Host 'All repos healthy!' -ForegroundColor Green
}
