# VWRT Dashboard

> Một dashboard giao diện hiện đại, gọn gàng và thời gian thực để theo dõi toàn bộ thông tin quan trọng trên router OpenWrt của bạn.

![VWRT Dashboard Screenshot]<img width="826" height="913" alt="image" src="https://github.com/user-attachments/assets/f9ed6ad7-f650-42c9-bec2-0b216067f624" />


---

## ✨ Tính năng nổi bật

* 📊 **Tổng quan thời gian thực**: Theo dõi các thông số quan trọng ngay khi chúng thay đổi.
* 🖥️ **Thông tin hệ thống**: Hiển thị Model router, phiên bản Firmware, Kernel, thời gian hoạt động...
* ⚙️ **Tài nguyên**: Giám sát trực quan CPU, RAM và dung lượng lưu trữ (ROM) với thanh tiến trình.
* 🌐 **Mạng WAN**: Hiển thị IP Public, nhà cung cấp dịch vụ (ISP), Ping và tổng dung lượng đã sử dụng (Tải xuống/Tải lên).
* 📈 **Biểu đồ trực quan**: Theo dõi lịch sử tốc độ mạng (Download/Upload) và độ trễ (Ping) theo thời gian thực.
* 📶 **Thông tin Wi-Fi**: Nhanh chóng xem SSID, kênh và số lượng thiết bị đang kết nối cho cả hai băng tần 2.4GHz và 5GHz.
* 📱 **Danh sách thiết bị**: Liệt kê chi tiết tất cả các thiết bị đang kết nối (cả LAN và Wi-Fi) kèm Hostname, IP, MAC và dung lượng đã sử dụng của từng thiết bị.

---

## 📋 Yêu cầu

* Một router đang chạy **OpenWrt** đã được cài đặt giao diện web **LuCI**.

## 🔑 Truy cập

* Sau khi cài đặt, VWRT Dashboard (Mặc định) sẽ được thiết lập như sau:
http://router-ip/vwrt
---

## 🚀 Cài đặt nhanh (Một dòng lệnh)

Chỉ cần kết nối vào router của bạn qua SSH và chạy một dòng lệnh duy nhất dưới đây. Script sẽ tự động cài đặt mọi thứ cần thiết.

```sh
wget -O setup.sh https://raw.githubusercontent.com/vietter99/vwrt-dashboard/main/setup_dashboard.sh && chmod +x setup.sh && ./setup.sh
