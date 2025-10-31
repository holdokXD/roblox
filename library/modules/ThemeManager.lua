local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)
local httpService = cloneref(game:GetService("HttpService"))
-- local httprequest = (syn and syn.request) or request or http_request or (http and http.request) -- Удалено, так как не используется
local getassetfunc = getcustomasset or getsynasset
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

local ThemeManager = {}
do
    ThemeManager.Folder = "ObsidianLibSettings"
    -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

    ThemeManager.Library = nil
    ThemeManager.AppliedToTab = false
    
    -- ОСТАВЛЕНА ТОЛЬКО ОДНА ТЕМА "Default" С ВАШИМИ ЦВЕТАМИ
    ThemeManager.BuiltInThemes = {
        ["Default"] = {
            1,
            httpService:JSONDecode(
                [[{"FontColor":"ffffff","MainColor":"000000","AccentColor":"ff0000","BackgroundColor":"000000","OutlineColor":"000000"}]]
            ), 
        },
    }

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    --// Folders \\--
    function ThemeManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        paths[#paths + 1] = self.Folder .. "/themes"

        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then
                continue
            end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then
            return
        end
        self:BuildFolderTree()

        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    --// Apply, Update theme \\--
    function ThemeManager:ApplyTheme(theme)
        -- Убрана логика CustomTheme, так как она не используется
        local data = self.BuiltInThemes[theme]

        if not data then
            return
        end

        local scheme = data[2]
        for idx, val in pairs(scheme) do
            if idx == "VideoLink" then
                continue
            elseif idx == "FontFace" then
                self.Library:SetFont(Enum.Font[val])

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            else
                -- Применяем цвета только при загрузке, но не добавляем их в UI как опции
                self.Library.Scheme[idx] = Color3.fromHex(val)

                -- Убран вызов Options[idx]:SetValueRGB
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        -- Обновляем цвета, только если они были изменены через настройки (но мы их убрали)
        local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        for i, field in pairs(options) do
            if self.Library.Options and self.Library.Options[field] then
                -- Убран код, который брал значения из Options
            end
        end

        self.Library:UpdateColorsUsingRegistry()
    end

    --// Get, Load, Save, Delete, Refresh \\--
    function ThemeManager:GetCustomTheme(file)
        -- Функция очищена: Пользовательские темы удалены
        return nil
    end

    function ThemeManager:LoadDefault()
        local theme = "Default"
        -- Файлы default.txt и пользовательские темы игнорируются
        -- Всегда применяем hardcoded "Default"
        
        self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        self:ApplyTheme(theme) -- Принудительное применение дефолтной темы
    end

    function ThemeManager:SaveDefault(theme)
        -- Функция очищена: Сохранение дефолтной темы удалено
    end

    function ThemeManager:SetDefaultTheme(theme)
        -- Функция очищена, но сохранена логика применения цветов по умолчанию
        assert(self.Library, "Must set ThemeManager.Library first!")
        assert(not self.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")

        local FinalTheme = {}
        local LibraryScheme = {}
        local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        
        -- Используем hardcoded цвета "Default"
        local defaultColors = ThemeManager.BuiltInThemes["Default"][2]

        for _, field in pairs(fields) do
            FinalTheme[field] = defaultColors[field]
            LibraryScheme[field] = Color3.fromHex(defaultColors[field])
        end

        if typeof(theme["FontFace"]) == "EnumItem" then
            FinalTheme["FontFace"] = theme["FontFace"].Name
            LibraryScheme["Font"] = Font.fromEnum(theme["FontFace"])
        elseif typeof(theme["FontFace"]) == "string" then
            FinalTheme["FontFace"] = theme["FontFace"]
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font[theme["FontFace"]])
        else
            FinalTheme["FontFace"] = "Code"
            LibraryScheme["Font"] = Font.fromEnum(Enum.Font.Code)
        end

        for _, field in pairs({ "Red", "Dark", "White" }) do
            LibraryScheme[field] = self.Library.Scheme[field]
        end

        self.Library.Scheme = LibraryScheme
        self.BuiltInThemes["Default"] = { 1, FinalTheme }

        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:SaveCustomTheme(file)
        -- Функция удалена
    end

    function ThemeManager:Delete(name)
        -- Функция удалена
        return false, "Custom themes disabled"
    end

    function ThemeManager:ReloadCustomThemes()
        -- Функция удалена
        return {}
    end

    --// GUI \\--
    function ThemeManager:CreateThemeManager(groupbox)
        -- ОСТАВЛЕН ТОЛЬКО ВЫБОР ШРИФТА
        
        groupbox:AddDropdown("FontFace", {
            Text = "Font Face",
            Default = "SourceSans",
            Values = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans" },
        })

        -- УДАЛЕНЫ ВСЕ ЭЛЕМЕНТЫ УПРАВЛЕНИЯ ТЕМАМИ И ЦВЕТАМИ
        
        -- Добавление заглушки для ThemeManager_ThemeList, чтобы не вызывать ошибку LoadDefault
        self.Library.Options.ThemeManager_ThemeList = { Value = "Default", SetValue = function() end }
        
        self:LoadDefault()
        self.AppliedToTab = true

        -- ОСТАВЛЕН ТОЛЬКО ОБРАБОТЧИК ДЛЯ ШРИФТА
        self.Library.Options.FontFace:OnChanged(function(Value)
            self.Library:SetFont(Enum.Font[Value])
            self.Library:UpdateColorsUsingRegistry()
        end)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        return tab:AddLeftGroupbox("Themes", "paintbrush")
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, "Must set ThemeManager.Library first!")
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "Must set ThemeManager.Library first!")
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
