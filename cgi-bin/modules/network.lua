-- modules/network.lua
local util = require "luci.util"
local jsonc = require "luci.jsonc"

local M = {}

function M.get()
    local function exec(command)
        local handle = io.popen(command .. " 2>/dev/null")
        if not handle then return "" end
        local result = handle:read("*a")
        handle:close()
        return util.trim(result)
    end
    
    local function read_file(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*a")
        file:close()
        return content
    end

    -- Tìm giao diện WAN
    local wan_iface = exec("ip route show default | awk '/default/ {print $5}'")
    
    -- Lấy tổng dung lượng
    local total_rx, total_tx = 0, 0
    if wan_iface and wan_iface ~= "" then
        total_rx = tonumber(util.trim(read_file(string.format("/sys/class/net/%s/statistics/rx_bytes", wan_iface)) or "0"))
        total_tx = tonumber(util.trim(read_file(string.format("/sys/class/net/%s/statistics/tx_bytes", wan_iface)) or "0"))
    end

    -- Đo Ping
    local ping_output = exec("ping -c 1 -W 1 8.8.8.8")
    local ping_ms = ping_output and tonumber(ping_output:match("time=([%d%.]+) ms"))

    -- Lấy IP Public
    local ip_info_json = exec("wget -qO- http://ip-api.com/json")
    local ip_info = {}
    if ip_info_json and ip_info_json ~= "" then
        local ok, parsed = pcall(jsonc.parse, ip_info_json)
        if ok and parsed and parsed.status == "success" then
            ip_info = {
                ip = parsed.query,
                isp = parsed.isp,
                country = parsed.country
            }
        end
    end

    return {
        network = {
            total_rx_bytes = total_rx,
            total_tx_bytes = total_tx,
            total_usage_bytes = total_rx + total_tx -- *** THÊM MỚI: Tính tổng dung lượng ***
        },
        latency = {
            ping = ping_ms
        },
        public_ip = ip_info
    }
end

return M
