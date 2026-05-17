local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

Library.Theme = {
    Background      = Color3.fromRGB(18, 18, 24),
    Sidebar         = Color3.fromRGB(22, 22, 28),
    Topbar          = Color3.fromRGB(22, 22, 28),
    Groupbox        = Color3.fromRGB(26, 26, 32),
    GroupboxHeader  = Color3.fromRGB(30, 30, 38),
    Element         = Color3.fromRGB(34, 34, 42),
    ElementHover    = Color3.fromRGB(40, 40, 50),
    ElementBorder   = Color3.fromRGB(45, 45, 55),
    Accent          = Color3.fromRGB(59, 130, 246),
    AccentHover     = Color3.fromRGB(79, 150, 255),
    Text            = Color3.fromRGB(235, 235, 240),
    TextDim         = Color3.fromRGB(150, 150, 160),
    TextMuted       = Color3.fromRGB(100, 100, 115),
    Success         = Color3.fromRGB(34, 197, 94),
    Danger          = Color3.fromRGB(239, 68, 68),
    Divider         = Color3.fromRGB(40, 40, 50),
}

Library.Toggles            = {}
Library.Options            = {}
Library.Tabs               = {}
Library.Connections        = {}
Library.UnloadCallbacks    = {}
Library.ThemeCallbacks     = {}
Library.Registry           = {}
Library.RegistryMap        = {}
Library.NotifySide         = "Right"
Library.ShowCustomCursor   = false
Library.Toggled            = true
Library.Unloaded           = false
Library.MinSize            = Vector2.new(600, 420)
Library.Title              = "Fatality Wins"
Library.Subtitle           = "Rivals"
Library.Version            = "1"
Library.ToggleKeybind      = { Value = Enum.KeyCode.RightShift }
Library.IsMobile           = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
Library.OpenedDropdown     = nil
Library.OpenedColorPicker  = nil

local function createInstance(class, props, children)
    local inst = Instance.new(class)
    if props then
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do
            inst[k] = v
        end
        if parent then inst.Parent = parent end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.ElementBorder
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top or 0)
    p.PaddingRight  = UDim.new(0, right or top or 0)
    p.PaddingBottom = UDim.new(0, bottom or top or 0)
    p.PaddingLeft   = UDim.new(0, left or top or 0)
    p.Parent = parent
    return p
end

local function listLayout(parent, pad, dir, hAlign, vAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 4)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function getTextSize(text, size, font, bounds)
    return TextService:GetTextSize(
        text,
        size or 14,
        font or Enum.Font.Gotham,
        bounds or Vector2.new(math.huge, math.huge)
    )
end

local function createSignal()
    local connections = {}
    local signal = {}

    function signal:Connect(fn)
        local c = { fn = fn, connected = true }
        function c:Disconnect() c.connected = false end
        table.insert(connections, c)
        return c
    end

    function signal:Fire(...)
        for _, c in ipairs(connections) do
            if c.connected then
                task.spawn(c.fn, ...)
            end
        end
    end

    function signal:DisconnectAll()
        for _, c in ipairs(connections) do c.connected = false end
        connections = {}
    end

    return signal
end

Library._createInstance = createInstance
Library._corner         = corner
Library._stroke         = stroke
Library._padding        = padding
Library._listLayout     = listLayout
Library._tween          = tween
Library._getTextSize    = getTextSize
Library._createSignal   = createSignal

function Library:SafeCallback(fn, ...)
    if not fn then return end
    local args = { ... }
    task.spawn(function()
        local ok, err = pcall(function() fn(table.unpack(args)) end)
        if not ok then
            warn("[FatalityUI] Callback error: " .. tostring(err))
        end
    end)
end

function Library:GiveSignal(connection)
    table.insert(self.Connections, connection)
    return connection
end

function Library:Connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(self.Connections, conn)
    return conn
end

function Library:OnUnload(fn)
    table.insert(self.UnloadCallbacks, fn)
end

function Library:OnThemeChanged(fn)
    table.insert(self.ThemeCallbacks, fn)
end

function Library:AddToRegistry(inst, props)
    self.RegistryMap[inst] = props
end

function Library:UpdateColorsUsingRegistry()
    for _, cb in ipairs(self.ThemeCallbacks) do
        pcall(cb)
    end
    for inst, props in pairs(self.RegistryMap) do
        if inst and inst.Parent then
            for prop, themeKey in pairs(props) do
                if self.Theme[themeKey] then
                    pcall(function() inst[prop] = self.Theme[themeKey] end)
                end
            end
        end
    end
end

function Library:ApplyTheme(themeTable)
    for k, v in pairs(themeTable) do
        if self.Theme[k] ~= nil then
            if typeof(v) == "Color3" then
                self.Theme[k] = v
            elseif typeof(v) == "table" then
                self.Theme[k] = Color3.fromRGB(v[1], v[2], v[3])
            end
        end
    end
    self:UpdateColorsUsingRegistry()
end

function Library:GetTextBounds(text, font, size, width)
    return getTextSize(text, size, font, Vector2.new(width or math.huge, math.huge))
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    for _, fn in ipairs(self.UnloadCallbacks) do
        pcall(fn)
    end
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end

    if self.ScreenGui  then self.ScreenGui:Destroy()  end
    if self.MobileGui  then self.MobileGui:Destroy()  end
    if self.NotifyGui  then self.NotifyGui:Destroy()  end
    if self.CursorGui  then self.CursorGui:Destroy()  end
end

function Library:AttemptSave()
    if self.SaveManager then
        pcall(function() self.SaveManager:Save() end)
    end
end

