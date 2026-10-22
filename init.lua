-- GodField/init.lua
-- Monolithic build: every module, every element, every utility in one file.
-- No fetches for lib/, ui/, or elements/. This file is entirely self-contained.

local GodField = { Version = "3.0.0" }

-- ═══════════════════════════════════════════════════════════════════
-- 1. UTIL
-- ═══════════════════════════════════════════════════════════════════
local Util = {}
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

function Util.tween(inst, props, dur, style, dir)
    return TweenService:Create(
        inst,
        TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Exponential, dir or Enum.EasingDirection.Out),
        props
    )
end

function Util.tweenPlay(inst, props, dur, style, dir)
    local t = Util.tween(inst, props, dur, style, dir)
    t:Play()
    return t
end

function Util.sanitizeFolder(v)
    local text = string.gsub(string.gsub(tostring(v), "\\", "/"), "[:%c]", "")
    local prev
    repeat prev = text; text = string.gsub(text, "%.%.", "") until text == prev
    text = string.gsub(text, "/+", "/")
    return (string.gsub(text, "^/+", ""))
end

function Util.encode(t)
    local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
    return ok and s or nil
end

function Util.decode(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    return ok and t or nil
end

-- ═══════════════════════════════════════════════════════════════════
-- 2. SIGNALS
-- ═══════════════════════════════════════════════════════════════════
local Signals = {}
Signals.__index = Signals
local Signal = {}
Signal.__index = Signal

function Signals.new()
    return setmetatable({ _signals = {}, _conns = {} }, Signals)
end

function Signals:define(name)
    local s = setmetatable({ _handlers = {}, _next = 0 }, Signal)
    self._signals[name] = s
    return s
end

function Signals:fire(name, ...)
    local s = self._signals[name]
    if not s then return 0 end
    return s:_fire(...)
end

function Signals:connect(name, fn)
    local s = self._signals[name]
    if not s then error("GodField.Signals: unknown signal " .. name, 2) end
    local handle = s:_connect(fn)
    table.insert(self._conns, handle)
    return handle
end

function Signals:sweep()
    for _, c in ipairs(self._conns) do pcall(c.Disconnect, c) end
    table.clear(self._conns)
end

function Signal:_connect(fn)
    self._next += 1
    local id = self._next
    self._handlers[id] = fn
    return { Disconnect = function() self._handlers[id] = nil end }
end

function Signal:_fire(...)
    local args = { ... }
    local n = 0
    for _, fn in pairs(self._handlers) do
        n += 1
        local ok, err = pcall(fn, table.unpack(args))
        if not ok then warn("GodField.Signal | handler error: " .. tostring(err)) end
    end
    return n
end

-- ═══════════════════════════════════════════════════════════════════
-- 3. STORE
-- ═══════════════════════════════════════════════════════════════════
local Store = {}
Store.__index = Store
local VERSION = 1
local ROOT = "GodField"

function Store.new(signals)
    return setmetatable({
        signals = signals,
        _data = { __version = VERSION },
        _overrides = {},
        _flags = {},
        _root = ROOT,
    }, Store)
end

function Store:setRoot(name)
    local clean = Util.sanitizeFolder(name)
    if clean ~= "" then self._root = clean end
end

function Store:load()
    if not (isfile and readfile) then return end
    local path = self._root .. "/settings.json"
    if not isfile(path) then return end
    local data = Util.decode(readfile(path))
    if type(data) ~= "table" then return end
    if data.__version == nil then data.__version = 1 end
    self._data = data
    self.signals:fire("config:loaded", self._data)
end

function Store:save()
    if not (writefile and makefolder and isfolder) then return end
    if not isfolder(self._root) then pcall(makefolder, self._root) end
    local encoded = Util.encode(self._data)
    if encoded then pcall(writefile, self._root .. "/settings.json", encoded) end
end

function Store:get(scope, name)
    local key = scope .. "." .. name
    if self._overrides[key] ~= nil then return self._overrides[key] end
    local row = self._data[scope]
    return row and row[name]
end

function Store:set(scope, name, value)
    self._overrides[scope .. "." .. name] = nil
    if self._data[scope] == nil then self._data[scope] = {} end
    self._data[scope][name] = value
    self.signals:fire("setting:changed", { scope = scope, name = name, value = value })
end

function Store:registerFlag(flag, handle) self._flags[flag] = handle end
function Store:flushFlags()
    for flag, handle in pairs(self._flags) do
        local ok, val = pcall(function() return handle:get() end)
        if ok and val ~= nil then
            local scope, name = flag:match("^([^%.]+)%.(.+)$")
            if scope then self:set(scope, name, val) end
        end
    end
    self:save()
end

-- ═══════════════════════════════════════════════════════════════════
-- 4. THEME
-- ═══════════════════════════════════════════════════════════════════
local Theme = {}
Theme.Default = {
    name = "Default",
    tokens = {
        text             = Color3.fromRGB(240, 240, 240),
        background       = Color3.fromRGB(25, 25, 25),
        topbar           = Color3.fromRGB(34, 34, 34),
        shadow           = Color3.fromRGB(20, 20, 20),
        tabBackground    = Color3.fromRGB(80, 80, 80),
        tabStroke        = Color3.fromRGB(85, 85, 85),
        tabSelected      = Color3.fromRGB(210, 210, 210),
        tabText          = Color3.fromRGB(240, 240, 240),
        tabTextSelected  = Color3.fromRGB(50, 50, 50),
        element          = Color3.fromRGB(35, 35, 35),
        elementHover     = Color3.fromRGB(40, 40, 40),
        elementStroke    = Color3.fromRGB(50, 50, 50),
        secondary        = Color3.fromRGB(25, 25, 25),
        secondaryStroke  = Color3.fromRGB(40, 40, 40),
        input            = Color3.fromRGB(30, 30, 30),
        inputStroke      = Color3.fromRGB(65, 65, 65),
        slider           = Color3.fromRGB(50, 138, 220),
        sliderProgress   = Color3.fromRGB(50, 138, 220),
        toggleOn         = Color3.fromRGB(0, 146, 214),
        toggleOff        = Color3.fromRGB(100, 100, 100),
        dropdownSelected   = Color3.fromRGB(40, 40, 40),
        dropdownUnselected = Color3.fromRGB(30, 30, 30),
        placeholder      = Color3.fromRGB(178, 178, 178),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(50, 138, 220),
    },
}
Theme.Ocean = {
    name = "Ocean",
    tokens = {
        text             = Color3.fromRGB(230, 240, 240),
        background       = Color3.fromRGB(20, 30, 30),
        topbar           = Color3.fromRGB(25, 40, 40),
        shadow           = Color3.fromRGB(15, 20, 20),
        tabBackground    = Color3.fromRGB(40, 60, 60),
        tabStroke        = Color3.fromRGB(50, 70, 70),
        tabSelected      = Color3.fromRGB(100, 180, 180),
        tabText          = Color3.fromRGB(210, 230, 230),
        tabTextSelected  = Color3.fromRGB(20, 50, 50),
        element          = Color3.fromRGB(30, 50, 50),
        elementHover     = Color3.fromRGB(40, 60, 60),
        elementStroke    = Color3.fromRGB(45, 70, 70),
        secondary        = Color3.fromRGB(30, 45, 45),
        secondaryStroke  = Color3.fromRGB(40, 65, 65),
        input            = Color3.fromRGB(30, 50, 50),
        inputStroke      = Color3.fromRGB(50, 70, 70),
        slider           = Color3.fromRGB(0, 110, 110),
        sliderProgress   = Color3.fromRGB(0, 140, 140),
        toggleOn         = Color3.fromRGB(0, 130, 130),
        toggleOff        = Color3.fromRGB(70, 90, 90),
        dropdownSelected   = Color3.fromRGB(30, 60, 60),
        dropdownUnselected = Color3.fromRGB(25, 40, 40),
        placeholder      = Color3.fromRGB(140, 160, 160),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(0, 140, 140),
    },
}
Theme.Amethyst = {
    name = "Amethyst",
    tokens = {
        text             = Color3.fromRGB(240, 240, 240),
        background       = Color3.fromRGB(30, 20, 40),
        topbar           = Color3.fromRGB(40, 25, 50),
        shadow           = Color3.fromRGB(20, 15, 30),
        tabBackground    = Color3.fromRGB(60, 40, 80),
        tabStroke        = Color3.fromRGB(70, 45, 90),
        tabSelected      = Color3.fromRGB(180, 140, 200),
        tabText          = Color3.fromRGB(230, 230, 240),
        tabTextSelected  = Color3.fromRGB(50, 20, 50),
        element          = Color3.fromRGB(45, 30, 60),
        elementHover     = Color3.fromRGB(50, 35, 70),
        elementStroke    = Color3.fromRGB(70, 50, 85),
        secondary        = Color3.fromRGB(40, 30, 55),
        secondaryStroke  = Color3.fromRGB(65, 45, 80),
        input            = Color3.fromRGB(45, 30, 60),
        inputStroke      = Color3.fromRGB(80, 50, 110),
        slider           = Color3.fromRGB(100, 60, 150),
        sliderProgress   = Color3.fromRGB(130, 80, 180),
        toggleOn         = Color3.fromRGB(120, 60, 150),
        toggleOff        = Color3.fromRGB(94, 47, 117),
        dropdownSelected   = Color3.fromRGB(50, 35, 70),
        dropdownUnselected = Color3.fromRGB(35, 25, 50),
        placeholder      = Color3.fromRGB(178, 150, 200),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(130, 80, 180),
    },
}
Theme.Light = {
    name = "Light",
    tokens = {
        text             = Color3.fromRGB(40, 40, 40),
        background       = Color3.fromRGB(245, 245, 245),
        topbar           = Color3.fromRGB(230, 230, 230),
        shadow           = Color3.fromRGB(200, 200, 200),
        tabBackground    = Color3.fromRGB(235, 235, 235),
        tabStroke        = Color3.fromRGB(215, 215, 215),
        tabSelected      = Color3.fromRGB(255, 255, 255),
        tabText          = Color3.fromRGB(80, 80, 80),
        tabTextSelected  = Color3.fromRGB(0, 0, 0),
        element          = Color3.fromRGB(240, 240, 240),
        elementHover     = Color3.fromRGB(225, 225, 225),
        elementStroke    = Color3.fromRGB(210, 210, 210),
        secondary        = Color3.fromRGB(235, 235, 235),
        secondaryStroke  = Color3.fromRGB(210, 210, 210),
        input            = Color3.fromRGB(240, 240, 240),
        inputStroke      = Color3.fromRGB(180, 180, 180),
        slider           = Color3.fromRGB(150, 180, 220),
        sliderProgress   = Color3.fromRGB(100, 150, 200),
        toggleOn         = Color3.fromRGB(0, 146, 214),
        toggleOff        = Color3.fromRGB(150, 150, 150),
        dropdownSelected   = Color3.fromRGB(230, 230, 230),
        dropdownUnselected = Color3.fromRGB(220, 220, 220),
        placeholder      = Color3.fromRGB(140, 140, 140),
        modalOverlay     = Color3.fromRGB(0, 0, 0),
        progressFill     = Color3.fromRGB(100, 150, 200),
    },
}
function Theme:get(name)
    if type(name) == "table" then return name end
    return Theme[name] or Theme.Default
end

-- ═══════════════════════════════════════════════════════════════════
-- 5. TAB (ELEMENTS)
-- ═══════════════════════════════════════════════════════════════════
local Tab = {}
Tab.__index = Tab

function Tab.new(window, name, icon, ext)
    local self = setmetatable({
        window = window, name = name, icon = icon, ext = ext,
        elements = {}, sections = {}, _descriptions = {}, _search = nil, _searchQuery = "",
    }, Tab)

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = window.theme.tokens.tabBackground
    btn.BackgroundTransparency = 0.6
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = window.theme.tokens.tabText
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = "  " .. name
    btn.AutoButtonColor = false
    btn.Visible = not ext
    btn.Parent = window.tabstrip

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = window.theme.tokens.elementStroke
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = not ext
    page.Parent = window.pages

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.PaddingRight  = UDim.new(0, 4)
    pad.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    self.btn = btn
    self.page = page

    btn.MouseButton1Click:Connect(function()
        self.window.pager:JumpTo(page)
        self:_syncButtonState()
        self.window.bus:fire("tab:changed", name)
    end)

    self:_applyTheme()
    self.window.bus:connect("theme:changed", function(theme)
        self.window.theme = theme
        self:_applyTheme()
    end)

    return self
end

function Tab:_syncButtonState()
    local tokens = self.window.theme.tokens
    local active = self.window.pager.CurrentPage == self.page
    for _, child in ipairs(self.window.tabstrip:GetChildren()) do
        if child:IsA("TextButton") then
            if child == self.btn and active then
                child.BackgroundTransparency = 0
                child.TextColor3 = tokens.tabTextSelected
            elseif child == self.btn then
                child.BackgroundTransparency = 0.6
                child.TextColor3 = tokens.tabText
            else
                child.BackgroundTransparency = 0.6
                child.TextColor3 = tokens.tabText
            end
        end
    end
end

function Tab:_applyTheme()
    local t = self.window.theme.tokens
    self.btn.BackgroundColor3 = t.tabBackground
    self.page.ScrollBarImageColor3 = t.elementStroke
    if self.window.pager.CurrentPage == self.page then
        self.btn.TextColor3 = t.tabTextSelected
        self.btn.BackgroundTransparency = 0
    else
        self.btn.TextColor3 = t.tabText
        self.btn.BackgroundTransparency = 0.6
    end
end

function Tab:_setDescription(frame, text)
    local d = self._descriptions[frame]
    if not d then
        d = Instance.new("TextLabel")
        d.Name = "Description"
        d.Size = UDim2.new(1, -20, 0, 14)
        d.Position = UDim2.new(0, 10, 1, 4)
        d.BackgroundTransparency = 1
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextColor3 = self.window.theme.tokens.placeholder
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Visible = false
        d.Parent = frame
        self._descriptions[frame] = d
        frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, frame.Size.Y.Offset + 16)
    end
    local hasText = text ~= nil and text ~= ""
    d.Text = text or ""
    d.Visible = hasText
