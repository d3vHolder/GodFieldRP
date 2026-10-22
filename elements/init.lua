-- GodField/elements/init.lua
-- Registry. Lazy-loads each element module on first use so a hub that only
-- creates toggles never pays for ColorPicker.
--
-- Every module exports: function(tab, opts, deps) -> handle
--   handle.frame    : the root frame (set by Tab before parenting)
--   handle:Set(v)   : programmatic update, fires Callback
--   handle:get()    : current value, used by Store on config flush
--   handle:Destroy(): removes frame, disconnects listeners
--
-- The caller passes `deps = { Util, Theme, Icons, Signals }`.

local Elements = {}

local MODULES = {
    Button       = "elements/Button.lua",
    Toggle       = "elements/Toggle.lua",
    Slider       = "elements/Slider.lua",
    Input        = "elements/Input.lua",
    Keybind      = "elements/Keybind.lua",
    Dropdown     = "elements/Dropdown.lua",
    ColorPicker  = "elements/ColorPicker.lua",
    Label        = "elements/Label.lua",
    Paragraph    = "elements/Paragraph.lua",
    SectionTitle = "elements/SectionTitle.lua",
    Divider      = "elements/Divider.lua",
}

local _cache = {}
local _base

function Elements.bind(base)
    _base = base
end

local function load(name)
    if _cache[name] then return _cache[name] end
    local path = MODULES[name]
    if not path then error("GodField.Elements: unknown element " .. name, 2) end
    local url = (_base or "") .. path
    local body
    if readfile and isfile and isfile(url) then
        body = readfile(url)
    else
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or #res == 0 then error("GodField.Elements: cannot load " .. path, 2) end
        body = res
    end
    local ok, mod = pcall(function() return (loadstring(body) :: any)() end)
    if not ok then error("GodField.Elements: " .. path .. " failed — " .. tostring(mod), 2) end
    _cache[name] = mod
    return mod
end

function Elements.create(name, tab, opts, deps)
    return load(name)(tab, opts, deps)
end

return Elements