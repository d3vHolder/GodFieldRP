-- GodField/init.lua
-- Entry point. Resolves base URL, loads modules in dependency order.

local GodField = {}
GodField.Version = "2.0.0"

local function resolveBase()
    local override = getgenv and getgenv().GODFIELD_BASE
    if type(override) == "string" then return override end

    local ok, path = pcall(function() return debug.info(1, "s") end)
    if ok and path and path:find("init%.lua") then
        local base = path:gsub("init%.lua.*$", "")
        if base ~= "" then return base end
    end

    return "https://raw.githubusercontent.com/d3vHolder/GodFieldRP/main/"
end

local BASE = resolveBase()

local function fetch(name)
    local url = BASE .. name
    local body
    if readfile and isfile and isfile(url) then
        body = readfile(url)
    else
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or #res == 0 then 
            error("GodField: could not load " .. name .. " from " .. url, 2) 
        end
        body = res
    end
    local ok, mod = pcall(function() return (loadstring(body) :: any)() end)
    if not ok then 
        error("GodField: " .. name .. " failed to load — " .. tostring(mod), 2) 
    end
    return mod
end

-- 1. Load core logic
local modules = {
    Util    = fetch("lib/Util.lua"),
    Signals = fetch("lib/Signals.lua"),
    Store   = fetch("lib/Store.lua"),
    Theme   = fetch("lib/Theme.lua"),
    Icons   = fetch("lib/Icons.lua"),
}

-- 2. Load Elements (returns a table with .create and .bind)
modules.Elements = fetch("elements/init.lua")
pcall(function() modules.Elements.bind(BASE) end)

-- 3. Load Create. It expects the `modules` table to exist so it can pull
-- Util, Theme, Signals, Store out of it.
modules.Create = fetch("lib/Create.lua")(modules)

-- 4. Load Tab. Tab needs Elements, Theme, Util, etc. 
-- (We pass these explicitly so Tab knows where to find them).
modules.Tab = fetch("ui/Tab.lua")({
    Signals  = modules.Signals,
    Theme    = modules.Theme,
    Util     = modules.Util,
    Icons    = modules.Icons,
    Elements = modules.Elements,
})

-- 5. Load Window. It wraps Create and Tab.
modules.Window = fetch("ui/Window.lua")({
    Create   = modules.Create,
    Tab      = modules.Tab,
    Signals  = modules.Signals,
    Store    = modules.Store,
    Theme    = modules.Theme,
    Util     = modules.Util,
    Icons    = modules.Icons,
    Elements = modules.Elements,
})

-- 6. Remaining modules
modules.Section  = fetch("ui/Section.lua")({})
modules.Config   = fetch("lib/Config.lua")({ Util = modules.Util, Store = modules.Store })
modules.Reporter = fetch("lib/Reporter.lua")({ Util = modules.Util })

for k, v in pairs(modules) do GodField[k] = v end

function GodField:CreateWindow(settings)
    return modules.Window.new(settings, modules)
end

return GodField
