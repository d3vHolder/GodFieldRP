-- GodField/ui/Window.lua
local Window = {}
Window.__index = Window

return function(deps)
    function Window.new(settings, modules)
        -- Create the raw window base (no tabs yet)
        local raw = deps.Create:Window(settings, modules)

        -- Expose the full dependency table on the window so Tab can reach it
        raw._deps = modules

        -- Attach CreateTab
        function raw:CreateTab(name, icon, ext)
            local tab = deps.Tab.new(self, name, icon, ext)
            self.tabs[#self.tabs + 1] = tab
            return tab
        end

        -- Attach config manager if not already on the raw window
        if not raw.CreateConfigManager then
            function raw:CreateConfigManager()
                return modules.Config.new(self.store, "GodField/Configs/" .. (self.settings.Name or "Default"))
            end
        end

        return raw
    end

    return Window
end
