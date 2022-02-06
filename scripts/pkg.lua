local yaml      = require("scripts.yaml")
local json      = require("scripts.json")
local pprint    = require("scripts.pprint")
pprint.defaults.indent_size = 4
local prettyprint = pprint.pprint

local modinfo = require("modinfo")

---Executes a program
---@param cmd string
---@param ... string[]?
function exec(cmd, ...)
    ---@type string
    local args = cmd .. " "

    for _, v in ipairs({...}) do
        args = args .. v .. " "
    end
    -- print(args)
    local p, err = io.popen(args, "r")
    if err then error("\x1b[31mError: " .. err .. "\x1b[0m") end
    p:close()
end


--- Check if a file or directory exists in this path
local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
            -- Permission denied, but it exists
            return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path .. "/")
end

local function mkdir(dir)
    if exists(dir) then return end
    -- local p, err = io.popen("mkdir -p \"" .. dir .. "\"", "r")
    -- if err then error("\x1b[31m" .. p:read("*a") .. "\x1b[0m") end
    -- p:close()
    exec("mkdir", "-p", dir)
end

local function copy(src, dst)
    local cf, cferr = io.open(src, "r")
    local rf, rferr = io.open(dst, "w")
    if cferr then error("\x1b[31mError: " .. cferr .. "\x1b[0m") end
    if rferr then error("\x1b[31mError: " .. rferr .. "\x1b[0m") end
    rf:write(cf:read("*a"))
    cf:close()
    rf:close()
end

local function copyb(src, dst)
    local cf = io.open(src, "rb")
    local rf = io.open(dst, "wb")
    rf:write(cf:read("*a"))
    cf:close()
    rf:close()
end

local function copydir(src, dst)
    exec("cp", "-r", src, dst)
end

function yaml.tojson(str)
    return json.encode(yaml.parse(str))
end

function list(directory)
    local i, t = 0, {}
    local pfile = io.popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        if filename ~= '.' and filename ~= ".." then
            i = i + 1
            t[i] = filename
        end
    end
    pfile:close()
    return t
end

function listdir(directory)
    local i, t = 0, {}
    local pfile = io.popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        if isdir(filename) and filename ~= '.' and filename ~= ".." then
            i = i + 1
            t[i] = filename
        end
    end
    pfile:close()
    return t
end

-- Lua implementation of PHP scandir function
function listfiles(directory)
    local i, t = 0, {}
    local pfile = io.popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        if not isdir(filename) and filename ~= '.' and filename ~= ".." then
            i = i + 1
            t[i] = filename
        end
    end
    pfile:close()
    return t
end

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

function zip(out, ...)
    exec("tar", "-cf", out, table.merge({...}, ' '))
end

function remove(fo)
    exec("rm", "-rf", fo)
end

--[[ SCRIPT START ]]--

print("\x1b[32mPackaging Deli file!\x1b[0m")
print("\x1b[34mMod info:")

prettyprint(modinfo)

local projdir = modinfo.name .. "/"

mkdir(projdir)

local tsmanifest = {
    name = modinfo.name,
    version = modinfo.version,
    description = modinfo.description,
    url = modinfo.url,
    dependencies = {
        "DeliCollective-Deli-0.4.1",
        "devyndamonster-TakeAndHoldTweaker-1.6.7"
    }
}

do
    local delifile, err = io.open(projdir .. "manifest.json", "w")
    if err then error("\x1b[31m" .. err .. "\x1b[0m") return end
    delifile:write(json.encode(tsmanifest))
    delifile:close()
end

copy(modinfo.files.readme, projdir .. "/README.md")

print("\x1b[33mCreated thunderstore manifest!\x1b[0m")

local delidir = projdir .. modinfo.author .. "-" .. modinfo.name .. "/"
local characterdir = delidir .. modinfo.name .. "/"
mkdir(characterdir)

local delimanifest = {
    guid = modinfo.author .. modinfo.name,
    version = modinfo.version,
    require = "0.4.1",
    dependencies = {
        ["h3vr.tnhtweaker.deli"] = "1.6.7"
    },
    name = modinfo.name,
    description = modinfo.description,
    authors = {
        modinfo.author
    },
    assets = {
        patcher = {},
        setup = {
            [modinfo.name .. "/"] = "h3vr.tnhtweaker.deli:character",
            [modinfo.name .. "/vault/*vault*.json"] = "h3vr.tnhtweaker.deli:vault_file",
            [modinfo.name .. "/sosig/*sosig*.json"] = "h3vr.tnhtweaker.deli:sosig"
        },
        runtime = {}
    }
}

do
    local deliman, err = io.open(delidir .. "manifest.json", "w")
    if err then error("\x1b[31m" .. err .. "\x1b[0m") return end
    deliman:write(json.encode(delimanifest))
    deliman:close()
end
print("\x1b[33mCreated deli manifest!\x1b[0m")

mkdir(characterdir .. "vault/")
mkdir(characterdir .. "sosig/")

local character
do
    local charfile, err = io.open(modinfo.files.character, "r")
    if err then error("\x1b[31m" .. err .. "\x1b[0m") return end
    character = yaml.parse(charfile:read("*a"))
    charfile:close()
end

character["DisplayName"] = modinfo.name
character["Description"] = modinfo.description

do
    local charfile, err = io.open(characterdir .. "character.json", "w")
    if err then error("\x1b[31m" .. err .. "\x1b[0m") return end
    charfile:write(json.encode(character))
    charfile:close()
end

print("\x1b[33mCreated character file!\x1b[0m")
copyb(modinfo.files.thumbnail, characterdir .. "thumb.png")
copyb(modinfo.files.thumbnail, projdir .. "icon.png")
print("\x1b[33mCopied thumbnail!\x1b[0m")

for _, file in ipairs(listfiles(modinfo.files.icons)) do
    copyb(modinfo.files.icons .. file, characterdir .. file)
end
print("\x1b[33mCopied icons!\x1b[0m")

for _, file in ipairs(listfiles(modinfo.files.vaultfiles)) do
    local dst = io.open(characterdir .. "vault/" .. file .. ".json", "w")
    local src = io.open(modinfo.files.vaultfiles .. file, "r")
    dst:write(yaml.tojson(src:read("*a")))
    dst:close()
    src:close()
end
print("\x1b[33mCopied vaultfiles!\x1b[0m")

for _, file in ipairs(listfiles(modinfo.files.sosigfiles)) do
    local dst = io.open(characterdir .. "sosig/" .. file .. ".json", "w")
    local src = io.open(modinfo.files.sosigfiles .. file, "r")
    dst:write(yaml.tojson(src:read("*a")))
    dst:close()
    src:close()
end
print("\x1b[33mCopied sosigfiles!\x1b[0m")

-- zip:new(delidir .. modinfo.name .. ".deli", delidir .. modinfo.name .. ".deli"):add_item(delidir .. modinfo.name)

zip(delidir .. modinfo.name .. ".deli", delidir .. "manifest.json", delidir .. modinfo.name .. "/")

copyb(delidir .. modinfo.name .. ".deli", projdir .. modinfo.name .. ".deli")
remove(delidir)

print("\x1b[33mCreated deli archive!\x1b[0m")

zip(modinfo.name .. ".zip", modinfo.name)
print("\x1b[33mCreated thunderstore package!\x1b[0m")
