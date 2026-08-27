# Project State

## Project
- Repository: https://github.com/phanthemy/oracle-vps-backup.git
- Branch: main

## Last Completed
- Added GET /health endpoint as health.sh returning {"status":"ok","time":"ISO8601"} (commit pending)
- Created .antigravity/STATE.md as single source of project state (commit 0d02c18)
- Created AGENTS.md with startup, working rules and finish protocol (commit b18e334)
- Added "Machine B continuation test" to README.md (commit 0d6bc41)
- Added "Runtime Test" to README.md (commit 7d85b2b)
- Added "Sync test from Machine A" to README.md (commit 3f52d93)

## Current Status
- Repository clean, all changes pushed to origin/main
- Infrastructure scripts: bootstrap.sh, backup.sh, restore.sh, doctor.sh, health.sh — all present
- Ansible playbook available at ansible/site.yml
- Project configs in configs/, database dumps in database/, per-project restore scripts in projects/

## Next Tasks
- (none queued)


## Open Issues
- .antigravity/project.json has trackingBranch set to "master" but actual branch is "main"

## Decisions
- Agent workflow follows AGENTS.md: startup checks → selective staging → conventional commit → push origin main
- Telegram notification sent after each completed task

## Notes
- VPS target: Oracle Cloud Ubuntu 22.04 LTS (149.118.62.155)
- Python not available on this Windows workstation (App Execution Alias only); Telegram notifications use PowerShell Invoke-RestMethod
