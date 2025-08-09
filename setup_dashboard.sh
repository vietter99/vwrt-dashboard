#!/bin/sh

# Hàm xuất JSON và thoát khỏi script
# Usage: json_exit "status" "message" "optional_data"
json_exit() {
    local status="$1"
    local msg="$2"
    local extra="$3"
    
    if [ -n "$extra" ]; then
        echo "{\"status\":\"$status\",\"msg\":\"$msg\",$extra}"
    else
        echo "{\"status\":\"$status\",\"msg\":\"$msg\"}"
    fi
    exit 0
}

# In header JSON trước
echo "Content-Type: application/json"
echo ""

# --- Cấu hình ---
REPO_NAME="vwrt-dashboard"
BRANCH="main" # Nhánh chính của repo
REPO="vietter99/$REPO_NAME"
DEST="/www/vwrt"
ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
VERSION_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/VERSION"
OUT_ZIP="/tmp/dashboard.zip"
WORKDIR="/tmp/dashboard_update"

# --- Bước 1: Kiểm tra và cài đặt các gói phụ thuộc ---
PACKAGES_NEEDED="curl unzip"
for pkg in $PACKAGES_NEEDED; do
    if ! opkg list-installed | grep -q "^$pkg "; then
        opkg update >/dev/null 2>&1
        opkg install $pkg >/dev/null 2>&1
        if ! opkg list-installed | grep -q "^$pkg "; then
            json_exit "error" "Không thể cài đặt gói phụ thuộc: $pkg"
        fi
    fi
done

# --- Bước 3: Tải và kiểm tra file ---
rm -rf "$OUT_ZIP" "$WORKDIR"
mkdir -p "$WORKDIR"

curl -s -L -o "$OUT_ZIP" "$ZIP_URL"
if [ $? -ne 0 ]; then
    json_exit "error" "Tải file cập nhật thất bại."
fi

if ! unzip -tq "$OUT_ZIP" >/dev/null 2>&1; then
    rm -f "$OUT_ZIP"
    json_exit "error" "File tải về không phải là file zip hợp lệ."
fi
# --- Bước 5: Cấu hình và dọn dẹp ---
BACKEND_SCRIPT="$DEST/cgi-bin/backend.lua"
if [ -f "$BACKEND_SCRIPT" ]; then
    chmod +x "$BACKEND_SCRIPT"
fi

rm -f "$OUT_ZIP"
rm -rf "$WORKDIR"

# Cấu hình uhttpd để dashboard làm trang chủ mặc định
UHTTPD_CONF="/etc/config/uhttpd"
CONFIG_CHANGED=0

# Thêm trang index mới nếu chưa có
if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    CONFIG_CHANGED=1
    # Vô hiệu hóa trang mặc định cũ
    sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"
    # Thêm vào cuối mục config uhttpd 'main'
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi

# Thêm trình thông dịch cho file .lua nếu chưa có
if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    CONFIG_CHANGED=1
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

# Khởi động lại uhttpd chỉ khi có thay đổi config
if [ "$CONFIG_CHANGED" -eq 1 ]; then
    /etc/init.d/uhttpd restart
fi

# --- Bước 6: Trả kết quả thành công ---
json_exit "ok" "Cập nhật thành công!" "\"old_ver\":\"$LOCAL
