-- GodField/elements/Button.lua
-- Push button. No value; fires Callback on click. `Set` changes the label.

return function(tab, opts, deps)
    local Util, Theme = deps.Util, deps.Theme
    local t = tab.window.theme.tokens

    local frame = Instance.new("TextButton")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Font = Enum.Font.GothamSemibold
    frame.TextSize = 13
    frame.TextColor3 = t.text
    frame.Text = opts.Name
    frame.AutoButtonColor = false
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local handle = { frame = frame, _enabled = true }
    local conn

    local function run()
        if handle._enabled == false then return end
        if not opts.Callback then return end
        local ok, err = pcall(opts.Callback)
        if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
    end

    local function enter() if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = t.elementHover }, 0.15) end end
    local function leave() if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = t.element }, 0.15) end end

    frame.MouseEnter:Connect(enter)
    frame.MouseLeave:Connect(leave)
    conn = frame.MouseButton1Click:Connect(run)

    function handle:Set(label)
        frame.Text = label
        frame.Name = label
    end

    function handle:get() return frame.Text end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        frame.Active = self._enabled
        frame.TextTransparency = self._enabled and 0 or 0.5
    end

    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        if conn then conn:Disconnect() end
        frame:Destroy()
    end

    tab.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        frame.TextColor3 = tk.text
        s.Color = tk.elementStroke
    end)

    return handle
end