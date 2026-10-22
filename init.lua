-- GodField/init.lua
-- Entry point. Resolves its own base URL, loads modules in dependency order,
-- returns the GodField library table.

local GodField = {}
GodField.Version = "2.0.0"

local function resolveBase()
    local override = getgenv and getgenv().GODFIELD_BASE
    if type(override) == "string" then return override end
    local ok, path = pcall(function() return debug.info(1, "s") end)
    if ok and path and path:find("init%.lua$") then
        return (path:gsub("init%.lua$", ""))
    end
    return "GodField/"
end

local BASE = resolveBase()

local function fetch(name)
    local url = BASE .. name
    local body
    if readfile and isfile and isfile(url) then
        body = readfile(url)
    else
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or #res == 0 then error("GodField: could not load " .. name, 2) end
        body = res
    end
    local ok, mod = pcall(function() return (loadstring(body) :: any)() end)
    if not ok then error("GodField: " .. name .. " failed to load — " .. tostring(mod), 2) end
    return mod
end

local modules = {
    Util    = fetch("lib/Util.lua"),
    Signals = fetch("lib/Signals.lua"),
    Store   = fetch("lib/Store.lua"),
    Theme   = fetch("lib/Theme.lua"),
}
modules.Icons    = fetch("lib/Icons.lua")
modules.Create   = fetch("lib/Create.lua")(modules)
modules.Window   = fetch("ui/Window.lua")({ Create = modules.Create, Signals = modules.Signals, Store = modules.Store, Theme = modules.Theme, Util = modules.Util, Icons = modules.Icons })
modules.Tab      = fetch("ui/Tab.lua")({ Signals = modules.Signals, Theme = modules.Theme, Util = modules.Util, Icons = modules.Icons, Elements = fetch("elements/init.lua")(modules) })
modules.Section  = fetch("ui/Section.lua")({ Util = modules.Util })
modules.Config   = fetch("lib/Config.lua")({ Util = modules.Util, Store = modules.Store })
modules.Reporter = fetch("lib/Reporter.lua")({ Util = modules.Util })

for k, v in pairs(modules) do GodField[k] = v end

function GodField:CreateWindow(settings)
    return modules.Window.new(settings, modules)
end

return GodField