local SaveManager = {}
local HttpService = game:GetService("HttpService")

SaveManager.Library = nil
SaveManager.Folder = "FatalityWins"
SaveManager.SubFolder = "configs"
SaveManager.IgnoreList = {}
SaveManager.IgnoreThemeKeys = false
SaveManager.AutoloadFile = "autoload.txt"
SaveManager.CurrentGame = tostring(game.PlaceId)

local function safeRead(p)
    if not readfile then return nil end
    local ok, c = pcall(readfile, p)
    if ok then return c end
    return nil
end

local function safeWrite(p, c)
    if not writefile then return end
    pcall(writefile, p, c)
end

local function safeDelete(p)
    if delfile then pcall(delfile, p) end
end

local function safeMkdir(p)
    if not makefolder then return end
    local exists = false
    if isfolder then
        local ok, result = pcall(isfolder, p)
        if ok then exists = result end
    end
    if not exists then
        pcall(makefolder, p)
    end
end

local THEME_KEYS = {
    AccentColor = true,
    BackgroundColor = true,
    SidebarColor = true,
    GroupboxColor = true,
    TextColor = true,
    ThemePreset = true,
    ThemeName = true,
}

function SaveManager:SetLibrary(lib)
    self.Library = lib
end

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
        for _, v in ipairs(list) do
            self.IgnoreList[v] = true
        end
    end
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreThemeKeys = true
end

local function colorToHex(c)
    if typeof(c) ~= "Color3" then return "#FFFFFF" end
    return string.format("#%02X%02X%02X",
        math.clamp(math.round(c.R * 255), 0, 255),
        math.clamp(math.round(c.G * 255), 0, 255),
        math.clamp(math.round(c.B * 255), 0, 255)
    )
end

