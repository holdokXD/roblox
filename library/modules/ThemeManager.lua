local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)

local httpService = cloneref(game:GetService("HttpService")) 
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(copyfunction) == "function" then
    local isfolder_copy, isfile_copy, listfiles_copy =
        copyfunction(isfolder), copyfunction(isfile), copyfunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

-- Renamed ThemeManager to SettingsManager as its function is now generalized settings control.
local SettingsManager = {}

-- Define the user's requested default theme constants
-- Эти значения будут применены как тема по умолчанию при первой загрузке.
local USER_DEFAULT_THEME = {
    MainColor = "000000",
    FontFace = "SourceSans",
    AccentColor = "ff0000",
    OutlineColor = "000000",
    BackgroundColor = "000000",
    FontColor = "ffffff"
}

do
    SettingsManager.Folder = "ObsidianLibSettings"
    SettingsManager.Library = nil
    SettingsManager.AppliedToTab = false

    function SettingsManager:SetLibrary(library)
        self.Library = library
        
        -- Принудительно устанавливаем цветовую схему и шрифт, запрошенные пользователем,
        -- сразу же, чтобы они использовались библиотекой до построения UI.
        if self.Library and self.Library.Scheme then
            self.Library.Scheme.MainColor = USER_DEFAULT_THEME.MainColor
            self.Library.Scheme.AccentColor = USER_DEFAULT_THEME.AccentColor
            self.Library.Scheme.OutlineColor = USER_DEFAULT_THEME.OutlineColor
            self.Library.Scheme.BackgroundColor = USER_DEFAULT_THEME.BackgroundColor
            self.Library.Scheme.FontColor = USER_DEFAULT_THEME.FontColor
            self.Library.Scheme.FontFace = USER_DEFAULT_THEME.FontFace -- Установка шрифта
        end
    end

    --// Folder Management \\--
    function SettingsManager:GetPaths()
        return { self.Folder }
    end

    function SettingsManager:BuildFolderTree()
        local paths = self:GetPaths()
        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then
                continue
            end
            makefolder(str)
        end
    end

    function SettingsManager:CheckFolderTree()
        if isfolder(self.Folder) then
            return
        end
        self:BuildFolderTree()
        task.wait(0.1)
    end

    function SettingsManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    --// Update Settings \\--
    function SettingsManager:UpdateColors()
        -- Ensure Library and Options exist before proceeding
        if not self.Library or not self.Library.Options then
            return
        end

        local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

        -- 1. Update Scheme colors from Options
        for i, field in pairs(options) do
            if self.Library.Options[field] then
                self.Library.Scheme[field] = self.Library.Options[field].Value
            end
        end
        
        -- 2. Apply changes to GUI
        self.Library:UpdateColorsUsingRegistry()
    end

    -- Function to load initial settings (using the library's current scheme)
    function SettingsManager:LoadInitialSettings()
        if not self.Library or not self.Library.Options then return end
        
        -- Применяем цвета, установленные в опциях, к схеме библиотеки.
        self:UpdateColors() 
    end


    --// GUI Creation - Simplified to only color settings \\--
    function SettingsManager:CreateColorSettings(groupbox)
        assert(self.Library, "Must set SettingsManager.Library first!")
        
        -- Используем hardcoded defaults из USER_DEFAULT_THEME для инициализации ColorPicker-ов
        local defaults = USER_DEFAULT_THEME

        -- Add color pickers
        groupbox
            :AddLabel("Background color")
            :AddColorPicker("BackgroundColor", { Default = defaults.BackgroundColor })
        groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = defaults.MainColor })
        groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = defaults.AccentColor })
        groupbox
            :AddLabel("Outline color")
            :AddColorPicker("OutlineColor", { Default = defaults.OutlineColor })
        groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = defaults.FontColor })

        self.AppliedToTab = true
        
        -- Handlers for continuous updating
        local function UpdateColorsHandler()
            self:UpdateColors()
        end
        
        self.Library.Options.BackgroundColor:OnChanged(UpdateColorsHandler)
        self.Library.Options.MainColor:OnChanged(UpdateColorsHandler)
        self.Library.Options.AccentColor:OnChanged(UpdateColorsHandler)
        self.Library.Options.OutlineColor:OnChanged(UpdateColorsHandler)
        self.Library.Options.FontColor:OnChanged(UpdateColorsHandler)
        
        self:LoadInitialSettings()
    end

    function SettingsManager:ApplyToTab(tab)
        assert(self.Library, "Must set SettingsManager.Library first!")
        -- Renamed Groupbox title to better reflect its function
        local groupbox = tab:AddLeftGroupbox("Appearance Colors", "color-palette") 
        self:CreateColorSettings(groupbox)
    end

    function SettingsManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set SettingsManager.Library first!")
        self:CreateColorSettings(groupbox)
    end

    SettingsManager:BuildFolderTree()
end

getgenv().ObsidianSettingsManager = SettingsManager
return SettingsManager
