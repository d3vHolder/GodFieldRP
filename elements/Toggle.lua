-- GodField/elements/Toggle.lua
-- Boolean switch. Draws label + rounded track + thumb. Value persists via
-- Flag if the caller passed one.

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local frame = Instance.new("TextButton")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 20)
    track.Position = UDim2.new(1, -50, 0.5, -10)
    track.BackgroundColor3 = t.toggleOff
    track.BorderSizePixel = 0
    track.Parent = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(16, 16)
    thumb.Position = UDim2.fromOffset(2, 2)
    thumb.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    local thc = Instance.new("UICorner"); thc.CornerRadius = UDim.new(1, 0); thc.Parent = thumb

    local value = opts.CurrentValue and true or false
    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "boolean" then value = saved end
    end

    local handle = { frame = frame, _enabled = true }

    local function render()
        track.BackgroundColor3 = value and t.toggleOn or t.toggleOff
        Util.tweenPlay(thumb, {
            Position = value and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2)
        }, 0.15)
    end

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, value)
            if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
        end
        tab.window.bus:fire("element:changed", { element = handle, value = value })
    end

    function handle:Set(v)
        value = v and true or false
        render()
        fire()
    end
    function handle:get() return value end

    local click
    click = frame.MouseButton1Click:Connect(function()
        if handle._enabled == false then return end
        value = not value
        render()
        fire()
    end)

    frame.MouseEnter:Connect(function() if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = t.elementHover }, 0.15) end end)
    frame.MouseLeave:Connect(function() if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = t.element }, 0.15) end end)

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        frame.Active = self._enabled
        frame.TextTransparency = self._enabled and 0 or 0.5
        label.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        if click then click:Disconnect() end
        frame:Destroy()
    end

    render()

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        s.Color = t.elementStroke
        render()
    end)

    return handle
end