-- GodField/elements/Slider.lua
-- Numeric slider. Snaps to Increment on drag and on :Set. Tracks pointer
-- via UserInputService, not a per-frame RenderStepped loop.

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local range = opts.Range or { 0, 100 }
    local inc = opts.Increment or 1
    local value = math.clamp(opts.CurrentValue or range[1], range[1], range[2])

    local frame = Instance.new("Frame")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 0, 20)
    label.Position = UDim2.fromOffset(10, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local readout = Instance.new("TextLabel")
    readout.Size = UDim2.new(0, 70, 0, 20)
    readout.Position = UDim2.new(1, -80, 0, 4)
    readout.BackgroundTransparency = 1
    readout.Font = Enum.Font.Gotham
    readout.TextSize = 12
    readout.TextColor3 = t.placeholder
    readout.TextXAlignment = Enum.TextXAlignment.Right
    readout.Text = tostring(value) .. (opts.Suffix and (" " .. opts.Suffix) or "")
    readout.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 1, -14)
    track.BackgroundColor3 = t.secondary
    track.BorderSizePixel = 0
    track.Parent = frame
    local tkc = Instance.new("UICorner"); tkc.CornerRadius = UDim.new(1, 0); tkc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - range[1]) / (range[2] - range[1]), 0, 1, 0)
    fill.BackgroundColor3 = t.sliderProgress
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    local handle = { frame = frame, _enabled = true }

    local function round(v)
        return range[1] + math.floor(((v - range[1]) / inc) + 0.5) * inc
    end

    local function render()
        local pct = (value - range[1]) / (range[2] - range[1])
        fill.Size = UDim2.new(pct, 0, 1, 0)
        readout.Text = tostring(value) .. (opts.Suffix and (" " .. opts.Suffix) or "")
    end

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, value)
            if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
        end
        tab.window.bus:fire("element:changed", { element = handle, value = value })
    end

    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = range[1] + rel * (range[2] - range[1])
        local next_ = math.clamp(round(raw), range[1], range[2])
        if next_ == value then return end
        value = next_
        render()
        fire()
    end

    local UIS = game:GetService("UserInputService")
    local dragging = false
    local trackBegan = track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if handle._enabled == false then return end
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    local inputMoved = UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    local inputEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    function handle:Set(v)
        v = math.clamp(round(v or range[1]), range[1], range[2])
        if v == value then return end
        value = v
        render()
        fire()
    end
    function handle:get() return value end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        frame.Active = self._enabled
        label.TextTransparency = self._enabled and 0 or 0.5
        readout.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        trackBegan:Disconnect()
        inputMoved:Disconnect()
        inputEnded:Disconnect()
        frame:Destroy()
    end

    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "number" then value = math.clamp(round(saved), range[1], range[2]) end
    end

    render()

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        readout.TextColor3 = t.placeholder
        s.Color = t.elementStroke
        track.BackgroundColor3 = t.secondary
        fill.BackgroundColor3 = t.sliderProgress
    end)

    return handle
end