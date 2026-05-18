local ThemeManager = {}

ThemeManager.Library = nil
ThemeManager.Folder = "FatalityWins"
ThemeManager.SubFolder = "themes"
ThemeManager.BuiltInThemes = {
    ["Dark Blue"] = {
        Background     = Color3.fromRGB(18, 18, 24),
        Sidebar        = Color3.fromRGB(22, 22, 28),
        Topbar         = Color3.fromRGB(22, 22, 28),
        Groupbox       = Color3.fromRGB(26, 26, 32),
        Element        = Color3.fromRGB(34, 34, 42),
        ElementHover   = Color3.fromRGB(40, 40, 50),
        ElementBorder  = Color3.fromRGB(45, 45, 55),
        Accent         = Color3.fromRGB(59, 130, 246),
        AccentHover    = Color3.fromRGB(79, 150, 255),
        Text           = Color3.fromRGB(235, 235, 240),
        TextDim        = Color3.fromRGB(150, 150, 160),
        TextMuted      = Color3.fromRGB(100, 100, 115),
        Divider        = Color3.fromRGB(40, 40, 50),
    },
    ["Dark Red"] = {
        Background     = Color3.fromRGB(20, 16, 18),
        Sidebar        = Color3.fromRGB(24, 18, 22),
        Topbar         = Color3.fromRGB(24, 18, 22),
        Groupbox       = Color3.fromRGB(28, 22, 26),
        Element        = Color3.fromRGB(38, 28, 32),
        ElementHover   = Color3.fromRGB(46, 34, 40),
        ElementBorder  = Color3.fromRGB(60, 40, 48),
        Accent         = Color3.fromRGB(239, 68, 68),
        AccentHover    = Color3.fromRGB(255, 100, 100),
        Text           = Color3.fromRGB(240, 230, 232),
        TextDim        = Color3.fromRGB(160, 145, 150),
        TextMuted      = Color3.fromRGB(110, 95, 100),
        Divider        = Color3.fromRGB(45, 32, 38),
    },
    ["Dark Green"] = {
        Background     = Color3.fromRGB(16, 22, 18),
        Sidebar        = Color3.fromRGB(20, 26, 22),
        Topbar         = Color3.fromRGB(20, 26, 22),
        Groupbox       = Color3.fromRGB(24, 30, 26),
        Element        = Color3.fromRGB(32, 40, 34),
        ElementHover   = Color3.fromRGB(40, 50, 42),
        ElementBorder  = Color3.fromRGB(50, 60, 52),
        Accent         = Color3.fromRGB(34, 197, 94),
        AccentHover    = Color3.fromRGB(70, 220, 130),
        Text           = Color3.fromRGB(230, 240, 232),
        TextDim        = Color3.fromRGB(150, 160, 152),
        TextMuted      = Color3.fromRGB(100, 115, 105),
        Divider        = Color3.fromRGB(40, 50, 42),
    },
    ["Purple"] = {
        Background     = Color3.fromRGB(20, 16, 26),
        Sidebar        = Color3.fromRGB(24, 20, 32),
        Topbar         = Color3.fromRGB(24, 20, 32),
        Groupbox       = Color3.fromRGB(28, 24, 36),
        Element        = Color3.fromRGB(38, 32, 48),
        ElementHover   = Color3.fromRGB(48, 40, 60),
        ElementBorder  = Color3.fromRGB(60, 50, 75),
        Accent         = Color3.fromRGB(168, 85, 247),
        AccentHover    = Color3.fromRGB(190, 120, 255),
        Text           = Color3.fromRGB(235, 230, 245),
        TextDim        = Color3.fromRGB(160, 150, 175),
        TextMuted      = Color3.fromRGB(110, 100, 125),
        Divider        = Color3.fromRGB(45, 38, 58),
    },
    ["Midnight"] = {
        Background     = Color3.fromRGB(10, 10, 14),
        Sidebar        = Color3.fromRGB(14, 14, 18),
        Topbar         = Color3.fromRGB(14, 14, 18),
        Groupbox       = Color3.fromRGB(18, 18, 24),
        Element        = Color3.fromRGB(26, 26, 32),
        ElementHover   = Color3.fromRGB(32, 32, 40),
        ElementBorder  = Color3.fromRGB(38, 38, 48),
        Accent         = Color3.fromRGB(99, 102, 241),
        AccentHover    = Color3.fromRGB(130, 135, 255),
        Text           = Color3.fromRGB(230, 230, 240),
        TextDim        = Color3.fromRGB(140, 140, 155),
        TextMuted      = Color3.fromRGB(90, 90, 110),
        Divider        = Color3.fromRGB(35, 35, 45),
    },
}

