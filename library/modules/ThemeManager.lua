local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
-- HttpService is no longer strictly necessary for themes but kept for compatibility if other parts of the library use it.
local httpService = cloneref(game:GetService("HttpService")) 
-- Unused utilities removed to clean up code
-- local httprequest = (syn and syn.request) or request or http_request or (http and http.request)
-- local getassetfunc = getcustomasset or getsynasset
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(copyfunction) == "function" then
    -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

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
do
    SettingsManager.Folder = "ObsidianLibSettings"
    SettingsManager.Library = nil
    SettingsManager.AppliedToTab = false
    -- BuiltInThemes, CustomThemes functionality removed

    function SettingsManager:SetLibrary(library)
        self.Library = library
    end

    --// Folder Management \\--
    -- Simplified GetPaths as /themes subfolder is no longer needed
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
    -- Renamed to UpdateSettings, handles both colors and font
    function SettingsManager:UpdateSettings()
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

        -- 2. Update Font from Options
        local fontOption = self.Library.Options["FontFace"]
        if fontOption and fontOption.Value then
            -- Fix for SourceSans issue: directly apply the enum via its name string
            self.Library:SetFont(Enum.Font[fontOption.Value])
        end

        -- 3. Apply changes to GUI
        self.Library:UpdateColorsUsingRegistry()
    end

    -- Function to load initial settings (using the library's current scheme)
    function SettingsManager:LoadInitialSettings()
        if not self.Library or not self.Library.Options then return end

        -- Set the default font explicitly to SourceSans and apply it immediately
        local fontOption = self.Library.Options.FontFace
        if fontOption then
            fontOption:SetValue("SourceSans")
            self.Library:SetFont(Enum.Font.SourceSans)
        end
        
        -- Apply the colors/font set in the options to the library's scheme
        self:UpdateSettings() 
    end


    --// GUI Creation - Simplified to only settings \\--
    function SettingsManager:CreateSettings(groupbox)
        assert(self.Library, "Must set SettingsManager.Library first!")
        
        local scheme = self.Library.Scheme

        -- Add color pickers
        groupbox
            :AddLabel("Background color")
            :AddColorPicker("BackgroundColor", { Default = scheme.BackgroundColor })
        groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = scheme.MainColor })
        groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = scheme.AccentColor })
        groupbox
            :AddLabel("Outline color")
            :AddColorPicker("OutlineColor", { Default = scheme.OutlineColor })
        groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = scheme.FontColor })

        groupbox:AddDivider()

        -- Font Dropdown (Moved to the general settings area as requested)
        groupbox:AddDropdown("FontFace", {
            Text = "Font Face",
            Default = "SourceSans",
            Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans" },
        })

        groupbox:AddDivider()

        self.AppliedToTab = true
        
        -- Handlers for continuous updating
        local function UpdateSettingsHandler()
            self:UpdateSettings()
        end
        
        self.Library.Options.BackgroundColor:OnChanged(UpdateSettingsHandler)
        self.Library.Options.MainColor:OnChanged(UpdateSettingsHandler)
        self.Library.Options.AccentColor:OnChanged(UpdateSettingsHandler)
        self.Library.Options.OutlineColor:OnChanged(UpdateSettingsHandler)
        self.Library.Options.FontColor:OnChanged(UpdateSettingsHandler)
        
        -- Font specific handler
        self.Library.Options.FontFace:OnChanged(function()
            self:UpdateSettings()
        end)
        
        self:LoadInitialSettings()
    end

    -- Renamed and simplified ApplyToTab
    function SettingsManager:ApplyToTab(tab)
        assert(self.Library, "Must set SettingsManager.Library first!")
        -- Renamed Groupbox title to better reflect its function
        local groupbox = tab:AddLeftGroupbox("Appearance Settings", "gear") 
        self:CreateSettings(groupbox)
    end

    -- Renamed and simplified ApplyToGroupbox
    function SettingsManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set SettingsManager.Library first!")
        self:CreateSettings(groupbox)
    end

    SettingsManager:BuildFolderTree()
end

getgenv().ObsidianSettingsManager = SettingsManager
return SettingsManager
