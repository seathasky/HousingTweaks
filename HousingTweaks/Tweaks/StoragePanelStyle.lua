-- StoragePanelStyle: Customizes the storage panel appearance to match Housing Tweaks style
local addonName, HT = ...

local StoragePanelStyle = {}
HT:RegisterTweak("StoragePanelStyle", StoragePanelStyle)

-- Color theme definitions
-- Use centralized constants exposed by the main addon table (HT)

local function GetCurrentTheme()
    return HT.GetTheme()
end

local TOOLBAR_STYLE = {
    fieldBg = { 0.06, 0.06, 0.08, 1 },
    fieldBgHover = { 0.1, 0.1, 0.12, 1 },
    fieldBorder = { 0.25, 0.25, 0.3, 1 },
    labelText = { 0.75, 0.75, 0.75 },
}

-- Function to apply position to preview frame
local function ApplyPreviewPosition(positionValue)
    local previewFrame = _G["HousingTweaksDecorPreview"]
    if not previewFrame then return end
    
    -- Clear any saved custom position so the preset takes effect
    if HousingTweaksDB and HousingTweaksDB.positions then
        HousingTweaksDB.positions["DecorPreview"] = nil
    end
    
    local parent = HouseEditorFrame or UIParent
    previewFrame:ClearAllPoints()
    
    if positionValue == "CENTER" then
        previewFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    elseif positionValue == "CENTERRIGHT" then
        previewFrame:SetPoint("RIGHT", parent, "RIGHT", -210, 0)
    elseif positionValue == "CENTERLEFT" then
        previewFrame:SetPoint("LEFT", parent, "LEFT", 210, 0)
    elseif positionValue == "TOP" then
        previewFrame:SetPoint("TOP", parent, "TOP", 0, -50)
    elseif positionValue == "TOPRIGHT" then
        previewFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -50, -50)
    elseif positionValue == "TOPLEFT" then
        previewFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, -50)
    elseif positionValue == "RIGHT" then
        previewFrame:SetPoint("RIGHT", parent, "RIGHT", -50, 0)
    elseif positionValue == "LEFT" then
        previewFrame:SetPoint("LEFT", parent, "LEFT", 50, 0)
    elseif positionValue == "BOTTOMRIGHT" then
        previewFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -50, 50)
    elseif positionValue == "BOTTOMLEFT" then
        previewFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 50, 50)
    else
        previewFrame:SetPoint("RIGHT", parent, "RIGHT", -50, 0)
    end
end

-- Create a generic dropdown widget
local function CreateDropdownWidget(parent, label, width, options, getCurrentValue, onSelect)
    local theme = GetCurrentTheme()
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 22)
    container:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    -- Background
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(TOOLBAR_STYLE.fieldBg[1], TOOLBAR_STYLE.fieldBg[2], TOOLBAR_STYLE.fieldBg[3], TOOLBAR_STYLE.fieldBg[4])
    container.bg = bg
    
    -- Border
    local border = CreateFrame("Frame", nil, container, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
    container.border = border
    
    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(labelText, "GameFontNormalSmall")
    labelText:SetPoint("LEFT", container, "LEFT", 6, 0)
    labelText:SetText(label)
    labelText:SetTextColor(TOOLBAR_STYLE.labelText[1], TOOLBAR_STYLE.labelText[2], TOOLBAR_STYLE.labelText[3])
    container.label = labelText
    
    -- Current selection text
    local selectedText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(selectedText, "GameFontNormalSmall")
    selectedText:SetPoint("LEFT", labelText, "RIGHT", 4, 0)
    selectedText:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetTextColor(theme.r, theme.g, theme.b)
    container.selectedText = selectedText
    
    -- Set initial text
    local currentVal = getCurrentValue()
    for _, opt in ipairs(options) do
        if opt.value == currentVal then
            selectedText:SetText(opt.text)
            break
        end
    end
    
    -- Dropdown arrow
    local arrow = container:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", container, "RIGHT", -4, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    container.arrow = arrow
    
    -- Create dropdown menu frame
    local menuFrame = CreateFrame("Frame", nil, container, "UIDropDownMenuTemplate")
    menuFrame:SetPoint("TOP", container, "BOTTOM", 0, 0)
    menuFrame:Hide()
    
    -- Click handler to show dropdown
    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function(self)
        local function OnClick(self, arg1)
            onSelect(arg1)
            
            -- Update display text
            for _, opt in ipairs(options) do
                if opt.value == arg1 then
                    selectedText:SetText(opt.text)
                    break
                end
            end
            
            CloseDropDownMenus()
        end
        
        local function Initialize(self, level)
            local currentVal = getCurrentValue()
            for _, opt in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.text
                info.arg1 = opt.value
                info.func = OnClick
                info.checked = (currentVal == opt.value)
                if opt.r then
                    info.colorCode = string.format("|cff%02x%02x%02x", opt.r * 255, opt.g * 255, opt.b * 255)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
        
        UIDropDownMenu_Initialize(menuFrame, Initialize, "MENU")
        ToggleDropDownMenu(1, nil, menuFrame, container, 0, 0)
    end)
    
    -- Hover effect
    container:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(TOOLBAR_STYLE.fieldBgHover[1], TOOLBAR_STYLE.fieldBgHover[2], TOOLBAR_STYLE.fieldBgHover[3], TOOLBAR_STYLE.fieldBgHover[4])
        self.border:SetBackdropBorderColor(theme.r, theme.g, theme.b, 0.6)
    end)
    container:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(TOOLBAR_STYLE.fieldBg[1], TOOLBAR_STYLE.fieldBg[2], TOOLBAR_STYLE.fieldBg[3], TOOLBAR_STYLE.fieldBg[4])
        self.border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
    end)
    
    return container
