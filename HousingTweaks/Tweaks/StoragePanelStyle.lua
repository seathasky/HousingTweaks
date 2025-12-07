-- StoragePanelStyle: Customizes the storage panel appearance to match Housing Tweaks style
local addonName, HT = ...

local StoragePanelStyle = {}
HT:RegisterTweak("StoragePanelStyle", StoragePanelStyle)

-- Color theme definitions
local COLOR_THEMES = {
    orange = {name = "Orange", r = 1, g = 0.5, b = 0},
    blue = {name = "Blue", r = 0.2, g = 0.6, b = 1},
    purple = {name = "Purple", r = 0.7, g = 0.3, b = 1},
    green = {name = "Green", r = 0.3, g = 0.9, b = 0.4},
    red = {name = "Red", r = 1, g = 0.2, b = 0.2},
    cyan = {name = "Cyan", r = 0.2, g = 0.9, b = 0.9},
    white = {name = "White", r = 1, g = 1, b = 1},
}

local function GetCurrentTheme()
    local themeName = HousingTweaksDB and HousingTweaksDB.storagePanelColorTheme or "orange"
    return COLOR_THEMES[themeName] or COLOR_THEMES.orange
end

local function ApplyThemeColor(storagePanel, storageButton)
    local theme = GetCurrentTheme()
    
    -- Apply to storage button icon
    if storageButton then
        if storageButton.Icon then
            storageButton.Icon:SetVertexColor(theme.r, theme.g, theme.b)
        end
        if storageButton.OverlayIcon then
            storageButton.OverlayIcon:SetVertexColor(theme.r, theme.g, theme.b)
        end
    end
    
    -- Apply to accent borders
    if storagePanel.htTopBorder then
        storagePanel.htTopBorder:SetColorTexture(theme.r, theme.g, theme.b, 1)
    end
    if storagePanel.htLeftBorder then
        storagePanel.htLeftBorder:SetColorTexture(theme.r, theme.g, theme.b, 1)
    end
    if storagePanel.htBottomBorder then
        storagePanel.htBottomBorder:SetColorTexture(theme.r, theme.g, theme.b, 1)
    end
end

-- Make ApplyThemeColor accessible globally for on-the-fly updates
function StoragePanelStyle:ApplyTheme()
    if HouseEditorFrame and HouseEditorFrame.StoragePanel then
        ApplyThemeColor(HouseEditorFrame.StoragePanel, HouseEditorFrame.StorageButton)
    end
end

function StoragePanelStyle:Init()
    local function ApplyCategoriesStyle(storagePanel)
        -- Style the categories background - dark/black
        if storagePanel.Categories and storagePanel.Categories.Background then
            storagePanel.Categories.Background:SetColorTexture(0.08, 0.08, 0.08, 1)
        end
        
        -- Style the categories top border - dark/black
        if storagePanel.Categories and storagePanel.Categories.TopBorder then
            storagePanel.Categories.TopBorder:SetColorTexture(0.08, 0.08, 0.08, 1)
        end
    end
    
    local function SetupStyle()
        if not HouseEditorFrame then return false end
        
        local storagePanel = HouseEditorFrame.StoragePanel
        local storageButton = HouseEditorFrame.StorageButton
        if not storagePanel then return false end
        
        -- Apply theme color to storage button
        ApplyThemeColor(storagePanel, storageButton)
        
        -- Style the main background - dark gray
        if storagePanel.Background then
            storagePanel.Background:SetColorTexture(0.12, 0.12, 0.12, 0.95)
        end
        
        -- Style the header background - dark gray
        if storagePanel.HeaderBackground then
            storagePanel.HeaderBackground:SetColorTexture(0.15, 0.15, 0.15, 1)
        end
        
        -- Apply categories style now
        ApplyCategoriesStyle(storagePanel)
        
        -- Hook OnShow to reapply categories style when panel reopens
        if not storagePanel.htCategoriesHooked then
            storagePanel:HookScript("OnShow", function(self)
                C_Timer.After(0.01, function()
                    ApplyCategoriesStyle(self)
                end)
            end)
            storagePanel.htCategoriesHooked = true
        end
        
        -- Add accent border at top
        if not storagePanel.htTopBorder then
            local topBorder = storagePanel:CreateTexture(nil, "OVERLAY", nil, 7)
            topBorder:SetPoint("TOPLEFT", 0, 0)
            topBorder:SetPoint("TOPRIGHT", 0, 0)
            topBorder:SetHeight(3)
            storagePanel.htTopBorder = topBorder
        end
        
        -- Add accent border at left (using higher draw layer to ensure visibility)
        if not storagePanel.htLeftBorder then
            local leftBorder = storagePanel:CreateTexture(nil, "BORDER", nil, 7)
            leftBorder:SetPoint("TOPLEFT", 0, -3)
            leftBorder:SetPoint("BOTTOMLEFT", 0, 3)
            leftBorder:SetWidth(3)
            leftBorder:SetDrawLayer("BORDER", 7)
            storagePanel.htLeftBorder = leftBorder
        end
        
        -- Add accent border at bottom
        if not storagePanel.htBottomBorder then
            local bottomBorder = storagePanel:CreateTexture(nil, "OVERLAY", nil, 7)
            bottomBorder:SetPoint("BOTTOMLEFT", 0, 0)
            bottomBorder:SetPoint("BOTTOMRIGHT", 0, 0)
            bottomBorder:SetHeight(3)
            storagePanel.htBottomBorder = bottomBorder
        end
        
        -- Apply theme colors to borders
        ApplyThemeColor(storagePanel, storageButton)
        
        -- Style the input blocker background
        if storagePanel.InputBlocker then
            local blockerTexture = storagePanel.InputBlocker:GetRegions()
            if blockerTexture and blockerTexture.SetColorTexture then
                blockerTexture:SetColorTexture(0.12, 0.12, 0.12, 0.9)
            end
        end
        
        -- Hide the corner border decoration
        if storagePanel.CornerBorder then
            storagePanel.CornerBorder:Hide()
        end
        
        return true
    end
    
    -- Try immediately
    if SetupStyle() then
        return
    end
    
    -- Wait for addon to load
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, event, loadedAddon)
        if loadedAddon == "Blizzard_HouseEditor" then
            C_Timer.After(0.5, function()
                if SetupStyle() then
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end)
end