function Library:CreateWindow(opts)
    opts = opts or {}
    self.Title = opts.Title or opts.Name or self.Title
    self.Subtitle = opts.Subtitle or self.Subtitle
    self.Version = opts.Version or self.Version
    self.Footer = opts.Footer or ("v" .. tostring(self.Version) .. " - Development Build")
    if opts.NotifySide then self.NotifySide = opts.NotifySide end
    if opts.ShowCustomCursor ~= nil then self.ShowCustomCursor = opts.ShowCustomCursor end

    local parentGui = CoreGui
    local ok = pcall(function() return CoreGui:GetChildren() end)
    if not ok then
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end

    for _, g in ipairs(parentGui:GetChildren()) do
        if g.Name == "FatalityUI" or g.Name == "FatalityUI_Mobile" or g.Name == "FatalityUI_Notify" or g.Name == "FatalityUI_Cursor" then
            g:Destroy()
        end
    end

    local screenGui = createInstance("ScreenGui", {
        Name = "FatalityUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = parentGui,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, screenGui) end
    if gethui then pcall(function() screenGui.Parent = gethui() end) end

    self.ScreenGui = screenGui

    local notifyGui = createInstance("ScreenGui", {
        Name = "FatalityUI_Notify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 1000,
        Parent = parentGui,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, notifyGui) end
    self.NotifyGui = notifyGui

    local notifyContainer = createInstance("Frame", {
        Name = "NotifyContainer",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        BackgroundTransparency = 1,
        Parent = notifyGui,
    })
    listLayout(notifyContainer, 8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right)
    self.NotifyContainer = notifyContainer

    local screenSize = workspace.CurrentCamera.ViewportSize
    local winW, winH = 720, 520
    local winX = (screenSize.X - winW) / 2
    local winY = (screenSize.Y - winH) / 2

    local main = createInstance("Frame", {
        Name = "Main",
        Position = UDim2.new(0, winX, 0, winY),
        Size = UDim2.new(0, winW, 0, winH),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    corner(main, 10)
    stroke(main, self.Theme.ElementBorder, 1)
    self:AddToRegistry(main, { BackgroundColor3 = "Background" })
    self.Main = main

    local shadow = createInstance("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 0,
        Parent = main,
    })

    local sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    self:AddToRegistry(sidebar, { BackgroundColor3 = "Sidebar" })

    local sidebarDivider = createInstance("Frame", {
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = self.Theme.ElementBorder,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:AddToRegistry(sidebarDivider, { BackgroundColor3 = "ElementBorder" })

    local logoArea = createInstance("Frame", {
        Name = "LogoArea",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    local logoBox = createInstance("Frame", {
        Position = UDim2.new(0, 14, 0, 16),
        Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = logoArea,
    })
    corner(logoBox, 6)
    self:AddToRegistry(logoBox, { BackgroundColor3 = "Accent" })

    local logoText = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "FW",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Parent = logoBox,
    })

    local titleLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 54, 0, 16),
        Size = UDim2.new(1, -64, 0, 16),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = logoArea,
    })
    self:AddToRegistry(titleLbl, { TextColor3 = "Text" })

    local subtitleLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 54, 0, 32),
        Size = UDim2.new(1, -64, 0, 14),
        BackgroundTransparency = 1,
        Text = self.Subtitle,
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = logoArea,
    })
    self:AddToRegistry(subtitleLbl, { TextColor3 = "TextDim" })

    local navLabel = createInstance("TextLabel", {
        Position = UDim2.new(0, 16, 0, 72),
        Size = UDim2.new(1, -32, 0, 14),
        BackgroundTransparency = 1,
        Text = "NAVIGATION",
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })
    self:AddToRegistry(navLabel, { TextColor3 = "TextMuted" })

    local tabList = createInstance("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.new(0, 8, 0, 94),
        Size = UDim2.new(1, -16, 1, -160),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar,
    })
    listLayout(tabList, 2)
    self.TabList = tabList

    local footerArea = createInstance("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -16),
        Size = UDim2.new(1, -32, 0, 50),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    local versionLbl = createInstance("TextLabel", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = self.Footer,
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footerArea,
    })
    self:AddToRegistry(versionLbl, { TextColor3 = "TextMuted" })

    local topbar = createInstance("Frame", {
        Name = "Topbar",
        Position = UDim2.new(0, 170, 0, 0),
        Size = UDim2.new(1, -170, 0, 56),
        BackgroundColor3 = self.Theme.Topbar,
        BorderSizePixel = 0,
        Parent = main,
    })
    self:AddToRegistry(topbar, { BackgroundColor3 = "Topbar" })

    local topbarDivider = createInstance("Frame", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self.Theme.ElementBorder,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    self:AddToRegistry(topbarDivider, { BackgroundColor3 = "ElementBorder" })

    local breadcrumb = createInstance("TextLabel", {
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(0.5, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })
    self:AddToRegistry(breadcrumb, { TextColor3 = "Text" })
    self.Breadcrumb = breadcrumb

    local statusPill = createInstance("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -60, 0.5, 0),
        Size = UDim2.new(0, 130, 0, 28),
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    corner(statusPill, 8)
    self:AddToRegistry(statusPill, { BackgroundColor3 = "Element" })

    local statusDot = createInstance("Frame", {
        Position = UDim2.new(0, 10, 0.5, -3),
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = self.Theme.Success,
        BorderSizePixel = 0,
        Parent = statusPill,
    })
    corner(statusDot, 3)
    self:AddToRegistry(statusDot, { BackgroundColor3 = "Success" })

    local statusTxt = createInstance("TextLabel", {
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(0, 50, 1, 0),
        BackgroundTransparency = 1,
        Text = "Active",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusPill,
    })
    self:AddToRegistry(statusTxt, { TextColor3 = "Text" })

    local versionTxt = createInstance("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 50, 1, 0),
        BackgroundTransparency = 1,
        Text = "v" .. tostring(self.Version),
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = statusPill,
    })
    self:AddToRegistry(versionTxt, { TextColor3 = "TextDim" })

    local minBtn = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Text = "—",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = topbar,
    })
    corner(minBtn, 6)
    self:AddToRegistry(minBtn, { BackgroundColor3 = "Element", TextColor3 = "Text" })

    local content = createInstance("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 170, 0, 56),
        Size = UDim2.new(1, -170, 1, -56),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })
    self.ContentFrame = content

    local resizeHandle = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = main,
    })

    local resizeIcon = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "◢",
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = resizeHandle,
    })
    self:AddToRegistry(resizeIcon, { TextColor3 = "TextMuted" })

    local function bindDrag(handle, target)
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = target.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local function bindResize(handle, target, minSize)
        local resizing, startPos, startSize
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startPos = input.Position
                startSize = target.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startPos
                local newW = math.max(minSize.X, startSize.X + delta.X)
                local newH = math.max(minSize.Y, startSize.Y + delta.Y)
                target.Size = UDim2.new(0, newW, 0, newH)
            end
        end)
    end

    bindDrag(topbar, main)
    bindDrag(logoArea, main)
    bindResize(resizeHandle, main, self.MinSize)

    self.Minimized = false
    local savedSize = main.Size
    minBtn.MouseButton1Click:Connect(function()
        if self.Minimized then
            self.Minimized = false
            tween(main, 0.25, { Size = savedSize })
            task.wait(0.1)
            content.Visible = true
            sidebar.Visible = true
        else
            savedSize = main.Size
            self.Minimized = true
            content.Visible = false
            sidebar.Visible = false
            tween(main, 0.25, { Size = UDim2.new(0, 220, 0, 56) })
        end
    end)

    minBtn.MouseEnter:Connect(function()
        tween(minBtn, 0.15, { BackgroundColor3 = self.Theme.ElementHover })
    end)
    minBtn.MouseLeave:Connect(function()
        tween(minBtn, 0.15, { BackgroundColor3 = self.Theme.Element })
    end)

    local mobileGui = createInstance("ScreenGui", {
        Name = "FatalityUI_Mobile",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 998,
        Parent = parentGui,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, mobileGui) end
    self.MobileGui = mobileGui

    local mobileFrame = createInstance("Frame", {
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 80, 0, 80),
        BackgroundTransparency = 1,
        Visible = self.IsMobile,
        Parent = mobileGui,
    })
    listLayout(mobileFrame, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

    local function makeMobileBtn(text)
        local b = createInstance("TextButton", {
            Size = UDim2.new(0, 78, 0, 34),
            BackgroundColor3 = Color3.fromRGB(28, 28, 34),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(235, 235, 240),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = mobileFrame,
        })
        corner(b, 6)
        stroke(b, Color3.fromRGB(55, 55, 65), 1)
        return b
    end

    local toggleBtn = makeMobileBtn("Toggle")
    local unlockBtn = makeMobileBtn("Unlock")

    toggleBtn.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        main.Visible = self.Toggled
    end)

    self.MobileLocked = true
    unlockBtn.MouseButton1Click:Connect(function()
        self.MobileLocked = not self.MobileLocked
        unlockBtn.Text = self.MobileLocked and "Unlock" or "Lock"
    end)

    self.MobileFrame = mobileFrame
    self.MobileToggleBtn = toggleBtn
    self.MobileUnlockBtn = unlockBtn

    self:Connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKeybind.Value then
            self.Toggled = not self.Toggled
            main.Visible = self.Toggled
        end
    end)

    self.Window = {}
    function self.Window:SetCurrentTab(tab)
        Library:SetCurrentTab(tab)
    end
    function self.Window:AddTab(name)
        return Library:AddTab(name)
    end

    return self.Window
end

function Library:SetCurrentTab(tab)
    if self.CurrentTab == tab then return end

    if self.CurrentTab then
        local oldPage = self.CurrentTab._Page
        local oldBtn = self.CurrentTab._Button
        local oldIndicator = self.CurrentTab._Indicator
        if oldPage then
            tween(oldPage, 0.15, { GroupTransparency = 1 })
            task.delay(0.15, function()
                if oldPage and oldPage.Parent then
                    oldPage.Visible = false
                end
            end)
        end
        if oldBtn then
            tween(oldBtn, 0.15, { BackgroundTransparency = 1 })
        end
        if oldIndicator then
            tween(oldIndicator, 0.15, { BackgroundTransparency = 1 })
        end
        if self.CurrentTab._Label then
            tween(self.CurrentTab._Label, 0.15, { TextColor3 = self.Theme.TextDim })
        end
    end

    self.CurrentTab = tab

    if tab then
        local page = tab._Page
        local btn = tab._Button
        local indicator = tab._Indicator
        if page then
            page.Visible = true
            page.GroupTransparency = 1
            tween(page, 0.2, { GroupTransparency = 0 })
        end
        if btn then
            tween(btn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = self.Theme.Element })
        end
        if indicator then
            tween(indicator, 0.15, { BackgroundTransparency = 0 })
        end
        if tab._Label then
            tween(tab._Label, 0.15, { TextColor3 = self.Theme.Text })
        end
        if self.Breadcrumb then
            self.Breadcrumb.Text = tab.Name .. "  ›  " .. tab.Name
        end
    end
end

