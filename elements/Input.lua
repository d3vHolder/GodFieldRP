-- GodField/elements/Input.lua
-- Single-line text field. Fires Callback on focus lost or Enter.

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local frame = Instance.new("Frame")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.fromOffset(10, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 1, -28)
    box.BackgroundColor3 = t.input
    box.TextColor3 = t.text
    box.PlaceholderColor3 = t.placeholder
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Text = opts.CurrentValue or ""
    box.PlaceholderText = opts.Placeholder or ""
    box.ClearTextOnFocus = false
    box.Parent = frame

    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = box
    local bs = Instance.new("UIStroke"); bs.Color = t.inputStroke; bs.Parent = box

    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "string" then box.Text = saved end
    end

    local handle = { frame = frame, _enabled = true }

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, box.Text)
            if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
        end
        tab.window.bus:fire("element:changed", { element = handle, value = box.Text })
    end

    local lost = box.FocusLost:Connect(function(enter)
        if opts.RemoveTextAfterFocusLost then box.Text = "" end
        fire()
    end)

    function handle:Set(v) box.Text = v or "" end
    function handle:get() return box.Text end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        box.TextEditable = self._enabled
        label.TextTransparency = self._enabled and 0 or 0.5
        box.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        if lost then lost:Disconnect() end
        frame:Destroy()
    end

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        s.Color = t.elementStroke
        box.BackgroundColor3 = t.input
        box.TextColor3 = t.text
        box.PlaceholderColor3 = t.placeholder
        bs.Color = t.inputStroke
    end)

    return handle
end