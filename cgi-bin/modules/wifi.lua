-- modules/wifi.lua
local util = require "luci.util"

local M = {}

function M.get()
    -- Hàm thực thi lệnh và trả về kết quả
    local function exec(command)
        local handle = io.popen(command .. " 2>/dev/null")
        if not handle then return "" end
        local result = handle:read("*a")
        handle:close()
        return util.trim(result)
    end

    -- Tìm tất cả các giao diện wifi đang hoạt động
    local wifi_ifaces_str = exec("iwinfo | grep ESSID | awk '{print $1}'")
    local wifi_ifaces = {}
    for iface in wifi_ifaces_str:gmatch("[^%s]+") do
        table.insert(wifi_ifaces, iface)
    end

    -- Mặc định cho 2 băng tần
    local wifi_24_data = { clients = 0 }
    local wifi_5_data = { clients = 0 }

    -- Lặp qua các giao diện tìm được để lấy thông tin
    for _, iface in ipairs(wifi_ifaces) do
        local info = util.ubus("iwinfo", "info", { device = iface })
        if info then
            local clients = #util.ubus("iwinfo", "assoclist", { device = iface }).results
            local data = {
                ssid = info.ssid,
                channel = info.channel,
                clients = clients
            }
            -- Phân loại băng tần dựa trên kênh
            if info.channel <= 14 then
                wifi_24_data = data
            else
                wifi_5_data = data
            end
        end
    end
    
    return {
        wifi = {
            ghz24 = wifi_24_data,
            ghz5 = wifi_5_data
        }
    }
end

return M
