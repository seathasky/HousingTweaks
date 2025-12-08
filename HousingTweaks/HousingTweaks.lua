-- HousingTweaks: Quality of life tweaks for the Housing system
local addonName, HT = ...

-- Default settings
local defaults = {
    tweaks = {
        MoveableStoragePanel = true,
        DecorPreview = true,
        StoragePanelStyle = true,
    },
    positions = {},
    DecorPreviewPosition = "CENTERRIGHT",
    storagePanelColorTheme = "orange",
}

-- Initialize saved variables
local function InitializeDB()
    if not HousingTweaksDB then
        HousingTweaksDB = CopyTable(defaults)
    end
    -- Ensure all default keys exist
    for k, v in pairs(defaults) do
        if HousingTweaksDB[k] == nil then
            if type(v) == "table" then
                HousingTweaksDB[k] = CopyTable(v)
            else
                HousingTweaksDB[k] = v
            end
        end
    end
    for k, v in pairs(defaults.tweaks) do
        if HousingTweaksDB.tweaks[k] == nil then
            HousingTweaksDB.tweaks[k] = v
        end
    end
    -- Ensure DecorPreviewPosition default
    if HousingTweaksDB.DecorPreviewPosition == nil then
        HousingTweaksDB.DecorPreviewPosition = defaults.DecorPreviewPosition
    end
    -- Ensure storagePanelColorTheme default
    if HousingTweaksDB.storagePanelColorTheme == nil then
        HousingTweaksDB.storagePanelColorTheme = defaults.storagePanelColorTheme
    end
end

-- Tweak definitions
HT.TweakInfo = {
    MoveableStoragePanel = {
        name = "Moveable Storage Panel",
        description = "Allows you to move the housing storage panel anywhere on screen.",
        requiresReload = true,
    },
    DecorPreview = {
        name = "Decor Preview",
        description = "Shows a large preview of decor items when you hover over them in the storage panel.",
        requiresReload = true,
    },
    StoragePanelStyle = {
        name = "Storage Panel Style",
        description = "Applies a dark gray theme with colored accents to the storage panel.",
        requiresReload = true,
    },
}

-- Registered tweak modules
HT.Tweaks = {}

function HT:RegisterTweak(name, module)
    self.Tweaks[name] = module
end

function HT:IsTweakEnabled(name)
    return HousingTweaksDB and HousingTweaksDB.tweaks[name]
end

function HT:SetTweakEnabled(name, enabled)
    if not HousingTweaksDB then return end
    HousingTweaksDB.tweaks[name] = enabled
end

function HT:GetPosition(name)
    return HousingTweaksDB and HousingTweaksDB.positions[name]
end

function HT:SavePosition(name, point, relativeTo, relativePoint, x, y)
    if not HousingTweaksDB then return end
    HousingTweaksDB.positions[name] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

