-- GodField/elements/SectionTitle.lua
-- Bold divider line with text. `Set` replaces the text.

return function(tab, opts, deps)
    local text = type(opts) == "string" and opts or (opts and opts.Name) or ""
    local t = tab.window.theme.tokens

    local frame = Instance.new("Frame")
    frame.Name = "Section"
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = frame

    local handle = { frame = frame }
    function handle:Set(v) label.Text = tostring(v or "") end
    function handle:get() return label.Text end
    function handle:SetEnabled(v) label.TextTransparency = v and 0 or 0.5 end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription() end
    function handle:Destroy() frame:Destroy() end

    tab.window.bus:connect("theme:changed", function(theme)
        label.TextColor3 = theme.tokens.text
    end)

    return handle
end