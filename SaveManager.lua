local SaveManager = {}
local HttpService = game:GetService("HttpService")

SaveManager.Library = nil
SaveManager.Folder = "FatalityWins"
SaveManager.SubFolder = "configs"
SaveManager.IgnoreList = {}
SaveManager.IgnoreThemeKeys = false
SaveManager.AutoloadFile = "autoload.txt"
SaveManager.CurrentGame = tostring(game.PlaceId)

local function safeRead(p) local ok, c = pcall(readfile, p); if ok then return c end end
local function safeWrite(p, c) pcall(writefile, p, c) end
local function safeDelete(p) if delfile then pcall(delfile, p) end end
local function safeMkdir(p) if makefolder and not (isfolder and isfolder(p)) then pcall(makefolder, p) end end

local THEME_KEYS = {
    AccentColor = true, BackgroundColor = true, SidebarColor = true,
    GroupboxColor = true, TextColor = true, ThemePreset = true, ThemeName = true,
}

function SaveManager:SetLibrary(lib) self.Library = lib end

function SaveManager:SetFolder(name)
    self.Folder = name
    self:BuildFolderTree()
end

function SaveManager:BuildFolderTree()
    safeMkdir(self.Folder)
    safeMkdir(self.Folder .. "/" .. self.SubFolder)
    safeMkdir(self:GetGamePath())
    safeMkdir(self.Folder .. "/settings")
end

function SaveManager:GetGamePath()
    return self.Folder .. "/" .. self.SubFolder .. "/" .. self.CurrentGame
end

function SaveManager:SetIgnoreIndexes(list)
    self.IgnoreList = {}
    if type(list) == "table" then
        for _, v in ipairs(list) do self.IgnoreList[v] = true end
    end
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreThemeKeys = true
end

