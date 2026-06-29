-- DecorPreview: Shows a large preview of decor items on hover
local addonName, HT = ...

local DecorPreview = {}
HT:RegisterTweak("DecorPreview", DecorPreview)

-- Create preview frame
local previewFrame
local PREVIEW_MODEL_SCENE_ID = 691
local PREVIEW_ACTOR_TAG = "decor"

-- Get current theme color
-- Use shared theme helper

-- Function to apply theme to existing preview frame
function DecorPreview:ApplyTheme()
    if previewFrame then
        if previewFrame.titleText then
            previewFrame.titleText:SetTextColor(HT.GetThemeColor())
        end
        if previewFrame.nameText then
            previewFrame.nameText:SetTextColor(HT.GetThemeColor())
        end
    end
end
local function CreatePreviewFrame()
    if previewFrame then 
        return previewFrame 
    end
    
    -- Parent to HouseEditorFrame instead of UIParent so it shows in housing mode
    local parent = HouseEditorFrame or UIParent
    local frame = CreateFrame("Frame", "MattHousingTweaksDecorPreview", parent)
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
    HT.ApplyFontString(titleText, "GameFontNormal")
    titleText:SetPoint("TOP", frame, "TOP", 0, -12)
    titleText:SetText("MattHousingTweaks Preview Window")
    titleText:SetTextColor(HT.GetThemeColor())
    frame.titleText = titleText
    
    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", frame, "CENTER", 0, -10)
    icon:SetSize(380, 380)
    frame.icon = icon

    -- Model preview for entries that use asset file IDs instead of icon textures.
    local modelScene = CreateFrame("ModelScene", nil, frame, "PanningModelSceneMixinTemplate")
    modelScene:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    modelScene:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    local forceSceneChange = true
    if modelScene.TransitionToModelSceneID then
        modelScene:TransitionToModelSceneID(PREVIEW_MODEL_SCENE_ID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceSceneChange)
    elseif modelScene.SetFromModelSceneID then
        modelScene:SetFromModelSceneID(PREVIEW_MODEL_SCENE_ID, forceSceneChange)
    end
    modelScene:Hide()
    frame.modelScene = modelScene
    
    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    HT.ApplyFontString(nameText, "GameFontNormalLarge")
    nameText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 40)
    nameText:SetTextColor(HT.GetThemeColor())
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
        local positionSetting = MattHousingTweaksDB and MattHousingTweaksDB.DecorPreviewPosition or "CENTERRIGHT"
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
    local entryInfo = nil
    if elementData and elementData.entryID and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfo then
        entryInfo = C_HousingCatalog.GetCatalogEntryInfo(elementData.entryID)
    end
    
    -- Featured bundle cards do not have entryID. Use the first decor entry for preview content.
    if not entryInfo and elementData and elementData.decorEntries and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID then
        local firstDecor = elementData.decorEntries[1]
        if firstDecor and firstDecor.decorID then
            local tryGetOwnedInfo = false
            entryInfo = C_HousingCatalog.GetCatalogEntryInfoByRecordID(Enum.HousingCatalogEntryType.Decor, firstDecor.decorID, tryGetOwnedInfo)
        end
    end
    
    -- Default to icon mode, then switch to model mode when needed.
    frame.icon:Show()
    frame.modelScene:Hide()

    -- Reset previous icon state before applying a new icon.
    frame.icon:SetDesaturated(false)
    frame.icon:SetVertexColor(1, 1, 1, 1)
    frame.icon:SetTexCoord(0, 1, 0, 1)

    -- Set preview from canonical entry data.
    if entryInfo and entryInfo.asset and frame.modelScene and frame.modelScene.GetActorByTag then
        local modelSceneID = entryInfo.uiModelSceneID or PREVIEW_MODEL_SCENE_ID
        if frame.modelScene.TransitionToModelSceneID then
            frame.modelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
        elseif frame.modelScene.SetFromModelSceneID then
            frame.modelScene:SetFromModelSceneID(modelSceneID, true)
        end

        local actor = frame.modelScene:GetActorByTag(PREVIEW_ACTOR_TAG)
        if actor then
            if actor.SetPreferModelCollisionBounds then
                actor:SetPreferModelCollisionBounds(true)
            end
            actor:SetModelByFileID(entryInfo.asset)
            actor:SetDesaturation(0)
            actor:SetAlpha(1)
            frame.icon:Hide()
            frame.modelScene:Show()
        else
            frame.icon:SetTexture(134400) -- question mark fallback
        end
    elseif entryInfo and entryInfo.iconTexture then
        frame.icon:SetTexture(entryInfo.iconTexture)
    elseif entryInfo and entryInfo.iconAtlas then
        frame.icon:SetAtlas(entryInfo.iconAtlas)
    elseif elementData and elementData.icon then
        frame.icon:SetTexture(elementData.icon)
    elseif button.Icon then
        frame.icon:SetTexture(button.Icon:GetTexture())
    elseif button.icon then
        frame.icon:SetTexture(button.icon:GetTexture())
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
    
    -- Wait for the Blizzard House Editor to load
    HT.WaitForHouseEditor(0, function()
        SetupHooks()
    end)
end
