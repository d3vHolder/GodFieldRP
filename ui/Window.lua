-- GodField/ui/Window.lua
local Window = {}
Window.__index = Window

function Window.new(settings, modules)
    local raw = modules.Create:Window(settings, modules)
    local tabs = {}
    local groups = {}

    function raw:CreateTab(name, icon, ext)
        local tab = modules.Tab.new(self, name, icon, ext)
        tabs[#tabs + 1] = tab
        return tab
    end

    function raw:CreateTabGroup(name)
        local g = { Name = name, Tabs = {} }
        groups[#groups + 1] = g
        return g
    end

    function raw:CreateConfigManager()
        return modules.Config.new(self.store, "GodField/Configs/" .. (self.settings.Name or "Default"))
    end

    function raw:LoadConfiguration()
        self.store:load()
        self.store:flushFlags()
    end

    function raw:SaveConfiguration()
        self.store:flushFlags()
    end

    return raw
end

return Window