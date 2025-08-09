#!/bin/sh

# =================================================================
# SCRIPT TỰ ĐỘNG CÀI ĐẶT VWRT DASHBOARD CHO OPENWRT
# =================================================================

# --- PHẦN CẤU HÌNH: Thay đổi dòng dưới đây thành URL repo GitHub của bạn ---
REPO_URL="https://github.com/user/repo.git" 

# --- Tên thư mục đích trên router ---
DEST_DIR="/www/vwrt"
UHTTPD_CONF="/etc/config/uhttpd"

# --- Hàm in thông báo ---
log() {
    echo "=> $1"
}

# --- BƯỚC 1: CÀI ĐẶT CÁC GÓI PHỤ THUỘC ---
log "Cập nhật danh sách gói và cài đặt git, wget..."
opkg update
opkg install git-http wget

# Kiểm tra xem git đã được cài đặt thành công chưa
if ! command -v git > /dev/null; then
    log "LỖI: Không thể cài đặt git. Vui lòng kiểm tra kết nối mạng và thử lại."
    exit 1
fi

# --- BƯỚC 2: TẢI DỰ ÁN TỪ GITHUB ---
log "Kiểm tra và dọn dẹp thư mục cũ (nếu có)..."
rm -rf "$DEST_DIR"

log "Bắt đầu tải dự án từ GitHub về thư mục $DEST_DIR..."
git clone "$REPO_URL" "$DEST_DIR"

# Kiểm tra xem tải về có thành công không
if [ $? -ne 0 ]; then
    log "LỖI: Tải dự án từ GitHub thất bại. Vui lòng kiểm tra lại REPO_URL."
    exit 1
fi

log "Tải dự án thành công."

# --- BƯỚC 3: CẤP QUYỀN THỰC THI ---
BACKEND_SCRIPT="$DEST_DIR/cgi-bin/backend.lua"
if [ -f "$BACKEND_SCRIPT" ]; then
    log "Cấp quyền thực thi cho file backend..."
    chmod +x "$BACKEND_SCRIPT"
else
    log "CẢNH BÁO: Không tìm thấy file backend.lua tại $BACKEND_SCRIPT"
fi

# --- BƯỚC 4: TỰ ĐỘNG CẤU HÌNH UHTTPD ---
log "Bắt đầu cấu hình web server (uhttpd)..."

# Sao lưu file cấu hình gốc để an toàn
cp "$UHTTPD_CONF" "$UHTTPD_CONF.bak"

# Sửa mục index_page: vô hiệu hóa trang mặc định và thêm trang dashboard mới
# Vô hiệu hóa dòng index.html cũ (nếu có) bằng cách thêm dấu # vào đầu
sed -i "s/.*list index_page 'index.html'.*/#&/" "$UHTTPD_CONF"
sed -i "s/.*option index_page 'index.html'.*/#&/" "$UHTTPD_CONF"

# Thêm trang index mới nếu nó chưa tồn tại
if ! grep -q "list index_page 'vwrt/index.html'" "$UHTTPD_CONF"; then
    log "Thiết lập trang chủ mặc định là VWRT Dashboard."
    # Thêm vào cuối mục config uhttpd 'main'
    sed -i "/config uhttpd 'main'/a\\
	list index_page 'vwrt/index.html'" "$UHTTPD_CONF"
fi

# Thêm trình thông dịch cho file .lua nếu nó chưa tồn tại
if ! grep -q "list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"; then
    log "Thêm trình thông dịch Lua cho uhttpd."
    sed -i "/config uhttpd 'main'/a\\
	list interpreter '.lua=/usr/bin/lua'" "$UHTTPD_CONF"
fi

log "Cấu hình uhttpd hoàn tất."

# --- BƯỚC 5: KHỞI ĐỘNG LẠI DỊCH VỤ ---
log "Khởi động lại web server để áp dụng tất cả thay đổi..."
/etc/init.d/uhttpd restart

log "HOÀN TẤT! Script đã chạy xong."
log "Bây giờ bạn có thể truy cập địa chỉ IP của router để xem dashboard mới."
echo "-----------------------------------------------------------------"

exit 0