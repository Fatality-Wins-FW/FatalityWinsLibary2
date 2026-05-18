local Library = {}

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local HttpService        = game:GetService("HttpService")
local TextService        = game:GetService("TextService")
local Stats              = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

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
Library.RegistryMap        = {}
Library.NotifySide         = "Right"
Library.Toggled            = true
Library.Unloaded           = false
Library.MinSize            = Vector2.new(900, 560)
Library.MaxSize            = Vector2.new(1280, 760)
Library.DefaultSize        = Vector2.new(1167, 683)
Library.Title              = "Fatality Wins"
Library.Subtitle           = "Rivals"
Library.Version            = "1"
Library.ToggleKeybind      = { Value = Enum.KeyCode.RightShift }
Library.IsMobile           = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
Library.OpenedDropdown     = nil
Library.OpenedColorPicker  = nil
Library.KeybindListEnabled = false
Library.WatermarkEnabled   = false

local function createInstance(class, props)
    local inst = Instance.new(class)
    if props then
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do
            inst[k] = v
        end
        if parent then inst.Parent = parent end
    end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.ElementBorder
    s.Thickness = thickness or 1
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

local function listLayout(parent, pad, dir, hAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 4)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function tween(obj, time, props, style)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad), props)
    t:Play()
    return t
end

Library._createInstance = createInstance
Library._corner = corner
Library._stroke = stroke
Library._padding = padding
Library._listLayout = listLayout
Library._tween = tween

function Library:SafeCallback(fn, ...)
    if not fn then return end
    local args = { ... }
    task.spawn(function()
        local ok, err = pcall(function() fn(table.unpack(args)) end)
        if not ok then warn("[FatalityUI] " .. tostring(err)) end
    end)
end

function Library:Connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(self.Connections, conn)
    return conn
end

function Library:GiveSignal(c) table.insert(self.Connections, c); return c end
function Library:OnUnload(fn) table.insert(self.UnloadCallbacks, fn) end
function Library:OnThemeChanged(fn) table.insert(self.ThemeCallbacks, fn) end
function Library:AddToRegistry(inst, props) self.RegistryMap[inst] = props end

function Library:UpdateColorsUsingRegistry()
    for _, cb in ipairs(self.ThemeCallbacks) do pcall(cb) end
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
            if typeof(v) == "Color3" then self.Theme[k] = v
            elseif typeof(v) == "table" then self.Theme[k] = Color3.fromRGB(v[1], v[2], v[3]) end
        end
    end
    self:UpdateColorsUsingRegistry()
end

function Library:GetTextBounds(text, font, size, width)
    return TextService:GetTextSize(text, size or 14, font or Enum.Font.Gotham, Vector2.new(width or math.huge, math.huge))
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, fn in ipairs(self.UnloadCallbacks) do pcall(fn) end
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    if self.ScreenGui then self.ScreenGui:Destroy() end
    if self.MobileGui then self.MobileGui:Destroy() end
    if self.NotifyGui then self.NotifyGui:Destroy() end
end

function Library:AttemptSave()
    if self.SaveManager then pcall(function() self.SaveManager:Save() end) end
end

function Library:SetFooter(text)
    self.Footer = text or self.Footer
    if self._FooterLbl then self._FooterLbl.Text = self.Footer end
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.Active = true
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function makeResizable(handle, target, minSize, maxSize)
    local resizing, startPos, startSize
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startPos = input.Position
            startSize = target.AbsoluteSize
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startPos
            local newW = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            target.Size = UDim2.fromOffset(newW, newH)
        end
    end)
end