function Library:AddTab(name)
    local tab = {}
    tab.Name = name
    tab.Groupboxes = {}

    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TabList,
    })
    corner(btn, 6)

    local indicator = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0.5, -8),
        Size = UDim2.new(0, 3, 0, 16),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = btn,
    })
    corner(indicator, 2)
    self:AddToRegistry(indicator, { BackgroundColor3 = "Accent" })

    local label = createInstance("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    btn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            tween(label, 0.12, { TextColor3 = self.Theme.Text })
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            tween(label, 0.12, { TextColor3 = self.Theme.TextDim })
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SetCurrentTab(tab)
    end)

    local page = createInstance("CanvasGroup", {
        Name = name .. "_Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        GroupTransparency = 1,
        Parent = self.ContentFrame,
    })

    local moduleToggleArea = createInstance("Frame", {
        Position = UDim2.new(1, -160, 0, 8),
        Size = UDim2.new(0, 150, 0, 26),
        BackgroundTransparency = 1,
        Parent = page,
    })

    local moduleLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        Text = "Module enabled",
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = moduleToggleArea,
    })
    self:AddToRegistry(moduleLbl, { TextColor3 = "TextDim" })

    local modSwitch = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 20),
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = moduleToggleArea,
    })
    corner(modSwitch, 10)

    local modKnob = createInstance("Frame", {
        Position = UDim2.new(0, 2, 0.5, -7),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.fromRGB(180, 180, 190),
        BorderSizePixel = 0,
        Parent = modSwitch,
    })
    corner(modKnob, 7)

    local moduleOn = false
    modSwitch.MouseButton1Click:Connect(function()
        moduleOn = not moduleOn
        if moduleOn then
            tween(modSwitch, 0.15, { BackgroundColor3 = self.Theme.Accent })
            tween(modKnob, 0.15, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1) })
        else
            tween(modSwitch, 0.15, { BackgroundColor3 = self.Theme.Element })
            tween(modKnob, 0.15, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(180, 180, 190) })
        end
    end)

    local scroll = createInstance("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = page,
    })
    padding(scroll, 4, 16, 16, 16)

    local columns = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = scroll,
    })

    local left = createInstance("Frame", {
        Size = UDim2.new(0.5, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = columns,
    })
    listLayout(left, 10)

    local right = createInstance("Frame", {
        Position = UDim2.new(0.5, 6, 0, 0),
        Size = UDim2.new(0.5, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = columns,
    })
    listLayout(right, 10)

    tab._Button     = btn
    tab._Label      = label
    tab._Indicator  = indicator
    tab._Page       = page
    tab._Left       = left
    tab._Right      = right
    tab._ModSwitch  = modSwitch
    tab._ModKnob    = modKnob

    table.insert(self.Tabs, tab)

    if not self.CurrentTab then
        self:SetCurrentTab(tab)
    end

    function tab:AddLeftGroupbox(gname)
        return Library:_CreateGroupbox(tab._Left, gname, tab)
    end

    function tab:AddRightGroupbox(gname)
        return Library:_CreateGroupbox(tab._Right, gname, tab)
    end

    function tab:AddLeftTabbox()
        return Library:_CreateTabbox(tab._Left, tab)
    end

    function tab:AddRightTabbox()
        return Library:_CreateTabbox(tab._Right, tab)
    end

    return tab
end

function Library:_CreateGroupbox(parent, name, parentTab)
    local groupbox = {}
    groupbox.Name = name
    groupbox.Elements = {}

    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        Parent = parent,
    })
    corner(frame, 8)
    stroke(frame, self.Theme.ElementBorder, 1)
    self:AddToRegistry(frame, { BackgroundColor3 = "Groupbox" })

    local header = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = frame,
    })

    local headerLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    self:AddToRegistry(headerLbl, { TextColor3 = "Text" })

    local headerLine = createInstance("Frame", {
        Position = UDim2.new(0, 14, 1, -1),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = self.Theme.Divider,
        BorderSizePixel = 0,
        Parent = header,
    })
    self:AddToRegistry(headerLine, { BackgroundColor3 = "Divider" })

    local body = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    padding(body, 10, 14, 12, 14)

    local container = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = body,
    })
    listLayout(container, 6)

    groupbox._Frame      = frame
    groupbox._Header     = header
    groupbox._HeaderLbl  = headerLbl
    groupbox._Body       = body
    groupbox._Container  = container
    groupbox._ParentTab  = parentTab

    Library:_AttachElementMethods(groupbox)

    return groupbox
end

function Library:_CreateTabbox(parent, parentTab)
    local tabbox = {}
    tabbox.Tabs = {}
    tabbox.CurrentTab = nil

    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        Parent = parent,
    })
    corner(frame, 8)
    stroke(frame, self.Theme.ElementBorder, 1)
    self:AddToRegistry(frame, { BackgroundColor3 = "Groupbox" })

    local tabHeader = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    padding(tabHeader, 4, 6, 0, 6)
    listLayout(tabHeader, 4, Enum.FillDirection.Horizontal)

    local headerLine = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self.Theme.Divider,
        BorderSizePixel = 0,
        Parent = frame,
    })
    self:AddToRegistry(headerLine, { BackgroundColor3 = "Divider" })

    local body = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 33),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    padding(body, 8, 14, 12, 14)

    function tabbox:AddTab(name)
        local sub = {}
        sub.Name = name
        sub.Elements = {}

        local tabBtn = createInstance("TextButton", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = tabHeader,
        })

        local tabLbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "  " .. name .. "  ",
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = tabBtn,
        })

        local underline = createInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, -8, 0, 2),
            BackgroundColor3 = Library.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabBtn,
        })
        Library:AddToRegistry(underline, { BackgroundColor3 = "Accent" })

        local subContainer = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = body,
        })
        listLayout(subContainer, 6)

        sub._Btn         = tabBtn
        sub._Lbl         = tabLbl
        sub._Underline   = underline
        sub._Container   = subContainer
        sub._ParentTab   = parentTab

        Library:_AttachElementMethods(sub)

        tabBtn.MouseButton1Click:Connect(function()
            tabbox:SetActive(sub)
        end)

        tabBtn.MouseEnter:Connect(function()
            if tabbox.CurrentTab ~= sub then
                tween(tabLbl, 0.12, { TextColor3 = Library.Theme.Text })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if tabbox.CurrentTab ~= sub then
                tween(tabLbl, 0.12, { TextColor3 = Library.Theme.TextDim })
            end
        end)

        table.insert(tabbox.Tabs, sub)
        if not tabbox.CurrentTab then
            tabbox:SetActive(sub)
        end

        return sub
    end

    function tabbox:SetActive(sub)
        if tabbox.CurrentTab == sub then return end
        for _, t in ipairs(tabbox.Tabs) do
            if t == sub then
                t._Container.Visible = true
                tween(t._Lbl, 0.15, { TextColor3 = Library.Theme.Text })
                tween(t._Underline, 0.15, { BackgroundTransparency = 0 })
            else
                t._Container.Visible = false
                tween(t._Lbl, 0.15, { TextColor3 = Library.Theme.TextDim })
                tween(t._Underline, 0.15, { BackgroundTransparency = 1 })
            end
        end
        tabbox.CurrentTab = sub
    end

    return tabbox
end

function Library:_AttachElementMethods(host)
end

