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
EXTRACTED_DIR_NAME="vwrt-dashboard-main" # Tên thư mục sau khi giải nén từ zip của GitHub

# --- Bắt đầu ---

# 1. Cài đặt các gói phụ thuộc
echo "=> Đang cài đặt các gói cần thiết (curl, unzip)..."
opkg update
opkg install curl unzip

# 2. Tải về phiên bản mới nhất
echo "=> Đang tải phiên bản mới nhất từ GitHub..."
# Dọn dẹp file tạm cũ
rm -rf "$OUT_ZIP" "$WORKDIR"
mkdir -p "$WORKDIR"

# Tải file zip
curl -sL "$REPO_URL" -o "$OUT_ZIP"

# Kiểm tra file zip
echo "=> Đang kiểm tra file đã tải về..."
unzip -tq "$OUT_ZIP"

# 3. Cài đặt an toàn
echo "=> Đang giải nén phiên bản mới..."
unzip -q "$OUT_ZIP" -d "$WORKDIR"

# Di chuyển phiên bản cũ (nếu có) để sao lưu
if [ -d "$DEST_DIR" ]; then
    echo "=> Đang sao lưu phiên bản cũ..."
    mv "$DEST_DIR" "$DEST_DIR.bak"
fi

# Di chuyển phiên bản mới vào vị trí
echo "=> Đang cài đặt phiên bản mới..."
mv "$WORKDIR/$EXTRACTED_DIR_NAME" "$DEST_DIR"

# Cấp quyền thực thi
if [ -d "$DEST_DIR/cgi-bin" ]; then
    chmod -R 755 "$DEST_DIR/cgi-bin"
fi

# 4. Cấu hình Web Server
echo "=> Đang cấu hình web server (uhttpd)..."
# Sao lưu file config gốc một lần
if [ ! -f "$UHTTPD_CONF.bak-vwrt" ]; then
    cp "$UHTTPD_CONF" "$UHTTPD_CONF.bak-vwrt"
fi

# Vô hiệu hóa trang index cũ
sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"

# Thêm cấu hình mới nếu chưa có
if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi

if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

# 5. Hoàn tất
echo "=> Đang khởi động lại web server..."
/etc/init.d/uhttpd restart

# Dọn dẹp file sao lưu và file tạm
echo "=> Đang dọn dẹp..."
rm -rf "$DEST_DIR.bak"
rm -f "$OUT_ZIP"
rm -rf "$WORKDIR"

echo "✅ HOÀN TẤT! VWRT Dashboard đã được cài đặt thành công."
echo "   Hãy truy cập địa chỉ IP của router để xem."

exit 0
