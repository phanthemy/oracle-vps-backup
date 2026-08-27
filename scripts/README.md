# Multi-Machine Bootstrap Toolkit

Bộ công cụ giúp khởi tạo và đồng bộ môi trường làm việc trên nhiều máy (A, B, C...) một cách thống nhất.

**Source of Truth**: `repos.txt` — danh sách duy nhất chứa tất cả repository.

---

## Cấu trúc

```
scripts/
├── repos.txt               # Danh sách repo (Source of Truth)
├── bootstrap-machine.ps1   # Khởi tạo máy mới
├── sync-all.ps1            # Đồng bộ tất cả repo
├── doctor.ps1              # Kiểm tra sức khỏe repo
└── README.md               # File này
```

---

## Ý nghĩa từng script

| Script | Mục đích | Có sửa dữ liệu? |
|--------|----------|-------------------|
| `bootstrap-machine.ps1` | Clone tất cả GitHub repo về máy, in danh sách cần add vào Antigravity | Có (tạo thư mục mới) |
| `sync-all.ps1` | Fetch + Pull tất cả repo, hiện trạng thái | Có (git pull) |
| `doctor.ps1` | Kiểm tra sức khỏe: git, origin, clean/dirty, sync | Không (read-only) |

---

## Kịch bản sử dụng

### 1. Máy lần đầu (First-time Setup)

```powershell
# Bước 1: Clone repo chính
git clone https://github.com/phanthemy/oracle-vps-backup.git C:\Users\<you>\Documents\antigravity\oracle-vps-backup

# Bước 2: Chạy bootstrap
cd C:\Users\<you>\Documents\antigravity\oracle-vps-backup\scripts
.\bootstrap-machine.ps1

# Bước 3: Add các thư mục được liệt kê vào Antigravity (thủ công)
```

### 2. Máy mới (Onboarding thêm máy B, C...)

Giống hệt bước "Máy lần đầu". Bootstrap sẽ:
- Clone các repo chưa có
- Bỏ qua các repo đã tồn tại
- In danh sách cần add vào Antigravity

**Chế độ thử trước** (không clone thật):

```powershell
.\bootstrap-machine.ps1 -DryRun
```

### 3. Đồng bộ hằng ngày

```powershell
cd C:\Users\<you>\Documents\antigravity\oracle-vps-backup\scripts
.\sync-all.ps1
```

Kết quả hiển thị cho mỗi repo:
- Project name
- Branch hiện tại
- Commit mới nhất
- DIRTY / CLEAN

Script tiếp tục chạy nếu một repo lỗi — không dừng toàn bộ.

### 4. Kiểm tra sức khỏe

```powershell
.\doctor.ps1
```

Kiểm tra từng repo:
- ✅ PASS — Mọi thứ ổn
- ⚠️ WARN — Working tree dirty hoặc local ≠ remote
- ❌ FAIL — Thiếu folder hoặc không có origin remote

---

## repos.txt — Định dạng

```
project-name|git-url|type
```

| Field | Mô tả |
|-------|--------|
| `project-name` | Tên thư mục sẽ tạo trong workspace |
| `git-url` | URL git clone (bỏ trống nếu internal) |
| `type` | `required`, `optional`, hoặc `internal` |

**Ví dụ:**

```
oracle-vps-backup|https://github.com/phanthemy/oracle-vps-backup.git|required
Mapgo.vn|https://github.com/phanthemy/parking-hcm.git|required
parking-manager|https://github.com/phanthemy/parking-manager.git|optional
CRM-AAU||internal
```

| Type | Bootstrap | Sync | Doctor (nếu thiếu folder) |
|------|-----------|------|---------------------------|
| `required` | Clone | Fetch + Pull | ❌ FAIL |
| `optional` | Clone | Fetch + Pull (nếu có) | ⏭️ SKIP |
| `internal` | SKIP | SKIP | ⏭️ SKIP |

---

## Lưu ý

- Tất cả script đọc `repos.txt` cùng thư mục — **không hard-code danh sách repo**.
- Thêm repo mới? Chỉ cần thêm 1 dòng vào `repos.txt`.
- Workspace mặc định: thư mục cha của `oracle-vps-backup` (thường là `…\Documents\antigravity\`).
