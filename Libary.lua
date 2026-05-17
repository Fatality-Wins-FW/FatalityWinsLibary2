-- ===== PART 1 START =====
-- Fatality Wins UI Library
-- Obsidian-compatible API

local Library = {}

-- Services
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

-- Theme
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

-- Global state
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

-- ===== UTILITIES =====

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

local function listLayout(parent, padding, dir, hAlign, vAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, padding or 4)
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

-- Signal class
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

-- Expose helpers on Library so other parts can use
Library._createInstance = createInstance
Library._corner         = corner
Library._stroke         = stroke
Library._padding        = padding
Library._listLayout     = listLayout
Library._tween          = tween
Library._getTextSize    = getTextSize
Library._createSignal   = createSignal

-- ===== LIBRARY METHODS =====

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

function Library:AddToRegistry(inst, props)
    self.RegistryMap[inst] = props
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

-- ===== PART 1 END =====