local function colorToHex(c)
    return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then return Color3.fromRGB(r, g, b) end
end

local function fileExists(p) return pcall(function() return readfile(p) end) end
local function dirExists(p) return isfolder and isfolder(p) end
local function safeRead(p) local ok, c = pcall(readfile, p); if ok then return c end end
local function safeWrite(p, c) pcall(writefile, p, c) end
local function safeMkdir(p) if makefolder and not (isfolder and isfolder(p)) then pcall(makefolder, p) end end

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:SetFolder(name)
    self.Folder = name
    self:BuildFolderTree()
end

function ThemeManager:BuildFolderTree()
    safeMkdir(self.Folder)
    safeMkdir(self.Folder .. "/" .. self.SubFolder)
    safeMkdir(self.Folder .. "/settings")
end

function ThemeManager:GetPath()
    return self.Folder .. "/" .. self.SubFolder
end

function ThemeManager:ApplyTheme(themeTable)
    if not self.Library then return end
    self.Library:ApplyTheme(themeTable)
end

function ThemeManager:LoadBuiltIn(name)
    local t = self.BuiltInThemes[name]
    if not t then return false end
    self:ApplyTheme(t)
    return true
end

function ThemeManager:SaveTheme(name)
    if not name or name == "" then return false, "No name" end
    self:BuildFolderTree()
    local data = {}
    for k, v in pairs(self.Library.Theme) do
        if typeof(v) == "Color3" then
            data[k] = colorToHex(v)
        end
    end
    local ok, encoded = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
    if not ok then return false, "Encode failed" end
    safeWrite(self:GetPath() .. "/" .. name .. ".json", encoded)
    return true
end

function ThemeManager:LoadTheme(name)
    if not name or name == "" then return false end
    local path = self:GetPath() .. "/" .. name .. ".json"
    local content = safeRead(path)
    if not content then return false end
    local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
    if not ok then return false end
    local theme = {}
    for k, v in pairs(decoded) do
        if type(v) == "string" then
            local c = hexToColor(v)
            if c then theme[k] = c end
        end
    end
    self:ApplyTheme(theme)
    return true
end

function ThemeManager:DeleteTheme(name)
    if not name or name == "" then return false end
    local path = self:GetPath() .. "/" .. name .. ".json"
    if delfile then pcall(delfile, path); return true end
    return false
end

function ThemeManager:GetCustomThemes()
    local list = {}
    if not listfiles then return list end
    self:BuildFolderTree()
    local ok, files = pcall(listfiles, self:GetPath())
    if not ok then return list end
    for _, f in ipairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name then table.insert(list, name) end
    end
    return list
end

function ThemeManager:GetAllThemes()
    local list = {}
    for k in pairs(self.BuiltInThemes) do table.insert(list, k) end
    for _, n in ipairs(self:GetCustomThemes()) do
        local exists = false
        for _, e in ipairs(list) do if e == n then exists = true break end end
        if not exists then table.insert(list, n) end
    end
    return list
end

function ThemeManager:SetDefault(name)
    self:BuildFolderTree()
    safeWrite(self.Folder .. "/settings/default_theme.txt", name or "")
end

function ThemeManager:GetDefault()
    return safeRead(self.Folder .. "/settings/default_theme.txt")
end

function ThemeManager:LoadDefault()
    local def = self:GetDefault()
    if def and def ~= "" then
        if self.BuiltInThemes[def] then
            self:LoadBuiltIn(def)
        else
            self:LoadTheme(def)
        end
    end
end