function Library:_AttachElementMethods(host)

    function host:AddLabel(text, doesWrap)
        local element = {}
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, doesWrap and 0 or 18),
            AutomaticSize = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Text = text or "",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = doesWrap or false,
            Parent = host._Container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })

        element._Label = lbl

        function element:SetText(t)
            lbl.Text = t
        end

        return element
    end

    function host:AddDivider()
        local frame = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Library.Theme.Divider,
            BorderSizePixel = 0,
            Parent = host._Container,
        })
        Library:AddToRegistry(frame, { BackgroundColor3 = "Divider" })
        return frame
    end

    function host:AddButton(opts, fn)
        local element = {}
        if type(opts) == "string" then
            opts = { Text = opts, Func = fn }
        end
        opts = opts or {}

        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })

        local btn = createInstance("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = opts.Text or "Button",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = container,
        })
        corner(btn, 6)
        stroke(btn, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(btn, { BackgroundColor3 = "Element", TextColor3 = "Text" })

        local clickCount = 0
        local clickReset
        btn.MouseButton1Click:Connect(function()
            if opts.DoubleClick then
                clickCount = clickCount + 1
                if clickCount == 1 then
                    local oldText = opts.Text or "Button"
                    btn.Text = "Are you sure?"
                    if clickReset then task.cancel(clickReset) end
                    clickReset = task.delay(1.5, function()
                        clickCount = 0
                        btn.Text = oldText
                    end)
                elseif clickCount >= 2 then
                    clickCount = 0
                    btn.Text = opts.Text or "Button"
                    if clickReset then task.cancel(clickReset); clickReset = nil end
                    Library:SafeCallback(opts.Func)
                end
            else
                Library:SafeCallback(opts.Func)
            end
        end)

        btn.MouseEnter:Connect(function()
            tween(btn, 0.12, { BackgroundColor3 = Library.Theme.ElementHover })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, 0.12, { BackgroundColor3 = Library.Theme.Element })
        end)

        element._Button = btn
        function element:SetText(t)
            btn.Text = t
            opts.Text = t
        end
        function element:AddButton(o, f)
            return host:AddButton(o, f)
        end

        return element
    end

    function host:AddToggle(idx, opts)
        opts = opts or {}
        local element = {}
        element.Type = "Toggle"
        element.Value = opts.Default or false
        element.Callbacks = {}
        element.Idx = idx

        local row = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })

        local txt = createInstance("TextLabel", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Toggle",
            TextColor3 = opts.Risky and Library.Theme.Danger or Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        if not opts.Risky then
            Library:AddToRegistry(txt, { TextColor3 = "Text" })
        end

        local switch = createInstance("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 36, 0, 20),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = row,
        })
        corner(switch, 10)
        stroke(switch, Library.Theme.ElementBorder, 1)

        local knob = createInstance("Frame", {
            Position = UDim2.new(0, 2, 0.5, -7),
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = Color3.fromRGB(180, 180, 190),
            BorderSizePixel = 0,
            Parent = switch,
        })
        corner(knob, 7)

        element._Row    = row
        element._Switch = switch
        element._Knob   = knob
        element._Label  = txt

        local function updateVisual()
            if element.Value then
                tween(switch, 0.15, { BackgroundColor3 = Library.Theme.Accent })
                tween(knob, 0.15, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1) })
            else
                tween(switch, 0.15, { BackgroundColor3 = Library.Theme.Element })
                tween(knob, 0.15, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(180, 180, 190) })
            end
        end

        function element:SetValue(v, skipCallback)
            element.Value = v and true or false
            updateVisual()
            if not skipCallback then
                Library:SafeCallback(opts.Callback, element.Value)
                Library:SafeCallback(opts.Changed, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
            end
            if Library.SaveManager then
                pcall(function() Library.SaveManager:Save() end)
            end
        end

        function element:GetState()
            return element.Value
        end

        function element:GetValue()
            return element.Value
        end

        function element:OnChanged(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        switch.MouseButton1Click:Connect(function()
            if opts.Disabled then return end
            element:SetValue(not element.Value)
        end)

        function element:AddKeyPicker(kidx, kopts)
            return host:_AttachKeyPicker(row, element, kidx, kopts)
        end

        function element:AddColorPicker(cidx, copts)
            return host:_AttachColorPicker(row, element, cidx, copts)
        end

        if idx then
            Library.Toggles[idx] = element
        end

        updateVisual()
        if element.Value then
            task.defer(function()
                Library:SafeCallback(opts.Callback, element.Value)
            end)
        end

        return element
    end

    function host:AddInput(idx, opts)
        opts = opts or {}
        local element = {}
        element.Type = "Input"
        element.Value = opts.Default or ""
        element.Callbacks = {}
        element.Idx = idx

        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })

        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Input",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })

        local box = createInstance("Frame", {
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Parent = container,
        })
        corner(box, 6)
        stroke(box, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(box, { BackgroundColor3 = "Element" })

        local input = createInstance("TextBox", {
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(element.Value),
            PlaceholderText = opts.Placeholder or "",
            PlaceholderColor3 = Library.Theme.TextMuted,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = box,
        })
        Library:AddToRegistry(input, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })

        element._Box   = box
        element._Input = input
        element._Label = lbl

        local function process(text)
            if opts.Numeric then
                text = tostring(text):gsub("[^%d%.%-]", "")
                local num = tonumber(text) or 0
                if opts.MaxLength and #text > opts.MaxLength then
                    text = text:sub(1, opts.MaxLength)
                end
                element.Value = num
                input.Text = text
            else
                if opts.MaxLength and #text > opts.MaxLength then
                    text = text:sub(1, opts.MaxLength)
                    input.Text = text
                end
                element.Value = text
            end
        end

        if opts.Finished then
            input.FocusLost:Connect(function(enter)
                process(input.Text)
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
                if Library.SaveManager then
                    pcall(function() Library.SaveManager:Save() end)
                end
            end)
        else
            input:GetPropertyChangedSignal("Text"):Connect(function()
                process(input.Text)
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
            end)
            input.FocusLost:Connect(function()
                if Library.SaveManager then
                    pcall(function() Library.SaveManager:Save() end)
                end
            end)
        end

        input.Focused:Connect(function()
            tween(box, 0.15, { BackgroundColor3 = Library.Theme.ElementHover })
        end)
        input.FocusLost:Connect(function()
            tween(box, 0.15, { BackgroundColor3 = Library.Theme.Element })
        end)

        function element:SetValue(v, skipCallback)
            element.Value = v
            input.Text = tostring(v)
            if not skipCallback then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
            end
        end

        function element:GetValue()
            return element.Value
        end

        function element:OnChanged(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        if idx then
            Library.Options[idx] = element
        end

        return element
    end

    function host:AddDependencyBox()
        local depBox = {}
        depBox.Elements = {}
        depBox.Dependencies = {}

        local frame = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible = true,
            Parent = host._Container,
        })

        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = frame,
        })
        listLayout(container, 6)

        depBox._Frame      = frame
        depBox._Container  = container

        Library:_AttachElementMethods(depBox)

        function depBox:SetupDependencies(deps)
            depBox.Dependencies = deps or {}
            depBox:Update()
        end

        function depBox:Update()
            local show = true
            for _, dep in ipairs(depBox.Dependencies) do
                local target, wanted = dep[1], dep[2]
                if not target then show = false break end
                local val = nil
                if target.GetState then val = target:GetState()
                elseif target.GetValue then val = target:GetValue()
                else val = target.Value end
                if val ~= wanted then show = false break end
            end
            frame.Visible = show
        end

        task.spawn(function()
            while frame.Parent do
                depBox:Update()
                task.wait(0.25)
            end
        end)

        return depBox
    end

    function host:_AttachKeyPicker(parentRow, parentElement, idx, opts)
    end

    function host:_AttachColorPicker(parentRow, parentElement, idx, opts)
    end
end