end

function Tab:_register(handle)
    table.insert(self.elements, handle)
    handle.frame.Parent = self.page
    if self._searchQuery ~= "" then
        handle:SetVisible(self:_matches(self._searchQuery, handle.frame))
    end
    return handle
end

function Tab:_matches(query, frame)
    if query == "" then return true end
    return string.find(string.lower(frame.Name or ""), query, 1, true) ~= nil
end

function Tab:CreateSearch()
    if self._search then return self._search end
    local box = Instance.new("Frame")
    box.Name = "_SearchBar"
    box.Size = UDim2.new(1, 0, 0, 30)
    box.BackgroundColor3 = self.window.theme.tokens.input
    box.BorderSizePixel = 0
    box.LayoutOrder = -1
    box.Parent = self.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = box
    local s = Instance.new("UIStroke"); s.Color = self.window.theme.tokens.inputStroke; s.Parent = box

    local field = Instance.new("TextBox")
    field.Name = "Query"
    field.Size = UDim2.new(1, -20, 1, 0)
    field.Position = UDim2.fromOffset(10, 0)
    field.BackgroundTransparency = 1
    field.Font = Enum.Font.Gotham
    field.TextSize = 12
    field.TextColor3 = self.window.theme.tokens.text
    field.PlaceholderText = "Search " .. self.name .. "…"
    field.PlaceholderColor3 = self.window.theme.tokens.placeholder
    field.Text = ""
    field.ClearTextOnFocus = false
    field.TextXAlignment = Enum.TextXAlignment.Left
    field.Parent = box

    field:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(field.Text or "")
        self._searchQuery = q
        for _, handle in ipairs(self.elements) do
            if handle.SetVisible then
                handle:SetVisible(self:_matches(q, handle.frame))
            else
                handle.frame.Visible = self:_matches(q, handle.frame)
            end
        end
    end)

    self._search = box
    self.window.bus:connect("theme:changed", function(theme)
        local t = theme.tokens
        box.BackgroundColor3 = t.input
        s.Color = t.inputStroke
        field.TextColor3 = t.text
        field.PlaceholderColor3 = t.placeholder
    end)
    return box
