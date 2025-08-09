#!/bin/sh

# Hàm xuất JSON và thoát khỏi script
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

# --- Bước 2: So sánh phiên bản ---
LOCAL_VER=$(cat "$DEST/VERSION" 2>/dev/null || echo "0.0.0")
LATEST_VER=$(curl -s -f "$VERSION_URL" 2>/dev/null)

if [ -z "$LATEST_VER" ]; then
    json_exit "error" "Không thể lấy thông tin phiên bản mới nhất từ GitHub."
fi

if [ "$LOCAL_VER" = "$LATEST_VER" ]; then
    json_exit "skip" "Bạn đang ở phiên bản mới nhất!" "\"version\":\"$LOCAL_VER\""
fi

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

# --- Bước 4: Cập nhật an toàn (Giải nén và di chuyển) ---
unzip -q "$OUT_ZIP" -d "$WORKDIR"
EXTRACTED_DIR="$WORKDIR/$REPO_NAME-$BRANCH"

if [ ! -d "$EXTRACTED_DIR" ]; then
    rm -rf "$OUT_ZIP" "$WORKDIR"
    json_exit "error" "Lỗi giải nén: không tìm thấy thư mục dự án."
fi

if [ -d "$DEST" ]; then
    mv "$DEST" "$DEST.bak"
fi

mv "$EXTRACTED_DIR" "$DEST"

if [ -d "$DEST" ]; then
    rm -rf "$DEST.bak"
else
    if [ -d "$DEST.bak" ]; then
        mv "$DEST.bak" "$DEST"
    fi
    json_exit "error" "Không thể di chuyển phiên bản mới vào vị trí."
fi

# --- Bước 5: Cấu hình và dọn dẹp ---
if [ -d "$DEST/cgi-bin" ]; then
    chmod -R 755 "$DEST/cgi-bin"
fi

rm -f "$OUT_ZIP"
rm -rf "$WORKDIR"

UHTTPD_CONF="/etc/config/uhttpd"
CONFIG_CHANGED=0

if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    CONFIG_CHANGED=1
    sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi

if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    CONFIG_CHANGED=1
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

if [ "$CONFIG_CHANGED" -eq 1 ]; then
    /etc/init.d/uhttpd restart
fi

# --- Bước 6: Trả kết quả thành công ---
json_exit "ok" "Cập nhật thành công!" "\"old_ver\":\"$LOCAL_VER\",\"new_ver\":\"$LATEST_VER\""