local function _addSliderMethod(host)
    function host:AddSlider(idx, opts)
        opts = opts or {}
        local element = {}
        element.Type = "Slider"
        element.Idx = idx
        element.Min = opts.Min or 0
        element.Max = opts.Max or 100
        element.Rounding = opts.Rounding or 0
        element.Suffix = opts.Suffix or ""
        element.Value = math.clamp(opts.Default or element.Min, element.Min, element.Max)
        element.Callbacks = {}

        local function roundValue(v)
            local mult = 10 ^ element.Rounding
            return math.floor(v * mult + 0.5) / mult
        end

        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, opts.Compact and 26 or 42),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })

        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -80, 0, 16),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Slider",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })

        local valLbl = createInstance("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 80, 0, 16),
            BackgroundTransparency = 1,
            Text = tostring(element.Value) .. element.Suffix,
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = container,
        })
        Library:AddToRegistry(valLbl, { TextColor3 = "TextDim" })

        local barBg = createInstance("Frame", {
            Position = UDim2.new(0, 0, 0, opts.Compact and 14 or 24),
            Size = UDim2.new(1, 0, 0, opts.Compact and 8 or 12),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Parent = container,
        })
        corner(barBg, 4)
        stroke(barBg, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(barBg, { BackgroundColor3 = "Element" })

        local fill = createInstance("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            Parent = barBg,
        })
        corner(fill, 4)
        Library:AddToRegistry(fill, { BackgroundColor3 = "Accent" })

        local hitbox = createInstance("TextButton", {
            Size = UDim2.new(1, 0, 1, 12),
            Position = UDim2.new(0, 0, 0, -6),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = barBg,
        })

        element._Container = container
        element._Bar       = barBg
        element._Fill      = fill
        element._ValueLbl  = valLbl
        element._Label     = lbl

        local function updateFromValue()
            local pct = (element.Value - element.Min) / (element.Max - element.Min)
            pct = math.clamp(pct, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            if opts.HideMax then
                valLbl.Text = tostring(element.Value) .. element.Suffix
            else
                valLbl.Text = tostring(element.Value) .. element.Suffix .. " / " .. tostring(element.Max) .. element.Suffix
            end
        end

        function element:SetValue(v, skipCallback)
            v = math.clamp(roundValue(v), element.Min, element.Max)
            if element.Rounding == 0 then v = math.floor(v) end
            element.Value = v
            updateFromValue()
            if not skipCallback then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
            end
            if Library.SaveManager then
                pcall(function() Library.SaveManager:Save() end)
            end
        end

        function element:GetValue() return element.Value end
        function element:OnChanged(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        local dragging = false
        local function updateFromPos(x)
            local abs = barBg.AbsolutePosition.X
            local size = barBg.AbsoluteSize.X
            if size <= 0 then return end
            local pct = math.clamp((x - abs) / size, 0, 1)
            local raw = element.Min + (element.Max - element.Min) * pct
            element:SetValue(raw)
        end

        hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromPos(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromPos(input.Position.X)
            end
        end)

        if idx then
            Library.Options[idx] = element
        end

        updateFromValue()
        return element
    end
end

local function _addDropdownMethod(host)
    function host:AddDropdown(idx, opts)
        opts = opts or {}
        local element = {}
        element.Type = "Dropdown"
        element.Idx = idx
        element.Values = opts.Values or {}
        element.Multi = opts.Multi or false
        element.AllowNull = opts.AllowNull or false
        element.Callbacks = {}
        element.SpecialType = opts.SpecialType

        if element.Multi then
            element.Value = opts.Default or {}
            if type(element.Value) ~= "table" then
                local t = {}
                if element.Value then t[tostring(element.Value)] = true end
                element.Value = t
            end
        else
            element.Value = opts.Default
        end

        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })

        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Dropdown",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })

        local btn = createInstance("TextButton", {
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = container,
        })
        corner(btn, 6)
        stroke(btn, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(btn, { BackgroundColor3 = "Element" })

        local displayLbl = createInstance("TextLabel", {
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        Library:AddToRegistry(displayLbl, { TextColor3 = "Text" })

        local arrow = createInstance("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Text = "v",
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            Parent = btn,
        })
        Library:AddToRegistry(arrow, { TextColor3 = "TextDim" })

        local popup = createInstance("Frame", {
            Visible = false,
            BackgroundColor3 = Library.Theme.Groupbox,
            BorderSizePixel = 0,
            ZIndex = 50,
            Parent = Library.ScreenGui,
        })
        corner(popup, 6)
        stroke(popup, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(popup, { BackgroundColor3 = "Groupbox" })

        local scroll = createInstance("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 51,
            Parent = popup,
        })
        padding(scroll, 4)
        local layout = listLayout(scroll, 2)

        element._Container = container
        element._Button    = btn
        element._Display   = displayLbl
        element._Popup     = popup
        element._Scroll    = scroll
        element._Arrow     = arrow

        local function isSelected(v)
            if element.Multi then
                return element.Value[tostring(v)] == true
            else
                return tostring(element.Value) == tostring(v)
            end
        end

        local function updateDisplay()
            if element.Multi then
                local list = {}
                for k, on in pairs(element.Value) do
                    if on then table.insert(list, tostring(k)) end
                end
                if #list == 0 then
                    displayLbl.Text = "None"
                    displayLbl.TextColor3 = Library.Theme.TextDim
                elseif #list == 1 then
                    displayLbl.Text = list[1]
                    displayLbl.TextColor3 = Library.Theme.Text
                else
                    displayLbl.Text = list[1] .. " +" .. (#list - 1)
                    displayLbl.TextColor3 = Library.Theme.Text
                end
            else
                if element.Value == nil or tostring(element.Value) == "" then
                    displayLbl.Text = "None"
                    displayLbl.TextColor3 = Library.Theme.TextDim
                else
                    displayLbl.Text = tostring(element.Value)
                    displayLbl.TextColor3 = Library.Theme.Text
                end
            end
        end

        local optionBtns = {}
        local function rebuild()
            for _, b in ipairs(optionBtns) do b:Destroy() end
            optionBtns = {}

            for _, val in ipairs(element.Values) do
                local strVal = tostring(val)
                local ob = createInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = Library.Theme.Element,
                    BackgroundTransparency = isSelected(val) and 0 or 1,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 52,
                    Parent = scroll,
                })
                corner(ob, 4)

                local indicator = createInstance("Frame", {
                    Position = UDim2.new(0, 6, 0.5, -6),
                    Size = UDim2.new(0, 3, 0, 12),
                    BackgroundColor3 = Library.Theme.Accent,
                    BackgroundTransparency = isSelected(val) and 0 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 53,
                    Parent = ob,
                })
                corner(indicator, 2)
                Library:AddToRegistry(indicator, { BackgroundColor3 = "Accent" })

                local oblbl = createInstance("TextLabel", {
                    Position = UDim2.new(0, 16, 0, 0),
                    Size = UDim2.new(1, -22, 1, 0),
                    BackgroundTransparency = 1,
                    Text = strVal,
                    TextColor3 = isSelected(val) and Library.Theme.Text or Library.Theme.TextDim,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 53,
                    Parent = ob,
                })

                ob.MouseEnter:Connect(function()
                    if not isSelected(val) then
                        tween(ob, 0.1, { BackgroundTransparency = 0.5 })
                    end
                end)
                ob.MouseLeave:Connect(function()
                    if not isSelected(val) then
                        tween(ob, 0.1, { BackgroundTransparency = 1 })
                    end
                end)

                ob.MouseButton1Click:Connect(function()
                    if element.Multi then
                        element.Value[strVal] = not element.Value[strVal] or nil
                        if element.Value[strVal] == false then element.Value[strVal] = nil end
                    else
                        if element.AllowNull and tostring(element.Value) == strVal then
                            element.Value = nil
                        else
                            element.Value = val
                        end
                        element:Close()
                    end
                    rebuild()
                    updateDisplay()
                    local out = element.Multi and element.Value or element.Value
                    Library:SafeCallback(opts.Callback, out)
                    for _, cb in ipairs(element.Callbacks) do
                        Library:SafeCallback(cb, out)
                    end
                    if Library.SaveManager then
                        pcall(function() Library.SaveManager:Save() end)
                    end
                end)

                table.insert(optionBtns, ob)
            end
        end

        function element:Open()
            if Library.OpenedDropdown and Library.OpenedDropdown ~= element then
                Library.OpenedDropdown:Close()
            end
            Library.OpenedDropdown = element
            local ap = btn.AbsolutePosition
            local as = btn.AbsoluteSize
            local maxH = math.min(200, #element.Values * 26 + 8)
            popup.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
            popup.Size = UDim2.new(0, as.X, 0, maxH)
            popup.Visible = true
            arrow.Text = "^"
        end

        function element:Close()
            popup.Visible = false
            arrow.Text = "v"
            if Library.OpenedDropdown == element then
                Library.OpenedDropdown = nil
            end
        end

        function element:Toggle()
            if popup.Visible then element:Close() else element:Open() end
        end

        function element:SetValues(vals)
            element.Values = vals or {}
            if element.Multi then
                for k in pairs(element.Value) do
                    local found = false
                    for _, v in ipairs(element.Values) do
                        if tostring(v) == k then found = true break end
                    end
                    if not found then element.Value[k] = nil end
                end
            else
                local found = false
                for _, v in ipairs(element.Values) do
                    if tostring(v) == tostring(element.Value) then found = true break end
                end
                if not found and not element.AllowNull then
                    element.Value = element.Values[1]
                end
            end
            rebuild()
            updateDisplay()
        end

        function element:SetValue(v, skipCallback)
            if element.Multi then
                if type(v) == "table" then
                    local nv = {}
                    if v[1] ~= nil then
                        for _, item in ipairs(v) do nv[tostring(item)] = true end
                    else
                        for k, on in pairs(v) do
                            if on then nv[tostring(k)] = true end
                        end
                    end
                    element.Value = nv
                end
            else
                element.Value = v
            end
            rebuild()
            updateDisplay()
            if not skipCallback then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, element.Value)
                end
            end
        end

        function element:GetValue() return element.Value end
        function element:OnChanged(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        btn.MouseButton1Click:Connect(function()
            element:Toggle()
        end)

        Library:Connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if popup.Visible then
                    local mp = input.Position
                    local pp = popup.AbsolutePosition
                    local ps = popup.AbsoluteSize
                    local bp = btn.AbsolutePosition
                    local bs = btn.AbsoluteSize
                    local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                    if not inPopup and not inBtn then
                        element:Close()
                    end
                end
            end
        end)

        if idx then
            Library.Options[idx] = element
        end

        rebuild()
        updateDisplay()
        return element
    end
end

local _origAttach = Library._AttachElementMethods
function Library:_AttachElementMethods(host)
    _origAttach(self, host)
    _addSliderMethod(host)
    _addDropdownMethod(host)
end

local function _addColorPickerToHost(host)

    local function buildColorPicker(parentRow, idx, opts, mode)
        opts = opts or {}
        local element = {}
        element.Type = "ColorPicker"
        element.Idx = idx
        element.Value = opts.Default or Color3.fromRGB(255, 255, 255)
        element.Transparency = opts.Transparency or 0
        element.Title = opts.Title or "Color"
        element.Callbacks = {}

        local h, s, v = Color3.toHSV(element.Value)
        element._H, element._S, element._V = h, s, v

        local size = 20
        local pickerBtn = createInstance("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = mode == "row" and UDim2.new(1, -44, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, size, 0, size),
            BackgroundColor3 = element.Value,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = parentRow,
        })
        corner(pickerBtn, 4)
        stroke(pickerBtn, Library.Theme.ElementBorder, 1)

        element._Btn = pickerBtn

        local popup = createInstance("Frame", {
            Visible = false,
            Size = UDim2.new(0, 240, 0, 260),
            BackgroundColor3 = Library.Theme.Groupbox,
            BorderSizePixel = 0,
            ZIndex = 60,
            Parent = Library.ScreenGui,
        })
        corner(popup, 8)
        stroke(popup, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(popup, { BackgroundColor3 = "Groupbox" })

        local title = createInstance("TextLabel", {
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -20, 0, 16),
            BackgroundTransparency = 1,
            Text = element.Title,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 61,
            Parent = popup,
        })

        local svBox = createInstance("ImageLabel", {
            Position = UDim2.new(0, 10, 0, 26),
            Size = UDim2.new(0, 180, 0, 140),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            BorderSizePixel = 0,
            Image = "",
            ZIndex = 61,
            Parent = popup,
        })
        corner(svBox, 4)

        local satGrad = createInstance("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1)),
            Parent = svBox,
        })

        local valOverlay = createInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 62,
            Parent = svBox,
        })
        corner(valOverlay, 4)
        createInstance("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Parent = valOverlay,
        })

        local svCursor = createInstance("Frame", {
            Size = UDim2.new(0, 8, 0, 8),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 64,
            Parent = svBox,
        })
        local svRing = createInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 64,
            Parent = svCursor,
        })
        corner(svRing, 4)
        stroke(svRing, Color3.new(1, 1, 1), 2)

        local hueBar = createInstance("ImageLabel", {
            Position = UDim2.new(0, 198, 0, 26),
            Size = UDim2.new(0, 14, 0, 140),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Image = "",
            ZIndex = 61,
            Parent = popup,
        })
        corner(hueBar, 3)
        createInstance("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0,    1, 1)),
                ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1,    1, 1)),
            }),
            Parent = hueBar,
        })

        local hueCursor = createInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 4, 0, 3),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 63,
            Parent = hueBar,
        })
        corner(hueCursor, 1)

        local alphaBar
        local alphaCursor
        if opts.Transparency ~= nil then
            alphaBar = createInstance("Frame", {
                Position = UDim2.new(0, 10, 0, 174),
                Size = UDim2.new(0, 202, 0, 12),
                BackgroundColor3 = element.Value,
                BorderSizePixel = 0,
                ZIndex = 61,
                Parent = popup,
            })
            corner(alphaBar, 3)
            createInstance("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Parent = alphaBar,
            })
            alphaCursor = createInstance("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 3, 1, 4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 63,
                Parent = alphaBar,
            })
            corner(alphaCursor, 1)
        end

        local hexBox = createInstance("Frame", {
            Position = UDim2.new(0, 10, 1, -64),
            Size = UDim2.new(1, -20, 0, 24),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            ZIndex = 61,
            Parent = popup,
        })
        corner(hexBox, 4)
        stroke(hexBox, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(hexBox, { BackgroundColor3 = "Element" })

        local hexInput = createInstance("TextBox", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = string.format("#%02X%02X%02X", element.Value.R*255, element.Value.G*255, element.Value.B*255),
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex = 62,
            Parent = hexBox,
        })

        local doneBtn = createInstance("TextButton", {
            Position = UDim2.new(0, 10, 1, -34),
            Size = UDim2.new(1, -20, 0, 26),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            Text = "Done",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 61,
            Parent = popup,
        })
        corner(doneBtn, 4)
        Library:AddToRegistry(doneBtn, { BackgroundColor3 = "Accent" })

        local function updateAll()
            local color = Color3.fromHSV(element._H, element._S, element._V)
            element.Value = color
            pickerBtn.BackgroundColor3 = color
            satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(element._H, 1, 1))
            svBox.BackgroundColor3 = Color3.fromHSV(element._H, 1, 1)
            valOverlay.BackgroundTransparency = element._V
            svCursor.Position = UDim2.new(element._S, 0, 1 - element._V, 0)
            hueCursor.Position = UDim2.new(0.5, 0, element._H, 0)
            hexInput.Text = string.format("#%02X%02X%02X", color.R*255, color.G*255, color.B*255)
            if alphaBar then
                alphaBar.BackgroundColor3 = color
                alphaCursor.Position = UDim2.new(1 - element.Transparency, 0, 0.5, 0)
            end
        end

        local function fire()
            Library:SafeCallback(opts.Callback, element.Value, element.Transparency)
            for _, cb in ipairs(element.Callbacks) do
                Library:SafeCallback(cb, element.Value, element.Transparency)
            end
            if Library.SaveManager then
                pcall(function() Library.SaveManager:Save() end)
            end
        end

        local svDragging, hueDragging, alphaDragging
        svBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                svDragging = true
            end
        end)
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                hueDragging = true
            end
        end)
        if alphaBar then
            alphaBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    alphaDragging = true
                end
            end)
        end
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if svDragging or hueDragging or alphaDragging then
                    svDragging, hueDragging, alphaDragging = false, false, false
                    fire()
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if svDragging then
                local rel = input.Position - svBox.AbsolutePosition
                local sX = math.clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
                local sY = math.clamp(rel.Y / svBox.AbsoluteSize.Y, 0, 1)
                element._S = sX
                element._V = 1 - sY
                updateAll()
            elseif hueDragging then
                local rel = input.Position.Y - hueBar.AbsolutePosition.Y
                local hY = math.clamp(rel / hueBar.AbsoluteSize.Y, 0, 1)
                element._H = hY
                updateAll()
            elseif alphaDragging and alphaBar then
                local rel = input.Position.X - alphaBar.AbsolutePosition.X
                local aX = math.clamp(rel / alphaBar.AbsoluteSize.X, 0, 1)
                element.Transparency = 1 - aX
                updateAll()
            end
        end)

        hexInput.FocusLost:Connect(function()
            local txt = hexInput.Text:gsub("#", ""):gsub("%s", "")
            if #txt == 6 then
                local r = tonumber(txt:sub(1, 2), 16)
                local g = tonumber(txt:sub(3, 4), 16)
                local b = tonumber(txt:sub(5, 6), 16)
                if r and g and b then
                    local c = Color3.fromRGB(r, g, b)
                    element._H, element._S, element._V = Color3.toHSV(c)
                    updateAll()
                    fire()
                    return
                end
            end
            updateAll()
        end)

        doneBtn.MouseButton1Click:Connect(function()
            element:Close()
        end)

        function element:Open()
            if Library.OpenedColorPicker and Library.OpenedColorPicker ~= element then
                Library.OpenedColorPicker:Close()
            end
            Library.OpenedColorPicker = element
            local ap = pickerBtn.AbsolutePosition
            local as = pickerBtn.AbsoluteSize
            popup.Position = UDim2.new(0, ap.X - 240 + as.X, 0, ap.Y + as.Y + 4)
            popup.Visible = true
            updateAll()
        end

        function element:Close()
            popup.Visible = false
            if Library.OpenedColorPicker == element then
                Library.OpenedColorPicker = nil
            end
        end

        function element:Toggle()
            if popup.Visible then element:Close() else element:Open() end
        end

        function element:SetValueRGB(color, transparency)
            element.Value = color
            element._H, element._S, element._V = Color3.toHSV(color)
            if transparency ~= nil then element.Transparency = transparency end
            updateAll()
            fire()
        end

        function element:SetValue(color, transparency)
            element:SetValueRGB(color, transparency)
        end

        function element:GetValue() return element.Value end

        function element:OnChanged(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        pickerBtn.MouseButton1Click:Connect(function()
            element:Toggle()
        end)

        Library:Connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if popup.Visible then
                    local mp = input.Position
                    local pp = popup.AbsolutePosition
                    local ps = popup.AbsoluteSize
                    local bp = pickerBtn.AbsolutePosition
                    local bs = pickerBtn.AbsoluteSize
                    local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                    if not inPopup and not inBtn then
                        element:Close()
                    end
                end
            end
        end)

        if idx then
            Library.Options[idx] = element
        end

        updateAll()
        return element
    end

    function host:_AttachColorPicker(parentRow, parentElement, idx, opts)
        return buildColorPicker(parentRow, idx, opts, "row")
    end

    function host:AddColorPicker(idx, opts)
        opts = opts or {}
        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -32, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or opts.Title or idx or "Color",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })
        return buildColorPicker(container, idx, opts, "standalone")
    end
