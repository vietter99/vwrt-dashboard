-- modules/sys_info.lua
local sys = require "luci.sys"
local util = require "luci.util"

local M = {}

function M.get()
    local function format_uptime(s)
        if not s then return "N/A" end
        local days = math.floor(s / 86400)
        s = s % 86400
        local hours = math.floor(s / 3600)
        s = s % 3600
        local minutes = math.floor(s / 60)
        return string.format("%dd %dh %dm", days, hours, minutes)
    end

    -- Sử dụng 'ubus' để lấy thông tin
    local binfo = util.ubus("system", "board", {})
    
    local model = "N/A"
    if binfo and binfo.model then
        model = binfo.model
    end

    local firmware = "N/A"
    if binfo and binfo.release and binfo.release.description then
        firmware = binfo.release.description
    end
    
    -- *** THÊM MỚI ***
    local target_platform = "N/A"
    if binfo and binfo.release and binfo.release.target then
        target_platform = binfo.release.target
    end

    local kernel_version = "N/A"
    if binfo and binfo.kernel then
        kernel_version = binfo.kernel
    end

    return {
        hostname = (binfo and binfo.hostname) or sys.hostname(),
        model = model,
        firmware = firmware,
        uptime = format_uptime(sys.uptime()),
        target_platform = target_platform,
        kernel_version = kernel_version
    }
end

return M
