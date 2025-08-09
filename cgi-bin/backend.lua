#!/usr/bin/lua
-- Bắt buộc phải có dòng trên để uhttpd biết cách thực thi file.

local jsonc = require "luci.jsonc"

local modules_path = "/www/vwrt/cgi-bin/modules/?.lua"
package.path = package.path .. ";" .. modules_path

local data = {}

-- Chạy tất cả các module
local modules_to_run = { "sys_info", "resources", "network", "wifi", "clients" }

for _, module_name in ipairs(modules_to_run) do
    local module_ok, module = pcall(require, module_name)
    if module_ok then
        local status, result = pcall(module.get)
        if status then
            for k, v in pairs(result) do
                data[k] = v
            end
        end
    end
end

print("Content-type: application/json")
print("")
print(jsonc.stringify(data, true))
