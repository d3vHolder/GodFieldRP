-- GodField/elements/Paragraph.lua
-- Title + body block. Opts: { Title, Content }. `Set` overwrites Content.

return function(tab, opts, deps)
    opts = opts or {}
    local t = tab.window.theme.tokens

    local frame = Instance.new("Frame")
    frame.Name = "Paragraph"
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = t.secondary
    frame.BorderSizePixel = 0
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.secondaryStroke; s.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 18)
    title.Position = UDim2.fromOffset(10, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 12
    title.TextColor3 = t.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = opts.Title or ""
    title.Parent = frame

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -20, 0, 22)
    content.Position = UDim2.fromOffset(10, 22)
    content.BackgroundTransparency = 1
    content.Font = Enum.Font.Gotham
    content.TextSize = 11
    content.TextColor3 = t.placeholder
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextWrapped = true
    content.Text = opts.Content or ""
    content.Parent = frame

    local handle = { frame = frame }
    function handle:Set(v) content.Text = tostring(v or "") end
    function handle:get() return content.Text end
    function handle:SetEnabled(v)
        title.TextTransparency = v and 0 or 0.5
        content.TextTransparency = v and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(txt) tab:_setDescription(frame, txt) end
    function handle:Destroy() frame:Destroy() end

    tab.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.secondary
        s.Color = tk.secondaryStroke
        title.TextColor3 = tk.text
        content.TextColor3 = tk.placeholder
    end)

    return handle
end