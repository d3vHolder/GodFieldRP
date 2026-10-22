-- GodField/elements/ColorPicker.lua
-- Swatch + expandable HSV panel. The panel is drawn from instances; no
-- asset IDs. `Set` accepts a Color3.

return function(tab, opts, deps)
    local Util = deps.Util
    local t = tab.window.theme.tokens

    local color = opts.Color or Color3.fromRGB(255, 255, 255)
    if opts.Flag then
        local saved = tab.window.store:get("GodField", opts.Flag)
        if type(saved) == "table" and saved.R then
            color = Color3.fromRGB(saved.R, saved.G, saved.B)
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
    label.Size = UDim2.new(1, -60, 0, 34)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = opts.Name
    label.Parent = frame

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.fromOffset(40, 20)
    swatch.Position = UDim2.new(1, -50, 0.5, -10)
    swatch.BackgroundColor3 = color
    swatch.BorderSizePixel = 0
    swatch.Parent = frame
    local swc = Instance.new("UICorner"); swc.CornerRadius = UDim.new(0, 4); swc.Parent = swatch

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, -20, 0, 120)
    panel.Position = UDim2.fromOffset(10, 38)
    panel.BackgroundColor3 = t.secondary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = frame
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = panel
    local ps = Instance.new("UIStroke"); ps.Color = t.secondaryStroke; ps.Parent = panel

    -- SV pad
    local pad = Instance.new("Frame")
    pad.Size = UDim2.new(1, -20, 0, 60)
    pad.Position = UDim2.fromOffset(10, 10)
    pad.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    pad.BorderSizePixel = 0
    pad.Parent = panel
    local pdc = Instance.new("UICorner"); pdc.CornerRadius = UDim.new(0, 4); pdc.Parent = pad

    local padWhite = Instance.new("Frame")
    padWhite.Size = UDim2.fromScale(1, 1)
    padWhite.BorderSizePixel = 0
    padWhite.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    padWhite.Parent = pad
    local pwc = Instance.new("UICorner"); pwc.CornerRadius = UDim.new(0, 4); pwc.Parent = padWhite
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
    grad.Transparency = NumberSequence.new(0, 1)
    grad.Parent = padWhite

    local padBlack = Instance.new("Frame")
    padBlack.Size = UDim2.fromScale(1, 1)
    padBlack.BorderSizePixel = 0
    padBlack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    padBlack.Parent = pad
    local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 4); pbc.Parent = padBlack
    local gradB = Instance.new("UIGradient")
    gradB.Rotation = 90
    gradB.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
    gradB.Parent = padBlack

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(10, 10)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 2
    dot.Parent = pad
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot

    -- Hue strip
    local hue = Instance.new("Frame")
    hue.Size = UDim2.new(1, -20, 0, 12)
    hue.Position = UDim2.new(0, 10, 0, 78)
    hue.BorderSizePixel = 0
    hue.Parent = panel
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(1, 0); hc.Parent = hue

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
    })
    hueGrad.Parent = hue

    local hueDot = Instance.new("Frame")
    hueDot.Size = UDim2.fromOffset(10, 14)
    hueDot.AnchorPoint = Vector2.new(0.5, 0)
    hueDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hueDot.BorderSizePixel = 2
    hueDot.Parent = hue
    local hdc = Instance.new("UICorner"); hdc.CornerRadius = UDim.new(0, 3); hdc.Parent = hueDot

    local hex = Instance.new("TextBox")
    hex.Size = UDim2.fromOffset(90, 20)
    hex.Position = UDim2.new(1, -100, 0, 96)
    hex.BackgroundColor3 = t.input
    hex.TextColor3 = t.text
    hex.PlaceholderColor3 = t.placeholder
    hex.Font = Enum.Font.Gotham
    hex.TextSize = 11
    hex.Text = string.format("#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5))
    hex.ClearTextOnFocus = false
    hex.Parent = panel
    local hxc = Instance.new("UICorner"); hxc.CornerRadius = UDim.new(0, 4); hxc.Parent = hex
    local hxs = Instance.new("UIStroke"); hxs.Color = t.inputStroke; hxs.Parent = hex

    local handle = { frame = frame, _enabled = true }
    local open = false

    local function render()
        local h, sat, v = color:ToHSV()
        pad.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        padWhite.Transparency = 1 - sat
        padBlack.Transparency = 1 - v
        dot.BackgroundColor3 = color
        dot.Position = UDim2.new(sat, 0, 1 - v, 0)
        hueDot.Position = UDim2.new(h, 0, 0, 0)
        swatch.BackgroundColor3 = color
        hex.Text = string.format("#%02X%02X%02X",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5))
    end

    local function fire()
        if opts.Flag then
            tab.window.store:set("GodField", opts.Flag, { R = color.R * 255, G = color.G * 255, B = color.B * 255 })
        end
        if opts.Callback then
            local ok, err = pcall(opts.Callback, color)
            if not ok then warn("GodField | " .. opts.Name .. " callback error: " .. tostring(err)) end
        end
        tab.window.bus:fire("element:changed", { element = handle, value = color })
    end

    local UIS = game:GetService("UserInputService")
    local draggingPad, draggingHue = false, false

    local function setPad(x, y)
        local sat = math.clamp((x - pad.AbsolutePosition.X) / pad.AbsoluteSize.X, 0, 1)
        local v = 1 - math.clamp((y - pad.AbsolutePosition.Y) / pad.AbsoluteSize.Y, 0, 1)
        local h = select(1, color:ToHSV())
        color = Color3.fromHSV(h, sat, v)
        render()
        fire()
    end
    local function setHue(x)
        local h = math.clamp((x - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
        local _, sat, v = color:ToHSV()
        color = Color3.fromHSV(h, sat, v)
        render()
        fire()
    end

    pad.InputBegan:Connect(function(input)
        if handle._enabled == false then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingPad = true
            setPad(input.Position.X, input.Position.Y)
        end
    end)
    hue.InputBegan:Connect(function(input)
        if handle._enabled == false then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            setHue(input.Position.X)
        end
    end)
    local inputMoved = UIS.InputChanged:Connect(function(input)
        if draggingPad and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setPad(input.Position.X, input.Position.Y)
        elseif draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setHue(input.Position.X)
        end
    end)
    local inputEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingPad, draggingHue = false, false
        end
    end)

    local hexLost = hex.FocusLost:Connect(function()
        local r, g, b = string.match(hex.Text or "", "^#?(%x%x)(%x%x)(%x%x)$")
        if r then
            color = Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
            render()
            fire()
        else
            render()
        end
    end)

    trigger.MouseButton1Click:Connect(function()
        if handle._enabled == false then return end
        open = not open
        panel.Visible = open
        frame.Size = UDim2.new(1, 0, 0, open and 172 or 34)
    end)

    function handle:Set(c)
        if typeof(c) ~= "Color3" then return end
        color = c
        render()
        fire()
    end
    function handle:get() return color end

    function handle:SetEnabled(v)
        self._enabled = v and true or false
        label.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab:_setDescription(frame, text) end

    function handle:Destroy()
        inputMoved:Disconnect()
        inputEnded:Disconnect()
        if hexLost then hexLost:Disconnect() end
        frame:Destroy()
    end

    render()

    tab.window.bus:connect("theme:changed", function(theme)
        t = theme.tokens
        frame.BackgroundColor3 = t.element
        label.TextColor3 = t.text
        s.Color = t.elementStroke
        panel.BackgroundColor3 = t.secondary
        ps.Color = t.secondaryStroke
        hex.BackgroundColor3 = t.input
        hex.TextColor3 = t.text
        hxs.Color = t.inputStroke
    end)

    return handle
end