local function hexToColor(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

function SaveManager:_ShouldIgnore(idx)
    if self.IgnoreList[idx] then return true end
    if idx == "MenuKeybind" then return true end
    if self.IgnoreThemeKeys and THEME_KEYS[idx] then return true end
    return false
end

function SaveManager:Serialize()
    local data = { Toggles = {}, Options = {} }

    if not self.Library then
        warn("[SaveManager] Library is nil during Serialize")
        return data
    end

    if self.Library.Toggles then
        for idx, opt in pairs(self.Library.Toggles) do
            if not self:_ShouldIgnore(idx) then
                data.Toggles[idx] = {
                    Type = "Toggle",
                    Value = opt.Value,
                }
            end
        end
    end

    if self.Library.Options then
        for idx, opt in pairs(self.Library.Options) do
            if not self:_ShouldIgnore(idx) then
                if opt.Type == "Slider" then
                    data.Options[idx] = {
                        Type = "Slider",
                        Value = opt.Value,
                    }
                elseif opt.Type == "Input" then
                    data.Options[idx] = {
                        Type = "Input",
                        Value = opt.Value,
                    }
                elseif opt.Type == "Dropdown" then
                    if opt.Multi then
                        local arr = {}
                        for k, on in pairs(opt.Value or {}) do
                            if on then table.insert(arr, k) end
                        end
                        data.Options[idx] = {
                            Type = "Dropdown",
                            Multi = true,
                            Value = arr,
                        }
                    else
                        data.Options[idx] = {
                            Type = "Dropdown",
                            Multi = false,
                            Value = opt.Value,
                        }
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
    end

    return data
end

function SaveManager:Deserialize(data)
    if type(data) ~= "table" then
        warn("[SaveManager] Deserialize received non-table data")
        return
    end

    if not self.Library then
        warn("[SaveManager] Library is nil during Deserialize")
        return
    end

    if data.Toggles and self.Library.Toggles then
        for idx, info in pairs(data.Toggles) do
            local el = self.Library.Toggles[idx]
            if el then
                if el.SetValue then
                    pcall(function() el:SetValue(info.Value, true) end)
                end
            end
        end
    end

    if data.Options and self.Library.Options then
        for idx, info in pairs(data.Options) do
            local el = self.Library.Options[idx]
            if el then
                if info.Type == "ColorPicker" then
                    local c = hexToColor(info.Value)
                    if c then
                        if el.SetValueRGB then
                            pcall(function()
                                el:SetValueRGB(c, info.Transparency or 0)
                            end)
                        elseif el.SetValue then
                            pcall(function()
                                el:SetValue(c)
                            end)
                        end
                    end
                elseif info.Type == "KeyPicker" then
                    if el.SetValue then
                        pcall(function()
                            el:SetValue({ info.Value, info.Mode or el.Mode })
                        end)
                    end
                elseif info.Type == "Dropdown" and info.Multi then
                    if el.SetValue then
                        pcall(function()
                            el:SetValue(info.Value, true)
                        end)
                    end
                else
                    if el.SetValue then
                        pcall(function()
                            el:SetValue(info.Value, true)
                        end)
                    end
                end
            end
        end
    end
end

function SaveManager:Save(name)
    if not name or name == "" then
        name = self._CurrentConfig or "default"
    end

    self:BuildFolderTree()

    local data = self:Serialize()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not ok or not encoded then
        warn("[SaveManager] JSON encode failed:", encoded)
        return false
    end

    local path = self:GetGamePath() .. "/" .. name .. ".json"
    safeWrite(path, encoded)
    self._CurrentConfig = name
    return true
end

function SaveManager:Load(name)
    if not name or name == "" then
        warn("[SaveManager] Load called with empty name")
        return false
    end

    local path = self:GetGamePath() .. "/" .. name .. ".json"
    local content = safeRead(path)

    if not content or content == "" then
        warn("[SaveManager] Could not read file:", path)
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not ok or type(data) ~= "table" then
        warn("[SaveManager] JSON decode failed:", data)
        return false
    end

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
    if not ok or type(files) ~= "table" then return list end

    for _, f in ipairs(files) do
        local n = f:match("([^/\\]+)%.json$")
        if n then
            table.insert(list, n)
        end
    end

    table.sort(list)
    return list
end

function SaveManager:SetAutoload(name)
    self:BuildFolderTree()
    safeWrite(self.Folder .. "/settings/" .. self.AutoloadFile, name or "")
end

function SaveManager:GetAutoload()
    local content = safeRead(self.Folder .. "/settings/" .. self.AutoloadFile)
    if content and content ~= "" then
        content = content:match("^%s*(.-)%s*$")
        return content ~= "" and content or nil
    end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local auto = self:GetAutoload()
    if not auto then return end

    local ok = self:Load(auto)
    if ok and self.Library then
        self.Library:Notify({
            Title = "Config",
            Description = "Autoloaded: " .. auto,
            Time = 3,
        })
    end
end

function SaveManager:BuildConfigSection(tab)
    if not self.Library then
        warn("[SaveManager] BuildConfigSection: Library is nil")
        return
    end
    if not tab then
        warn("[SaveManager] BuildConfigSection: tab is nil")
        return
    end

    local box = tab:AddRightGroupbox("Configuration")

    local configs = self:GetConfigs()
    local autoloadName = self:GetAutoload()

    local configDropdown = box:AddDropdown("ConfigList", {
        Text = "Config",
        Values = configs,
        AllowNull = true,
        Default = autoloadName or nil,
    })

    box:AddDivider()

    local nameInput = box:AddInput("ConfigName", {
        Text = "Config Name",
        Placeholder = "default",
        Default = "",
        Finished = false,
    })

    local function notify(desc, time)
        self.Library:Notify({
            Title = "Config",
            Description = desc,
            Time = time or 3,
        })
    end

    local function refreshDropdown()
        local fresh = self:GetConfigs()
        if configDropdown.SetValues then
            configDropdown:SetValues(fresh)
        elseif configDropdown.Refresh then
            configDropdown:Refresh(fresh)
        end
    end

    box:AddButton({
        Text = "Create / Save",
        Func = function()
            local name = nameInput and nameInput:GetValue() or ""
            name = name:match("^%s*(.-)%s*$")

            if name == "" then
                local sel = configDropdown:GetValue()
                if sel and sel ~= "" then
                    name = sel
                else
                    notify("Enter a config name first")
                    return
                end
            end

            local ok = self:Save(name)
            if ok then
                refreshDropdown()
                notify("Saved: " .. name)
            else
                notify("Failed to save config")
            end
        end,
    })

    box:AddButton({
        Text = "Load",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                notify("Select a config first")
                return
            end

            local ok = self:Load(sel)
            if ok then
                notify("Loaded: " .. sel)
            else
                notify("Failed to load: " .. sel)
            end
        end,
    })

    box:AddButton({
        Text = "Overwrite",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                notify("Select a config first")
                return
            end

            local ok = self:Save(sel)
            if ok then
                notify("Overwrote: " .. sel)
            else
                notify("Failed to overwrite: " .. sel)
            end
        end,
    })

    box:AddButton({
        Text = "Delete",
        DoubleClick = true,
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                notify("Select a config first")
                return
            end

            self:Delete(sel)
            refreshDropdown()
            notify("Deleted: " .. sel)
        end,
    })

    box:AddButton({
        Text = "Refresh List",
        Func = function()
            refreshDropdown()
            notify("List refreshed", 2)
        end,
    })

    box:AddDivider()

    box:AddButton({
        Text = "Set Autoload",
        Func = function()
            local sel = configDropdown:GetValue()
            if not sel or sel == "" then
                notify("Select a config first")
                return
            end
            self:SetAutoload(sel)
            notify("Autoload set: " .. sel)
        end,
    })

    box:AddButton({
        Text = "Clear Autoload",
        Func = function()
            self:SetAutoload("")
            notify("Autoload cleared")
        end,
    })

    local currentAutoText = "Autoload: " .. (self:GetAutoload() or "None")
    local autoLbl = box:AddLabel(currentAutoText)

    task.spawn(function()
        while task.wait(1) do
            local stillAlive = false
            pcall(function()
                if autoLbl and autoLbl.SetText then
                    stillAlive = true
                end
            end)
            if not stillAlive then break end

            local cur = self:GetAutoload() or "None"
            local want = "Autoload: " .. cur
            if currentAutoText ~= want then
                currentAutoText = want
                pcall(function() autoLbl:SetText(want) end)
            end
        end
    end)

    self._ConfigDropdown = configDropdown
    self._ConfigInput = nameInput
end

return SaveManager