end

-- Create the HT settings button
local function CreateSettingsButton(parent)
    local theme = GetCurrentTheme()
    
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(28, 22)
    button:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(TOOLBAR_STYLE.fieldBg[1], TOOLBAR_STYLE.fieldBg[2], TOOLBAR_STYLE.fieldBg[3], TOOLBAR_STYLE.fieldBg[4])
    button.bg = bg
    
    -- Border
    local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
    button.border = border
    
    -- Text
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(text, "GameFontNormalSmall")
    text:SetPoint("CENTER", 0, 0)
    text:SetText("HT")
    text:SetTextColor(theme.r, theme.g, theme.b)
    button.text = text
    
    -- Click handler
    button:SetScript("OnClick", function()
        -- Exit housing editor mode using the proper API
        if C_HouseEditor and C_HouseEditor.LeaveHouseEditor then
            C_HouseEditor.LeaveHouseEditor()
        end
        
        -- Open settings after a short delay to let the UI transition
        C_Timer.After(0.1, function()
            SlashCmdList["HOUSINGTWEAKS"]("")
        end)
    end)
    
    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(TOOLBAR_STYLE.fieldBgHover[1], TOOLBAR_STYLE.fieldBgHover[2], TOOLBAR_STYLE.fieldBgHover[3], TOOLBAR_STYLE.fieldBgHover[4])
        self.border:SetBackdropBorderColor(theme.r, theme.g, theme.b, 0.6)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Housing Tweaks Settings")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(TOOLBAR_STYLE.fieldBg[1], TOOLBAR_STYLE.fieldBg[2], TOOLBAR_STYLE.fieldBg[3], TOOLBAR_STYLE.fieldBg[4])
        self.border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
        GameTooltip:Hide()
    end)
    
    return button
end

-- Get toolbar position from settings
local function GetToolbarPosition()
    return HousingTweaksDB and HousingTweaksDB.toolbarPosition or "BOTTOMRIGHT"
end

-- Apply toolbar position to all toolbar elements
local function ApplyToolbarPosition(storagePanel)
    if not storagePanel then return end
    
    local position = GetToolbarPosition()
    
    -- Update HT button position
    if storagePanel.htSettingsButton then
        storagePanel.htSettingsButton:ClearAllPoints()
        if position == "TOPRIGHT" then
            storagePanel.htSettingsButton:SetPoint("BOTTOMRIGHT", storagePanel, "TOPRIGHT", 0, 4)
        else
            storagePanel.htSettingsButton:SetPoint("TOPRIGHT", storagePanel, "BOTTOMRIGHT", 0, -4)
        end
    end
