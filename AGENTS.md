# AGENTS

## Startup

- Kiểm tra git status
- Kiểm tra branch hiện tại
- Kiểm tra remote
- Đọc README.md
- Đọc AGENTS.md
- Đọc thư mục .antigravity nếu tồn tại

## Working Rules

- Chỉ sửa file liên quan.
- Không dùng git add -A.
- Chỉ stage đúng các file đã sửa.

## Finish

- git status
- Conventional Commit
- git push origin main
- Báo:
  - commit hash
  - git status
  - git log --oneline -1
  - git ls-remote origin main

Nếu push thất bại thì dừng và báo lỗi.

## User Prompt Contract

Người dùng chỉ mô tả mục tiêu cần đạt.

Agent phải tự:

1. git pull
2. đọc README.md
3. đọc AGENTS.md
4. đọc .antigravity/STATE.md
5. xác định task
6. thực hiện
7. cập nhật STATE.md
8. commit
9. push
10. báo cáo kết quả

Không yêu cầu người dùng nhắc lại các bước trên.