function Library:CreateWindow(opts)
    opts = opts or {}
    self.Title    = opts.Title or opts.Name or self.Title
    self.Subtitle = opts.Subtitle or self.Subtitle
    self.Version  = opts.Version or self.Version
    self.Footer   = opts.Footer or ("v" .. tostring(self.Version) .. " - Development Build")
    if opts.NotifySide then self.NotifySide = opts.NotifySide end

    local parentGui = CoreGui
    if not pcall(function() return CoreGui:GetChildren() end) then
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end

    for _, g in ipairs(parentGui:GetChildren()) do
        if g.Name:find("FatalityUI") then g:Destroy() end
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
    local winW, winH = self.DefaultSize.X, self.DefaultSize.Y

    local main = createInstance("Frame", {
        Name = "Main",
        Position = UDim2.fromOffset((screenSize.X - winW) / 2, (screenSize.Y - winH) / 2),
        Size = UDim2.fromOffset(winW, winH),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    corner(main, 10)
    stroke(main, self.Theme.ElementBorder, 1)
    self:AddToRegistry(main, { BackgroundColor3 = "Background" })
    self.Main = main

    local sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    corner(sidebar, 10)
    self:AddToRegistry(sidebar, { BackgroundColor3 = "Sidebar" })
    self.Sidebar = sidebar

    local sidebarMask = createInstance("Frame", {
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 10, 1, 0),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    self:AddToRegistry(sidebarMask, { BackgroundColor3 = "Sidebar" })

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

    createInstance("TextLabel", {
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
        Size = UDim2.new(1, -16, 1, -200),
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

    local versionLbl = createInstance("TextLabel", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -16),
        Size = UDim2.new(1, -32, 0, 14),
        BackgroundTransparency = 1,
        Text = self.Footer,
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })
    self:AddToRegistry(versionLbl, { TextColor3 = "TextMuted" })
    self._FooterLbl = versionLbl

    local topbar = createInstance("Frame", {
        Name = "Topbar",
        Position = UDim2.new(0, 170, 0, 0),
        Size = UDim2.new(1, -170, 0, 56),
        BackgroundColor3 = self.Theme.Topbar,
        BorderSizePixel = 0,
        Parent = main,
    })
    corner(topbar, 10)
    self:AddToRegistry(topbar, { BackgroundColor3 = "Topbar" })
    self.Topbar = topbar

    local topbarMask = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 10, 1, 0),
        BackgroundColor3 = self.Theme.Topbar,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    self:AddToRegistry(topbarMask, { BackgroundColor3 = "Topbar" })

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

    createInstance("TextLabel", {
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

    createInstance("TextLabel", {
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

    local gear = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Text = "⚙",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = topbar,
    })
    corner(gear, 6)
    self:AddToRegistry(gear, { BackgroundColor3 = "Element", TextColor3 = "Text" })

    gear.MouseEnter:Connect(function() tween(gear, 0.12, { BackgroundColor3 = self.Theme.ElementHover }) end)
    gear.MouseLeave:Connect(function() tween(gear, 0.12, { BackgroundColor3 = self.Theme.Element }) end)
    gear.MouseButton1Click:Connect(function()
        if self._SettingsTab then self:SetCurrentTab(self._SettingsTab) end
    end)

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
        Text = "◢",
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = main,
    })
    self:AddToRegistry(resizeHandle, { TextColor3 = "TextMuted" })

    makeDraggable(topbar, main)
    makeDraggable(logoArea, main)
    makeResizable(resizeHandle, main, self.MinSize, self.MaxSize)

    self.Minimized = false
    local lastClick = 0
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local now = tick()
            if now - lastClick < 0.35 then
                self:ToggleMinimize()
                lastClick = 0
            else
                lastClick = now
            end
        end
    end)

    local mobileGui = createInstance("ScreenGui", {
        Name = "FatalityUI_Mobile",
        ResetOnSpawn = false,
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

    self:Connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKeybind.Value then
            self.Toggled = not self.Toggled
            main.Visible = self.Toggled
        end
    end)

    self.Window = {}
    function self.Window:SetCurrentTab(tab) Library:SetCurrentTab(tab) end
    function self.Window:AddTab(name) return Library:AddTab(name) end

    task.defer(function()
        self:_BuildSettingsTab()
        self:_PinSettingsToBottom()
        self.CurrentTab = nil
        if self._SettingsTab and self._SettingsTab._Page then
            self._SettingsTab._Page.Visible = false
            self._SettingsTab._Page.GroupTransparency = 1
        end
        for _, t in ipairs(self.Tabs) do
            if not t._IsSettings then
                self:SetCurrentTab(t)
                break
            end
        end
    end)

    return self.Window
end

function Library:ToggleMinimize()
    if not self.Main then return end
    if self.Minimized then
        self.Minimized = false
        if self.ContentFrame then self.ContentFrame.Visible = true end
        if self.Sidebar then self.Sidebar.Visible = true end
        tween(self.Main, 0.25, { Size = self._SavedMainSize or UDim2.fromOffset(self.DefaultSize.X, self.DefaultSize.Y) })
    else
        self._SavedMainSize = self.Main.Size
        self.Minimized = true
        if self.ContentFrame then self.ContentFrame.Visible = false end
        if self.Sidebar then self.Sidebar.Visible = false end
        tween(self.Main, 0.25, { Size = UDim2.fromOffset(260, 56) })
    end
end

function Library:Toggle(state)
    if state == nil then self.Toggled = not self.Toggled
    else self.Toggled = state and true or false end
    if self.Main then self.Main.Visible = self.Toggled end
end

function Library:SetCurrentTab(tab)
    if self.CurrentTab == tab then return end
    if self.CurrentTab then
        local oldPage = self.CurrentTab._Page
        local oldBtn = self.CurrentTab._Button
        local oldIndicator = self.CurrentTab._Indicator
        if oldPage then
            tween(oldPage, 0.15, { GroupTransparency = 1 })
            task.delay(0.15, function() if oldPage and oldPage.Parent then oldPage.Visible = false end end)
        end
        if oldBtn then tween(oldBtn, 0.15, { BackgroundTransparency = 1 }) end
        if oldIndicator then tween(oldIndicator, 0.15, { BackgroundTransparency = 1 }) end
        if self.CurrentTab._Label then tween(self.CurrentTab._Label, 0.15, { TextColor3 = self.Theme.TextDim }) end
    end
    self.CurrentTab = tab
    if tab then
        if tab._Page then
            tab._Page.Visible = true
            tab._Page.GroupTransparency = 1
            tween(tab._Page, 0.2, { GroupTransparency = 0 })
        end
        if tab._Button then tween(tab._Button, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = self.Theme.Element }) end
        if tab._Indicator then tween(tab._Indicator, 0.15, { BackgroundTransparency = 0 }) end
        if tab._Label then tween(tab._Label, 0.15, { TextColor3 = self.Theme.Text }) end
        if self.Breadcrumb then self.Breadcrumb.Text = tab.Name .. "  ›  " .. tab.Name end
    end
end

function Library:AddTab(name)
    local tab = {}
    tab.Name = name

    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
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
        if self.CurrentTab ~= tab then tween(label, 0.12, { TextColor3 = self.Theme.Text }) end
    end)
    btn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then tween(label, 0.12, { TextColor3 = self.Theme.TextDim }) end
    end)
    btn.MouseButton1Click:Connect(function() self:SetCurrentTab(tab) end)

    local page = createInstance("CanvasGroup", {
        Name = name .. "_Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        GroupTransparency = 1,
        Parent = self.ContentFrame,
    })

    local moduleArea = createInstance("Frame", {
        Position = UDim2.new(1, -160, 0, 8),
        Size = UDim2.new(0, 150, 0, 26),
        BackgroundTransparency = 1,
        Parent = page,
    })

    local moduleLbl = createInstance("TextLabel", {
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        Text = "Module enabled",
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = moduleArea,
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
        Parent = moduleArea,
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

    local scroll = createInstance("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
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

    tab._Button = btn
    tab._Label = label
    tab._Indicator = indicator
    tab._Page = page
    tab._Left = left
    tab._Right = right
    tab._ModSwitch = modSwitch
    tab._ModKnob = modKnob
    tab._ModuleArea = moduleArea
    tab._ModuleEnabled = false

    local overlay = createInstance("TextButton", {
        Name = "ModuleOverlay",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 100,
        Active = true,
        Parent = page,
    })
    self:AddToRegistry(overlay, { BackgroundColor3 = "Background" })

    local msgBox = createInstance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 80),
        BackgroundColor3 = self.Theme.Groupbox,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = overlay,
    })
    corner(msgBox, 8)
    stroke(msgBox, self.Theme.ElementBorder, 1)
    self:AddToRegistry(msgBox, { BackgroundColor3 = "Groupbox" })

    local mt = createInstance("TextLabel", {
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "Module Disabled",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 102,
        Parent = msgBox,
    })
    self:AddToRegistry(mt, { TextColor3 = "Text" })

    local ms = createInstance("TextLabel", {
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "Enable this module using the toggle in the top-right corner.",
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        ZIndex = 102,
        Parent = msgBox,
    })
    self:AddToRegistry(ms, { TextColor3 = "TextDim" })

    tab._Overlay = overlay

    modSwitch.MouseButton1Click:Connect(function()
        tab._ModuleEnabled = not tab._ModuleEnabled
        if tab._ModuleEnabled then
            tween(modSwitch, 0.15, { BackgroundColor3 = self.Theme.Accent })
            tween(modKnob, 0.15, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1) })
            overlay.Visible = false
        else
            tween(modSwitch, 0.15, { BackgroundColor3 = self.Theme.Element })
            tween(modKnob, 0.15, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(180, 180, 190) })
            overlay.Visible = true
        end
    end)

    table.insert(self.Tabs, tab)

    function tab:AddLeftGroupbox(gname) return Library:_CreateGroupbox(tab._Left, gname, tab) end
    function tab:AddRightGroupbox(gname) return Library:_CreateGroupbox(tab._Right, gname, tab) end
    function tab:AddLeftTabbox() return Library:_CreateTabbox(tab._Left, tab) end
    function tab:AddRightTabbox() return Library:_CreateTabbox(tab._Right, tab) end

    return tab