end

-- Create all toolbar elements above the storage panel
local function CreateStorageToolbar(storagePanel)
    if storagePanel.htToolbar then return end
    
    local theme = GetCurrentTheme()
    local position = GetToolbarPosition()
    
    -- Color options for dropdown
    local colorOptions = {
        { value = "orange", text = "Orange", r = 1, g = 0.5, b = 0 },
        { value = "blue", text = "Blue", r = 0.2, g = 0.6, b = 1 },
        { value = "purple", text = "Purple", r = 0.7, g = 0.3, b = 1 },
        { value = "green", text = "Green", r = 0.3, g = 0.9, b = 0.4 },
        { value = "red", text = "Red", r = 1, g = 0.2, b = 0.2 },
        { value = "cyan", text = "Cyan", r = 0.2, g = 0.9, b = 0.9 },
        { value = "white", text = "White", r = 1, g = 1, b = 1 },
    }
    
    -- Always create HT Settings button
    local htButton = CreateSettingsButton(storagePanel)
    if position == "TOPRIGHT" then
        htButton:SetPoint("BOTTOMRIGHT", storagePanel, "TOPRIGHT", 0, 4)
    else
        htButton:SetPoint("TOPRIGHT", storagePanel, "BOTTOMRIGHT", 0, -4)
    end
    storagePanel.htSettingsButton = htButton
    
    -- Track the leftmost element for anchoring
    local leftmostElement = htButton
    
    -- Only create Color dropdown if StoragePanelStyle is enabled
    if HT:IsTweakEnabled("StoragePanelStyle") then
        local colorDropdown = CreateDropdownWidget(
            storagePanel,
            "Color:",
            110,
            colorOptions,
            function() return HousingTweaksDB and HousingTweaksDB.storagePanelColorTheme or "orange" end,
            function(value)
                HousingTweaksDB.storagePanelColorTheme = value
                
                -- Apply theme immediately
                if HT.Tweaks.StoragePanelStyle and HT.Tweaks.StoragePanelStyle.ApplyTheme then
                    HT.Tweaks.StoragePanelStyle:ApplyTheme()
                end
                if HT.Tweaks.DecorPreview and HT.Tweaks.DecorPreview.ApplyTheme then
                    HT.Tweaks.DecorPreview:ApplyTheme()
                end
                if HT.Tweaks.Favorites and HT.Tweaks.Favorites.ApplyTheme then
                    HT.Tweaks.Favorites:ApplyTheme()
                end
            end
        )
        colorDropdown:SetPoint("RIGHT", leftmostElement, "LEFT", -8, 0)
        storagePanel.htColorDropdown = colorDropdown
        leftmostElement = colorDropdown
    end
    
    -- Only create Preview dropdown if DecorPreview is enabled
    if HT:IsTweakEnabled("DecorPreview") then
        local previewDropdown = CreateDropdownWidget(
            storagePanel,
            "Preview:",
            190,
            HT.PREVIEW_POSITIONS,
            function() return HousingTweaksDB and HousingTweaksDB.DecorPreviewPosition or "CENTERRIGHT" end,
            function(value)
                HousingTweaksDB.DecorPreviewPosition = value
                ApplyPreviewPosition(value)
            end
        )
        previewDropdown:SetPoint("RIGHT", leftmostElement, "LEFT", -8, 0)
        storagePanel.htPreviewDropdown = previewDropdown
    end
    
    storagePanel.htToolbar = true
end

