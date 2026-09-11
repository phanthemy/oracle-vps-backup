# Project State

## Project
- Repository: https://github.com/phanthemy/oracle-vps-backup.git
- Branch: main

## Last Completed
- Refactored entire repository to standard Portable & Zero Hardcoding architecture (supports Oracle Cloud, VMware, Hetzner, DigitalOcean, custom user accounts).
- Implemented `lib/user.sh` (dynamic app user detection) & `lib/common.sh` (git safe directory across users, logging, non-root PM2 isolation).
- Created `restore-vps.sh` (1-Click Zero-to-Production master script automating bootstrap, projects restore, and doctor health check).
- Fully verified all 21 scripts with automated syntax tests.
- Fixed PostgreSQL database creation syntax and initialized PostGIS spatial tables for MapGo (`places`, `user_reports`).
- Registered projects in `projects/`: `parking-hcm` (Port 3003), `chamcong` (Port 3015), `hrm-unified` (Port 3000).

## Current Status
- Framework 1-Click Disaster Recovery đạt chuẩn Production, đã kiểm thử trên VPS test (User `test` & User `ubuntu`).
- Sẵn sàng mở rộng thêm dự án mới bằng cách thêm file cấu hình vào thư mục `projects/<project-name>.json`.

## Next Tasks
- Bổ sung thêm registry dự án mới vào `projects/` khi triển khai thêm app lên VPS.
- Duy trì backup định kỳ (`sudo bash backup.sh`) mỗi khi thay đổi cấu hình PM2 / Caddy trên VPS production.

## Open Issues
- (none)

## Decisions
- Agent workflow follows AGENTS.md: startup checks → selective staging → conventional commit → push origin main
- Telegram notification sent after each completed task

## Notes
- VPS target: Oracle Cloud Ubuntu 22.04 LTS (149.118.62.155)
- Python not available on this Windows workstation (App Execution Alias only); Telegram notifications use PowerShell Invoke-RestMethod
