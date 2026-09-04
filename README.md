# VPS INFRASTRUCTURE AS CODE & DISASTER RECOVERY (PORTABLE)

Repository quản lý toàn bộ hạ tầng máy chủ VPS (Ubuntu 22.04 / 24.04 LTS ARM64 & x86_64), cho phép dựng lại toàn bộ máy chủ từ con số 0 trong vòng 15-30 phút mà không cần snapshot hay image.

Được thiết kế theo chuẩn **Portable & Zero Hardcoding**: Tự động nhận diện user ứng dụng, tự động xác thực GitHub clone, và thiết lập môi trường chạy trên mọi nền tảng điện toán đám mây lẫn máy chủ ảo hóa nội bộ.

---

## ⚡ 1-Click Zero-to-Production VPS Restore (Khởi tạo toàn diện 1 lệnh)

Trên bất kỳ VPS mới (Ubuntu 22.04 / 24.04), đăng nhập quyền `root` và chạy đúng **1 lệnh duy nhất**:

```bash
curl -sSL https://raw.githubusercontent.com/phanthemy/oracle-vps-backup/main/restore-vps.sh | bash
```

*Hoặc clone và chạy trực tiếp:*

```bash
git clone https://github.com/phanthemy/oracle-vps-backup.git /tmp/oracle-vps-backup
cd /tmp/oracle-vps-backup
bash restore-vps.sh
```

> **Script tự động thực hiện từ A-Z:**
> 1. Chuẩn bị công cụ cơ bản (`git`, `jq`, `curl`...).
> 2. Bootstrap toàn bộ hạ tầng (Swap 4GB, limits, Node.js 20, PM2, Python 3, PostgreSQL + PostGIS, Redis, Caddy, UFW Firewall).
> 3. Tự động khôi phục toàn bộ database và các dự án (`parking-hcm`, `chamcong`, `hrm-unified`...).
> 4. Tự tạo `.env`, build code, đồng bộ Prisma schema/seed và kích hoạt PM2 process.
> 5. Chạy `doctor.sh` kiểm tra sức khỏe và báo cáo kết quả.

---

## 🛠️ Supported User Accounts (Tính Linh Hoạt & Đa Môi Trường)

Repository tích hợp cơ chế tự động phát hiện người dùng ứng dụng (`lib/user.sh` & `lib/common.sh`) theo thứ tự ưu tiên:
1. **Biến môi trường `APP_USER`**: Khi người dùng chỉ định rõ ràng.
2. **`SUDO_USER`**: User thực tế thực thi lệnh `sudo`.
3. **User UID $\ge 1000$ đầu tiên**: Tự động phát hiện user thông thường trên hệ thống.
4. **Fallback `root`**: Khi chạy trên môi trường VPS không tạo sẵn user phụ.

### Ví Dụ Chạy Trên Các Nền Tảng:

| Nền tảng / Môi trường | User mặc định | Lệnh thực thi |
|---|---|---|
| **Oracle Cloud** | `ubuntu` | `sudo bash bootstrap.sh` *(Tự nhận `ubuntu`)* |
| **VMware / VirtualBox** | `test` | `sudo bash bootstrap.sh` *(Tự nhận `test`)* |
| **Server Riêng / On-Premise** | `deploy` | `APP_USER=deploy sudo bash bootstrap.sh` |
| **Hetzner / DigitalOcean** | `root` hoặc custom | `sudo bash bootstrap.sh` |

---

## 🚀 1. Khởi Tạo Máy Chủ Mới Từ 0 (Zero to Production)

Khi tạo một VPS mới:

```bash
# 1. Clone repository hạ tầng
git clone https://github.com/phanthemy/oracle-vps-backup.git /tmp/oracle-vps-backup
cd /tmp/oracle-vps-backup

# 2. Khởi chạy bộ cài đặt tự động (chạy với sudo/root)
sudo bash bootstrap.sh
```

---

## 📦 2. Khôi Phục Toàn Bộ Ứng Dụng (1-Click Restore)

Sau khi bootstrap hoàn tất, chỉ cần **1 lệnh duy nhất** để khôi phục toàn bộ dự án:

```bash
# Khôi phục toàn bộ tất cả dự án trong registry (MapGo, Chấm công, HRM...) và chạy Doctor Audit:
bash restore-all.sh

# Hoặc khôi phục từng dự án riêng biệt:
bash restore.sh parking-hcm
bash restore.sh chamcong
bash restore.sh hrm-unified
```

---

## 💾 3. Sao Lưu Cấu Hình VPS Hiện Tại

Chạy trên VPS hiện tại để đồng bộ cấu hình PM2, Caddy, Nginx, UFW, Crontab về repository:

```bash
cd /path/to/oracle-vps-backup
sudo bash backup.sh
git add -A
git commit -m "chore(vps): update live vps configs & pm2 dump"
git push origin main
```

---

## 🩺 4. Chẩn Đoán Sức Khỏe & Kiểm Thử Idempotency

Kiểm tra toàn diện 10+ tiêu chuẩn hạ tầng (Swap, RAM, Disk, Limits, PM2, DB, Redis, Ports, Endpoints):

```bash
bash doctor.sh
```

Script `bootstrap.sh` đạt chuẩn **Idempotent** — có thể chạy nhiều lần liên tiếp mà không gây lỗi hoặc trùng lặp cấu hình:

```bash
sudo bash bootstrap.sh
```