-- Function to update all toolbar theme colors
local function UpdateToolbarTheme(storagePanel)
    if not storagePanel.htToolbar then return end
    
    local theme = GetCurrentTheme()
    
    -- Update preview dropdown
    if storagePanel.htPreviewDropdown then
        local container = storagePanel.htPreviewDropdown
        if container.border and container.border.SetBackdropBorderColor then
            container.border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
        end
        if container.selectedText then
            container.selectedText:SetTextColor(theme.r, theme.g, theme.b)
        end
    end
    
    -- Update color dropdown
    if storagePanel.htColorDropdown then
        local container = storagePanel.htColorDropdown
        if container.border and container.border.SetBackdropBorderColor then
            container.border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
        end
        if container.selectedText then
            container.selectedText:SetTextColor(theme.r, theme.g, theme.b)
        end
        -- Update displayed color name
        local currentTheme = HousingTweaksDB and HousingTweaksDB.storagePanelColorTheme or "orange"
        -- Get display name from centralized theme list
        local currentName = (HT.COLOR_THEMES[currentTheme] and HT.COLOR_THEMES[currentTheme].name) or "Orange"
        container.selectedText:SetText(currentName)
    end
    
    -- Update HT button
    if storagePanel.htSettingsButton then
        local button = storagePanel.htSettingsButton
        if button.border and button.border.SetBackdropBorderColor then
            button.border:SetBackdropBorderColor(TOOLBAR_STYLE.fieldBorder[1], TOOLBAR_STYLE.fieldBorder[2], TOOLBAR_STYLE.fieldBorder[3], TOOLBAR_STYLE.fieldBorder[4])
        end
        if button.text then
            button.text:SetTextColor(theme.r, theme.g, theme.b)
        end
    end
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
    
    -- Apply to collapse button icon
    if storagePanel and storagePanel.CollapseButton then
        local collapseBtn = storagePanel.CollapseButton
        if collapseBtn.Icon then
            collapseBtn.Icon:SetVertexColor(theme.r, theme.g, theme.b)
        end
        if collapseBtn.OverlayIcon then
            collapseBtn.OverlayIcon:SetVertexColor(theme.r, theme.g, theme.b)
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
        UpdateToolbarTheme(HouseEditorFrame.StoragePanel)
    end
end

-- Apply toolbar position from settings
function StoragePanelStyle:ApplyToolbarPosition()
    if HouseEditorFrame and HouseEditorFrame.StoragePanel then
        ApplyToolbarPosition(HouseEditorFrame.StoragePanel)
    end
end

-- Always create the toolbar (HT button always, dropdowns based on enabled tweaks)
local function SetupToolbar()
    if not HouseEditorFrame then return false end
    
    local storagePanel = HouseEditorFrame.StoragePanel
    if not storagePanel then return false end
    
    -- Create the toolbar with HT button (always) and conditional dropdowns
    CreateStorageToolbar(storagePanel)
    
    return true
end

-- Initialize toolbar separately (always runs)
local function InitToolbar()
    -- Try immediately
    if SetupToolbar() then
        return
    end
    
    -- Wait for the Blizzard House Editor to load (no delay)
    HT.WaitForHouseEditor(0, function()
        SetupToolbar()
    end)
end

-- Run toolbar init immediately when file loads
InitToolbar()