-- Reload prompt dialog
StaticPopupDialogs["HOUSINGTWEAKS_RELOAD_PROMPT"] = {
    text = "This tweak requires a UI reload to take effect. Reload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Get current theme color
local function GetThemeColor()
    local colorThemes = {
        orange = {r = 1, g = 0.5, b = 0},
        blue = {r = 0.2, g = 0.6, b = 1},
        purple = {r = 0.7, g = 0.3, b = 1},
        green = {r = 0.3, g = 0.9, b = 0.4},
        red = {r = 1, g = 0.2, b = 0.2},
        cyan = {r = 0.2, g = 0.9, b = 0.9},
        white = {r = 1, g = 1, b = 1},
    }
    local themeName = HousingTweaksDB and HousingTweaksDB.storagePanelColorTheme or "orange"
    local theme = colorThemes[themeName] or colorThemes.orange
    return theme.r, theme.g, theme.b
end

-- Function to refresh GUI colors
local function RefreshGUIColors(frame)
    local r, g, b = GetThemeColor()
    
    -- Update title
    if frame.TitleText then
        frame.TitleText:SetTextColor(r, g, b)
    end
    
    -- Update active tab text
    if frame.tabs then
        for _, tab in ipairs(frame.tabs) do
            if tab.name == frame.activeTab then
                tab.text:SetTextColor(r, g, b)
            else
                tab.text:SetTextColor(0.7, 0.7, 0.7)
            end
        end
    end
    
    -- Update all children of scrollChild to find and update colored text
    if frame.scrollChild then
        local function UpdateRegion(region)
            if region and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    -- Update specific colored elements
                    if text == "Theme Settings" or 
                       text == "Moveable Storage Panel" or 
                       text == "Storage Panel Style" or 
                       text == "Decor Preview" then
                        region:SetTextColor(r, g, b)
                    end
                end
            end
        end
        
        -- Update all font strings in scrollChild
        local regions = {frame.scrollChild:GetRegions()}
        for _, region in ipairs(regions) do
            UpdateRegion(region)
        end
        
        -- Update font strings in containers
        local children = {frame.scrollChild:GetChildren()}
        for _, child in ipairs(children) do
            local childRegions = {child:GetRegions()}
            for _, region in ipairs(childRegions) do
                UpdateRegion(region)
            end
        end
    end
end

-- Forward declare PopulateSettingsFrame
local PopulateSettingsFrame

-- Create the settings GUI
local function CreateSettingsFrame()
    local frame = CreateFrame("Frame", "HousingTweaksSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 450)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    frame:SetFrameStrata("LOW")
    frame.InsetBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    frame.Bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    frame.TitleBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    -- Hide borders for minimal style
    frame.TopBorder:Hide()
    frame.BottomBorder:Hide()
    frame.LeftBorder:Hide()
    frame.RightBorder:Hide()
    frame.TopLeftCorner:Hide()
    frame.TopRightCorner:Hide()
    frame.BotLeftCorner:Hide()
    frame.BotRightCorner:Hide()
    frame.InsetBorderTop:Hide()
    frame.InsetBorderBottom:Hide()
    frame.InsetBorderLeft:Hide()
    frame.InsetBorderRight:Hide()
    frame.InsetBorderTopLeft:Hide()
    frame.InsetBorderTopRight:Hide()
    frame.InsetBorderBottomLeft:Hide()
    frame.InsetBorderBottomRight:Hide()
    
    frame.TitleText:SetText("Housing Tweaks")
    frame.TitleText:SetTextColor(GetThemeColor())
    frame.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Version text in top right corner
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -5)
    versionText:SetText("ver. 1.0.2")
    versionText:SetTextColor(0.6, 0.6, 0.6)
    versionText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Create tab buttons
    local tabButtons = {}
    
    local function CreateTab(name, index)
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(100, 30)
        tab:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 10 + (index - 1) * 105, 5)
        
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(name)
        text:SetTextColor(0.7, 0.7, 0.7)
        
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 1)
        tab.bg = bg
        
        tab:SetScript("OnClick", function()
            for _, t in ipairs(tabButtons) do
                t.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
                t.text:SetTextColor(0.7, 0.7, 0.7)
            end
            tab.bg:SetColorTexture(0.25, 0.25, 0.25, 1)
            tab.text:SetTextColor(GetThemeColor())
            frame.activeTab = name
            PopulateSettingsFrame(frame)
        end)
        
        tab.text = text
        tab.name = name
        table.insert(tabButtons, tab)
        return tab
    end
    
    local themeTab = CreateTab("Theme", 1)
    local storageTab = CreateTab("Storage", 2)
    
    -- Set Theme as default
    themeTab.bg:SetColorTexture(0.25, 0.25, 0.25, 1)
    themeTab.text:SetTextColor(GetThemeColor())
    frame.activeTab = "Theme"
    frame.tabs = tabButtons
    
    -- Scroll frame for tweaks list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 5, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.InsetBg, "BOTTOMRIGHT", -26, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    frame.containers = {}
    
    return frame
end

