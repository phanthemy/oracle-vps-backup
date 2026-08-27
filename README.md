# ORACLE VPS INFRASTRUCTURE AS CODE & DISASTER RECOVERY

Repository quản lý toàn bộ hạ tầng máy chủ Oracle VPS (Ubuntu 22.04 LTS ARM64/x86), cho phép dựng lại toàn bộ máy chủ từ con số 0 trong vòng 15-30 phút mà không cần snapshot hay image.

---

## 1. Khởi Tạo Máy Chủ Mới Từ 0 (Zero to Production)

Khi tạo một VPS Oracle mới:

```bash
# 1. Clone repository hạ tầng
git clone https://github.com/phanthemy/oracle-vps-backup.git /tmp/oracle-vps-backup
cd /tmp/oracle-vps-backup

# 2. Khởi chạy bộ cài đặt tự động
sudo bash bootstrap.sh
```

---

## 2. Khôi Phục Từng Dự Án (Project Restoration)

Sau khi bootstrap hoàn tất:

```bash
# Khôi phục MapGo Platform
bash restore.sh parking-hcm

# Khôi phục Chấm công CTV
bash restore.sh chamcong

# Khôi phục HRM Unified
bash restore.sh hrm-unified
```

---

## 3. Sao Lưu Cấu Hình VPS Hiện Tại

Chạy trên VPS hiện tại để đồng bộ cấu hình PM2, Caddy, Nginx, UFW, Crontab về repository:

```bash
cd /path/to/oracle-vps-backup
sudo bash backup.sh
git add -A
git commit -m "chore(vps): update live vps configs & pm2 dump"
git push origin main
```

---

## 4. Kiểm Thử Idempotency & Health Check

Script `bootstrap.sh` đạt chuẩn Idempotent — có thể chạy nhiều lần liên tiếp mà không gây lỗi hoặc trùng lặp cấu hình:

```bash
sudo bash bootstrap.sh
```
