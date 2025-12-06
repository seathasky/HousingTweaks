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
        description = "Applies a dark gray theme with orange accents to the storage panel.",
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

-- Create the settings GUI
local function CreateSettingsFrame()
    local frame = CreateFrame("Frame", "HousingTweaksSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 450)
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
    frame.TitleText:SetTextColor(1, 0.5, 0)
    frame.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Version text in top right corner
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -5)
    versionText:SetText("ver. 1.0.0")
    versionText:SetTextColor(0.6, 0.6, 0.6)
    versionText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    
    -- Subtitle
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 10, -20)
    subtitle:SetText("Toggle tweaks below. Some require a reload.")
    subtitle:SetTextColor(1, 1, 1)
    
    -- Scroll frame for tweaks list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.InsetBg, "TOPLEFT", 5, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame.InsetBg, "BOTTOMRIGHT", -26, 35)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- "More Tweaks soon..." text at bottom
    local moreText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moreText:SetPoint("BOTTOM", frame.InsetBg, "BOTTOM", 0, 10)
    moreText:SetText("More Tweaks soon...")
    moreText:SetTextColor(0.7, 0.7, 0.7)
    moreText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    
    frame.scrollChild = scrollChild
    frame.containers = {}
    
    return frame
end

local function PopulateSettingsFrame(frame)
    local scrollChild = frame.scrollChild
    local yOffset = -5
    
    -- Clear existing containers
    for _, container in pairs(frame.containers) do
        container:Hide()
        container:SetParent(nil)
    end
    wipe(frame.containers)
    
    -- Sort tweaks alphabetically
    local sortedTweaks = {}
    for name in pairs(HT.TweakInfo) do
        table.insert(sortedTweaks, name)
    end
    table.sort(sortedTweaks)
    
    for _, tweakName in ipairs(sortedTweaks) do
        local info = HT.TweakInfo[tweakName]
        
        local container = CreateFrame("Frame", nil, scrollChild)
        container:SetSize(scrollChild:GetWidth() - 10, 60)
        container:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        
        local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        checkbox:SetChecked(HT:IsTweakEnabled(tweakName))
        
        local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(info.name)
        label:SetTextColor(1, 0.5, 0)
        
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
        yOffset = yOffset - 65
        
        -- Add dropdown for DecorPreview position
        if tweakName == "DecorPreview" then
            -- Separator line above
            local sepAbove = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sepAbove:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
            sepAbove:SetText("_______________________________")
            sepAbove:SetTextColor(0.5, 0.5, 0.5)
            yOffset = yOffset - 15
            
            -- Position label
            local posLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            posLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
            posLabel:SetText("Preview Position:")
            posLabel:SetTextColor(1, 1, 1)
            yOffset = yOffset - 20
            
            -- Dropdown
            local dropdown = CreateFrame("Frame", "HousingTweaksPreviewPosDropdown", scrollChild, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
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
            
            yOffset = yOffset - 35
            
            -- Separator line below
            local sepBelow = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sepBelow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
            sepBelow:SetText("_______________________________")
            sepBelow:SetTextColor(0.5, 0.5, 0.5)
            yOffset = yOffset - 20
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