end

function Tab:CreateButton(opts)
    opts = opts or {}
    local frame = Instance.new("TextButton")
    frame.Name = opts.Name or "Button"
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = self.window.theme.tokens.element
    frame.BorderSizePixel = 0
    frame.Font = Enum.Font.GothamSemibold
    frame.TextSize = 13
    frame.TextColor3 = self.window.theme.tokens.text
    frame.Text = opts.Name or "Button"
    frame.AutoButtonColor = false
    frame.Parent = self.page

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = frame
    local s = Instance.new("UIStroke"); s.Color = self.window.theme.tokens.elementStroke; s.Parent = frame

    local handle = { frame = frame, _enabled = true }
    local clickConn, enterConn, leaveConn
    local self_tab = self

    local function run()
        if handle._enabled == false then return end
        if not opts.Callback then return end
        local ok, err = pcall(opts.Callback)
        if not ok then warn("GodField | " .. (opts.Name or "Button") .. " callback error: " .. tostring(err)) end
    end

    enterConn = frame.MouseEnter:Connect(function()
        if handle._enabled ~= false then
            Util.tweenPlay(frame, { BackgroundColor3 = self.window.theme.tokens.elementHover }, 0.15)
        end
    end)
    leaveConn = frame.MouseLeave:Connect(function()
        if handle._enabled ~= false then
            Util.tweenPlay(frame, { BackgroundColor3 = self.window.theme.tokens.element }, 0.15)
        end
    end)
    clickConn = frame.MouseButton1Click:Connect(run)

    function handle:Set(label) frame.Text = label; frame.Name = label end
    function handle:get() return frame.Text end
    function handle:SetEnabled(v)
        self._enabled = v and true or false
        frame.Active = self._enabled
        frame.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) self_tab:_setDescription(frame, text) end
    function handle:Destroy()
        clickConn:Disconnect(); enterConn:Disconnect(); leaveConn:Disconnect(); frame:Destroy()
    end

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        frame.TextColor3 = tk.text
        s.Color = tk.elementStroke
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateToggle(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local frame = Instance.new("TextButton")
    frame.Name = opts.Name or "Toggle"
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = self.page

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
    label.Text = opts.Name or "Toggle"
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
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "boolean" then value = saved end
    end

    local handle = { frame = frame, _enabled = true }
    local tab_for_desc = self

    local function render()
        local tk = self.window.theme.tokens
        track.BackgroundColor3 = value and tk.toggleOn or tk.toggleOff
        Util.tweenPlay(thumb, {
            Position = value and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2)
        }, 0.15)
    end

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, value)
            if not ok then warn("GodField | " .. (opts.Name or "Toggle") .. " callback error: " .. tostring(err)) end
        end
        self.window.bus:fire("element:changed", { element = handle, value = value })
    end

    function handle:Set(v)
        value = v and true or false
        render()
        fire()
    end
    function handle:get() return value end
    function handle:SetEnabled(v)
        self._enabled = v and true or false
        frame.Active = self._enabled
        label.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) tab_for_desc:_setDescription(frame, text) end

    local clickConn = frame.MouseButton1Click:Connect(function()
        if handle._enabled == false then return end
        value = not value
        render()
        fire()
    end)
    local enterConn = frame.MouseEnter:Connect(function()
        if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = self.window.theme.tokens.elementHover }, 0.15) end
    end)
    local leaveConn = frame.MouseLeave:Connect(function()
        if handle._enabled ~= false then Util.tweenPlay(frame, { BackgroundColor3 = self.window.theme.tokens.element }, 0.15) end
    end)

    function handle:Destroy()
        clickConn:Disconnect(); enterConn:Disconnect(); leaveConn:Disconnect(); frame:Destroy()
    end
    render()

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        s.Color = tk.elementStroke
        render()
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateSlider(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local range = opts.Range or { 0, 100 }
    local inc = opts.Increment or 1
    local value = math.clamp(opts.CurrentValue or range[1], range[1], range[2])

    local frame = Instance.new("Frame")
    frame.Name = opts.Name or "Slider"
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = self.page

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
    label.Text = opts.Name or "Slider"
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
    local slider_tab = self

    local function round(v) return range[1] + math.floor(((v - range[1]) / inc) + 0.5) * inc end

    local function render()
        local pct = (value - range[1]) / (range[2] - range[1])
        fill.Size = UDim2.new(pct, 0, 1, 0)
        readout.Text = tostring(value) .. (opts.Suffix and (" " .. opts.Suffix) or "")
    end

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, value)
            if not ok then warn("GodField | " .. (opts.Name or "Slider") .. " callback error: " .. tostring(err)) end
        end
        self.window.bus:fire("element:changed", { element = handle, value = value })
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if handle._enabled == false then return end
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    local inputMoved = UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    local inputEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    function handle:SetDescription(text) slider_tab:_setDescription(frame, text) end
    function handle:Destroy()
        trackBegan:Disconnect(); inputMoved:Disconnect(); inputEnded:Disconnect(); frame:Destroy()
    end

    if opts.Flag then
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "number" then value = math.clamp(round(saved), range[1], range[2]) end
    end
    render()

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        readout.TextColor3 = tk.placeholder
        s.Color = tk.elementStroke
        track.BackgroundColor3 = tk.secondary
        fill.BackgroundColor3 = tk.sliderProgress
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateInput(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = opts.Name or "Input"
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = self.page

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
    label.Text = opts.Name or "Input"
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
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "string" then box.Text = saved end
    end

    local handle = { frame = frame, _enabled = true }
    local input_tab = self

    local function fire()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, box.Text)
            if not ok then warn("GodField | " .. (opts.Name or "Input") .. " callback error: " .. tostring(err)) end
        end
        self.window.bus:fire("element:changed", { element = handle, value = box.Text })
    end

    local lost = box.FocusLost:Connect(function()
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
    function handle:SetDescription(text) input_tab:_setDescription(frame, text) end
    function handle:Destroy()
        lost:Disconnect(); frame:Destroy()
    end

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        s.Color = tk.elementStroke
        box.BackgroundColor3 = tk.input
        box.TextColor3 = tk.text
        box.PlaceholderColor3 = tk.placeholder
        bs.Color = tk.inputStroke
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateKeybind(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = opts.Name or "Keybind"
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.Parent = self.page

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
    label.Text = opts.Name or "Keybind"
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
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "string" then currentKey = saved; box.Text = saved end
    end

    local handle = { frame = frame, _enabled = true, _held = false }
    local UIS = game:GetService("UserInputService")
    local keybind_tab = self

    local function fire(value)
        if handle._enabled == false then return end
        if not opts.Callback then return end
        local ok, err = pcall(opts.Callback, value)
        if not ok then warn("GodField | " .. (opts.Name or "Keybind") .. " callback error: " .. tostring(err)) end
    end

    local captureConn
    local focused = box.Focused:Connect(function()
        box.Text = "…"
        captureConn = UIS.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Unknown then return end
            currentKey = input.KeyCode.Name
            box.Text = currentKey
            box:ReleaseFocus()
            if captureConn then captureConn:Disconnect(); captureConn = nil end
            if opts.Flag then self.window.store:set("GodField", opts.Flag, currentKey) end
            fire(currentKey)
        end)
    end)

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
        if opts.Flag then self.window.store:set("GodField", opts.Flag, k) end
    end
    function handle:get() return currentKey end
    function handle:SetEnabled(v)
        self._enabled = v and true or false
        label.TextTransparency = self._enabled and 0 or 0.5
        box.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) keybind_tab:_setDescription(frame, text) end
    function handle:Destroy()
        if focused then focused:Disconnect() end
        if captureConn then captureConn:Disconnect() end
        down:Disconnect(); up:Disconnect(); frame:Destroy()
    end

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        s.Color = tk.elementStroke
        box.BackgroundColor3 = tk.input
        box.TextColor3 = tk.text
        bs.Color = tk.inputStroke
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateDropdown(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local options = opts.Options or {}
    local multiple = opts.MultipleOptions and true or false

    local current = opts.CurrentOption
    if type(current) == "string" then current = { current } end
    if current == nil then current = multiple and {} or { options[1] } end
    if not multiple then current = { current[1] or options[1] } end

    if opts.Flag then
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "table" then
            current = multiple and saved or { saved[1] or options[1] }
        end
    end

    local frame = Instance.new("Frame")
    frame.Name = opts.Name or "Dropdown"
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = self.page

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
    label.Text = opts.Name or "Dropdown"
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
    local dropdown_tab = self

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
        if opts.Flag then self.window.store:set("GodField", opts.Flag, current) end
        if opts.Callback then
            local ok, err = pcall(opts.Callback, current)
            if not ok then warn("GodField | " .. (opts.Name or "Dropdown") .. " callback error: " .. tostring(err)) end
        end
        self.window.bus:fire("element:changed", { element = handle, value = current })
    end

    local close

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

    close = function()
        open = false
        search.Visible = false
        list.Visible = false
        list.Size = UDim2.new(1, -20, 0, 0)
        frame.Size = UDim2.new(1, 0, 0, 34)
    end

    local function openList()
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
    function handle:Refresh(newOptions)
        options = newOptions or {}
        if not multiple then
            if not table.find(options, current[1]) then
                current = { options[1] }
            end
        end
        refreshReadout()
        if open then rebuild() end
    end
    function handle:get() return current end
    function handle:SetEnabled(v)
        self._enabled = v and true or false
        label.TextTransparency = self._enabled and 0 or 0.5
        readout.TextTransparency = self._enabled and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(text) dropdown_tab:_setDescription(frame, text) end
    function handle:Destroy()
        for _, b in ipairs(buttons) do b:Destroy() end
        frame:Destroy()
    end

    refreshReadout()

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        s.Color = tk.elementStroke
        readout.TextColor3 = tk.placeholder
        search.BackgroundColor3 = tk.input
        search.TextColor3 = tk.text
        search.PlaceholderColor3 = tk.placeholder
        ss.Color = tk.inputStroke
        if open then rebuild() end
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateColorPicker(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local color = opts.Color or Color3.fromRGB(255, 255, 255)
    if opts.Flag then
        local saved = self.window.store:get("GodField", opts.Flag)
        if type(saved) == "table" and saved.R then
            color = Color3.fromRGB(saved.R, saved.G, saved.B)
        end
    end

    local frame = Instance.new("Frame")
    frame.Name = opts.Name or "ColorPicker"
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = t.element
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = self.page

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
    label.Text = opts.Name or "ColorPicker"
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
    local colorpicker_tab = self

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
            self.window.store:set("GodField", opts.Flag, { R = color.R * 255, G = color.G * 255, B = color.B * 255 })
        end
        if opts.Callback then
            local ok, err = pcall(opts.Callback, color)
            if not ok then warn("GodField | " .. (opts.Name or "ColorPicker") .. " callback error: " .. tostring(err)) end
        end
        self.window.bus:fire("element:changed", { element = handle, value = color })
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingPad = true
            setPad(input.Position.X, input.Position.Y)
        end
    end)
    hue.InputBegan:Connect(function(input)
        if handle._enabled == false then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            setHue(input.Position.X)
        end
    end)
    local inputMoved = UIS.InputChanged:Connect(function(input)
        if draggingPad and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setPad(input.Position.X, input.Position.Y)
        elseif draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setHue(input.Position.X)
        end
    end)
    local inputEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    function handle:SetDescription(text) colorpicker_tab:_setDescription(frame, text) end
    function handle:Destroy()
        inputMoved:Disconnect(); inputEnded:Disconnect(); if hexLost then hexLost:Disconnect() end; frame:Destroy()
    end

    render()

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.element
        label.TextColor3 = tk.text
        s.Color = tk.elementStroke
        panel.BackgroundColor3 = tk.secondary
        ps.Color = tk.secondaryStroke
        hex.BackgroundColor3 = tk.input
        hex.TextColor3 = tk.text        hxs.Color = tk.inputStroke
    end)

    if opts.Flag then self.window.store:registerFlag(opts.Flag, handle) end
    return self:_register(handle)