end

local function _addKeyPickerToHost(host)

    local function buildKeyPicker(parentRow, idx, opts, mode)
        opts = opts or {}
        local element = {}
        element.Type = "KeyPicker"
        element.Idx = idx
        element.Value = opts.Default or "None"
        element.Mode = opts.Mode or "Toggle"
        element.Text = opts.Text or idx or "Keybind"
        element.SyncToggleState = opts.SyncToggleState or false
        element.NoUI = opts.NoUI or false
        element.Callbacks = {}
        element.ChangedCallbacks = {}
        element.Toggled = false
        element.Holding = false

        local btn = createInstance("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = mode == "row" and UDim2.new(1, -44, 0.5, 0) or UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 90, 0, 20),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = tostring(element.Value),
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            AutoButtonColor = false,
            Parent = parentRow,
        })
        corner(btn, 4)
        stroke(btn, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(btn, { BackgroundColor3 = "Element", TextColor3 = "TextDim" })

        element._Btn = btn

        local listening = false

        local function setText()
            if listening then
                btn.Text = "..."
            else
                btn.Text = "[" .. tostring(element.Value) .. "]"
            end
        end

        btn.MouseButton1Click:Connect(function()
            listening = true
            setText()
        end)

        local function keyToString(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                return input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                return "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                return "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                return "MB3"
            end
            return nil
        end

        Library:Connect(UserInputService.InputBegan, function(input, processed)
            if listening then
                local key = keyToString(input)
                if key then
                    element.Value = key
                    listening = false
                    setText()
                    Library:SafeCallback(opts.ChangedCallback, element.Value)
                    for _, cb in ipairs(element.ChangedCallbacks) do
                        Library:SafeCallback(cb, element.Value)
                    end
                    if Library.SaveManager then
                        pcall(function() Library.SaveManager:Save() end)
                    end
                end
                return
            end
            if processed then return end
            local key = keyToString(input)
            if key and key == element.Value then
                if element.Mode == "Toggle" then
                    element.Toggled = not element.Toggled
                    if element.SyncToggleState and parentElement and parentElement.SetValue then
                        parentElement:SetValue(element.Toggled)
                    end
                    Library:SafeCallback(opts.Callback, element.Toggled)
                    for _, cb in ipairs(element.Callbacks) do
                        Library:SafeCallback(cb, element.Toggled)
                    end
                elseif element.Mode == "Hold" then
                    element.Holding = true
                    Library:SafeCallback(opts.Callback, true)
                    for _, cb in ipairs(element.Callbacks) do
                        Library:SafeCallback(cb, true)
                    end
                elseif element.Mode == "Always" then
                end
            end
        end)

        Library:Connect(UserInputService.InputEnded, function(input)
            local key = keyToString(input)
            if key and key == element.Value and element.Mode == "Hold" then
                element.Holding = false
                Library:SafeCallback(opts.Callback, false)
                for _, cb in ipairs(element.Callbacks) do
                    Library:SafeCallback(cb, false)
                end
            end
        end)

        function element:GetState()
            if element.Mode == "Always" then return true end
            if element.Mode == "Toggle" then return element.Toggled end
            if element.Mode == "Hold"   then return element.Holding end
            return false
        end

        function element:SetValue(data)
            if type(data) == "table" then
                element.Value = data[1] or element.Value
                element.Mode  = data[2] or element.Mode
            else
                element.Value = data
            end
            setText()
        end

        function element:GetValue() return element.Value end

        function element:OnChanged(cb)
            table.insert(element.ChangedCallbacks, cb)
            return element
        end

        function element:OnClick(cb)
            table.insert(element.Callbacks, cb)
            return element
        end

        if idx then
            Library.Options[idx] = element
        end

        setText()
        return element
    end

    function host:_AttachKeyPicker(parentRow, parentElement, idx, opts)
        return buildKeyPicker(parentRow, idx, opts, "row")
    end

    function host:AddKeyPicker(idx, opts)
        opts = opts or {}
        local container = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = host._Container,
        })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -100, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Keybind",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })
        return buildKeyPicker(container, idx, opts, "standalone")
    end