function ThemeManager:ApplyToTab(tab)
    if not self.Library or not tab then return end

    local box = tab:AddLeftGroupbox("Theme")

    local themeDropdown = box:AddDropdown("ThemePreset", {
        Text = "Theme Preset",
        Values = self:GetAllThemes(),
        Default = self:GetDefault() or "Dark Blue",
        Callback = function(name)
            if not name or name == "" then return end
            if self.BuiltInThemes[name] then
                self:LoadBuiltIn(name)
            else
                self:LoadTheme(name)
            end
        end,
    })

    box:AddDivider()

    local accentPicker = box:AddColorPicker("AccentColor", {
        Text = "Accent Color",
        Default = self.Library.Theme.Accent,
        Callback = function(c)
            self.Library.Theme.Accent = c
            self.Library:UpdateColorsUsingRegistry()
        end,
    })

    local backgroundPicker = box:AddColorPicker("BackgroundColor", {
        Text = "Background Color",
        Default = self.Library.Theme.Background,
        Callback = function(c)
            self.Library.Theme.Background = c
            self.Library:UpdateColorsUsingRegistry()
        end,
    })

    local sidebarPicker = box:AddColorPicker("SidebarColor", {
        Text = "Sidebar Color",
        Default = self.Library.Theme.Sidebar,
        Callback = function(c)
            self.Library.Theme.Sidebar = c
            self.Library.Theme.Topbar = c
            self.Library:UpdateColorsUsingRegistry()
        end,
    })

    local groupboxPicker = box:AddColorPicker("GroupboxColor", {
        Text = "Groupbox Color",
        Default = self.Library.Theme.Groupbox,
        Callback = function(c)
            self.Library.Theme.Groupbox = c
            self.Library:UpdateColorsUsingRegistry()
        end,
    })

    local textPicker = box:AddColorPicker("TextColor", {
        Text = "Text Color",
        Default = self.Library.Theme.Text,
        Callback = function(c)
            self.Library.Theme.Text = c
            self.Library:UpdateColorsUsingRegistry()
        end,
    })

    box:AddDivider()

    local nameInput = box:AddInput("ThemeName", {
        Text = "Theme Name",
        Placeholder = "MyTheme",
        Default = "",
        Finished = true,
    })

    box:AddButton({
        Text = "Save Theme",
        Func = function()
            local name = nameInput:GetValue()
            if not name or name == "" then
                self.Library:Notify({ Title = "Theme", Description = "Enter a theme name first", Time = 3 })
                return
            end
            local ok = self:SaveTheme(name)
            if ok then
                themeDropdown:SetValues(self:GetAllThemes())
                self.Library:Notify({ Title = "Theme", Description = "Saved theme: " .. name, Time = 3 })
            else
                self.Library:Notify({ Title = "Theme", Description = "Failed to save", Time = 3 })
            end
        end,
    })

    box:AddButton({
        Text = "Delete Selected",
        DoubleClick = true,
        Func = function()
            local sel = themeDropdown:GetValue()
            if not sel or self.BuiltInThemes[sel] then
                self.Library:Notify({ Title = "Theme", Description = "Cannot delete built-in", Time = 3 })
                return
            end
            self:DeleteTheme(sel)
            themeDropdown:SetValues(self:GetAllThemes())
            self.Library:Notify({ Title = "Theme", Description = "Deleted: " .. sel, Time = 3 })
        end,
    })

    box:AddButton({
        Text = "Set as Default",
        Func = function()
            local sel = themeDropdown:GetValue()
            if not sel or sel == "" then return end
            self:SetDefault(sel)
            self.Library:Notify({ Title = "Theme", Description = "Default: " .. sel, Time = 3 })
        end,
    })

    box:AddButton({
        Text = "Refresh List",
        Func = function()
            themeDropdown:SetValues(self:GetAllThemes())
            self.Library:Notify({ Title = "Theme", Description = "List refreshed", Time = 2 })
        end,
    })

    self._AccentPicker     = accentPicker
    self._BackgroundPicker = backgroundPicker
    self._SidebarPicker    = sidebarPicker
    self._GroupboxPicker   = groupboxPicker
    self._TextPicker       = textPicker
    self._ThemeDropdown    = themeDropdown
end

return ThemeManager