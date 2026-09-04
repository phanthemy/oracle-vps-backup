# SECRETS INVENTORY & RESTORATION GUIDE

> ⚠️ **BẢO MẬT TUYỆT ĐỐI**: File này KHÔNG lưu trữ mật khẩu hay private key thô. File này hướng dẫn nơi lưu trữ nguồn và cách khôi phục secrets khi dựng lại VPS mới.

---

## 1. Danh Mục Nguồn Lưu Trữ Secrets

| Secret / Khóa | Mô tả | Nơi lưu trữ an toàn | Cách khôi phục khi tạo VPS mới |
|---|---|---|---|
| **SSH Key Pair** | Truy cập VPS (App User / Root) | 1Password / Vault an toàn của Admin | Thêm public key vào `~/.ssh/authorized_keys` |
| **PostgreSQL Master** | Role `erp` / `postgres` | Password Vault (`erp_dev_2026`) | Tự động tạo bởi `install/postgres.sh` |
| **Telegram Bot Token** | `@linhcuatoi_bot` API Token | Bitwarden / Environment Vault | Khai báo vào `configs/telegram/.env` |
| **Cloudflare API Key** | Quản trị DNS `mapgo.vn`, `nextapp.vn` | Cloudflare Dashboard Admin | Cấu hình SSL / DNS A-record |
| **Google Maps API** | Geocoding & Elevation API | Google Cloud Console Project | Khai báo vào `.env` của `parking-hcm` |
| **JWT Secrets** | Mã hóa Token đăng nhập người dùng | Secrets Manager | Khai báo trong `.env` từng dự án |

---

## 2. Quy Trình Khôi Phục File `.env` Cho Dự Án

Mỗi dự án trên VPS cần file `.env` chứa các biến môi trường thực tế. Khi khôi phục dự án bằng `restore.sh`, sao chép từ kho lưu trữ bảo mật:

```bash
# Ví dụ cấu hình cho parking-hcm
cat << 'EOF' > /var/www/parking-hcm/.env
DATABASE_URL="postgresql://erp:erp_dev_2026@localhost:5432/mapgo_spatial"
NEXT_PUBLIC_APP_URL="https://mapgo.vn"
NODE_ENV="production"
PORT=3003
EOF
```