end

function Library:_CreateGroupbox(parent, name, parentTab)
    local groupbox = {}
    groupbox.Name = name

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

    local headerLbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    self:AddToRegistry(headerLbl, { TextColor3 = "Text" })

    local headerLine = createInstance("Frame", {
        Position = UDim2.new(0, 14, 0, 32),
        Size = UDim2.new(1, -28, 0, 1),
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
    padding(body, 10, 14, 12, 14)

    local container = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = body,
    })
    listLayout(container, 6)

    groupbox._Frame = frame
    groupbox._Container = container
    groupbox._ParentTab = parentTab

    Library:_AttachElements(groupbox)
    return groupbox
end

function Library:_CreateTabbox(parent, parentTab)
    local tabbox = { Tabs = {}, CurrentTab = nil }

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
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    padding(tabHeader, 4, 6, 0, 6)
    listLayout(tabHeader, 4, Enum.FillDirection.Horizontal)

    local headerLine = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self.Theme.Divider,
        BorderSizePixel = 0,
        Parent = frame,
    })
    self:AddToRegistry(headerLine, { BackgroundColor3 = "Divider" })

    local body = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 31),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    padding(body, 8, 14, 12, 14)

    function tabbox:AddTab(name)
        local sub = { Name = name }
        local tabBtn = createInstance("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = tabHeader,
        })
        local tabLbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = "  " .. name .. "  ",
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
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

        sub._Lbl = tabLbl
        sub._Underline = underline
        sub._Container = subContainer
        Library:_AttachElements(sub)

        tabBtn.MouseButton1Click:Connect(function() tabbox:SetActive(sub) end)
        table.insert(tabbox.Tabs, sub)
        if not tabbox.CurrentTab then tabbox:SetActive(sub) end
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

