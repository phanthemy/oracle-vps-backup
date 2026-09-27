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
- **[2026-09-27]** Fixed admin variant "+ Thêm tùy chọn" button and variant sync (matrix ↔ blocks).
- **[2026-09-27]** Data fix: synced colors/sizes from variants for products with empty fields.
- **[2026-09-27]** Added TikTok Shop export: `GET /api/admin/export/tiktok` — 19 products → 288 rows Excel.
- **[2026-09-27]** DB migration: 7 new columns (brand, parcel_weight/length/width/height, origin_country, tiktok_category_id).

## Current Status
- Framework 1-Click Disaster Recovery đạt chuẩn Production.
- DauTayStore: Video/variant/sync bugs fixed. TikTok export feature deployed and tested.

## Next Tasks
- DauTayStore: Thêm nút "Export TikTok" vào admin UI (hiện gọi qua API URL).
- DauTayStore: Cần tạo lại React source từ bundle để maintain dài hạn.
- Bổ sung thêm registry dự án mới vào `projects/` khi triển khai thêm app lên VPS.
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
