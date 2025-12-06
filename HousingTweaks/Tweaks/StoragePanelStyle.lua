-- StoragePanelStyle: Customizes the storage panel appearance to match Housing Tweaks style
local addonName, HT = ...

local StoragePanelStyle = {}
HT:RegisterTweak("StoragePanelStyle", StoragePanelStyle)

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
        
        -- Tint the storage button icon orange
        if storageButton then
            if storageButton.Icon then
                storageButton.Icon:SetVertexColor(1, 0.5, 0)
            end
            if storageButton.OverlayIcon then
                storageButton.OverlayIcon:SetVertexColor(1, 0.5, 0)
            end
        end
        
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
        
        -- Add orange accent border at top
        if not storagePanel.htTopBorder then
            local topBorder = storagePanel:CreateTexture(nil, "OVERLAY", nil, 7)
            topBorder:SetPoint("TOPLEFT", 0, 0)
            topBorder:SetPoint("TOPRIGHT", 0, 0)
            topBorder:SetHeight(3)
            topBorder:SetColorTexture(1, 0.5, 0, 1)
            storagePanel.htTopBorder = topBorder
        end
        
        -- Add orange accent border at left
        if not storagePanel.htLeftBorder then
            local leftBorder = storagePanel:CreateTexture(nil, "OVERLAY", nil, 7)
            leftBorder:SetPoint("TOPLEFT", 0, 0)
            leftBorder:SetPoint("BOTTOMLEFT", 0, 0)
            leftBorder:SetWidth(3)
            leftBorder:SetColorTexture(1, 0.5, 0, 1)
            storagePanel.htLeftBorder = leftBorder
        end
        
        -- Add orange accent border at bottom
        if not storagePanel.htBottomBorder then
            local bottomBorder = storagePanel:CreateTexture(nil, "OVERLAY", nil, 7)
            bottomBorder:SetPoint("BOTTOMLEFT", 0, 0)
            bottomBorder:SetPoint("BOTTOMRIGHT", 0, 0)
            bottomBorder:SetHeight(3)
            bottomBorder:SetColorTexture(1, 0.5, 0, 1)
            storagePanel.htBottomBorder = bottomBorder
        end
        
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
