-- modules/clients.lua
local util = require "luci.util"

local M = {}

function M.get()
    local clients = {}
    
    local function exec(command)
        local handle = io.popen(command .. " 2>/dev/null")
        if not handle then return "" end
        local result = handle:read("*a")
        handle:close()
        return util.trim(result)
    end

    -- Bước 1: Đọc file dhcp.leases để tạo một bảng tra cứu (MAC -> Hostname)
    -- Bảng này chỉ dùng để lấy tên thiết bị, không phải để xác định kết nối.
    local lease_map = {}
    local leases_content = exec("cat /tmp/dhcp.leases")
    for line in leases_content:gmatch("[^\r\n]+") do
        local _, mac, ip, hostname = line:match("^(%d+)%s+([%x:]+)%s+([%d%.]+)%s+([^%s]+)")
        if mac and ip then
            lease_map[mac:upper()] = (hostname and hostname ~= "*") and hostname or "N/A"
        end
    end

    -- Bước 2: Lấy tất cả các client Wi-Fi đang thực sự kết nối từ `iwinfo`
    local wifi_clients_map = {} -- Dùng để tra cứu nhanh client Wi-Fi
    local wifi_ifaces_str = exec("iwinfo | grep ESSID | awk '{print $1}'")
    for iface in wifi_ifaces_str:gmatch("[^%s]+") do
        local info = util.ubus("iwinfo", "info", { device = iface })
        local assoclist = util.ubus("iwinfo", "assoclist", { device = iface })
        
        if assoclist and assoclist.results and info then
            local band = (info.channel and info.channel <= 14) and "2.4 GHz" or "5 GHz"
            
            for _, client_data in ipairs(assoclist.results) do
                if client_data.mac and client_data.rx and client_data.tx then
                    local upper_mac = client_data.mac:upper()
                    -- Lưu thông tin client Wi-Fi vào bảng tra cứu
                    wifi_clients_map[upper_mac] = {
                        mac = client_data.mac,
                        rx_bytes = client_data.rx.bytes or 0,
                        tx_bytes = client_data.tx.bytes or 0,
                        total_bytes = (client_data.rx.bytes or 0) + (client_data.tx.bytes or 0),
                        band = band
                    }
                end
            end
        end
    end

    -- Bước 3: Đọc bảng ARP để lấy tất cả các thiết bị đang hoạt động (cả LAN và Wi-Fi)
    local arp_content = exec("cat /proc/net/arp")
    for line in arp_content:gmatch("[^\r\n]+") do
        -- Ví dụ dòng: 192.168.15.66     0x1         0x2         40:a5:ef:54:3f:09     * br-lan
        local ip, mac = line:match("^([%d%.]+)%s+0x%x%s+0x2%s+([%x:]+)") -- Chỉ lấy các kết nối hợp lệ (flag 0x2)
        if ip and mac then
            local upper_mac = mac:upper()
            local client_info = {
                mac = mac,
                ip = ip,
                hostname = lease_map[upper_mac] or "N/A",
                rx_bytes = 0,
                tx_bytes = 0,
                total_bytes = 0,
                band = "LAN" -- Mặc định là LAN
            }

            -- Nếu thiết bị này có trong danh sách Wi-Fi, cập nhật thông tin
            if wifi_clients_map[upper_mac] then
                local wifi_stats = wifi_clients_map[upper_mac]
                client_info.rx_bytes = wifi_stats.rx_bytes
                client_info.tx_bytes = wifi_stats.tx_bytes
                client_info.total_bytes = wifi_stats.total_bytes
                client_info.band = wifi_stats.band
            end
            
            table.insert(clients, client_info)
        end
    end
    
    return { clients = clients }
end

return M
