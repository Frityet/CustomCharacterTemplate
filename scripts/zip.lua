local export = {}

function table.keys(tbl)
    ---@type string[]
    local keys = {}
    for k, v in pairs(tbl) do
        keys[#keys + 1] = tostring(k)
    end
    return keys
end

function table.values(tbl)
    ---@type string[]
    local keys = {}
    for k, v in pairs(tbl) do
        keys[#keys + 1] = tostring(v)
    end
    return keys
end

function table.merge(tbl, sep)
    local str = ""
    for k, v in pairs(tbl) do
        str = str .. v .. (sep or '')
    end
    return str
end

---Executes a program
---@param cmd string
---@param ... string[]?
function io.exec(cmd, ...)
    local args = {...} or {}
    local p, err = io.popen(cmd .. " " .. table.merge(table.values(args), ' '), "r")
    if err then error("\x1b[31mError: " .. err .. "\x1b[0m") end
    p:close() 
end

---@class ZipFile
local zipfile = {
    path = "",
    ---@type string[]
    files = {
        ""
    },
    itemcount = 0
}
zipfile.__index = zipfile

---Creates a zipfile
---@param name string
---@param file string
---@return ZipFile
function zipfile:new(name, file)
    ---@type ZipFile
    local t = {}
    setmetatable(t, zipfile)
    t.path = name
    t.itemcount = 0
    t.files = { file }
    io.exec("tar", "-czvf", name, file)
    return t
end

function zipfile:add_item(item)
    io.exec("tar", "-rvf", self.path, item)
end

export.zipfile = zipfile
return export