function StoragePanelStyle:Init()
    local function ApplyCategoriesStyle(storagePanel)
        -- Style the categories background - dark/black
        if storagePanel.Categories and storagePanel.Categories.Background then
            local bg = storagePanel.Categories.Background
            bg:SetTexture(nil)
            bg:SetAtlas(nil)
            bg:SetColorTexture(0.08, 0.08, 0.08, 1)
            
            -- Hook SetTexture and SetAtlas to prevent wood texture from ever being set
            if not bg.htHooked then
                bg.SetTexture = function(self, texture, ...)
                    -- Ignore any texture setting, keep our color
                    self:SetColorTexture(0.08, 0.08, 0.08, 1)
                end
                bg.SetAtlas = function(self, atlas, ...)
                    -- Ignore any atlas setting, keep our color
                    self:SetColorTexture(0.08, 0.08, 0.08, 1)
                end
                bg.htHooked = true
            end
        end
        
        -- Style the categories top border - dark/black
        if storagePanel.Categories and storagePanel.Categories.TopBorder then
            local topBorder = storagePanel.Categories.TopBorder
            topBorder:SetTexture(nil)
            topBorder:SetAtlas(nil)
            topBorder:SetColorTexture(0.08, 0.08, 0.08, 1)
            
            -- Hook SetTexture and SetAtlas to prevent wood texture from ever being set
            if not topBorder.htHooked then
                topBorder.SetTexture = function(self, texture, ...)
                    -- Ignore any texture setting, keep our color
                    self:SetColorTexture(0.08, 0.08, 0.08, 1)
                end
                topBorder.SetAtlas = function(self, atlas, ...)
                    -- Ignore any atlas setting, keep our color
                    self:SetColorTexture(0.08, 0.08, 0.08, 1)
                end
                topBorder.htHooked = true
            end
        end
    end
    
    local function SetupStyle()
        if not HouseEditorFrame then return false end
        
        local storagePanel = HouseEditorFrame.StoragePanel
        local storageButton = HouseEditorFrame.StorageButton
        if not storagePanel then return false end
        
        -- Ensure toolbar is created (in case style init runs first)
        CreateStorageToolbar(storagePanel)
        
        -- Apply theme color to storage button
        ApplyThemeColor(storagePanel, storageButton)
        
        -- Style the main background - dark gray and hook to prevent Blizzard from resetting
        if storagePanel.Background and not storagePanel.Background.htHooked then
            storagePanel.Background:SetColorTexture(0.12, 0.12, 0.12, 0.95)
            storagePanel.Background.SetTexture = function(self)
                self:SetColorTexture(0.12, 0.12, 0.12, 0.95)
            end
            storagePanel.Background.SetAtlas = function(self)
                self:SetColorTexture(0.12, 0.12, 0.12, 0.95)
            end
            storagePanel.Background.htHooked = true
        end
        
        -- Style the header background - dark gray and hook to prevent Blizzard from resetting
        if storagePanel.HeaderBackground and not storagePanel.HeaderBackground.htHooked then
            storagePanel.HeaderBackground:SetColorTexture(0.15, 0.15, 0.15, 1)
            storagePanel.HeaderBackground.SetTexture = function(self)
                self:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
            storagePanel.HeaderBackground.SetAtlas = function(self)
                self:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
            storagePanel.HeaderBackground.htHooked = true
        end
        
        -- Apply categories style now
        ApplyCategoriesStyle(storagePanel)
        
        -- Hook Show method to apply styles BEFORE panel becomes visible (prevents flash)
        if not storagePanel.htShowHooked then
            local originalShow = storagePanel.Show
            storagePanel.Show = function(self, ...)
                -- Apply all styles before showing
                if self.Background then
                    self.Background:SetColorTexture(0.12, 0.12, 0.12, 0.95)
                end
                if self.HeaderBackground then
                    self.HeaderBackground:SetColorTexture(0.15, 0.15, 0.15, 1)
                end
                ApplyCategoriesStyle(self)
                ApplyThemeColor(self, HouseEditorFrame and HouseEditorFrame.StorageButton)
                if self.CornerBorder then
                    self.CornerBorder:Hide()
                end
                -- Now show the panel
                return originalShow(self, ...)
            end
            storagePanel.htShowHooked = true
        end
        
        -- Also hook OnShow as backup for any edge cases
        if not storagePanel.htCategoriesHooked then
            storagePanel:HookScript("OnShow", function(self)
                -- Apply styles immediately (no delay) to prevent flash
                if self.Background then
                    self.Background:SetColorTexture(0.12, 0.12, 0.12, 0.95)
                end
                if self.HeaderBackground then
                    self.HeaderBackground:SetColorTexture(0.15, 0.15, 0.15, 1)
                end
                ApplyCategoriesStyle(self)
                ApplyThemeColor(self, HouseEditorFrame.StorageButton)
                if self.CornerBorder then
                    self.CornerBorder:Hide()
                end
            end)
            
            -- Hook SetCategoriesBackground to prevent wood texture from coming back
            if storagePanel.Categories and storagePanel.Categories.SetCategoriesBackground then
                hooksecurefunc(storagePanel.Categories, "SetCategoriesBackground", function()
                    ApplyCategoriesStyle(storagePanel)
                end)
            end
            
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
    
    -- Wait for the Blizzard House Editor to load with no delay
    HT.WaitForHouseEditor(0, function()
        SetupStyle()
        -- Also hook HouseEditorFrame.Show to catch it before it's visible
        if HouseEditorFrame and not HouseEditorFrame.htShowHooked then
            local originalFrameShow = HouseEditorFrame.Show
            HouseEditorFrame.Show = function(self, ...)
                SetupStyle()
                return originalFrameShow(self, ...)
            end
            HouseEditorFrame.htShowHooked = true
        end
    end)
end
