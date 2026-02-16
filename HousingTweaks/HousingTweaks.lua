-- HousingTweaks: Quality of life tweaks for the Housing system
local addonName, HT = ...

-- Default settings
local defaults = {
    tweaks = {
        MoveableStoragePanel = true,
        DecorPreview = true,
        StoragePanelStyle = true,
        Favorites = true,
    },
    positions = {},
    DecorPreviewPosition = "CENTERRIGHT",
    storagePanelColorTheme = "orange",
    toolbarPosition = "BOTTOMRIGHT",
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
    -- Ensure toolbarPosition default
    if HousingTweaksDB.toolbarPosition == nil then
        HousingTweaksDB.toolbarPosition = defaults.toolbarPosition
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
    Favorites = {
        name = "Favorites",
        description = "Adds a favorites system to mark and filter decor items with a star.",
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

-- Font helpers
HT.FontPath = "Interface\\AddOns\\HousingTweaks\\Fonts\\htfont.ttf"
function HT.GetFontPath()
    if HT.FontPath and HT.FontPath ~= "" then
        return HT.FontPath
    end
    return "Fonts\\FRIZQT__.TTF"
end

-- Returns font size from a template name or number
local function ResolveFontSize(templateOrSize)
    if type(templateOrSize) == "number" then
        return templateOrSize
    end
    local t = tostring(templateOrSize or "GameFontNormal")
    if string.find(t, "Small") then
        return 11
    elseif string.find(t, "Large") then
        return 14
    elseif string.find(t, "Huge") then
        return 16
    else
        return 12
    end
end

function HT.ApplyFontString(fontString, templateOrSize, flags)
    if not fontString or not fontString.SetFont then return end
    local size = ResolveFontSize(templateOrSize)
    flags = flags or ""
    -- Set font safely - fall back to FRIZQT if setting the custom font fails
    local path = HT.GetFontPath()
    local ok, err = pcall(fontString.SetFont, fontString, path, size, flags)
    if not ok then
        -- Try fallback to the default FRIZQT font
        local fallback = "Fonts\\FRIZQT__.TTF"
        local ok2, err2 = pcall(fontString.SetFont, fontString, fallback, size, flags)
        if not ok2 then
            -- As a last resort, do nothing to avoid breaking UI further
            print("HousingTweaks: Failed to set font (custom and fallback). Error:", err, err2)
        end
    end
end

-- Validate the custom font by applying it to a temp FontString and checking for errors
function HT.ValidateCustomFont()
    if not HT.FontPath or HT.FontPath == "" then
        return false, "No font path set"
    end
    -- Create a temporary invisible fontstring to test SetFont
    local tmp = UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tmp:SetPoint("CENTER", UIParent, "CENTER", 9999, 9999) -- off-screen
    local size = 12
    local ok, err = pcall(tmp.SetFont, tmp, HT.FontPath, size, "")
    tmp:SetParent(nil)
    tmp:Hide()
    if not ok then
        return false, err
    end
    return true
end

-- Slash command to toggle or test custom font
SLASH_HOUSINGTWEAKS_FONT1 = "/htfont"
SlashCmdList["HOUSINGTWEAKS_FONT"] = function(msg)
    local action = (msg or ""):lower():match("^(%S+)") or "test"
    if action == "test" then
        local ok, err = HT.ValidateCustomFont()
        if ok then
            print("HousingTweaks: Custom font appears valid: ", HT.GetFontPath())
        else
            print("HousingTweaks: Custom font validation failed:", err)
        end
    elseif action == "enable" then
        if HT.FontPath == "" then
            print("HousingTweaks: No custom font path set. Edit HT.FontPath in HousingTweaks.lua to set a path.")
            return
        end
        HT.ApplyFontString(UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormal"), 12, "")
        print("HousingTweaks: Enabled custom font (attempted). Reload UI to ensure all elements update.")
    elseif action == "disable" then
        HT.FontPath = ""
        print("HousingTweaks: Custom font disabled; fallback font will be used on next UI updates.")
    else
        print("HousingTweaks /htfont commands: test | enable | disable")
    end
end

-- Helper: invoke a callback once the Blizzard House Editor is loaded
function HT.WaitForHouseEditor(delay, callback)
    if type(delay) == "function" then
        callback = delay
        delay = 0
    end
    delay = delay or 0
    if HouseEditorFrame then
        -- Frame already exists, run immediately or with minimal delay
        if delay > 0 then
            C_Timer.After(delay, callback)
        else
            callback()
        end
        return
    end
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, event, loadedAddon)
        if loadedAddon == "Blizzard_HouseEditor" then
            self:UnregisterEvent("ADDON_LOADED")
            if delay > 0 then
                C_Timer.After(delay, callback)
            else
                callback()
            end
        end
    end)
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
-- Shared color themes for the addon
HT.COLOR_THEMES = {
    orange = { name = "Orange", r = 1, g = 0.5, b = 0 },
    blue = { name = "Blue", r = 0.2, g = 0.6, b = 1 },
    purple = { name = "Purple", r = 0.7, g = 0.3, b = 1 },
    green = { name = "Green", r = 0.3, g = 0.9, b = 0.4 },
    red = { name = "Red", r = 1, g = 0.2, b = 0.2 },
    cyan = { name = "Cyan", r = 0.2, g = 0.9, b = 0.9 },
    white = { name = "White", r = 1, g = 1, b = 1 },
}

-- Also provide an array list useful for dropdowns
HT.COLOR_THEME_LIST = {
    { value = "orange", text = "Orange", r = 1, g = 0.5, b = 0 },
    { value = "blue", text = "Blue", r = 0.2, g = 0.6, b = 1 },
    { value = "purple", text = "Purple", r = 0.7, g = 0.3, b = 1 },
    { value = "green", text = "Green", r = 0.3, g = 0.9, b = 0.4 },
    { value = "red", text = "Red", r = 1, g = 0.2, b = 0.2 },
    { value = "cyan", text = "Cyan", r = 0.2, g = 0.9, b = 0.9 },
    { value = "white", text = "White", r = 1, g = 1, b = 1 },
}

function HT.GetTheme()
    local themeName = HousingTweaksDB and HousingTweaksDB.storagePanelColorTheme or "orange"
    return HT.COLOR_THEMES[themeName] or HT.COLOR_THEMES.orange
end

function HT.GetThemeColor()
    local theme = HT.GetTheme()
    return theme.r, theme.g, theme.b
end

-- Preview positions array
HT.PREVIEW_POSITIONS = {
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

local GUI_STYLE = {
    baseBg = { 0.04, 0.04, 0.05, 0.98 },
    baseBorder = { 0.1, 0.1, 0.12, 1 },
    titleBg = { 0.12, 0.12, 0.15, 1 },
    panelBg = { 0.08, 0.08, 0.1, 1 },
    panelBorder = { 0.18, 0.18, 0.22, 1 },
    fieldBg = { 0.06, 0.06, 0.08, 1 },
    fieldBorder = { 0.25, 0.25, 0.3, 1 },
    textPrimary = { 0.92, 0.92, 0.92 },
    textSecondary = { 0.72, 0.72, 0.72 },
    textMuted = { 0.56, 0.56, 0.56 },
}

local PIXEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local function ApplyMinimalBackdrop(frame, bgColor, borderColor)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(PIXEL_BACKDROP)
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
end

local function AddAccentRegion(frame, region)
    if not frame or not region then return end
    if not frame.accentRegions then
        frame.accentRegions = {}
    end
    table.insert(frame.accentRegions, region)
end

local function AddThemeWidget(frame, widgetListName, widget)
    if not frame or not widget then return end
    if not frame[widgetListName] then
        frame[widgetListName] = {}
    end
    table.insert(frame[widgetListName], widget)
end

local function UpdateTabStyles(frame)
    if not frame or not frame.tabs then return end
    local r, g, b = HT.GetThemeColor()

    for _, tab in ipairs(frame.tabs) do
        if tab.name == frame.activeTab then
            tab.isActive = true
            tab:SetBackdropColor(GUI_STYLE.titleBg[1], GUI_STYLE.titleBg[2], GUI_STYLE.titleBg[3], GUI_STYLE.titleBg[4])
            tab:SetBackdropBorderColor(r, g, b, 0.85)
            tab.text:SetTextColor(1, 1, 1)
        else
            tab.isActive = false
            tab:SetBackdropColor(GUI_STYLE.fieldBg[1], GUI_STYLE.fieldBg[2], GUI_STYLE.fieldBg[3], GUI_STYLE.fieldBg[4])
            tab:SetBackdropBorderColor(GUI_STYLE.panelBorder[1], GUI_STYLE.panelBorder[2], GUI_STYLE.panelBorder[3], GUI_STYLE.panelBorder[4])
            tab.text:SetTextColor(GUI_STYLE.textSecondary[1], GUI_STYLE.textSecondary[2], GUI_STYLE.textSecondary[3])
        end
    end
end

-- Function to refresh GUI colors
local function RefreshGUIColors(frame)
    if not frame then return end
    local r, g, b = HT.GetThemeColor()

    if frame.titleText then
        frame.titleText:SetTextColor(r, g, b)
    end
    if frame.accentLine then
        frame.accentLine:SetColorTexture(r, g, b, 0.9)
    end

    UpdateTabStyles(frame)

    if frame.accentRegions then
        for _, region in ipairs(frame.accentRegions) do
            if region and region.SetTextColor then
                region:SetTextColor(r, g, b)
            end
        end
    end

    if frame.toggleWidgets then
        for _, widget in ipairs(frame.toggleWidgets) do
            if widget and widget.ApplyTheme then
                widget:ApplyTheme()
            end
        end
    end

    if frame.dropdownWidgets then
        for _, widget in ipairs(frame.dropdownWidgets) do
            if widget and widget.ApplyTheme then
                widget:ApplyTheme()
            end
            if widget and widget.RefreshValue then
                widget:RefreshValue()
            end
        end
    end
end

local function CreateMinimalDropdown(parent, width, options, getCurrentValue, onSelect)
    local dropdown = CreateFrame("Button", nil, parent, "BackdropTemplate")
    dropdown:SetSize(width, 20)
    ApplyMinimalBackdrop(dropdown, GUI_STYLE.fieldBg, GUI_STYLE.fieldBorder)

    local valueText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(valueText, "GameFontNormalSmall")
    valueText:SetPoint("LEFT", dropdown, "LEFT", 6, 0)
    valueText:SetPoint("RIGHT", dropdown, "RIGHT", -18, 0)
    valueText:SetJustifyH("LEFT")
    dropdown.valueText = valueText

    local arrowText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(arrowText, "GameFontNormalSmall")
    arrowText:SetPoint("RIGHT", dropdown, "RIGHT", -6, 0)
    arrowText:SetText("v")
    arrowText:SetTextColor(GUI_STYLE.textSecondary[1], GUI_STYLE.textSecondary[2], GUI_STYLE.textSecondary[3])
    dropdown.arrowText = arrowText

    local menuFrame = CreateFrame("Frame", nil, dropdown, "UIDropDownMenuTemplate")
    menuFrame:Hide()

    local function FindOptionText(value)
        for _, opt in ipairs(options or {}) do
            if opt.value == value then
                return opt.text
            end
        end
        return nil
    end

    local function RefreshValue()
        local value = getCurrentValue and getCurrentValue() or nil
        valueText:SetText(FindOptionText(value) or tostring(value or "Select..."))
    end

    dropdown.RefreshValue = RefreshValue
    function dropdown:ApplyTheme()
        local r, g, b = HT.GetThemeColor()
        self.valueText:SetTextColor(r, g, b)
    end

    dropdown:SetScript("OnEnter", function(self)
        local r, g, b = HT.GetThemeColor()
        self:SetBackdropBorderColor(r, g, b, 0.6)
        self.arrowText:SetTextColor(1, 1, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(GUI_STYLE.fieldBorder[1], GUI_STYLE.fieldBorder[2], GUI_STYLE.fieldBorder[3], GUI_STYLE.fieldBorder[4])
        self.arrowText:SetTextColor(GUI_STYLE.textSecondary[1], GUI_STYLE.textSecondary[2], GUI_STYLE.textSecondary[3])
    end)

    dropdown:SetScript("OnClick", function(self)
        local function HandleSelect(_, value)
            if onSelect then
                onSelect(value)
            end
            RefreshValue()
            CloseDropDownMenus()
        end

        UIDropDownMenu_Initialize(menuFrame, function(_, level)
            local currentValue = getCurrentValue and getCurrentValue() or nil
            for _, opt in ipairs(options or {}) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.text
                info.arg1 = opt.value
                info.func = HandleSelect
                info.checked = (opt.value == currentValue)
                if opt.r and opt.g and opt.b then
                    info.colorCode = string.format("|cff%02x%02x%02x", math.floor(opt.r * 255), math.floor(opt.g * 255), math.floor(opt.b * 255))
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end, "MENU")

        ToggleDropDownMenu(1, nil, menuFrame, self, 0, 0)
    end)

    RefreshValue()
    return dropdown
end

local function CreateSectionCard(parent, yOffset, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset)
    card:SetHeight(height)
    ApplyMinimalBackdrop(card, GUI_STYLE.panelBg, GUI_STYLE.panelBorder)
    return card, (yOffset - height - 10)
end

local function CreateTweakToggleCard(parent, frame, tweakName, yOffset)
    local info = HT.TweakInfo[tweakName]
    if not info then
        return yOffset
    end

    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:RegisterForClicks("LeftButtonUp")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, yOffset)
    card:SetHeight(72)
    ApplyMinimalBackdrop(card, GUI_STYLE.panelBg, GUI_STYLE.panelBorder)

    local checkbox = CreateFrame("Button", nil, card, "BackdropTemplate")
    checkbox:RegisterForClicks("LeftButtonUp")
    checkbox:SetSize(14, 14)
    checkbox:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -12)
    ApplyMinimalBackdrop(checkbox, GUI_STYLE.fieldBg, GUI_STYLE.fieldBorder)

    local checkFill = checkbox:CreateTexture(nil, "ARTWORK")
    checkFill:SetSize(8, 8)
    checkFill:SetPoint("CENTER")
    checkbox.checkFill = checkFill

    local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    HT.ApplyFontString(label, "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(info.name)
    AddAccentRegion(frame, label)

    if info.requiresReload then
        local reloadText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(reloadText, "GameFontNormalSmall")
        reloadText:SetPoint("LEFT", label, "RIGHT", 6, 0)
        reloadText:SetText("|cFFFFAA00(reload)|r")
    end

    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(desc, "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 2, -4)
    desc:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    desc:SetJustifyH("LEFT")
    desc:SetText(info.description)
    desc:SetTextColor(GUI_STYLE.textSecondary[1], GUI_STYLE.textSecondary[2], GUI_STYLE.textSecondary[3])

    local function SetCheckedVisual(isChecked)
        checkbox.isChecked = isChecked
        checkbox.checkFill:SetShown(isChecked)
        local r, g, b = HT.GetThemeColor()
        checkbox.checkFill:SetColorTexture(r, g, b, 1)
        if isChecked then
            checkbox:SetBackdropBorderColor(r, g, b, 0.8)
        else
            checkbox:SetBackdropBorderColor(GUI_STYLE.fieldBorder[1], GUI_STYLE.fieldBorder[2], GUI_STYLE.fieldBorder[3], GUI_STYLE.fieldBorder[4])
        end
    end

    function checkbox:ApplyTheme()
        SetCheckedVisual(self.isChecked)
    end

    local function ToggleSetting()
        local enabled = not checkbox.isChecked
        HT:SetTweakEnabled(tweakName, enabled)
        SetCheckedVisual(enabled)

        if info.requiresReload then
            StaticPopup_Show("HOUSINGTWEAKS_RELOAD_PROMPT")
        end
    end

    SetCheckedVisual(HT:IsTweakEnabled(tweakName))
    card:SetScript("OnClick", ToggleSetting)
    checkbox:SetScript("OnClick", ToggleSetting)

    card:SetScript("OnEnter", function(self)
        local r, g, b = HT.GetThemeColor()
        self:SetBackdropBorderColor(r, g, b, 0.45)
    end)
    card:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(GUI_STYLE.panelBorder[1], GUI_STYLE.panelBorder[2], GUI_STYLE.panelBorder[3], GUI_STYLE.panelBorder[4])
    end)

    table.insert(frame.containers, card)
    AddThemeWidget(frame, "toggleWidgets", checkbox)
    return yOffset - 82
end

-- Forward declare PopulateSettingsFrame
local PopulateSettingsFrame

-- Create the settings GUI
local function CreateSettingsFrame()
    local frame = CreateFrame("Frame", "HousingTweaksSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(620, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    ApplyMinimalBackdrop(frame, GUI_STYLE.baseBg, GUI_STYLE.baseBorder)

    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(28)
    ApplyMinimalBackdrop(titleBar, GUI_STYLE.titleBg, GUI_STYLE.baseBorder)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    frame.accentLine = frame:CreateTexture(nil, "BORDER")
    frame.accentLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -29)
    frame.accentLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -29)
    frame.accentLine:SetHeight(1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    HT.ApplyFontString(titleText, 13, "")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    titleText:SetText("Matt's Housing Tweaks")
    frame.titleText = titleText

    local closeButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    ApplyMinimalBackdrop(closeButton, GUI_STYLE.fieldBg, GUI_STYLE.fieldBorder)

    local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    HT.ApplyFontString(closeText, 12, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(0.6, 0.6, 0.6)

    closeButton:SetScript("OnEnter", function(self)
        local r, g, b = HT.GetThemeColor()
        self:SetBackdropBorderColor(r, g, b, 0.7)
        closeText:SetTextColor(1, 0.35, 0.35)
    end)
    closeButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(GUI_STYLE.fieldBorder[1], GUI_STYLE.fieldBorder[2], GUI_STYLE.fieldBorder[3], GUI_STYLE.fieldBorder[4])
        closeText:SetTextColor(0.6, 0.6, 0.6)
    end)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -36)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -36)
    tabBar:SetHeight(24)

    local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -6)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    ApplyMinimalBackdrop(content, GUI_STYLE.panelBg, GUI_STYLE.panelBorder)

    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -28, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    frame.containers = {}
    frame.accentRegions = {}
    frame.toggleWidgets = {}
    frame.dropdownWidgets = {}

    local tabButtons = {}
    local tabNames = { "Theme", "Storage" }
    for index, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        tab:SetSize(112, 24)
        if index == 1 then
            tab:SetPoint("TOPLEFT", tabBar, "TOPLEFT", 0, 0)
        else
            tab:SetPoint("LEFT", tabButtons[index - 1], "RIGHT", 4, 0)
        end
        ApplyMinimalBackdrop(tab, GUI_STYLE.fieldBg, GUI_STYLE.panelBorder)

        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(tabText, "GameFontNormalSmall")
        tabText:SetPoint("CENTER")
        tabText:SetText(name)
        tab.text = tabText
        tab.name = name

        tab:SetScript("OnEnter", function(self)
            if self.isActive then return end
            local r, g, b = HT.GetThemeColor()
            self:SetBackdropBorderColor(r, g, b, 0.5)
            self.text:SetTextColor(0.88, 0.88, 0.88)
        end)
        tab:SetScript("OnLeave", function(self)
            if self.isActive then return end
            self:SetBackdropBorderColor(GUI_STYLE.panelBorder[1], GUI_STYLE.panelBorder[2], GUI_STYLE.panelBorder[3], GUI_STYLE.panelBorder[4])
            self.text:SetTextColor(GUI_STYLE.textSecondary[1], GUI_STYLE.textSecondary[2], GUI_STYLE.textSecondary[3])
        end)
        tab:SetScript("OnClick", function()
            frame.activeTab = name
            PopulateSettingsFrame(frame)
        end)

        tabButtons[index] = tab
    end

    frame.activeTab = "Theme"
    frame.tabs = tabButtons
    AddAccentRegion(frame, titleText)

    RefreshGUIColors(frame)
    return frame