function Library:_AttachElements(host)

    function host:AddLabel(text, doesWrap)
        local element = {}
        local row = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, doesWrap and 0 or 20),
            AutomaticSize = doesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Parent = host._Container,
        })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -28, 1, 0),
            BackgroundTransparency = 1,
            Text = text or "",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = doesWrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            TextWrapped = doesWrap or false,
            Parent = row,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })
        element._Row = row
        element._Label = lbl
        function element:SetText(t) lbl.Text = t end
        function element:AddColorPicker(cidx, copts) return Library:_BuildColorPicker(row, cidx, copts) end
        function element:AddKeyPicker(kidx, kopts) return Library:_BuildKeyPicker(row, nil, kidx, kopts) end
        return element
    end

    function host:AddDivider()
        local f = createInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Library.Theme.Divider,
            BorderSizePixel = 0,
            Parent = host._Container,
        })
        Library:AddToRegistry(f, { BackgroundColor3 = "Divider" })
        return f
    end

    function host:AddButton(opts, fn)
        if type(opts) == "string" then opts = { Text = opts, Func = fn } end
        opts = opts or {}
        local element = {}
        local container = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = host._Container })
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
        local reset
        btn.MouseButton1Click:Connect(function()
            if opts.DoubleClick then
                clickCount = clickCount + 1
                if clickCount == 1 then
                    btn.Text = "Are you sure?"
                    if reset then task.cancel(reset) end
                    reset = task.delay(1.5, function() clickCount = 0; btn.Text = opts.Text or "Button" end)
                else
                    clickCount = 0
                    btn.Text = opts.Text or "Button"
                    if reset then task.cancel(reset); reset = nil end
                    Library:SafeCallback(opts.Func)
                end
            else
                Library:SafeCallback(opts.Func)
            end
        end)

        btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Library.Theme.ElementHover }) end)
        btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Library.Theme.Element }) end)

        element._Button = btn
        function element:SetText(t) btn.Text = t; opts.Text = t end
        function element:AddButton(o, f) return host:AddButton(o, f) end
        return element
    end

    function host:AddToggle(idx, opts)
        opts = opts or {}
        local element = { Type = "Toggle", Idx = idx, Value = opts.Default or false, Callbacks = {} }
        local row = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = host._Container })
        local txt = createInstance("TextLabel", {
            Size = UDim2.new(1, -120, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Toggle",
            TextColor3 = opts.Risky and Library.Theme.Danger or Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        if not opts.Risky then Library:AddToRegistry(txt, { TextColor3 = "Text" }) end

        local switch = createInstance("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 32, 0, 18),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = row,
        })
        corner(switch, 9)
        stroke(switch, Library.Theme.ElementBorder, 1)
        local knob = createInstance("Frame", {
            Position = UDim2.new(0, 2, 0.5, -6),
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = Color3.fromRGB(180, 180, 190),
            BorderSizePixel = 0,
            Parent = switch,
        })
        corner(knob, 6)

        element._Row = row
        element._Switch = switch
        element._Knob = knob

        local function vis()
            if element.Value then
                tween(switch, 0.15, { BackgroundColor3 = Library.Theme.Accent })
                tween(knob, 0.15, { Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1) })
            else
                tween(switch, 0.15, { BackgroundColor3 = Library.Theme.Element })
                tween(knob, 0.15, { Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(180, 180, 190) })
            end
        end

        function element:SetValue(v, skipCB)
            element.Value = v and true or false
            vis()
            if not skipCB then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
            end
            Library:AttemptSave()
        end
        function element:GetState() return element.Value end
        function element:GetValue() return element.Value end
        function element:OnChanged(cb) table.insert(element.Callbacks, cb); return element end

        switch.MouseButton1Click:Connect(function()
            if opts.Disabled then return end
            element:SetValue(not element.Value)
        end)

        function element:AddKeyPicker(kidx, kopts) return Library:_BuildKeyPicker(row, element, kidx, kopts) end
        function element:AddColorPicker(cidx, copts) return Library:_BuildColorPicker(row, cidx, copts) end

        if idx then Library.Toggles[idx] = element end
        vis()
        if element.Value then task.defer(function() Library:SafeCallback(opts.Callback, element.Value) end) end
        return element
    end

    function host:AddInput(idx, opts)
        opts = opts or {}
        local element = { Type = "Input", Idx = idx, Value = opts.Default or "", Callbacks = {} }
        local container = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = host._Container })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
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
            Position = UDim2.new(0, 0, 0, 16),
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Parent = container,
        })
        corner(box, 5)
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
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = box,
        })
        Library:AddToRegistry(input, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })

        local function process(t)
            if opts.Numeric then
                t = tostring(t):gsub("[^%d%.%-]", "")
                element.Value = tonumber(t) or 0
                input.Text = t
            else
                if opts.MaxLength and #t > opts.MaxLength then t = t:sub(1, opts.MaxLength); input.Text = t end
                element.Value = t
            end
        end

        if opts.Finished then
            input.FocusLost:Connect(function()
                process(input.Text)
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
                Library:AttemptSave()
            end)
        else
            input:GetPropertyChangedSignal("Text"):Connect(function()
                process(input.Text)
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
            end)
            input.FocusLost:Connect(function() Library:AttemptSave() end)
        end

        function element:SetValue(v, skipCB)
            element.Value = v
            input.Text = tostring(v)
            if not skipCB then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
            end
        end
        function element:GetValue() return element.Value end
        function element:OnChanged(cb) table.insert(element.Callbacks, cb); return element end
        if idx then Library.Options[idx] = element end
        return element
    end

    function host:AddSlider(idx, opts)
        opts = opts or {}
        local element = {
            Type = "Slider", Idx = idx,
            Min = opts.Min or 0, Max = opts.Max or 100,
            Rounding = opts.Rounding or 0, Suffix = opts.Suffix or "",
            Callbacks = {},
        }
        element.Value = math.clamp(opts.Default or element.Min, element.Min, element.Max)

        local function round(v)
            local m = 10 ^ element.Rounding
            return math.floor(v * m + 0.5) / m
        end

        local container = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = host._Container })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -100, 0, 14),
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
            Size = UDim2.new(0, 100, 0, 14),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = container,
        })
        Library:AddToRegistry(valLbl, { TextColor3 = "TextDim" })
        local barBg = createInstance("Frame", {
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 8),
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
            Size = UDim2.new(1, 0, 1, 14),
            Position = UDim2.new(0, 0, 0, -7),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = barBg,
        })

        local function vis()
            local pct = math.clamp((element.Value - element.Min) / (element.Max - element.Min), 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            if opts.HideMax then
                valLbl.Text = tostring(element.Value) .. element.Suffix
            else
                valLbl.Text = tostring(element.Value) .. element.Suffix .. " / " .. tostring(element.Max) .. element.Suffix
            end
        end

        function element:SetValue(v, skipCB)
            v = math.clamp(round(v), element.Min, element.Max)
            if element.Rounding == 0 then v = math.floor(v) end
            element.Value = v
            vis()
            if not skipCB then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
            end
            Library:AttemptSave()
        end
        function element:GetValue() return element.Value end
        function element:OnChanged(cb) table.insert(element.Callbacks, cb); return element end

        local dragging = false
        local function fromPos(x)
            local s = barBg.AbsoluteSize.X
            if s <= 0 then return end
            local pct = math.clamp((x - barBg.AbsolutePosition.X) / s, 0, 1)
            element:SetValue(element.Min + (element.Max - element.Min) * pct)
        end

        hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; fromPos(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromPos(input.Position.X)
            end
        end)

        if idx then Library.Options[idx] = element end
        vis()
        return element
    end

    function host:AddDropdown(idx, opts)
        opts = opts or {}
        local element = {
            Type = "Dropdown", Idx = idx,
            Values = opts.Values or {},
            Multi = opts.Multi or false,
            AllowNull = opts.AllowNull or false,
            Callbacks = {},
        }
        if element.Multi then
            element.Value = {}
            if type(opts.Default) == "table" then
                for _, v in ipairs(opts.Default) do element.Value[tostring(v)] = true end
            end
        else
            element.Value = opts.Default
        end

        local container = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = host._Container })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
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
            Position = UDim2.new(0, 0, 0, 16),
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = Library.Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = container,
        })
        corner(btn, 5)
        stroke(btn, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(btn, { BackgroundColor3 = "Element" })
        local display = createInstance("TextLabel", {
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -26, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        Library:AddToRegistry(display, { TextColor3 = "Text" })
        local arrow = createInstance("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = "v",
            TextColor3 = Library.Theme.TextDim,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Parent = btn,
        })
        Library:AddToRegistry(arrow, { TextColor3 = "TextDim" })

        local popup = createInstance("Frame", {
            Visible = false,
            BackgroundColor3 = Library.Theme.Groupbox,
            BorderSizePixel = 0,
            ZIndex = 150,
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
            ZIndex = 151,
            Parent = popup,
        })
        padding(scroll, 4)
        listLayout(scroll, 2)

        local function isSel(v)
            if element.Multi then return element.Value[tostring(v)] == true
            else return tostring(element.Value) == tostring(v) end
        end

        local function updateDisp()
            if element.Multi then
                local list = {}
                for k, on in pairs(element.Value) do if on then table.insert(list, tostring(k)) end end
                if #list == 0 then display.Text = "None"; display.TextColor3 = Library.Theme.TextDim
                elseif #list == 1 then display.Text = list[1]; display.TextColor3 = Library.Theme.Text
                else display.Text = list[1] .. " +" .. (#list - 1); display.TextColor3 = Library.Theme.Text end
            else
                if element.Value == nil or tostring(element.Value) == "" then
                    display.Text = "None"; display.TextColor3 = Library.Theme.TextDim
                else display.Text = tostring(element.Value); display.TextColor3 = Library.Theme.Text end
            end
        end

        local optBtns = {}
        local function rebuild()
            for _, b in ipairs(optBtns) do b:Destroy() end
            optBtns = {}
            for _, val in ipairs(element.Values) do
                local sv = tostring(val)
                local ob = createInstance("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = Library.Theme.Element,
                    BackgroundTransparency = isSel(val) and 0 or 1,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 152,
                    Parent = scroll,
                })
                corner(ob, 4)
                local ind = createInstance("Frame", {
                    Position = UDim2.new(0, 6, 0.5, -5),
                    Size = UDim2.new(0, 3, 0, 10),
                    BackgroundColor3 = Library.Theme.Accent,
                    BackgroundTransparency = isSel(val) and 0 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 153,
                    Parent = ob,
                })
                corner(ind, 2)
                Library:AddToRegistry(ind, { BackgroundColor3 = "Accent" })
                createInstance("TextLabel", {
                    Position = UDim2.new(0, 16, 0, 0),
                    Size = UDim2.new(1, -22, 1, 0),
                    BackgroundTransparency = 1,
                    Text = sv,
                    TextColor3 = isSel(val) and Library.Theme.Text or Library.Theme.TextDim,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 153,
                    Parent = ob,
                })
                ob.MouseEnter:Connect(function() if not isSel(val) then tween(ob, 0.1, { BackgroundTransparency = 0.5 }) end end)
                ob.MouseLeave:Connect(function() if not isSel(val) then tween(ob, 0.1, { BackgroundTransparency = 1 }) end end)
                ob.MouseButton1Click:Connect(function()
                    if element.Multi then
                        if element.Value[sv] then element.Value[sv] = nil else element.Value[sv] = true end
                    else
                        if element.AllowNull and tostring(element.Value) == sv then element.Value = nil
                        else element.Value = val end
                        element:Close()
                    end
                    rebuild(); updateDisp()
                    Library:SafeCallback(opts.Callback, element.Value)
                    for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
                    Library:AttemptSave()
                end)
                table.insert(optBtns, ob)
            end
        end

        function element:Open()
            if Library.OpenedDropdown and Library.OpenedDropdown ~= element then Library.OpenedDropdown:Close() end
            Library.OpenedDropdown = element
            local ap, as = btn.AbsolutePosition, btn.AbsoluteSize
            local h = math.min(180, #element.Values * 24 + 8)
            popup.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
            popup.Size = UDim2.fromOffset(as.X, h)
            popup.Visible = true; arrow.Text = "^"
        end
        function element:Close()
            popup.Visible = false; arrow.Text = "v"
            if Library.OpenedDropdown == element then Library.OpenedDropdown = nil end
        end
        function element:Toggle() if popup.Visible then element:Close() else element:Open() end end
        function element:SetValues(vs)
            element.Values = vs or {}
            rebuild(); updateDisp()
        end
        function element:SetValue(v, skipCB)
            if element.Multi then
                local nv = {}
                if type(v) == "table" then
                    if v[1] ~= nil then for _, i in ipairs(v) do nv[tostring(i)] = true end
                    else for k, on in pairs(v) do if on then nv[tostring(k)] = true end end end
                end
                element.Value = nv
            else element.Value = v end
            rebuild(); updateDisp()
            if not skipCB then
                Library:SafeCallback(opts.Callback, element.Value)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value) end
            end
        end
        function element:GetValue() return element.Value end
        function element:OnChanged(cb) table.insert(element.Callbacks, cb); return element end

        btn.MouseButton1Click:Connect(function() element:Toggle() end)
        Library:Connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if popup.Visible then
                    local mp = input.Position
                    local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
                    local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                    local inP = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local inB = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                    if not inP and not inB then element:Close() end
                end
            end
        end)

        if idx then Library.Options[idx] = element end
        rebuild(); updateDisp()
        return element
    end

    function host:AddColorPicker(idx, opts) return Library:_BuildColorPicker(host._Container, idx, opts, true) end
    function host:AddKeyPicker(idx, opts) return Library:_BuildKeyPicker(host._Container, nil, idx, opts, true) end

    function host:AddDependencyBox()
        local d = { Dependencies = {} }
        local f = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = host._Container })
        local c = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = f })
        listLayout(c, 6)
        d._Frame = f; d._Container = c
        Library:_AttachElements(d)
        function d:SetupDependencies(deps) d.Dependencies = deps or {}; d:Update() end
        function d:Update()
            local show = true
            for _, dep in ipairs(d.Dependencies) do
                local t, w = dep[1], dep[2]
                if not t then show = false; break end
                local v = t.GetState and t:GetState() or t.GetValue and t:GetValue() or t.Value
                if v ~= w then show = false; break end
            end
            f.Visible = show
        end
        task.spawn(function() while f.Parent do d:Update(); task.wait(0.25) end end)
        return d
    end
