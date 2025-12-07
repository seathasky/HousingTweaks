-- DecorPreview: Shows a large preview of decor items on hover
local addonName, HT = ...

local DecorPreview = {}
HT:RegisterTweak("DecorPreview", DecorPreview)

-- Create preview frame
local previewFrame

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

-- Function to apply theme to existing preview frame
function DecorPreview:ApplyTheme()
    if previewFrame then
        if previewFrame.titleText then
            previewFrame.titleText:SetTextColor(GetThemeColor())
        end
        if previewFrame.nameText then
            previewFrame.nameText:SetTextColor(GetThemeColor())
        end
    end
end
local function CreatePreviewFrame()
    if previewFrame then 
        return previewFrame 
    end
    
    -- Parent to HouseEditorFrame instead of UIParent so it shows in housing mode
    local parent = HouseEditorFrame or UIParent
    local frame = CreateFrame("Frame", "HousingTweaksDecorPreview", parent)
    frame:SetSize(450, 480)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(9999)
    frame:Hide()
    
    -- Make frame moveable
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, x, y = self:GetPoint()
        HT:SavePosition("DecorPreview", point, nil, relativePoint, x, y)
    end)
    
    -- Use the same atlas background as the storage panel items
    local itemBg = frame:CreateTexture(nil, "BACKGROUND")
    itemBg:SetPoint("TOPLEFT", 2, -32)
    itemBg:SetPoint("BOTTOMRIGHT", -2, 2)
    itemBg:SetAtlas("house-chest-list-item-default")
    frame.itemBg = itemBg
    
    -- Dark title bar
    local titleBg = frame:CreateTexture(nil, "BORDER", nil, 1)
    titleBg:SetPoint("TOPLEFT", 2, -2)
    titleBg:SetPoint("TOPRIGHT", -2, -2)
    titleBg:SetHeight(30)
    titleBg:SetColorTexture(0.15, 0.15, 0.15, 0.95)
    frame.titleBg = titleBg
    
    -- Title text
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", frame, "TOP", 0, -12)
    titleText:SetText("Housing Tweaks Preview Window")
    titleText:SetTextColor(GetThemeColor())
    frame.titleText = titleText
    
    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", frame, "CENTER", 0, -10)
    icon:SetSize(380, 380)
    frame.icon = icon
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 40)
    nameText:SetTextColor(GetThemeColor())
    nameText:SetWidth(430)
    nameText:SetWordWrap(true)
    frame.nameText = nameText
    
    -- Apply saved position or default based on setting
    local pos = HT:GetPosition("DecorPreview")
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, parent, pos.relativePoint, pos.x, pos.y)
    else
        -- Use position from settings
        local positionSetting = HousingTweaksDB and HousingTweaksDB.DecorPreviewPosition or "CENTERRIGHT"
        frame:ClearAllPoints()
        if positionSetting == "CENTER" then
            frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
        elseif positionSetting == "CENTERRIGHT" then
            frame:SetPoint("RIGHT", parent, "RIGHT", -210, 0)
        elseif positionSetting == "CENTERLEFT" then
            frame:SetPoint("LEFT", parent, "LEFT", 210, 0)
        elseif positionSetting == "TOP" then
            frame:SetPoint("TOP", parent, "TOP", 0, -50)
        elseif positionSetting == "TOPRIGHT" then
            frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -50, -50)
        elseif positionSetting == "TOPLEFT" then
            frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, -50)
        elseif positionSetting == "RIGHT" then
            frame:SetPoint("RIGHT", parent, "RIGHT", -50, 0)
        elseif positionSetting == "LEFT" then
            frame:SetPoint("LEFT", parent, "LEFT", 50, 0)
        elseif positionSetting == "BOTTOMRIGHT" then
            frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -50, 50)
        elseif positionSetting == "BOTTOMLEFT" then
            frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 50, 50)
        else
            frame:SetPoint("RIGHT", parent, "RIGHT", -50, 0)
        end
    end
    
    previewFrame = frame
    return frame
end

local function ShowPreview(button)
    local frame = CreatePreviewFrame()
    
    -- Get element data from button
    local elementData = button.elementData or (button.GetElementData and button:GetElementData())
    
    -- Set icon - try multiple sources
    local iconTexture = nil
    if elementData and elementData.icon then
        iconTexture = elementData.icon
    elseif button.Icon then
        iconTexture = button.Icon:GetTexture()
    elseif button.icon then
        iconTexture = button.icon:GetTexture()
    end
    
    if iconTexture then
        frame.icon:SetTexture(iconTexture)
    else
        -- Fallback: use a placeholder
        frame.icon:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
    
    -- Set name - get from GameTooltip first line
    local name = "Decor Item"
    
    -- Try to get name from GameTooltip (most reliable)
    if GameTooltip:IsShown() then
        local tooltipName = GameTooltipTextLeft1:GetText()
        if tooltipName and tooltipName ~= "" then
            name = tooltipName
        end
    end
    
    -- Fallback to elementData
    if name == "Decor Item" and elementData then
        if elementData.name then
            name = elementData.name
        elseif elementData.decorName then
            name = elementData.decorName
        elseif elementData.itemName then
            name = elementData.itemName
        end
    end
    
    frame.nameText:SetText(name)
    
    frame:Show()
end

local function HidePreview()
    if previewFrame then
        previewFrame:Hide()
    end
end

function DecorPreview:Init()
    local function SetupHooks()
        if not HouseEditorFrame then return false end
        
        local storagePanel = HouseEditorFrame.StoragePanel
        if not storagePanel then return false end
        
        local optionsContainer = storagePanel.OptionsContainer
        if not optionsContainer then return false end
        
        local scrollBox = optionsContainer.ScrollBox
        if not scrollBox then return false end
        
        -- Hook into button creation/updates
        local function HookButton(button)
            if not button or button.decorPreviewHooked then return end
            
            button:HookScript("OnEnter", function(self)
                ShowPreview(self)
            end)
            button:HookScript("OnLeave", function(self)
                HidePreview()
            end)
            button.decorPreviewHooked = true
        end
        
        hooksecurefunc(scrollBox, "Update", function(self)
            self:ForEachFrame(function(button)
                HookButton(button)
            end)
        end)
        
        -- Also hook existing frames immediately
        scrollBox:ForEachFrame(function(button)
            HookButton(button)
        end)
        
        return true
    end
    
    -- Try immediately
    if SetupHooks() then
        return
    end
    
    -- Wait for addon to load
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, event, loadedAddon)
        if loadedAddon == "Blizzard_HouseEditor" then
            C_Timer.After(0.5, function()
                if SetupHooks() then
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end)
end
