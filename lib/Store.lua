-- GodField/lib/Store.lua
local Store = {}
Store.__index = Store

local VERSION = 1
local ROOT    = "GodField"
local HS      = game:GetService("HttpService")

local function sanitizeFolder(v)
    local text = string.gsub(string.gsub(tostring(v), "\\", "/"), "[:%c]", "")
    local prev
    repeat prev = text; text = string.gsub(text, "%.%.", "") until text == prev
    text = string.gsub(text, "/+", "/")
    return (string.gsub(text, "^/+", ""))
end

local function ensureFolder(p)
    if isfolder and not isfolder(p) then pcall(makefolder, p) end
end

function Store.new(signals)
    return setmetatable({
        signals    = signals,
        _data      = { __version = VERSION },
        _overrides = {},
        _flags     = {},
        _root      = ROOT,
    }, Store)
end

function Store:setRoot(name)
    local clean = sanitizeFolder(name)
    if clean ~= "" then self._root = clean end
end

function Store:load()
    if not (isfile and readfile) then return end
    local path = self._root .. "/settings.json"
    if not isfile(path) then return end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return end
    if data.__version == nil then data.__version = 1 end
    if data.__version > VERSION then
        warn("GodField.Store: saved config schema " .. data.__version .. " > runtime " .. VERSION)
    end
    self._data = data
    self.signals:fire("config:loaded", self._data)
end

function Store:save()
    if not (writefile and makefolder and isfolder) then return end
    ensureFolder(self._root)
    local ok, encoded = pcall(function() return HS:JSONEncode(self._data) end)
    if ok and encoded then pcall(writefile, self._root .. "/settings.json", encoded) end
end

function Store:get(scope, name)
    local key = scope .. "." .. name
    if self._overrides[key] ~= nil then return self._overrides[key] end
    local row = self._data[scope]
    return row and row[name]
end

function Store:set(scope, name, value)
    self._overrides[scope .. "." .. name] = nil
    if self._data[scope] == nil then self._data[scope] = {} end
    self._data[scope][name] = value
    self.signals:fire("setting:changed", { scope = scope, name = name, value = value })
end

function Store:override(scope, name, value)
    self._overrides[scope .. "." .. name] = value
    self.signals:fire("setting:changed", { scope = scope, name = name, value = value, overridden = true })
end

function Store:registerFlag(flag, handle) self._flags[flag] = handle end
function Store:getFlag(flag) return self._flags[flag] end

function Store:flushFlags()
    for flag, handle in pairs(self._flags) do
        local ok, val = pcall(function() return handle:get() end)
        if ok and val ~= nil then
            local scope, name = flag:match("^([^%.]+)%.(.+)$")
            if scope then self:set(scope, name, val) end
        end
    end
    self:save()
end

return Store