function PopulateSettingsFrame(frame)
    local scrollChild = frame.scrollChild
    local yOffset = -10
    local activeTab = frame.activeTab or "Theme"
    
    -- Clear existing containers and all children from scrollChild
    for _, container in pairs(frame.containers) do
        container:Hide()
        container:SetParent(nil)
    end
    wipe(frame.containers)
    
    -- Clear all existing children from scrollChild
    local regions = {scrollChild:GetChildren()}
    for _, region in ipairs(regions) do
        region:Hide()
        region:SetParent(nil)
    end
    local fontStrings = {scrollChild:GetRegions()}
    for _, fontString in ipairs(fontStrings) do
        if fontString:GetObjectType() == "FontString" then
            fontString:Hide()
            fontString:SetParent(nil)
        end
    end
    
    -- Theme Tab Content
    if activeTab == "Theme" then
        -- Color theme section
        local themeLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        themeLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
        themeLabel:SetText("Theme Settings")
        themeLabel:SetTextColor(GetThemeColor())
        yOffset = yOffset - 30
        
        local themeDesc = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        themeDesc:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
        themeDesc:SetText("Accent Color Theme:")
        themeDesc:SetTextColor(1, 1, 1)
        yOffset = yOffset - 25
        
        -- Dropdown
        local dropdown = CreateFrame("Frame", "HousingTweaksColorThemeDropdown", scrollChild, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        UIDropDownMenu_SetWidth(dropdown, 150)
        
        local colorThemes = {
            { value = "orange", text = "Orange", r = 1, g = 0.5, b = 0 },
            { value = "blue", text = "Blue", r = 0.2, g = 0.6, b = 1 },
            { value = "purple", text = "Purple", r = 0.7, g = 0.3, b = 1 },
            { value = "green", text = "Green", r = 0.3, g = 0.9, b = 0.4 },
            { value = "red", text = "Red", r = 1, g = 0.2, b = 0.2 },
            { value = "cyan", text = "Cyan", r = 0.2, g = 0.9, b = 0.9 },
            { value = "white", text = "White", r = 1, g = 1, b = 1 },
        }
        
        local function OnClick(self, arg1)
            HousingTweaksDB.storagePanelColorTheme = arg1
            UIDropDownMenu_SetText(dropdown, self:GetText())
            CloseDropDownMenus()
            
                -- Apply theme immediately without reload
                if HT.Tweaks.StoragePanelStyle and HT.Tweaks.StoragePanelStyle.ApplyTheme then
                    HT.Tweaks.StoragePanelStyle:ApplyTheme()
                end
                if HT.Tweaks.DecorPreview and HT.Tweaks.DecorPreview.ApplyTheme then
                    HT.Tweaks.DecorPreview:ApplyTheme()
                end
                
                -- Refresh GUI colors
                RefreshGUIColors(frame)            -- Update tab colors
            if frame.tabs then
                for _, tab in ipairs(frame.tabs) do
                    if tab.text:GetText() == activeTab then
                        tab.text:SetTextColor(GetThemeColor())
                    end
                end
            end
        end
        
        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, theme in ipairs(colorThemes) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = theme.text
                info.arg1 = theme.value
                info.func = OnClick
                info.checked = (HousingTweaksDB.storagePanelColorTheme == theme.value)
                info.colorCode = string.format("|cff%02x%02x%02x", theme.r * 255, theme.g * 255, theme.b * 255)
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        
        -- Set current selection text
        local currentTheme = HousingTweaksDB.storagePanelColorTheme or "orange"
        for _, theme in ipairs(colorThemes) do
            if theme.value == currentTheme then
                UIDropDownMenu_SetText(dropdown, theme.text)
                break
            end
        end
        
        yOffset = yOffset - 40
        
        local note = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        note:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
        note:SetPoint("RIGHT", scrollChild, "RIGHT", -15, 0)
        note:SetJustifyH("LEFT")
        note:SetText("This color theme applies to GUI elements and storage panel accents.")
        note:SetTextColor(0.7, 0.7, 0.7)
        
        table.insert(frame.containers, dropdown)
        
        yOffset = yOffset - 50
        
        -- Storage Panel Style tweak
        local info = HT.TweakInfo["StoragePanelStyle"]
        if info then
            local container = CreateFrame("Frame", nil, scrollChild)
            container:SetSize(scrollChild:GetWidth() - 10, 60)
            container:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
            
            local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
            checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            checkbox:SetChecked(HT:IsTweakEnabled("StoragePanelStyle"))
            
            local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
            label:SetText(info.name)
            label:SetTextColor(GetThemeColor())
            
            if info.requiresReload then
                local reloadIcon = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                reloadIcon:SetPoint("LEFT", label, "RIGHT", 5, 0)
                reloadIcon:SetText("|cFFFFAA00(reload)|r")
            end
            
            local desc = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 5, 2)
            desc:SetPoint("RIGHT", container, "RIGHT", -5, 0)
            desc:SetJustifyH("LEFT")
            desc:SetText(info.description)
            desc:SetTextColor(1, 1, 1)
            
            checkbox:SetScript("OnClick", function(self)
                local enabled = self:GetChecked()
                HT:SetTweakEnabled("StoragePanelStyle", enabled)
                
                if info.requiresReload then
                    StaticPopup_Show("HOUSINGTWEAKS_RELOAD_PROMPT")
                end
            end)
            
            table.insert(frame.containers, container)
        end
    end
    
    -- Storage Tab Content
    if activeTab == "Storage" then
        -- Sort storage-related tweaks (StoragePanelStyle is in Theme tab)
        local storageTweaks = {"MoveableStoragePanel", "DecorPreview"}
        
        for _, tweakName in ipairs(storageTweaks) do
            local info = HT.TweakInfo[tweakName]
            if info then
                local container = CreateFrame("Frame", nil, scrollChild)
                container:SetSize(scrollChild:GetWidth() - 10, 60)
                container:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
                
                local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
                checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
                checkbox:SetChecked(HT:IsTweakEnabled(tweakName))
                
                local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
                label:SetText(info.name)
                label:SetTextColor(GetThemeColor())
                
                if info.requiresReload then
                    local reloadIcon = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    reloadIcon:SetPoint("LEFT", label, "RIGHT", 5, 0)
                    reloadIcon:SetText("|cFFFFAA00(reload)|r")
                end
                
                local desc = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                desc:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 5, 2)
                desc:SetPoint("RIGHT", container, "RIGHT", -5, 0)
                desc:SetJustifyH("LEFT")
                desc:SetText(info.description)
                desc:SetTextColor(1, 1, 1)
                
                checkbox:SetScript("OnClick", function(self)
                    local enabled = self:GetChecked()
                    HT:SetTweakEnabled(tweakName, enabled)
                    
                    if info.requiresReload then
                        StaticPopup_Show("HOUSINGTWEAKS_RELOAD_PROMPT")
                    end
                end)
                
                table.insert(frame.containers, container)
                yOffset = yOffset - 70
                
                -- Add dropdown for DecorPreview position
                if tweakName == "DecorPreview" then
                -- Separator line
                local sep = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                sep:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
                sep:SetText("_______________________________")
                sep:SetTextColor(0.5, 0.5, 0.5)
                yOffset = yOffset - 20
                
                -- Position label
                local posLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                posLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
                posLabel:SetText("Preview Position:")
                posLabel:SetTextColor(1, 1, 1)
                yOffset = yOffset - 25
                
                -- Dropdown
                local dropdown = CreateFrame("Frame", "HousingTweaksPreviewPosDropdown", scrollChild, "UIDropDownMenuTemplate")
                dropdown:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
                UIDropDownMenu_SetWidth(dropdown, 150)
                
                local positions = {
                    { value = "CENTER", text = "Center" },
                    { value = "CENTERRIGHT", text = "Center Right *" },
                    { value = "CENTERLEFT", text = "Center Left" },
                    { value = "TOP", text = "Top" },
                    { value = "TOPRIGHT", text = "Top Right" },
                    { value = "TOPLEFT", text = "Top Left" },
                    { value = "RIGHT", text = "Right" },
                    { value = "LEFT", text = "Left" },
                    { value = "BOTTOMRIGHT", text = "Bottom Right" },
                    { value = "BOTTOMLEFT", text = "Bottom Left" },
                }
                
                local function OnClick(self, arg1)
                    HousingTweaksDB.DecorPreviewPosition = arg1
                    UIDropDownMenu_SetText(dropdown, self:GetText())
                    CloseDropDownMenus()
                    StaticPopup_Show("HOUSINGTWEAKS_RELOAD_PROMPT")
                end
                
                UIDropDownMenu_Initialize(dropdown, function(self, level)
                    for _, pos in ipairs(positions) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = pos.text
                        info.arg1 = pos.value
                        info.func = OnClick
                        info.checked = (HousingTweaksDB.DecorPreviewPosition == pos.value)
                        UIDropDownMenu_AddButton(info, level)
                    end
                end)
                
                -- Set current selection text
                local currentPos = HousingTweaksDB.DecorPreviewPosition or "RIGHT"
                for _, pos in ipairs(positions) do
                    if pos.value == currentPos then
                        UIDropDownMenu_SetText(dropdown, pos.text)
                        break
                    end
                end
                
                    yOffset = yOffset - 45
                end
            end
        end
    end
    
    scrollChild:SetHeight(math.abs(yOffset) + 10)
