-- modules/resources.lua
local util = require "luci.util"

local M = {}

function M.get()
    local function exec_first_line(command)
        local handle = io.popen(command)
        if not handle then return "" end
        local result = handle:read("*a")
        handle:close()
        return util.trim(result:match("[^\r\n]+"))
    end

    -- Hàm đọc nội dung từ một file
    local function read_file(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*a")
        file:close()
        return content
    end

    -- CPU (Dùng /proc/loadavg)
    local loadavg_str = exec_first_line("cat /proc/loadavg")
    local load1 = loadavg_str:match("([%d%.]+)") -- Lấy giá trị đầu tiên

    -- RAM (Sửa lỗi: Dùng /proc/meminfo để đáng tin cậy hơn)
    local meminfo_content = read_file("/proc/meminfo")
    local mem_total = tonumber(meminfo_content:match("MemTotal:%s+(%d+)")) or 0
    local mem_available = tonumber(meminfo_content:match("MemAvailable:%s+(%d+)")) or 0
    local mem_used = mem_total - mem_available

    -- ROM
    local df_output = exec_first_line("df /overlay | awk 'NR==2 {print $2, $3}'")
    local rom_total, rom_used = df_output:match("(%d+)%s+(%d+)")

    return {
        cpu = {
            load = tonumber(load1) or 0
        },
        memory = {
            total = mem_total,
            used = mem_used
        },
        storage = {
            total = tonumber(rom_total) or 0,
            used = tonumber(rom_used) or 0
        }
    }
end

return M
