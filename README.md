# VPS INFRASTRUCTURE AS CODE & DISASTER RECOVERY (PORTABLE)

Repository quản lý toàn bộ hạ tầng máy chủ VPS (Ubuntu 22.04 / 24.04 LTS ARM64 & x86_64), cho phép dựng lại toàn bộ máy chủ từ con số 0 trong vòng 15-30 phút mà không cần snapshot hay image.

Được thiết kế theo chuẩn **Portable & Zero Hardcoding**: Tự động nhận diện user ứng dụng, thư mục HOME và môi trường chạy trên mọi nền tảng điện toán đám mây lẫn máy chủ ảo hóa nội bộ.

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

# Hoặc chỉ định rõ user ứng dụng mong muốn:
# APP_USER=test sudo bash bootstrap.sh
```

---

## 📦 2. Khôi Phục Từng Dự Án (Project Restoration)

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