end

function Library:_BuildColorPicker(parentRow, idx, opts, standalone)
    opts = opts or {}
    local element = {
        Type = "ColorPicker", Idx = idx,
        Value = opts.Default or Color3.fromRGB(255, 255, 255),
        Transparency = opts.Transparency or 0,
        Title = opts.Title or opts.Text or "Color",
        Callbacks = {},
    }
    local h, s, v = Color3.toHSV(element.Value)
    element._H, element._S, element._V = h, s, v

    local row = parentRow
    if standalone then
        row = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = parentRow })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -28, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or opts.Title or idx or "Color",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })
    end

    local pickerBtn = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = element.Value,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(pickerBtn, 4)
    stroke(pickerBtn, Library.Theme.ElementBorder, 1)
    element._Btn = pickerBtn

    local popup = createInstance("Frame", {
        Visible = false,
        Size = UDim2.fromOffset(230, 230),
        BackgroundColor3 = Library.Theme.Groupbox,
        BorderSizePixel = 0,
        ZIndex = 200,
        Parent = Library.ScreenGui,
    })
    corner(popup, 8)
    stroke(popup, Library.Theme.ElementBorder, 1)
    Library:AddToRegistry(popup, { BackgroundColor3 = "Groupbox" })
    createInstance("TextLabel", {
        Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = element.Title,
        TextColor3 = Library.Theme.Text, Font = Enum.Font.GothamBold,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201, Parent = popup,
    })

    local svBox = createInstance("ImageButton", {
        Position = UDim2.fromOffset(10, 26), Size = UDim2.fromOffset(170, 130),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0, Image = "", AutoButtonColor = false,
        ZIndex = 201, Parent = popup,
    })
    corner(svBox, 4)
    local satGrad = createInstance("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1)), Parent = svBox })
    local valOverlay = createInstance("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0, ZIndex = 202, Parent = svBox,
    })
    corner(valOverlay, 4)
    createInstance("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
        Parent = valOverlay,
    })
    local svCursor = createInstance("Frame", {
        Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        ZIndex = 204, Parent = svBox,
    })
    corner(svCursor, 4)
    stroke(svCursor, Color3.new(0, 0, 0), 1)

    local hueBar = createInstance("ImageButton", {
        Position = UDim2.fromOffset(188, 26), Size = UDim2.fromOffset(14, 130),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Image = "", AutoButtonColor = false,
        ZIndex = 201, Parent = popup,
    })
    corner(hueBar, 3)
    createInstance("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        }),
        Parent = hueBar,
    })
    local hueCursor = createInstance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        ZIndex = 203, Parent = hueBar,
    })
    corner(hueCursor, 1)

    local hexBox = createInstance("Frame", {
        Position = UDim2.fromOffset(10, 164), Size = UDim2.new(1, -20, 0, 22),
        BackgroundColor3 = Library.Theme.Element, BorderSizePixel = 0,
        ZIndex = 201, Parent = popup,
    })
    corner(hexBox, 4)
    stroke(hexBox, Library.Theme.ElementBorder, 1)
    Library:AddToRegistry(hexBox, { BackgroundColor3 = "Element" })
    local hexInput = createInstance("TextBox", {
        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0),
        BackgroundTransparency = 1,
        Text = string.format("#%02X%02X%02X", element.Value.R * 255, element.Value.G * 255, element.Value.B * 255),
        TextColor3 = Library.Theme.Text, Font = Enum.Font.Code, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        ZIndex = 202, Parent = hexBox,
    })

    local doneBtn = createInstance("TextButton", {
        Position = UDim2.fromOffset(10, 194), Size = UDim2.new(1, -20, 0, 22),
        BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0,
        Text = "Done", TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium, TextSize = 11, AutoButtonColor = false,
        ZIndex = 201, Parent = popup,
    })
    corner(doneBtn, 4)
    Library:AddToRegistry(doneBtn, { BackgroundColor3 = "Accent" })

    local function update()
        local c = Color3.fromHSV(element._H, element._S, element._V)
        element.Value = c
        pickerBtn.BackgroundColor3 = c
        satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(element._H, 1, 1))
        svBox.BackgroundColor3 = Color3.fromHSV(element._H, 1, 1)
        svCursor.Position = UDim2.new(element._S, 0, 1 - element._V, 0)
        hueCursor.Position = UDim2.new(0.5, 0, element._H, 0)
        if not hexInput:IsFocused() then
            hexInput.Text = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
        end
    end

    local function fire()
        Library:SafeCallback(opts.Callback, element.Value, element.Transparency)
        for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Value, element.Transparency) end
        Library:AttemptSave()
    end

    local svDrag, hueDrag = false, false
    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDrag = true end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDrag = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if svDrag or hueDrag then svDrag, hueDrag = false, false; fire() end
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not popup.Visible then return end
        if svDrag then
            local mp = UserInputService:GetMouseLocation()
            local rel = Vector2.new(mp.X, mp.Y - 36) - svBox.AbsolutePosition
            element._S = math.clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
            element._V = 1 - math.clamp(rel.Y / svBox.AbsoluteSize.Y, 0, 1)
            update()
        end
        if hueDrag then
            local mp = UserInputService:GetMouseLocation()
            local rel = (mp.Y - 36) - hueBar.AbsolutePosition.Y
            element._H = math.clamp(rel / hueBar.AbsoluteSize.Y, 0, 1)
            update()
        end
    end)

    hexInput.FocusLost:Connect(function()
        local t = hexInput.Text:gsub("#", ""):gsub("%s", "")
        if #t == 6 then
            local r = tonumber(t:sub(1, 2), 16)
            local g = tonumber(t:sub(3, 4), 16)
            local b = tonumber(t:sub(5, 6), 16)
            if r and g and b then
                element._H, element._S, element._V = Color3.toHSV(Color3.fromRGB(r, g, b))
                update(); fire(); return
            end
        end
        update()
    end)

    doneBtn.MouseButton1Click:Connect(function() element:Close() end)

    function element:Open()
        if Library.OpenedColorPicker and Library.OpenedColorPicker ~= element then Library.OpenedColorPicker:Close() end
        Library.OpenedColorPicker = element
        local ap, as, ps = pickerBtn.AbsolutePosition, pickerBtn.AbsoluteSize, Vector2.new(230, 230)
        local ss = workspace.CurrentCamera.ViewportSize
        local px = ap.X + as.X - ps.X
        local py = ap.Y + as.Y + 6
        if py + ps.Y > ss.Y - 10 then py = ap.Y - ps.Y - 6 end
        if px < 10 then px = 10 end
        if px + ps.X > ss.X - 10 then px = ss.X - ps.X - 10 end
        popup.Position = UDim2.fromOffset(px, py)
        popup.Visible = true
        update()
    end
    function element:Close() popup.Visible = false; if Library.OpenedColorPicker == element then Library.OpenedColorPicker = nil end end
    function element:Toggle() if popup.Visible then element:Close() else element:Open() end end
    function element:SetValueRGB(c, t) element.Value = c; element._H, element._S, element._V = Color3.toHSV(c); if t then element.Transparency = t end; update(); fire() end
    function element:SetValue(c, t) element:SetValueRGB(c, t) end
    function element:GetValue() return element.Value end
    function element:OnChanged(cb) table.insert(element.Callbacks, cb); return element end

    pickerBtn.MouseButton1Click:Connect(function() element:Toggle() end)
    Library:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if popup.Visible then
                local mp = input.Position
                local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
                local bp, bs = pickerBtn.AbsolutePosition, pickerBtn.AbsoluteSize
                local inP = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                local inB = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                if not inP and not inB then element:Close() end
            end
        end
    end)

    if idx then Library.Options[idx] = element end
    update()
    return element