end

function Tab:CreateLabel(text)
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = "Label"
    frame.Size = UDim2.new(1, 0, 0, 22)
    frame.BackgroundTransparency = 1
    frame.Parent = self.page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = t.placeholder
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = type(text) == "string" and text or ""
    label.Parent = frame

    local handle = { frame = frame }
    local label_tab = self
    function handle:Set(v) label.Text = tostring(v or "") end
    function handle:get() return label.Text end
    function handle:SetEnabled(v) label.TextTransparency = v and 0 or 0.5 end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(txt) label_tab:_setDescription(frame, txt) end
    function handle:Destroy() frame:Destroy() end

    self.window.bus:connect("theme:changed", function(theme)
        label.TextColor3 = theme.tokens.placeholder
    end)
    return self:_register(handle)
end

function Tab:CreateParagraph(opts)
    opts = opts or {}
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = "Paragraph"
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = t.secondary
    frame.BorderSizePixel = 0
    frame.Parent = self.page

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
    local paragraph_tab = self
    function handle:Set(v) content.Text = tostring(v or "") end
    function handle:get() return content.Text end
    function handle:SetEnabled(v)
        title.TextTransparency = v and 0 or 0.5
        content.TextTransparency = v and 0 or 0.5
    end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription(txt) paragraph_tab:_setDescription(frame, txt) end
    function handle:Destroy() frame:Destroy() end

    self.window.bus:connect("theme:changed", function(theme)
        local tk = theme.tokens
        frame.BackgroundColor3 = tk.secondary
        s.Color = tk.secondaryStroke
        title.TextColor3 = tk.text
        content.TextColor3 = tk.placeholder
    end)
    return self:_register(handle)