end

-- Slash command
local settingsFrame
SLASH_HOUSINGTWEAKS1 = "/housingtweaks"
SLASH_HOUSINGTWEAKS2 = "/ht"
SlashCmdList["HOUSINGTWEAKS"] = function(msg)
    if not settingsFrame then
        settingsFrame = CreateSettingsFrame()
    end
    PopulateSettingsFrame(settingsFrame)
    settingsFrame:SetShown(not settingsFrame:IsShown())
end

function HT:ShowSettings()
    if not settingsFrame then
        settingsFrame = CreateSettingsFrame()
    end
    PopulateSettingsFrame(settingsFrame)
    settingsFrame:Show()
    if HouseEditorFrame and HouseEditorFrame:IsShown() then
        print("|cFFFFAA00Housing Tweaks:|r Settings GUI will open when you leave Edit House mode.")
    end
end

-- Initialize on load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        InitializeDB()
        
        -- Initialize enabled tweaks
        C_Timer.After(0, function()
            for name, module in pairs(HT.Tweaks) do
                if HT:IsTweakEnabled(name) and module.Init then
                    module:Init()
                end
            end
        end)
        
        print("|cFF00FF00Housing Tweaks|r loaded. Type |cFFFFFF00/ht|r to open settings.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Export addon table
_G.HousingTweaks = HT
