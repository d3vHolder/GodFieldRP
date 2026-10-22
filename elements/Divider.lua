-- GodField/elements/Divider.lua
-- One-pixel horizontal rule. No value.

return function(tab, opts, deps)
    local t = tab.window.theme.tokens

    local frame = Instance.new("Frame")
    frame.Name = "Divider"
    frame.Size = UDim2.new(1, 0, 0, 1)
    frame.BackgroundColor3 = t.elementStroke
    frame.BorderSizePixel = 0
    frame.Parent = tab.page

    local handle = { frame = frame }
    function handle:Set() end
    function handle:get() return nil end
    function handle:SetEnabled() end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription() end
    function handle:Destroy() frame:Destroy() end

    tab.window.bus:connect("theme:changed", function(theme)
        frame.BackgroundColor3 = theme.tokens.elementStroke
    end)

    return handle
end