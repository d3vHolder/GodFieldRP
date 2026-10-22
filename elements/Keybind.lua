-- GodField/elements/Keybind.lua
-- Key capture + trigger. Two callback modes:
--   HoldToInteract = false : Callback(keyName) on keydown
--   HoldToInteract = true  : Callback(true) on down, Callback(false) on up

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local frame = Instance.new("Frame")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(60, 24)
    box.Position = UDim2.new(1, -70, 0.5, -12)
    box.BackgroundColor3 = t.input
    box.TextColor3 = t.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Text = opts.CurrentKeybind or "K"
    box.ClearTextOnFocus = false
    box.TextEditable = false
    box.Parent = frame

    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = box
    local bs = Instance.new("UIStroke"); bs.Color = t.inputStroke; bs.Parent = box

    local currentKey = opts.CurrentKeybind or "K"
    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "string" then currentKey = saved; box.Text = saved end
    end

    local handle = { frame = frame, _enabled = true, _held = false }
    local UIS = game:GetService("UserInputService")

    local function fire(value)
        if handle._enabled == false then return end
        if not opts.Callback then return end
        local ok, err = pcall(opts.Callback, value)
        if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
    end

    -- Key capture. While the box is focused, the next keydown becomes the
    -- current keybind and the box releases focus.
    local captureConn
    local focused = box.Focused:Connect(function()
        box.Text = "…"
        captureConn = UIS.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Unknown then return end
            currentKey = input.KeyCode.Name
            box.Text = currentKey
            box:ReleaseFocus()
            if captureConn then captureConn:Disconnect(); captureConn = nil end
            if opts.Flag then tab.window.store:set("GodField", opts.Flag, currentKey) end
            fire(currentKey)
        end)
    end)

    -- Trigger. Matches on KeyCode name so a rebind takes effect immediately.
    local down = UIS.InputBegan:Connect(function(input, processed)
        if handle._enabled == false then return end
        if processed then return end
        if input.KeyCode.Name ~= currentKey then return end
        if opts.HoldToInteract then
            if handle._held then return end
            handle._held = true
            fire(true)
        else
            fire(currentKey)
        end
    end)
    local up = UIS.InputEnded:Connect(function(input)
        if not opts.HoldToInteract then return end
        if input.KeyCode.Name ~= currentKey then return end
        if not handle._held then return end
        handle._held = false
        fire(false)
    end)

    function handle:Set(k)
        if type(k) ~= "string" or k == "" then return end
        currentKey = k
        box.Text = k
        if opts.Flag then tab.window.store:set("GodField", opts.Flag, k) end
    end
    function handle:get() return currentKey end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        label.TextTransparency = self._enabled and 0 or 0.5
        box.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        if focused then focused:Disconnect() end
        if captureConn then captureConn:Disconnect() end
        down:Disconnect()
        up:Disconnect()
        frame:Destroy()
    end

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        s.Color = t.elementStroke
        box.BackgroundColor3 = t.input
        box.TextColor3 = t.text
        bs.Color = t.inputStroke
    end)

    return handle
end