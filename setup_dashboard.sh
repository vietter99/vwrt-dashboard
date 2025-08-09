#!/bin/sh
# --- Các biến cấu hình ---
REPO_URL="https://github.com/vietter99/vwrt-dashboard.git"
DEST_DIR="/www/vwrt"
UHTTPD_CONF="/etc/config/uhttpd"

# --- Tải dự án ---
rm -rf "$DEST_DIR"
git clone "$REPO_URL" "$DEST_DIR"

if [ $? -ne 0 ]; then
    exit 1
fi

# --- Cấp quyền ---
BACKEND_SCRIPT="$DEST_DIR/cgi-bin/backend.lua"
if [ -f "$BACKEND_SCRIPT" ]; then
    chmod +x "$BACKEND_SCRIPT"
fi

# --- Cấu hình Web Server ---
cp "$UHTTPD_CONF" "$UHTTPD_CONF.bak"

sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"
sed -i "s/.*option index_page 'index.html'.*/#&/" "$UHTTPD_CONF"

if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi

if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

# --- Khởi động lại dịch vụ ---
/etc/init.d/uhttpd restart

exit 0