end

local _prevAttach = Library._AttachElementMethods
function Library:_AttachElementMethods(host)
    _prevAttach(self, host)
    _addColorPickerToHost(host)
    _addKeyPickerToHost(host)
end

function Library:Notify(opts, timeOverride)
    if not self.NotifyContainer then return end

    if type(opts) == "string" then
        opts = { Title = self.Title, Description = opts, Time = timeOverride or 4 }
    end
    opts = opts or {}

    local title    = opts.Title or self.Title
    local desc     = opts.Description or ""
    local duration = opts.Time or 4

    local notif = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.NotifyContainer,
    })
    corner(notif, 8)
    stroke(notif, self.Theme.ElementBorder, 1)

    local accent = createInstance("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })
    corner(accent, 2)

    local titleLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 20, 0, 8),
        Size = UDim2.new(1, -28, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local descLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 20, 0, 28),
        Size = UDim2.new(1, -28, 0, 30),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = notif,
    })

    local progress = createInstance("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })

    local fromX = self.NotifySide == "Left" and -320 or 320
    notif.Position = UDim2.new(0, fromX, 0, 0)
    tween(notif, 0.3, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quart)
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(notif, 0.3, { Position = UDim2.new(0, fromX, 0, 0) }, Enum.EasingStyle.Quart)
        task.wait(0.3)
        if notif and notif.Parent then notif:Destroy() end
    end)

    if opts.SoundId then
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://" .. tostring(opts.SoundId)
            s.Volume = 0.5
            s.Parent = self.NotifyGui
            s:Play()
            game:GetService("Debris"):AddItem(s, 3)
        end)
    end
end

function Library:SetNotifySide(side)
    self.NotifySide = side
    if self.NotifyContainer then
        if side == "Left" then
            self.NotifyContainer.AnchorPoint = Vector2.new(0, 0)
            self.NotifyContainer.Position    = UDim2.new(0, 20, 0, 20)
            local layout = self.NotifyContainer:FindFirstChildOfClass("UIListLayout")
            if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Left end
        else
            self.NotifyContainer.AnchorPoint = Vector2.new(1, 0)
            self.NotifyContainer.Position    = UDim2.new(1, -20, 0, 20)
            local layout = self.NotifyContainer:FindFirstChildOfClass("UIListLayout")
            if layout then layout.HorizontalAlignment = Enum.HorizontalAlignment.Right end
        end
    end
end

function Library:SetWatermarkVisibility(state)
    if not self.Watermark then self:_BuildWatermark() end
    self.Watermark.Visible = state and true or false
    self.WatermarkVisible = state and true or false
end

function Library:SetWatermark(text)
    self.WatermarkText = text
    if not self.Watermark then self:_BuildWatermark() end
    if self._WatermarkLbl then
        self._WatermarkLbl.Text = text or ""
    end
end

function Library:_BuildWatermark()
    if self.Watermark then return end
    if not self.NotifyGui then return end

    local frame = createInstance("Frame", {
        Name = "Watermark",
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 240, 0, 28),
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.NotifyGui,
    })
    corner(frame, 6)
    stroke(frame, self.Theme.ElementBorder, 1)
    self:AddToRegistry(frame, { BackgroundColor3 = "Groupbox" })

    local accent = createInstance("Frame", {
        Size = UDim2.new(0, 3, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(accent, 2)
    self:AddToRegistry(accent, { BackgroundColor3 = "Accent" })

    local lbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    self:AddToRegistry(lbl, { TextColor3 = "Text" })

    self.Watermark = frame
    self._WatermarkLbl = lbl

    local lastUpdate = 0
    self:Connect(RunService.RenderStepped, function(dt)
        lastUpdate = lastUpdate + dt
        if lastUpdate < 0.5 then return end
        lastUpdate = 0
        if not frame.Visible then return end
        local fps = math.floor(1 / dt)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local txt = self.WatermarkText
        if not txt then
            txt = self.Title .. " | v" .. tostring(self.Version) .. " | " .. fps .. " fps | " .. ping .. " ms"
        end
        lbl.Text = txt
    end)
end

function Library:_BuildCursor()
    if self.CursorGui then return end
    local parentGui = self.ScreenGui and self.ScreenGui.Parent or CoreGui
    local cg = createInstance("ScreenGui", {
        Name = "FatalityUI_Cursor",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1001,
        Parent = parentGui,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, cg) end
    self.CursorGui = cg

    local cursor = createInstance("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6764432293",
        ImageColor3 = self.Theme.Accent,
        Visible = false,
        Parent = cg,
    })
    self:AddToRegistry(cursor, { ImageColor3 = "Accent" })
    self._Cursor = cursor

    self:Connect(RunService.RenderStepped, function()
        if self.ShowCustomCursor and self.Toggled and not self.IsMobile then
            cursor.Visible = true
            UserInputService.MouseIconEnabled = false
            local mp = UserInputService:GetMouseLocation()
            cursor.Position = UDim2.new(0, mp.X, 0, mp.Y - 36)
        else
            cursor.Visible = false
            UserInputService.MouseIconEnabled = true
        end
    end)
end

function Library:_BuildKeybindList()
    if self.KeybindFrame then return end
    local frame = createInstance("Frame", {
        Name = "Keybinds",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, -20),
        Size = UDim2.new(0, 180, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.NotifyGui,
    })
    corner(frame, 6)
    stroke(frame, self.Theme.ElementBorder, 1)
    self:AddToRegistry(frame, { BackgroundColor3 = "Groupbox" })

    local header = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = frame,
    })
    self:AddToRegistry(header, { TextColor3 = "Text" })

    local list = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    listLayout(list, 2)
    padding(list, 2, 10, 8, 10)

    self.KeybindFrame = frame
    self.KeybindContainer = frame
    self._KeybindList = list

    self:Connect(RunService.Heartbeat, function()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        local count = 0
        for idx, opt in pairs(self.Options) do
            if opt.Type == "KeyPicker" and not opt.NoUI then
                count = count + 1
                local state = opt:GetState()
                local color = state and self.Theme.Accent or self.Theme.TextDim
                local lbl = createInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = opt.Text .. ": [" .. tostring(opt.Value) .. "]",
                    TextColor3 = color,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = list,
                })
            end
        end
        frame.Visible = count > 0
    end)