end

function Library:_BuildKeyPicker(parentRow, parentElement, idx, opts, standalone)
    opts = opts or {}
    local element = {
        Type = "KeyPicker", Idx = idx,
        Value = opts.Default or "None",
        Mode = opts.Mode or "Toggle",
        Text = opts.Text or idx or "Keybind",
        SyncToggleState = opts.SyncToggleState or false,
        NoUI = opts.NoUI or false,
        Callbacks = {}, ChangedCallbacks = {},
        Toggled = false, Holding = false,
    }

    local row = parentRow
    if standalone then
        row = createInstance("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = parentRow })
        local lbl = createInstance("TextLabel", {
            Size = UDim2.new(1, -100, 1, 0),
            BackgroundTransparency = 1,
            Text = opts.Text or idx or "Keybind",
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        Library:AddToRegistry(lbl, { TextColor3 = "Text" })
    end

    local btn = createInstance("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = standalone and UDim2.new(1, 0, 0.5, 0) or UDim2.new(1, -42, 0.5, 0),
        Size = UDim2.new(0, standalone and 90 or 70, 0, 18),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "[" .. tostring(element.Value) .. "]",
        TextColor3 = Library.Theme.TextDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = row,
    })
    corner(btn, 4)
    stroke(btn, Library.Theme.ElementBorder, 1)
    Library:AddToRegistry(btn, { BackgroundColor3 = "Element", TextColor3 = "TextDim" })
    element._Btn = btn

    local listening = false
    local function setTxt() btn.Text = listening and "..." or ("[" .. tostring(element.Value) .. "]") end

    btn.MouseButton1Click:Connect(function() listening = true; setTxt() end)

    local function k2s(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2"
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then return "MB3" end
    end

    Library:Connect(UserInputService.InputBegan, function(input, processed)
        if listening then
            local k = k2s(input)
            if k then
                element.Value = k; listening = false; setTxt()
                Library:SafeCallback(opts.ChangedCallback, element.Value)
                for _, cb in ipairs(element.ChangedCallbacks) do Library:SafeCallback(cb, element.Value) end
                Library:AttemptSave()
            end
            return
        end
        if processed then return end
        local k = k2s(input)
        if k and k == element.Value then
            if element.Mode == "Toggle" then
                element.Toggled = not element.Toggled
                if element.SyncToggleState and parentElement and parentElement.SetValue then parentElement:SetValue(element.Toggled) end
                Library:SafeCallback(opts.Callback, element.Toggled)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, element.Toggled) end
            elseif element.Mode == "Hold" then
                element.Holding = true
                Library:SafeCallback(opts.Callback, true)
                for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, true) end
            end
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(input)
        local k = k2s(input)
        if k and k == element.Value and element.Mode == "Hold" then
            element.Holding = false
            Library:SafeCallback(opts.Callback, false)
            for _, cb in ipairs(element.Callbacks) do Library:SafeCallback(cb, false) end
        end
    end)

    function element:GetState()
        if element.Mode == "Always" then return true end
        if element.Mode == "Toggle" then return element.Toggled end
        if element.Mode == "Hold" then return element.Holding end
        return false
    end
    function element:SetValue(d)
        if type(d) == "table" then element.Value = d[1] or element.Value; element.Mode = d[2] or element.Mode
        else element.Value = d end
        setTxt()
    end
    function element:GetValue() return element.Value end
    function element:OnChanged(cb) table.insert(element.ChangedCallbacks, cb); return element end
    function element:OnClick(cb) table.insert(element.Callbacks, cb); return element end

    if not element.NoUI then
        local menu = createInstance("Frame", {
            Visible = false,
            Size = UDim2.fromOffset(110, 76),
            BackgroundColor3 = Library.Theme.Groupbox,
            BorderSizePixel = 0,
            ZIndex = 250,
            Parent = Library.ScreenGui,
        })
        corner(menu, 6)
        stroke(menu, Library.Theme.ElementBorder, 1)
        Library:AddToRegistry(menu, { BackgroundColor3 = "Groupbox" })

        local modes = { "Toggle", "Hold", "Always" }
        local optBtns = {}

        local function rebuildMenu()
            for _, b in ipairs(optBtns) do b:Destroy() end
            optBtns = {}
            for i, mode in ipairs(modes) do
                local active = element.Mode == mode
                local mb = createInstance("TextButton", {
                    Position = UDim2.fromOffset(4, 4 + (i - 1) * 24),
                    Size = UDim2.new(1, -8, 0, 22),
                    BackgroundColor3 = Library.Theme.Element,
                    BackgroundTransparency = active and 0 or 1,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 251,
                    Parent = menu,
                })
                corner(mb, 4)
                local ind = createInstance("Frame", {
                    Position = UDim2.new(0, 6, 0.5, -5),
                    Size = UDim2.new(0, 3, 0, 10),
                    BackgroundColor3 = Library.Theme.Accent,
                    BackgroundTransparency = active and 0 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 252,
                    Parent = mb,
                })
                corner(ind, 2)
                Library:AddToRegistry(ind, { BackgroundColor3 = "Accent" })
                createInstance("TextLabel", {
                    Position = UDim2.new(0, 16, 0, 0),
                    Size = UDim2.new(1, -22, 1, 0),
                    BackgroundTransparency = 1,
                    Text = mode,
                    TextColor3 = active and Library.Theme.Text or Library.Theme.TextDim,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 252,
                    Parent = mb,
                })
                mb.MouseEnter:Connect(function()
                    if not active then tween(mb, 0.1, { BackgroundTransparency = 0.5 }) end
                end)
                mb.MouseLeave:Connect(function()
                    if not active then tween(mb, 0.1, { BackgroundTransparency = 1 }) end
                end)
                mb.MouseButton1Click:Connect(function()
                    element.Mode = mode
                    if mode ~= "Toggle" then element.Toggled = false end
                    if mode ~= "Hold" then element.Holding = false end
                    if mode == "Always" then element.Toggled = true end
                    menu.Visible = false
                    Library:AttemptSave()
                    rebuildMenu()
                end)
                table.insert(optBtns, mb)
            end
        end

        btn.MouseButton2Click:Connect(function()
            if menu.Visible then menu.Visible = false; return end
            rebuildMenu()
            local ap, as = btn.AbsolutePosition, btn.AbsoluteSize
            menu.Position = UDim2.fromOffset(ap.X + as.X - 110, ap.Y + as.Y + 4)
            menu.Visible = true
        end)

        Library:Connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                if menu.Visible then
                    local mp = input.Position
                    local pp, ps = menu.AbsolutePosition, menu.AbsoluteSize
                    local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                    local inMenu = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
                    if not inMenu and not inBtn then menu.Visible = false end
                end
            end
        end)
    end

    if idx then Library.Options[idx] = element end
    setTxt()
    return element
