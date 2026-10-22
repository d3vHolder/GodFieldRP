-- GodField/lib/Create.lua
-- Builds the entire ScreenGui tree from Instance.new. No CDN asset.

local Create = {}
Create.__index = Create

local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = parent
    return c
end
local function stroke(parent, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or Color3.fromRGB(50,50,50)
    s.Thickness = th or 1; s.Parent = parent
    return s
end

function Create:Window(settings, modules)
    local Util, Theme = modules.Util, modules.Theme
    local Signals, Store = modules.Signals, modules.Store
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

    -- New: close button on topbar (v1 only had hide + settings).
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

    -- Modal overlay (used by Confirm, Prompt, Progress).
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
        gui       = interface,
        root      = root,
        topbar    = topbar,
        tabstrip  = tabstrip,
        pages     = pages,
        overlay   = overlay,
        bus       = bus,
        settings  = settings,
        theme     = theme,
        tabs      = {},
        tabGroups = {},
        _hotkeys  = {},
        _bindings = {},
        _modals   = 0,
        _teardown = teardown,
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
        theme = Theme:get(theme.name or theme)
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

    -- ── Drag ────────────────────────────────────────────────────────────
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- ── Close ──────────────────────────────────────────────────────────
    close.MouseButton1Click:Connect(function() window:Destroy() end)

    -- ── Modal helpers (new) ────────────────────────────────────────────
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
        local done = false
        local result = false
        local frame = Instance.new("Frame")
        frame.Name = "ConfirmModal"
        frame.Size = UDim2.fromOffset(320, 140)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = t.background
        frame.BorderSizePixel = 0
        corner(frame, 10)
        stroke(frame, t.elementStroke, 1)

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
        corner(yes, 6)
        yes.Parent = frame

        local no = Instance.new("TextButton")
        no.Size = UDim2.fromOffset(130, 34)
        no.Position = UDim2.new(0.5, 10, 1, -50)
        no.BackgroundColor3 = t.element
        no.TextColor3 = t.text
        no.Font = Enum.Font.GothamSemibold
        no.TextSize = 13
        no.Text = opts.CancelText or "Cancel"
        corner(no, 6)
        no.Parent = frame

        yes.MouseButton1Click:Connect(function() result = true; done = true; closeModal(frame) end)
        no.MouseButton1Click:Connect(function() done = true; closeModal(frame) end)

        openModal(frame)
        task.spawn(function() while not done do task.wait() end end)
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
        corner(box, 6); stroke(box, t.inputStroke, 1)
        box.Parent = frame

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
        local handle = {
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
        return handle
    end

    -- ── Hotkey registry (new) ──────────────────────────────────────────
    function window:OnKeybind(id, key, callback)
        if self._hotkeys[id] then
            pcall(self._hotkeys[id].Disconnect, self._hotkeys[id])
        end
        local conn = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode[key] then callback() end
        end)
        self._hotkeys[id] = conn
        return conn
    end

    -- ── Reactive bind (new) ────────────────────────────────────────────
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

    return window
end

return Create