end

function Library:SetKeybindVisibility(state)
    if not self.KeybindFrame then self:_BuildKeybindList() end
    self.KeybindFrame.Visible = state and true or false
end

local _origCreateWindow = Library.CreateWindow
function Library:CreateWindow(opts)
    local win = _origCreateWindow(self, opts)
    self:_BuildWatermark()
    self:_BuildCursor()
    self:_BuildKeybindList()
    return win
end

function Library:GetOption(idx)
    return self.Options[idx]
end

function Library:GetToggle(idx)
    return self.Toggles[idx]
end

function Library:SetToggleKeybind(keyCode)
    if typeof(keyCode) == "EnumItem" then
        self.ToggleKeybind.Value = keyCode
    end
end

function Library:Toggle(state)
    if state == nil then
        self.Toggled = not self.Toggled
    else
        self.Toggled = state and true or false
    end
    if self.Main then
        self.Main.Visible = self.Toggled
    end
end

function Library:IsMobileDevice()
    return self.IsMobile
end

function Library:GetCurrentTab()
    return self.CurrentTab
end

getgenv = getgenv or function() return _G end
local env = getgenv()
env.Toggles = Library.Toggles
env.Options = Library.Options
env.Library = Library

local function _patchSharpCorners()
    if not Library.Main then return end

    if Library.Sidebar then return end

    for _, child in ipairs(Library.Main:GetChildren()) do
        if child.Name == "Sidebar" then
            Library.Sidebar = child
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 10)
            c.Parent = child
            child.ClipsDescendants = false
        elseif child.Name == "Topbar" then
            Library.Topbar = child
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 10)
            c.Parent = child
            child.ClipsDescendants = false
        end
    end

    if Library.Sidebar then
        local mask = Library._createInstance("Frame", {
            Position = UDim2.new(1, -10, 0, 0),
            Size = UDim2.new(0, 10, 1, 0),
            BackgroundColor3 = Library.Theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = Library.Sidebar,
        })
        Library:AddToRegistry(mask, { BackgroundColor3 = "Sidebar" })
    end

    if Library.Topbar then
        local mask = Library._createInstance("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 10, 1, 0),
            BackgroundColor3 = Library.Theme.Topbar,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = Library.Topbar,
        })
        Library:AddToRegistry(mask, { BackgroundColor3 = "Topbar" })
    end
end

local function _replaceMinimizeWithGear()
    if not Library.Main then return end
    local topbar
    for _, c in ipairs(Library.Main:GetChildren()) do
        if c.Name == "Topbar" then topbar = c break end
    end
    if not topbar then return end

    for _, child in ipairs(topbar:GetChildren()) do
        if child:IsA("TextButton") and child.Text == "—" then
            child:Destroy()
        end
    end

    local gear = Library._createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "⚙",
        TextColor3 = Library.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = topbar,
    })
    Library._corner(gear, 6)
    Library:AddToRegistry(gear, { BackgroundColor3 = "Element", TextColor3 = "Text" })

    gear.MouseEnter:Connect(function()
        Library._tween(gear, 0.12, { BackgroundColor3 = Library.Theme.ElementHover })
    end)
    gear.MouseLeave:Connect(function()
        Library._tween(gear, 0.12, { BackgroundColor3 = Library.Theme.Element })
    end)
    gear.MouseButton1Click:Connect(function()
        if Library._SettingsTab then
            Library:SetCurrentTab(Library._SettingsTab)
        end
    end)

    Library._GearBtn = gear

    local lastClick = 0
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local now = tick()
            if now - lastClick < 0.35 then
                Library:_ToggleMinimize()
                lastClick = 0
            else
                lastClick = now
            end
        end
    end)
end

Library._SavedMainSize = nil
Library.Minimized = false
function Library:_ToggleMinimize()
    if not self.Main then return end
    if self.Minimized then
        self.Minimized = false
        if self.ContentFrame then self.ContentFrame.Visible = true end
        if self.Sidebar then self.Sidebar.Visible = true end
        self._tween(self.Main, 0.25, { Size = self._SavedMainSize or UDim2.new(0, 720, 0, 520) })
    else
        self._SavedMainSize = self.Main.Size
        self.Minimized = true
        if self.ContentFrame then self.ContentFrame.Visible = false end
        if self.Sidebar then self.Sidebar.Visible = false end
        self._tween(self.Main, 0.25, { Size = UDim2.new(0, 260, 0, 56) })
    end
end

function Library:SetFooter(text)
    self.Footer = text or self.Footer
    if self.Main then
        for _, desc in ipairs(self.Main:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Parent and desc.Parent.Name == "" and desc.Text:find("Development") then
                desc.Text = self.Footer
            end
        end
        if self._FooterLbl then
            self._FooterLbl.Text = self.Footer
        end
    end
end

local _origCreateWindowPatch = Library.CreateWindow
function Library:CreateWindow(opts)
    local win = _origCreateWindowPatch(self, opts)

    for _, desc in ipairs(self.Main:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text == self.Footer then
            self._FooterLbl = desc
            break
        end
    end

    _patchSharpCorners()
    _replaceMinimizeWithGear()

    self:_BuildSettingsTab()

    return win
end

function Library:_BuildSettingsTab()
    local tab = self:AddTab("Settings")
    self._SettingsTab = tab

    local left = tab:AddLeftGroupbox("Menu")

    left:AddButton({
        Text = "Unload",
        DoubleClick = true,
        Func = function()
            self:Unload()
        end,
    })

    local kb = left:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
        Default = self.ToggleKeybind.Value.Name,
        NoUI = true,
        Text = "Menu Keybind",
        ChangedCallback = function(newKey)
            local enumKey = Enum.KeyCode[newKey]
            if enumKey then
                self.ToggleKeybind.Value = enumKey
            end
        end,
    })
    self._MenuKeybindPicker = kb

    left:AddInput("CustomFooter", {
        Text = "Footer Text",
        Default = self.Footer,
        Placeholder = "v1 - Development Build",
        Finished = true,
        Callback = function(v)
            if v and v ~= "" then
                self:SetFooter(v)
            end
        end,
    })

    local right = tab:AddRightGroupbox("Display")

    right:AddToggle("ShowKeybindList", {
        Text = "Show Keybind List",
        Default = false,
        Callback = function(v)
            self.KeybindListEnabled = v
            self:_RefreshKeybindList()
        end,
    })

    right:AddToggle("ShowWatermark", {
        Text = "Show Watermark",
        Default = false,
        Callback = function(v)
            self:SetWatermarkVisibility(v)
        end,
    })

    right:AddToggle("CustomCursor", {
        Text = "Custom Cursor",
        Default = false,
        Callback = function(v)
            self.ShowCustomCursor = v
        end,
    })

    right:AddDropdown("NotifySide", {
        Text = "Notification Side",
        Values = { "Left", "Right" },
        Default = self.NotifySide,
        Callback = function(v)
            self:SetNotifySide(v)
        end,
    })
end

Library.KeybindListEnabled = false

function Library:_RefreshKeybindList()
    if not self.KeybindFrame then self:_BuildKeybindList() end
    if not self._KeybindList then return end

    for _, child in ipairs(self._KeybindList:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

    if not self.KeybindListEnabled then
        self.KeybindFrame.Visible = false
        return
    end

    local count = 0
    for idx, opt in pairs(self.Options) do
        if opt.Type == "KeyPicker" and not opt.NoUI then
            local active = false
            if opt.Mode == "Always" then active = true
            elseif opt.Mode == "Toggle" then active = opt.Toggled
            elseif opt.Mode == "Hold"   then active = opt.Holding end

            if active then
                count = count + 1
                Library._createInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = opt.Text .. ": [" .. tostring(opt.Value) .. "]",
                    TextColor3 = self.Theme.Accent,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = self._KeybindList,
                })
            end
        end
    end

    self.KeybindFrame.Visible = count > 0
end

function Library:_BuildKeybindList()
    if self.KeybindFrame then return end
    local frame = Library._createInstance("Frame", {
        Name = "Keybinds",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, -20),
        Size = UDim2.new(0, 180, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.NotifyGui,
    })
    Library._corner(frame, 6)
    Library._stroke(frame, self.Theme.ElementBorder, 1)
    self:AddToRegistry(frame, { BackgroundColor3 = "Groupbox" })

    local header = Library._createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = frame,
    })
    self:AddToRegistry(header, { TextColor3 = "Text" })

    local list = Library._createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    Library._listLayout(list, 2)
    Library._padding(list, 2, 10, 8, 10)

    self.KeybindFrame = frame
    self.KeybindContainer = frame
    self._KeybindList = list

    self:Connect(RunService.Heartbeat, function()
        self:_RefreshKeybindList()
    end)
end

return Library