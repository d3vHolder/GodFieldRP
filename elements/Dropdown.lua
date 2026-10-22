-- GodField/elements/Dropdown.lua
-- Single or multi select. Type-to-filter inside the open list when the
-- option count exceeds 10.

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local options = opts.Options or {}
    local multiple = opts.MultipleOptions and true or false

    local current = opts.CurrentOption
    if type(current) == "string" then current = { current } end
    if current == nil then
        current = multiple and {} or { options[1] }
    end
    if not multiple then
        current = { current[1] or options[1] }
    end

    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "table" then
            current = multiple and saved or { saved[1] or options[1] }
        end
    end

    local frame = Instance.new("Frame")
    frame.Name = opts.Name
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = tab.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = t.elementStroke; s.Parent = frame

    local trigger = Instance.new("TextButton")
    trigger.Size = UDim2.new(1, 0, 0, 34)
    trigger.BackgroundTransparency = 1
    trigger.Text = ""
    trigger.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 0, 34)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local readout = Instance.new("TextLabel")
    readout.Size = UDim2.new(0, 90, 0, 34)
    readout.Position = UDim2.new(1, -100, 0, 0)
    readout.BackgroundTransparency = 1
    readout.Font = Enum.Font.Gotham
    readout.TextSize = 12
    readout.TextColor3 = t.placeholder
    readout.TextXAlignment = Enum.TextXAlignment.Right
    readout.Text = "None"
    readout.Parent = frame

    local search = Instance.new("TextBox")
    search.Size = UDim2.new(1, -20, 0, 22)
    search.Position = UDim2.fromOffset(10, 34)
    search.BackgroundColor3 = t.input
    search.TextColor3 = t.text
    search.PlaceholderColor3 = t.placeholder
    search.PlaceholderText = "Search…"
    search.Font = Enum.Font.Gotham
    search.TextSize = 11
    search.ClearTextOnFocus = false
    search.Visible = false
    search.Parent = frame
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 4); sc.Parent = search
    local ss = Instance.new("UIStroke"); ss.Color = t.inputStroke; ss.Parent = search

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -20, 0, 0)
    list.Position = UDim2.fromOffset(10, 34)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.Visible = false
    list.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = list

    local handle = { frame = frame, _enabled = true }
    local buttons = {}
    local open = false

    local function refreshReadout()
        if not multiple then
            readout.Text = current[1] or "None"
            return
        end
        if #current == 0 then readout.Text = "None"
        elseif #current == 1 then readout.Text = current[1]
        else readout.Text = "Various" end
    end

    local function fire()
        refreshReadout()
        if opts.Flag then tab.window.store:set("GodField", opts.Flag, current) end
        if opts.Callback then
            local ok, err = pcall(opts.Callback, current)
            if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
        end
        tab.window.bus:fire("element:changed", { element = handle, value = current })
    end

    local function rebuild()
        for _, b in ipairs(buttons) do b:Destroy() end
        buttons = {}
        local filter = string.lower(search.Text or "")
        local visible = 0
        for _, opt in ipairs(options) do
            if filter == "" or string.find(string.lower(opt), filter, 1, true) then
                visible += 1
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 26)
                b.BackgroundColor3 = table.find(current, opt) and t.dropdownSelected or t.dropdownUnselected
                b.BorderSizePixel = 0
                b.Font = Enum.Font.Gotham
                b.TextSize = 12
                b.TextColor3 = t.text
                b.Text = opt
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.Parent = list
                local bc2 = Instance.new("UICorner"); bc2.CornerRadius = UDim.new(0, 4); bc2.Parent = b
                b.MouseButton1Click:Connect(function()
                    if handle._enabled == false then return end
                    if not multiple then
                        current = { opt }
                        close()
                    else
                        local idx = table.find(current, opt)
                        if idx then table.remove(current, idx) else table.insert(current, opt) end
                    end
                    fire()
                    rebuild()
                end)
                table.insert(buttons, b)
            end
        end
        list.CanvasSize = UDim2.new(0, 0, 0, visible * 28)
    end

    function close()
        open = false
        search.Visible = false
        list.Visible = false
        list.Size = UDim2.new(1, -20, 0, 0)
        frame.Size = UDim2.new(1, 0, 0, 34)
    end

    function openList()
        open = true
        local big = #options > 10
        search.Visible = big
        list.Position = UDim2.fromOffset(10, big and 60 or 34)
        local visibleRows = math.min(#options, 6)
        list.Size = UDim2.new(1, -20, 0, visibleRows * 28)
        list.Visible = true
        frame.Size = UDim2.new(1, 0, 0, (big and 60 or 34) + list.Size.Y.Offset + 8)
        rebuild()
    end

    trigger.MouseButton1Click:Connect(function()
        if handle._enabled == false then return end
        if open then close() else openList() end
    end)
    search:GetPropertyChangedSignal("Text"):Connect(function()
        if open then rebuild() end
    end)

    function handle:Set(v)
        if v == nil then return end
        if type(v) == "string" then v = { v } end
        current = multiple and v or { v[1] or options[1] }
        refreshReadout()
        fire()
    end
    function handle:get() return current end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        label.TextTransparency = self._enabled and 0 or 0.5
        readout.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        for _, b in ipairs(buttons) do b:Destroy() end
        frame:Destroy()
    end

    refreshReadout()

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        s.Color = t.elementStroke
        readout.TextColor3 = t.placeholder
        search.BackgroundColor3 = t.input
        search.TextColor3 = t.text
        search.PlaceholderColor3 = t.placeholder
        ss.Color = t.inputStroke
        if open then rebuild() end
    end)

    return handle
end