end

function Library:Notify(opts, t)
    if not self.NotifyContainer then return end
    if type(opts) == "string" then opts = { Title = self.Title, Description = opts, Time = t or 4 } end
    opts = opts or {}
    local title, desc, dur = opts.Title or self.Title, opts.Description or "", opts.Time or 4
    local notif = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = self.Theme.Groupbox, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = self.NotifyContainer,
    })
    corner(notif, 8)
    stroke(notif, self.Theme.ElementBorder, 1)
    local accent = createInstance("Frame", {
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Parent = notif,
    })
    corner(accent, 2)
    createInstance("TextLabel", {
        Position = UDim2.new(0, 20, 0, 8), Size = UDim2.new(1, -28, 0, 18),
        BackgroundTransparency = 1, Text = title, TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = notif,
    })
    createInstance("TextLabel", {
        Position = UDim2.new(0, 20, 0, 28), Size = UDim2.new(1, -28, 0, 30),
        BackgroundTransparency = 1, Text = desc, TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = notif,
    })
    local progress = createInstance("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0, Parent = notif,
    })
    local from = self.NotifySide == "Left" and -320 or 320
    notif.Position = UDim2.new(0, from, 0, 0)
    tween(notif, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
    tween(progress, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(dur, function()
        tween(notif, 0.3, { Position = UDim2.new(0, from, 0, 0) })
        task.wait(0.3); if notif.Parent then notif:Destroy() end
    end)
end

function Library:SetNotifySide(side)
    self.NotifySide = side
    if self.NotifyContainer then
        if side == "Left" then
            self.NotifyContainer.AnchorPoint = Vector2.new(0, 0)
            self.NotifyContainer.Position = UDim2.new(0, 20, 0, 20)
        else
            self.NotifyContainer.AnchorPoint = Vector2.new(1, 0)
            self.NotifyContainer.Position = UDim2.new(1, -20, 0, 20)
        end
    end
end

function Library:_BuildWatermark()
    if self.Watermark then return end
    local f = createInstance("Frame", {
        Name = "Watermark", Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 240, 0, 28),
        BackgroundColor3 = self.Theme.Groupbox, BorderSizePixel = 0,
        Visible = false, Parent = self.NotifyGui,
    })
    corner(f, 6)
    stroke(f, self.Theme.ElementBorder, 1)
    self:AddToRegistry(f, { BackgroundColor3 = "Groupbox" })
    local ac = createInstance("Frame", {
        Size = UDim2.new(0, 3, 1, -10), Position = UDim2.new(0, 5, 0, 5),
        BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Parent = f,
    })
    corner(ac, 2)
    self:AddToRegistry(ac, { BackgroundColor3 = "Accent" })
    local lbl = createInstance("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1, Text = "", TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })
    self:AddToRegistry(lbl, { TextColor3 = "Text" })
    self.Watermark = f; self._WatermarkLbl = lbl
    makeDraggable(f, f)
    local last = 0
    self:Connect(RunService.RenderStepped, function(dt)
        last = last + dt
        if last < 0.5 or not f.Visible then return end
        last = 0
        local fps, ping = math.floor(1 / dt), 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        lbl.Text = self.WatermarkText or (self.Title .. " | v" .. tostring(self.Version) .. " | " .. fps .. " fps | " .. ping .. " ms")
    end)
end

function Library:SetWatermarkVisibility(s)
    if not self.Watermark then self:_BuildWatermark() end
    self.Watermark.Visible = s and true or false
end
function Library:SetWatermark(t)
    self.WatermarkText = t
    if not self.Watermark then self:_BuildWatermark() end
    if self._WatermarkLbl then self._WatermarkLbl.Text = t or "" end
end

function Library:_BuildKeybindList()
    if self.KeybindFrame then return end
    local f = createInstance("Frame", {
        Name = "Keybinds", AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, -20), Size = UDim2.new(0, 180, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Groupbox, BorderSizePixel = 0,
        Visible = false, Parent = self.NotifyGui,
    })
    corner(f, 6)
    stroke(f, self.Theme.ElementBorder, 1)
    self:AddToRegistry(f, { BackgroundColor3 = "Groupbox" })
    createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "Keybinds",
        TextColor3 = self.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = f,
    })
    local list = createInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = f,
    })
    listLayout(list, 2)
    padding(list, 2, 10, 8, 10)
    self.KeybindFrame = f
    self.KeybindContainer = f
    self._KeybindList = list
    makeDraggable(f, f)
    self:Connect(RunService.Heartbeat, function() self:_RefreshKeybindList() end)
