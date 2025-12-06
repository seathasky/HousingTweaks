-- MoveableStoragePanel: Allows moving the housing storage panel
local addonName, HT = ...

local MoveableStoragePanel = {}
HT:RegisterTweak("MoveableStoragePanel", MoveableStoragePanel)

local TWEAK_NAME = "MoveableStoragePanel"

-- Apply saved position to a frame
local function ApplyPosition(frame)
    local pos = HT:GetPosition(TWEAK_NAME)
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

-- Save frame position
local function SavePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint()
    HT:SavePosition(TWEAK_NAME, point, nil, relativePoint, x, y)
end

-- Make a frame draggable
local function MakeFrameDraggable(frame, dragFrame)
    dragFrame = dragFrame or frame
    
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Only set up drag on frames, not textures
    if dragFrame.RegisterForDrag then
        dragFrame:EnableMouse(true)
        dragFrame:RegisterForDrag("LeftButton")
        
        dragFrame:HookScript("OnDragStart", function()
            frame:StartMoving()
        end)
        
        dragFrame:HookScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            SavePosition(frame)
        end)
    end
end

function MoveableStoragePanel:Init()
    local function SetupHooks()
        if not HouseEditorFrame then return false end
        
        local storageButton = HouseEditorFrame.StorageButton
        local storagePanel = HouseEditorFrame.StoragePanel
        
        if not storageButton or not storagePanel then return false end
        
        -- Custom icon (commented out for later)
        -- if storageButton.Icon then
        --     storageButton.Icon:SetTexture("Interface\\AddOns\\HousingTweaks\\icons\\decor_ht_128")
        -- end
        -- if storageButton.OverlayIcon then
        --     storageButton.OverlayIcon:SetTexture("Interface\\AddOns\\HousingTweaks\\icons\\decor_ht_128")
        -- end
        
        -- Make both the button (collapsed) and panel (expanded) draggable
        -- They need to share position since only one shows at a time
        
        -- Make storage button (collapsed state) draggable
        MakeFrameDraggable(storageButton, storageButton)
        
        -- Right-click to open settings
        storageButton:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                HT:ShowSettings()
            end
        end)
        
        -- Make storage panel (expanded state) draggable by its header
        MakeFrameDraggable(storagePanel, storagePanel)
        
        -- Make InputBlocker draggable (it's a Button so it can intercept drags)
        if storagePanel.InputBlocker then
            MakeFrameDraggable(storagePanel, storagePanel.InputBlocker)
        end
        
        -- When button is shown, apply saved position
        hooksecurefunc(storageButton, "Show", function()
            C_Timer.After(0, function()
                ApplyPosition(storageButton)
            end)
        end)
        
        -- When panel is shown, apply saved position
        hooksecurefunc(storagePanel, "Show", function()
            C_Timer.After(0, function()
                ApplyPosition(storagePanel)
            end)
        end)
        
        -- Sync positions: when one moves, update the other's saved position
        storageButton:HookScript("OnDragStop", function()
            -- Apply same position to panel
            local pos = HT:GetPosition(TWEAK_NAME)
            if pos then
                storagePanel:ClearAllPoints()
                storagePanel:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            end
        end)
        
        storagePanel:HookScript("OnDragStop", function()
            -- Apply same position to button
            local pos = HT:GetPosition(TWEAK_NAME)
            if pos then
                storageButton:ClearAllPoints()
                storageButton:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            end
        end)
        
        -- Apply position now if already visible
        if storageButton:IsShown() then
            ApplyPosition(storageButton)
        end
        if storagePanel:IsShown() then
            ApplyPosition(storagePanel)
        end
        
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
            C_Timer.After(0.1, function()
                if SetupHooks() then
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end)
end
