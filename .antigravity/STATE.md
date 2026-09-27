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
- **[2026-09-27]** Removed 4 malicious exfiltration canary files (canary.js, scripts/canary-init.js, .npmrc, package.json) injected via compromised token.
- **[2026-09-27]** Fixed DauTayStore video playback: added `toAbsUrl()` wrapper for video_url in React bundle (product detail + admin preview).
- **[2026-09-27]** Fixed DauTayStore Zalo catalog.js: added video player to product detail modal.

## Current Status
- Framework 1-Click Disaster Recovery đạt chuẩn Production, đã kiểm thử trên VPS test (User `test` & User `ubuntu`).
- Sẵn sàng mở rộng thêm dự án mới bằng cách thêm file cấu hình vào thư mục `projects/<project-name>.json`.
- DauTayStore: Video playback fixed trên cả React SPA và Zalo Mini App. Admin variant form có 2 block cố định (Màu sắc + Kích cỡ).

## Next Tasks
- DauTayStore: Cần tạo lại React source từ bundle để có thể maintain dài hạn (hiện chỉ có build artifacts).
- DauTayStore: Cân nhắc thêm project registry `projects/dautayshop.json` vào repo IaC.
- Bổ sung thêm registry dự án mới vào `projects/` khi triển khai thêm app lên VPS.
- Duy trì backup định kỳ (`sudo bash backup.sh`) mỗi khi thay đổi cấu hình PM2 / Caddy trên VPS production.
- **URGENT**: Revoke tất cả GitHub Personal Access Tokens — token bị lộ dẫn đến mã độc inject.

## Open Issues
- DauTayStore React source code không tồn tại (chỉ có build bundle) → khó maintain
- GitHub token có thể bị compromise (4 commits mã độc vào 01:06-01:07 ngày 27/09/2026)

## Decisions
- Agent workflow follows AGENTS.md: startup checks → selective staging → conventional commit → push origin main
- Telegram notification sent after each completed task
- DauTayStore fixes applied trực tiếp trên VPS (Source of Truth = Oracle VPS theo project-workflow IX)

## Notes
- VPS target: Oracle Cloud Ubuntu 22.04 LTS (149.118.62.155)
- Python not available on this Windows workstation (App Execution Alias only); Telegram notifications use PowerShell Invoke-RestMethod
- DauTayStore: Express+SQLite backend, React SPA (Vite) + Zalo Mini App (catalog.js), domain dautayshop.nextapp.vn, port 4000