end

function Library:_RefreshKeybindList()
    if not self.KeybindFrame or not self._KeybindList then return end
    for _, c in ipairs(self._KeybindList:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    if not self.KeybindListEnabled then self.KeybindFrame.Visible = false; return end
    local count = 0
    for _, opt in pairs(self.Options) do
        if opt.Type == "KeyPicker" and not opt.NoUI then
            local active = (opt.Mode == "Always") or (opt.Mode == "Toggle" and opt.Toggled) or (opt.Mode == "Hold" and opt.Holding)
            if active then
                count = count + 1
                createInstance("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
                    Text = opt.Text .. ": [" .. tostring(opt.Value) .. "]",
                    TextColor3 = self.Theme.Accent, Font = Enum.Font.Gotham, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = self._KeybindList,
                })
            end
        end
    end
    self.KeybindFrame.Visible = count > 0
end

function Library:_BuildSettingsTab()
    if self._SettingsTab then return end
    self:_BuildWatermark()
    self:_BuildKeybindList()
    local tab = self:AddTab("Settings")
    tab._IsSettings = true
    if tab._ModuleArea then tab._ModuleArea.Visible = false end
    if tab._Overlay then tab._Overlay:Destroy(); tab._Overlay = nil end
    self._SettingsTab = tab

    local left = tab:AddLeftGroupbox("Menu")
    left:AddButton({ Text = "Unload", DoubleClick = true, Func = function() self:Unload() end })
    left:AddKeyPicker("MenuKeybind", {
        Default = self.ToggleKeybind.Value.Name, NoUI = true, Text = "Menu Keybind",
        ChangedCallback = function(k) local e = Enum.KeyCode[k]; if e then self.ToggleKeybind.Value = e end end,
    })

    local right = tab:AddRightGroupbox("Display")
    right:AddToggle("ShowKeybindList", { Text = "Show Keybind List", Default = false, Callback = function(v) self.KeybindListEnabled = v; self:_RefreshKeybindList() end })
    right:AddToggle("ShowWatermark", { Text = "Show Watermark", Default = false, Callback = function(v) self.WatermarkEnabled = v; self:SetWatermarkVisibility(v) end })
    right:AddDropdown("NotifySide", { Text = "Notification Side", Values = { "Left", "Right" }, Default = self.NotifySide, Callback = function(v) self:SetNotifySide(v) end })
end

function Library:_PinSettingsToBottom()
    if not self._SettingsTab or not self._SettingsTab._Button or not self.Sidebar then return end
    local btn = self._SettingsTab._Button
    btn.Parent = self.Sidebar
    btn.AnchorPoint = Vector2.new(0, 1)
    btn.Position = UDim2.new(0, 8, 1, -70)
    btn.Size = UDim2.new(1, -16, 0, 32)
    local div = createInstance("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -108),
        Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = self.Theme.Divider,
        BorderSizePixel = 0, Parent = self.Sidebar,
    })
    self:AddToRegistry(div, { BackgroundColor3 = "Divider" })
end

function Library:GetOption(i) return self.Options[i] end
function Library:GetToggle(i) return self.Toggles[i] end
function Library:GetCurrentTab() return self.CurrentTab end
function Library:IsMobileDevice() return self.IsMobile end
function Library:SetKeybindVisibility(s)
    self.KeybindListEnabled = s
    self:_RefreshKeybindList()
end

getgenv = getgenv or function() return _G end
local env = getgenv()
env.Toggles = Library.Toggles
env.Options = Library.Options
env.Library = Library

task.defer(function()
    for _, opt in pairs(Library.Options) do
        if opt.Type == "ColorPicker" and opt._Btn then
            opt._Btn.AnchorPoint = Vector2.new(1, 0.5)
            opt._Btn.Position = UDim2.new(1, -6, 0.5, 0)
        end
    end

    for _, page in ipairs(Library.ContentFrame:GetChildren()) do
        if page:IsA("CanvasGroup") then
            for _, scroll in ipairs(page:GetChildren()) do
                if scroll:IsA("ScrollingFrame") then
                    for _, columns in ipairs(scroll:GetChildren()) do
                        if columns:IsA("Frame") then
                            for _, col in ipairs(columns:GetChildren()) do
                                if col:IsA("Frame") then
                                    for _, gb in ipairs(col:GetChildren()) do
                                        if gb:IsA("Frame") then
                                            gb.ClipsDescendants = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)


return Library