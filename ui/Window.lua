-- GodField/ui/Window.lua
local Window = {}
Window.__index = Window

return function(deps)
    function Window.new(settings, modules)
        local raw = deps.Create:Window(settings, modules)

        -- Tab construction
        function raw:CreateTab(name, icon, ext)
            local tab = deps.Tab.new(self, name, icon, ext)
            self.tabs[#self.tabs + 1] = tab
            return tab
        end

        -- Config manager
        function raw:CreateConfigManager()
            return modules.Config.new(self.store, "GodField/Configs/" .. (self.settings.Name or "Default"))
        end

        -- Manual config control
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
end