end

function PopulateSettingsFrame(frame)
    local scrollChild = frame.scrollChild
    local activeTab = frame.activeTab or "Theme"
    local yOffset = -8

    for _, container in pairs(frame.containers) do
        container:Hide()
        container:SetParent(nil)
    end
    wipe(frame.containers)

    frame.accentRegions = { frame.titleText }
    frame.toggleWidgets = {}
    frame.dropdownWidgets = {}

    local childWidth = frame.scrollFrame and (frame.scrollFrame:GetWidth() - 4) or 560
    if childWidth < 200 then
        childWidth = 560
    end
    scrollChild:SetWidth(childWidth)

    if activeTab == "Theme" then
        local themeCard
        themeCard, yOffset = CreateSectionCard(scrollChild, yOffset, 122)
        table.insert(frame.containers, themeCard)

        local themeHeader = themeCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        HT.ApplyFontString(themeHeader, "GameFontNormal")
        themeHeader:SetPoint("TOPLEFT", themeCard, "TOPLEFT", 12, -12)
        themeHeader:SetText("Theme Settings")
        AddAccentRegion(frame, themeHeader)

        local themeDesc = themeCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(themeDesc, "GameFontNormalSmall")
        themeDesc:SetPoint("TOPLEFT", themeHeader, "BOTTOMLEFT", 0, -10)
        themeDesc:SetText("Accent Color Theme")
        themeDesc:SetTextColor(GUI_STYLE.textPrimary[1], GUI_STYLE.textPrimary[2], GUI_STYLE.textPrimary[3])

        local themeDropdown = CreateMinimalDropdown(
            themeCard,
            220,
            HT.COLOR_THEME_LIST,
            function()
                return HousingTweaksDB.storagePanelColorTheme or "orange"
            end,
            function(value)
                HousingTweaksDB.storagePanelColorTheme = value

                if HT.Tweaks.StoragePanelStyle and HT.Tweaks.StoragePanelStyle.ApplyTheme then
                    HT.Tweaks.StoragePanelStyle:ApplyTheme()
                end
                if HT.Tweaks.DecorPreview and HT.Tweaks.DecorPreview.ApplyTheme then
                    HT.Tweaks.DecorPreview:ApplyTheme()
                end
                if HT.Tweaks.Favorites and HT.Tweaks.Favorites.ApplyTheme then
                    HT.Tweaks.Favorites:ApplyTheme()
                end

                RefreshGUIColors(frame)
            end
        )
        themeDropdown:SetPoint("TOPLEFT", themeDesc, "BOTTOMLEFT", 0, -6)
        AddThemeWidget(frame, "dropdownWidgets", themeDropdown)

        local themeNote = themeCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(themeNote, "GameFontNormalSmall")
        themeNote:SetPoint("TOPLEFT", themeDropdown, "BOTTOMLEFT", 0, -8)
        themeNote:SetPoint("RIGHT", themeCard, "RIGHT", -12, 0)
        themeNote:SetJustifyH("LEFT")
        themeNote:SetText("Applies to Housing Tweaks GUI accents and storage panel highlights.")
        themeNote:SetTextColor(GUI_STYLE.textMuted[1], GUI_STYLE.textMuted[2], GUI_STYLE.textMuted[3])

        yOffset = CreateTweakToggleCard(scrollChild, frame, "StoragePanelStyle", yOffset)

        local toolbarCard
        toolbarCard, yOffset = CreateSectionCard(scrollChild, yOffset, 106)
        table.insert(frame.containers, toolbarCard)

        local toolbarHeader = toolbarCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        HT.ApplyFontString(toolbarHeader, "GameFontNormal")
        toolbarHeader:SetPoint("TOPLEFT", toolbarCard, "TOPLEFT", 12, -12)
        toolbarHeader:SetText("Toolbar Position")
        AddAccentRegion(frame, toolbarHeader)

        local toolbarOptions = {
            { value = "TOPRIGHT", text = "Top Right" },
            { value = "BOTTOMRIGHT", text = "Bottom Right *" },
        }

        local toolbarDropdown = CreateMinimalDropdown(
            toolbarCard,
            220,
            toolbarOptions,
            function()
                return HousingTweaksDB.toolbarPosition or "BOTTOMRIGHT"
            end,
            function(value)
                HousingTweaksDB.toolbarPosition = value
                if HT.Tweaks.StoragePanelStyle and HT.Tweaks.StoragePanelStyle.ApplyToolbarPosition then
                    HT.Tweaks.StoragePanelStyle:ApplyToolbarPosition()
                end
            end
        )
        toolbarDropdown:SetPoint("TOPLEFT", toolbarHeader, "BOTTOMLEFT", 0, -10)
        AddThemeWidget(frame, "dropdownWidgets", toolbarDropdown)

        local toolbarNote = toolbarCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(toolbarNote, "GameFontNormalSmall")
        toolbarNote:SetPoint("TOPLEFT", toolbarDropdown, "BOTTOMLEFT", 0, -8)
        toolbarNote:SetPoint("RIGHT", toolbarCard, "RIGHT", -12, 0)
        toolbarNote:SetJustifyH("LEFT")
        toolbarNote:SetText("Controls the position of the Preview, Color, and HT controls near the storage panel.")
        toolbarNote:SetTextColor(GUI_STYLE.textMuted[1], GUI_STYLE.textMuted[2], GUI_STYLE.textMuted[3])
    end

    if activeTab == "Storage" then
        local storageHeaderCard
        storageHeaderCard, yOffset = CreateSectionCard(scrollChild, yOffset, 50)
        table.insert(frame.containers, storageHeaderCard)

        local storageHeader = storageHeaderCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        HT.ApplyFontString(storageHeader, "GameFontNormal")
        storageHeader:SetPoint("TOPLEFT", storageHeaderCard, "TOPLEFT", 12, -12)
        storageHeader:SetText("Storage Tweaks")
        AddAccentRegion(frame, storageHeader)

        local storageSub = storageHeaderCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HT.ApplyFontString(storageSub, "GameFontNormalSmall")
        storageSub:SetPoint("TOPLEFT", storageHeader, "BOTTOMLEFT", 0, -6)
        storageSub:SetText("Enable features and tune preview behavior.")
        storageSub:SetTextColor(GUI_STYLE.textMuted[1], GUI_STYLE.textMuted[2], GUI_STYLE.textMuted[3])

        local storageTweaks = { "MoveableStoragePanel", "DecorPreview", "Favorites" }
        for _, tweakName in ipairs(storageTweaks) do
            yOffset = CreateTweakToggleCard(scrollChild, frame, tweakName, yOffset)

            if tweakName == "DecorPreview" then
                local previewCard
                previewCard, yOffset = CreateSectionCard(scrollChild, yOffset, 94)
                table.insert(frame.containers, previewCard)

                local posHeader = previewCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                HT.ApplyFontString(posHeader, "GameFontNormal")
                posHeader:SetPoint("TOPLEFT", previewCard, "TOPLEFT", 12, -12)
                posHeader:SetText("Preview Position")
                AddAccentRegion(frame, posHeader)

                local previewDropdown = CreateMinimalDropdown(
                    previewCard,
                    230,
                    HT.PREVIEW_POSITIONS,
                    function()
                        return HousingTweaksDB.DecorPreviewPosition or "CENTERRIGHT"
                    end,
                    function(value)
                        HousingTweaksDB.DecorPreviewPosition = value
                        StaticPopup_Show("HOUSINGTWEAKS_RELOAD_PROMPT")
                    end
                )
                previewDropdown:SetPoint("TOPLEFT", posHeader, "BOTTOMLEFT", 0, -10)
                AddThemeWidget(frame, "dropdownWidgets", previewDropdown)

                local previewNote = previewCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                HT.ApplyFontString(previewNote, "GameFontNormalSmall")
                previewNote:SetPoint("TOPLEFT", previewDropdown, "BOTTOMLEFT", 0, -8)
                previewNote:SetText("Changing this option requires a reload.")
                previewNote:SetTextColor(GUI_STYLE.textMuted[1], GUI_STYLE.textMuted[2], GUI_STYLE.textMuted[3])
            end
        end
    end

    scrollChild:SetHeight(math.max(math.abs(yOffset) + 8, frame.scrollFrame:GetHeight()))
    RefreshGUIColors(frame)
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
        print("|cFFFFAA00Matt's Housing Tweaks:|r Settings GUI will open when you leave Edit House mode.")
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
        
        print("|cFF00FF00Matt's Housing Tweaks|r loaded. Type |cFFFFFF00/ht|r to open settings.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Export addon table
_G.HousingTweaks = HT
