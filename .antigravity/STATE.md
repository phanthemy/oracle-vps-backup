# Project State

## Project
- Repository: https://github.com/phanthemy/oracle-vps-backup.git
- Branch: main

## Last Completed
- Added "User Prompt Contract" section to AGENTS.md — agent tự thực hiện 10 bước workflow (commit pending)
- Fixed trackingBranch to "main" in .antigravity/project.json (commit c0371d7)
- Added GET /health endpoint as health.sh returning {"status":"ok","time":"ISO8601"} (commit 202ef9c)
- Created .antigravity/STATE.md as single source of project state (commit 0d02c18)
- Created AGENTS.md with startup, working rules and finish protocol (commit b18e334)

## Current Status
- Repository clean, all changes pushed to origin/main
- Infrastructure scripts: bootstrap.sh, backup.sh, restore.sh, doctor.sh, health.sh — all present
- AGENTS.md now includes: Startup, Working Rules, Finish, User Prompt Contract
- Ansible playbook available at ansible/site.yml

## Next Tasks
- (none queued)



## Open Issues
- (none)

## Decisions
- Agent workflow follows AGENTS.md: startup checks → selective staging → conventional commit → push origin main
- Telegram notification sent after each completed task

## Notes
- VPS target: Oracle Cloud Ubuntu 22.04 LTS (149.118.62.155)
- Python not available on this Windows workstation (App Execution Alias only); Telegram notifications use PowerShell Invoke-RestMethod