end

function Tab:CreateSection(name)
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = "Section"
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.Parent = self.page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = t.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = type(name) == "string" and name or ""
    label.Parent = frame

    local handle = { frame = frame }
    function handle:Set(v) label.Text = tostring(v or "") end
    function handle:get() return label.Text end
    function handle:SetEnabled(v) label.TextTransparency = v and 0 or 0.5 end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription() end
    function handle:Destroy() frame:Destroy() end

    self.window.bus:connect("theme:changed", function(theme)
        label.TextColor3 = theme.tokens.text
    end)

    self:_register(handle)
    table.insert(self.sections, handle)
    return handle
end

function Tab:CreateDivider()
    local t = self.window.theme.tokens
    local frame = Instance.new("Frame")
    frame.Name = "Divider"
    frame.Size = UDim2.new(1, 0, 0, 1)
    frame.BackgroundColor3 = t.elementStroke
    frame.BorderSizePixel = 0
    frame.Parent = self.page

    local handle = { frame = frame }
    function handle:Set() end
    function handle:get() return nil end
    function handle:SetEnabled() end
    function handle:SetVisible(v) frame.Visible = v and true or false end
    function handle:SetDescription() end
    function handle:Destroy() frame:Destroy() end

    self.window.bus:connect("theme:changed", function(theme)
        frame.BackgroundColor3 = theme.tokens.elementStroke
    end)
    return self:_register(handle)
