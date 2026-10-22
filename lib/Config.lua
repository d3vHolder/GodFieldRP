-- GodField/lib/Config.lua
-- Named save slots. Separate from auto-config.

local Config = {}
Config.__index = Config

local HS = game:GetService("HttpService")

function Config.new(store, root)
    return setmetatable({ store = store, root = root }, Config)
end

function Config:_path(name)
    local clean = tostring(name):gsub("[/\\%c]", ""):gsub("%.%.", "")
    return self.root .. "/" .. clean .. ".json"
end

function Config:List()
    local out = {}
    if not (listfiles and isfolder and isfolder(self.root)) then return out end
    for _, f in ipairs(listfiles(self.root)) do
        local name = f:match("([^/]+)%.json$")
        if name then out[#out + 1] = name end
    end
    return out
end

function Config:Save(name)
    if not (writefile and makefolder) then return false end
    if isfolder and not isfolder(self.root) then pcall(makefolder, self.root) end
    local data = self.store._data
    local ok, encoded = pcall(function() return HS:JSONEncode(data) end)
    if not ok then return false end
    return (pcall(writefile, self:_path(name), encoded))
end

function Config:Load(name)
    if not (isfile and readfile) then return false end
    local path = self:_path(name)
    if not isfile(path) then return false end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false end
    self.store._data = data
    self.store.signals:fire("config:loaded", data)
    return true
end

function Config:Delete(name)
    if not (delfile and isfile) then return false end
    local path = self:_path(name)
    if isfile(path) then return pcall(delfile, path) end
    return false
end

return Config