#!/bin/sh

# Dừng script ngay lập tức nếu có bất kỳ lệnh nào thất bại
set -e

# --- Cấu hình ---
REPO_URL="https://github.com/vietter99/vwrt-dashboard/archive/refs/heads/main.zip"
DEST_DIR="/www/vwrt"
UHTTPD_CONF="/etc/config/uhttpd"

# Các thư mục và file tạm
OUT_ZIP="/tmp/dashboard.zip"
WORKDIR="/tmp/dashboard_update"
# Tên thư mục sau khi giải nén từ zip của GitHub sẽ là ten-repo-ten-nhanh
EXTRACTED_DIR_NAME="vwrt-dashboard-main" 

# --- Bắt đầu ---

echo "=> Dang tai phien ban moi nhat tu GitHub..."
# Dọn dẹp file tạm cũ
rm -rf "$OUT_ZIP" "$WORKDIR"
mkdir -p "$WORKDIR"

wget -O "$OUT_ZIP" "$REPO_URL"

echo "=> Dang kiem tra file da tai ve..."
unzip -tq "$OUT_ZIP"

echo "=> Dang giai nen phien ban moi..."
unzip -q "$OUT_ZIP" -d "$WORKDIR"

# Di chuyển phiên bản cũ (nếu có) để sao lưu
if [ -d "$DEST_DIR" ]; then
    echo "=> Dang sao luu phien ban cu..."
    mv "$DEST_DIR" "$DEST_DIR.bak"
fi

echo "=> Dang cai dat phien ban moi..."
mv "$WORKDIR/$EXTRACTED_DIR_NAME" "$DEST_DIR"

if [ -d "$DEST_DIR/cgi-bin" ]; then
    chmod -R 755 "$DEST_DIR/cgi-bin"
fi

echo "=> Dang cau hinh web server (uhttpd)..."
if [ ! -f "$UHTTPD_CONF.bak-vwrt" ]; then
    cp "$UHTTPD_CONF" "$UHTTPD_CONF.bak-vwrt"
fi

sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"

if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi
if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

echo "=> Dang khoi dong lai web server..."
/etc/init.d/uhttpd restart

echo "=> Dang don dep..."
rm -rf "$DEST_DIR.bak"
rm -f "$OUT_ZIP"
rm -rf "$WORKDIR"

echo "HOAN TAT! VWRT Dashboard da duoc cai dat thanh cong."
echo "Hay truy cap dia chi IP cua router-ip/vwrt de xem."

exit 0