local function colorToHex(c)
    return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function hexToColor(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then return Color3.fromRGB(r, g, b) end
end

local function shouldIgnore(self, idx)
    if self.IgnoreList[idx] then return true end
    if idx == "MenuKeybind" then return true end
    if self.IgnoreThemeKeys and THEME_KEYS[idx] then return true end
    return false
end

function SaveManager:Serialize()
    local data = { Toggles = {}, Options = {} }

    for idx, opt in pairs(self.Library.Toggles) do
        if not shouldIgnore(self, idx) then
            data.Toggles[idx] = { Type = "Toggle", Value = opt.Value }
        end
    end

    for idx, opt in pairs(self.Library.Options) do
        if not shouldIgnore(self, idx) then
            if opt.Type == "Slider" then
                data.Options[idx] = { Type = "Slider", Value = opt.Value }
            elseif opt.Type == "Input" then
                data.Options[idx] = { Type = "Input", Value = opt.Value }
            elseif opt.Type == "Dropdown" then
                if opt.Multi then
                    local arr = {}
                    for k, on in pairs(opt.Value or {}) do
                        if on then table.insert(arr, k) end
                    end
                    data.Options[idx] = { Type = "Dropdown", Multi = true, Value = arr }
                else
                    data.Options[idx] = { Type = "Dropdown", Multi = false, Value = opt.Value }
                end
            elseif opt.Type == "ColorPicker" then
                data.Options[idx] = {
                    Type = "ColorPicker",
                    Value = colorToHex(opt.Value),
                    Transparency = opt.Transparency or 0,
                }
            elseif opt.Type == "KeyPicker" then
                data.Options[idx] = {
                    Type = "KeyPicker",
                    Value = opt.Value,
                    Mode = opt.Mode,
                }
            end
        end
    end

    return data
end

function SaveManager:Deserialize(data)
    if type(data) ~= "table" then return end

    if data.Toggles then
        for idx, info in pairs(data.Toggles) do
            local el = self.Library.Toggles[idx]
            if el and el.SetValue then
                pcall(function() el:SetValue(info.Value, true) end)
            end
        end
    end

    if data.Options then
        for idx, info in pairs(data.Options) do
            local el = self.Library.Options[idx]
            if el then
                if info.Type == "ColorPicker" then
                    local c = hexToColor(info.Value)
                    if c and el.SetValueRGB then
                        pcall(function() el:SetValueRGB(c, info.Transparency or 0) end)
                    end
                elseif info.Type == "KeyPicker" then
                    if el.SetValue then
                        pcall(function() el:SetValue({ info.Value, info.Mode or el.Mode }) end)
                    end
                elseif info.Type == "Dropdown" and info.Multi then
                    if el.SetValue then
                        pcall(function() el:SetValue(info.Value, true) end)
                    end
                else
                    if el.SetValue then
                        pcall(function() el:SetValue(info.Value, true) end)
                    end
                end
            end
        end
    end
end

function SaveManager:Save(name)
    if not name then
        name = self._CurrentConfig or "default"
    end
    if name == "" then return false end
    self:BuildFolderTree()
    local data = self:Serialize()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    safeWrite(self:GetGamePath() .. "/" .. name .. ".json", encoded)
    return true
end

function SaveManager:Load(name)
    if not name or name == "" then return false end
    local path = self:GetGamePath() .. "/" .. name .. ".json"
    local content = safeRead(path)
    if not content then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok then return false end
    self:Deserialize(data)
    self._CurrentConfig = name
    return true
end

function SaveManager:Delete(name)
    if not name or name == "" then return false end
    safeDelete(self:GetGamePath() .. "/" .. name .. ".json")
    return true
end

function SaveManager:GetConfigs()
    local list = {}
    if not listfiles then return list end
    self:BuildFolderTree()
    local ok, files = pcall(listfiles, self:GetGamePath())
    if not ok then return list end
    for _, f in ipairs(files) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(list, n) end
    end
    return list
end

function SaveManager:SetAutoload(name)
    self:BuildFolderTree()
    safeWrite(self.Folder .. "/settings/" .. self.AutoloadFile, name or "")
end

function SaveManager:GetAutoload()
    return safeRead(self.Folder .. "/settings/" .. self.AutoloadFile)
end

function SaveManager:LoadAutoloadConfig()
    local auto = self:GetAutoload()
    if auto and auto ~= "" then
        local ok = self:Load(auto)
        if ok and self.Library then
            self.Library:Notify({
                Title = "Config",
                Description = "Autoloaded: " .. auto,
                Time = 3,
            })
        end
    end
end

function SaveManager:BuildConfigSection(tab)
    if not self.Library or not tab then return end

    local box = tab:AddRightGroupbox("Configuration")

    local configDropdown = box:AddDropdown("ConfigList", {
        Text = "Config",
        Values = self:GetConfigs(),
        AllowNull = true,
        Default = self:GetAutoload() or nil,
    })

    box:AddDivider()

    local nameInput = box:AddInput("ConfigName", {
        Text = "Config Name",
        Placeholder = "default",
        Default = "",
        Finished = true,
    })

    box:AddButton({
        Text = "Create / Save",
        Func = function()
            local name = nameInput:GetValue()
            if not name or name == "" then
                local sel = configDropdown:GetValue()
                if sel and sel ~= "" then
                    name = sel
                else
                    self.Library:Notify({ Title = "Config", Description = "Enter a name first", Time = 3 })
                    return
                end
            end
            local ok = self:Save(name)
            if ok then
                configDropdown:SetValues(self:GetConfigs())
                self.Library:Notify({ Title = "Config", Description = "Saved: " .. name, Time = 3 })
            else
                self.Library:Notify({ Title = "Config", Description = "Failed to save", Time = 3 })
            end
        end,
    })

    box:AddButton({
        Text = "Load",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                self.Library:Notify({ Title = "Config", Description = "Select a config first", Time = 3 })
                return
            end
            local ok = self:Load(sel)
            if ok then
                self.Library:Notify({ Title = "Config", Description = "Loaded: " .. sel, Time = 3 })
            else
                self.Library:Notify({ Title = "Config", Description = "Failed to load", Time = 3 })
            end
        end,
    })

    box:AddButton({
        Text = "Overwrite",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                self.Library:Notify({ Title = "Config", Description = "Select a config first", Time = 3 })
                return
            end
            self:Save(sel)
            self.Library:Notify({ Title = "Config", Description = "Overwrote: " .. sel, Time = 3 })
        end,
    })

    box:AddButton({
        Text = "Delete",
        DoubleClick = true,
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                self.Library:Notify({ Title = "Config", Description = "Select a config first", Time = 3 })
                return
            end
            self:Delete(sel)
            configDropdown:SetValues(self:GetConfigs())
            self.Library:Notify({ Title = "Config", Description = "Deleted: " .. sel, Time = 3 })
        end,
    })

    box:AddButton({
        Text = "Refresh List",
        Func = function()
            configDropdown:SetValues(self:GetConfigs())
            self.Library:Notify({ Title = "Config", Description = "List refreshed", Time = 2 })
        end,
    })

    box:AddDivider()

    box:AddButton({
        Text = "Set Autoload",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                self.Library:Notify({ Title = "Config", Description = "Select a config first", Time = 3 })
                return
            end
            self:SetAutoload(sel)
            self.Library:Notify({ Title = "Config", Description = "Autoload set: " .. sel, Time = 3 })
        end,
    })

    box:AddButton({
        Text = "Clear Autoload",
        Func = function()
            self:SetAutoload("")
            self.Library:Notify({ Title = "Config", Description = "Autoload cleared", Time = 3 })
        end,
    })

    local autoLbl = box:AddLabel("Autoload: " .. (self:GetAutoload() or "None"))

    task.spawn(function()
        while autoLbl._Label and autoLbl._Label.Parent do
            local cur = self:GetAutoload() or "None"
            if autoLbl._Label.Text ~= "Autoload: " .. cur then
                autoLbl:SetText("Autoload: " .. cur)
            end
            task.wait(1)
        end
    end)

    self._ConfigDropdown = configDropdown
    self._ConfigInput = nameInput
end

return SaveManager