end

function Tab:SetVisible(v)
    v = v and true or false
    self.btn.Visible = v and not self.ext
    self.page.Visible = v
end

function Tab:IsVisible()
    return self.page.Visible
end

function Tab:Destroy()
    for _, handle in ipairs(self.elements) do
        if handle.Destroy then pcall(handle.Destroy, handle) end
    end
    self.elements = {}; self.sections = {}; self._descriptions = {}
    if self._search then self._search:Destroy(); self._search = nil end
    self.btn:Destroy(); self.page:Destroy()
end

-- ═══════════════════════════════════════════════════════════════════
-- 6. CREATE / WINDOW
-- ═══════════════════════════════════════════════════════════════════
local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = parent
    return c
end
local function stroke(parent, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or Color3.fromRGB(50, 50, 50)
    s.Thickness = th or 1; s.Parent = parent
    return s
end

function GodField:CreateWindow(settings)
    settings = settings or {}
    local interface = Instance.new("ScreenGui")
    interface.Name = "GodField"
    interface.ResetOnSpawn = false
    interface.IgnoreGuiInset = true
    interface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local theme = Theme:get(settings.Theme or "Default")
    local t = theme.tokens

    local root = Instance.new("Frame")
    root.Name = "Main"
    root.Size = UDim2.fromOffset(500, 475)
    root.Position = UDim2.new(0.5, 0, 0.5, 0)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.BackgroundColor3 = t.background
    root.BorderSizePixel = 0
    root.Active = true
    corner(root, 10)
    local rootStroke = stroke(root, t.elementStroke, 1)
    root.Parent = interface

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 45)
    topbar.BackgroundColor3 = t.topbar
    topbar.BorderSizePixel = 0
    corner(topbar, 10)
    topbar.Parent = root

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.fromOffset(15, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 15
    title.TextColor3 = t.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = settings.Name or "GodField"
    title.Parent = topbar

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -32, 0.5, -12)
    close.BackgroundTransparency = 1
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.TextColor3 = t.text
    close.Text = "×"
    close.Parent = topbar

    local tabstrip = Instance.new("ScrollingFrame")
    tabstrip.Name = "Tabs"
    tabstrip.Size = UDim2.new(0, 120, 1, -60)
    tabstrip.Position = UDim2.fromOffset(0, 50)
    tabstrip.BackgroundTransparency = 1
    tabstrip.BorderSizePixel = 0
    tabstrip.ScrollBarThickness = 3
    tabstrip.Parent = root
    local tablist = Instance.new("UIListLayout")
    tablist.Padding = UDim.new(0, 6)
    tablist.Parent = tabstrip

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.Size = UDim2.new(1, -130, 1, -65)
    pages.Position = UDim2.fromOffset(125, 55)
    pages.BackgroundTransparency = 1
    pages.Parent = root
    local pager = Instance.new("UIPageLayout")
    pager.Animated = true
    pager.TweenTime = 0.15
    pager.EasingStyle = Enum.EasingStyle.Exponential
    pager.Parent = pages

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = t.modalOverlay
    overlay.BackgroundTransparency = 0.5
    overlay.Visible = false
    overlay.ZIndex = 100
    overlay.Parent = interface

    local bus = Signals.new()
    local teardown = Instance.new("BindableEvent")
    teardown.Name = "GodFieldTeardown"
    teardown.Parent = interface

    local window = {
        gui = interface, root = root, topbar = topbar,
        tabstrip = tabstrip, pages = pages, pager = pager, overlay = overlay,
        bus = bus, settings = settings, theme = theme,
        tabs = {}, tabGroups = {}, _hotkeys = {}, _bindings = {}, _modals = 0, _teardown = teardown,
    }

    for _, name in ipairs({
        "theme:changed", "tab:changed", "element:changed",
        "window:shown", "window:hidden", "window:destroyed",
        "modal:open", "modal:close",
    }) do bus:define(name) end

    local store = Store.new(bus)
    if settings.FolderName then store:setRoot(settings.FolderName) end
    if not settings.DisableConfig then store:load() end
    window.store = store

    local function refreshTheme()
        theme = Theme:get(window.theme)
        window.theme = theme
        t = theme.tokens
        root.BackgroundColor3 = t.background
        topbar.BackgroundColor3 = t.topbar
        rootStroke.Color = t.elementStroke
        title.TextColor3 = t.text
        close.TextColor3 = t.text
        overlay.BackgroundColor3 = t.modalOverlay
        bus:fire("theme:changed", theme)
    end

    function window:ModifyTheme(newTheme)
        window.theme = Theme:get(newTheme)
        refreshTheme()
    end

    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local UIS = game:GetService("UserInputService")
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    close.MouseButton1Click:Connect(function() window:Destroy() end)

    local function openModal(frame)
        window._modals += 1
        overlay.Visible = true
        frame.ZIndex = 101
        frame.Parent = overlay
        bus:fire("modal:open", frame)
    end
    local function closeModal(frame)
        window._modals = math.max(0, window._modals - 1)
        if window._modals == 0 then overlay.Visible = false end
        if frame then frame:Destroy() end
        bus:fire("modal:close", frame)
    end

    function window:Confirm(opts)
        opts = opts or {}
        local done, result = false, false
        local frame = Instance.new("Frame")
        frame.Name = "ConfirmModal"
        frame.Size = UDim2.fromOffset(320, 140)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = t.background
        frame.BorderSizePixel = 0
        corner(frame, 10); stroke(frame, t.elementStroke, 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 0, 60)
        label.Position = UDim2.fromOffset(15, 15)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = t.text
        label.TextWrapped = true
        label.Text = opts.Body or opts.Title or "Are you sure?"
        label.Parent = frame

        local yes = Instance.new("TextButton")
        yes.Size = UDim2.fromOffset(130, 34)
        yes.Position = UDim2.new(0.5, -140, 1, -50)
        yes.BackgroundColor3 = t.element
        yes.TextColor3 = t.text
        yes.Font = Enum.Font.GothamSemibold
        yes.TextSize = 13
        yes.Text = opts.ConfirmText or "Confirm"
        corner(yes, 6); yes.Parent = frame

        local no = Instance.new("TextButton")
        no.Size = UDim2.fromOffset(130, 34)
        no.Position = UDim2.new(0.5, 10, 1, -50)
        no.BackgroundColor3 = t.element
        no.TextColor3 = t.text
        no.Font = Enum.Font.GothamSemibold
        no.TextSize = 13
        no.Text = opts.CancelText or "Cancel"
        corner(no, 6); no.Parent = frame

        yes.MouseButton1Click:Connect(function() result = true; done = true; closeModal(frame) end)
        no.MouseButton1Click:Connect(function() done = true; closeModal(frame) end)
        openModal(frame)
        repeat task.wait() until done
        return result
    end

    function window:Prompt(opts)
        opts = opts or {}
        local done, result = false, nil
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(340, 160)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = t.background
        frame.BorderSizePixel = 0
        corner(frame, 10); stroke(frame, t.elementStroke, 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 0, 24)
        label.Position = UDim2.fromOffset(15, 15)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextColor3 = t.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = opts.Title or "Input"
        label.Parent = frame

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -30, 0, 34)
        box.Position = UDim2.fromOffset(15, 50)
        box.BackgroundColor3 = t.input
        box.TextColor3 = t.text
        box.Font = Enum.Font.Gotham
        box.TextSize = 13
        box.PlaceholderText = opts.Placeholder or ""
        box.PlaceholderColor3 = t.placeholder
        box.Text = opts.Default or ""
        box.ClearTextOnFocus = false
        corner(box, 6); stroke(box, t.inputStroke, 1); box.Parent = frame

        local ok = Instance.new("TextButton")
        ok.Size = UDim2.fromOffset(140, 32)
        ok.Position = UDim2.new(0.5, -150, 1, -46)
        ok.BackgroundColor3 = t.element
        ok.TextColor3 = t.text
        ok.Text = "OK"
        ok.Font = Enum.Font.GothamSemibold
        corner(ok, 6); ok.Parent = frame

        local cancel = Instance.new("TextButton")
        cancel.Size = UDim2.fromOffset(140, 32)
        cancel.Position = UDim2.new(0.5, 10, 1, -46)
        cancel.BackgroundColor3 = t.element
        cancel.TextColor3 = t.text
        cancel.Text = "Cancel"
        cancel.Font = Enum.Font.GothamSemibold
        corner(cancel, 6); cancel.Parent = frame

        ok.MouseButton1Click:Connect(function() result = box.Text; done = true; closeModal(frame) end)
        cancel.MouseButton1Click:Connect(function() done = true; closeModal(frame) end)
        box.FocusLost:Connect(function(enter) if enter then result = box.Text; done = true; closeModal(frame) end end)
        openModal(frame)
        box:CaptureFocus()
        repeat task.wait() until done
        return result
    end

    function window:NotifyProgress(opts)
        opts = opts or {}
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(340, 110)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = t.background
        frame.BorderSizePixel = 0
        corner(frame, 10); stroke(frame, t.elementStroke, 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 0, 24)
        label.Position = UDim2.fromOffset(15, 12)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextColor3 = t.text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = opts.Title or "Working…"
        label.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -30, 0, 8)
        track.Position = UDim2.fromOffset(15, 52)
        track.BackgroundColor3 = t.element
        track.BorderSizePixel = 0
        corner(track, 4); track.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = t.progressFill
        fill.BorderSizePixel = 0
        corner(fill, 4); fill.Parent = track

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -30, 0, 20)
        status.Position = UDim2.fromOffset(15, 74)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.Gotham
        status.TextSize = 12
        status.TextColor3 = t.placeholder
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Text = "0%"
        status.Parent = frame

        openModal(frame)
        return {
            frame = frame,
            Update = function(_, pct, text)
                pct = math.clamp(pct or 0, 0, 1)
                Util.tweenPlay(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.2)
                status.Text = text or (math.floor(pct * 100) .. "%")
            end,
            Done = function(_, text)
                status.Text = text or "Done"
                task.delay(0.4, function() closeModal(frame) end)
            end,
            Fail = function(_, text)
                status.TextColor3 = Color3.fromRGB(220, 90, 90)
                status.Text = text or "Failed"
                task.delay(1.2, function() closeModal(frame) end)
            end,
        }
    end

    function window:OnKeybind(id, key, callback)
        if self._hotkeys[id] then pcall(self._hotkeys[id].Disconnect, self._hotkeys[id]) end
        local conn = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode[key] then callback() end
        end)
        self._hotkeys[id] = conn
        return conn
    end

    function window:Bind(storeKey, getter)
        local scope, name = storeKey:match("^([^%.]+)%.(.+)$")
        if not scope then return end
        self.store:registerFlag(storeKey, { get = getter })
        self.bus:connect("setting:changed", function(ev)
            if ev.scope == scope and ev.name == name then getter() end
        end)
    end

    function window:Destroy()
        bus:fire("window:destroyed")
        for _, c in pairs(self._hotkeys) do pcall(c.Disconnect, c) end
        bus:sweep()
        self.store:flushFlags()
        interface:Destroy()
    end

    function window:SetVisible(v)
        root.Visible = v
        bus:fire(v and "window:shown" or "window:hidden", v)
    end

    function window:IsVisible() return root.Visible end

    function window:CreateTab(name, icon, ext)
        local tab = Tab.new(self, name, icon, ext)
        self.tabs[#self.tabs + 1] = tab
        return tab
    end

    function window:CreateTabGroup(name)
        local g = { Name = name, Tabs = {} }
        self.tabGroups[#self.tabGroups + 1] = g
        return g
    end

    function window:CreateConfigManager()
        return {
            Save = function(_, name) self.store:save() end,
            Load = function(_, name) self.store:load() end,
            List = function(_) return {} end,
            Delete = function(_, name) end
        }
    end

    function window:LoadConfiguration() self.store:load(); self.store:flushFlags() end
    function window:SaveConfiguration() self.store:flushFlags() end

    return window
end

return GodField
