-- Favorites: Adds a favorites system for decor items
local addonName, HT = ...

local Favorites = {}
HT:RegisterTweak("Favorites", Favorites)

-- Get current theme color
-- Use shared theme helper

-- Check if a decor is favorited
local function IsFavorited(decorID)
    if not HousingTweaksDB.favorites then
        HousingTweaksDB.favorites = {}
    end
    return HousingTweaksDB.favorites[decorID] == true
end

-- Toggle favorite status
local function ToggleFavorite(decorID)
    if not HousingTweaksDB.favorites then
        HousingTweaksDB.favorites = {}
    end
    if HousingTweaksDB.favorites[decorID] then
        HousingTweaksDB.favorites[decorID] = nil
    else
        HousingTweaksDB.favorites[decorID] = true
    end
end

-- Get all favorited decor IDs
local function GetFavoriteDecorIDs()
    local ids = {}
    if HousingTweaksDB.favorites then
        for id, _ in pairs(HousingTweaksDB.favorites) do
            table.insert(ids, id)
        end
    end
    return ids
end

-- Count favorites
local function GetFavoriteCount()
    local count = 0
    if HousingTweaksDB.favorites then
        for _ in pairs(HousingTweaksDB.favorites) do
            count = count + 1
        end
    end
    return count
end

-- Store reference to our custom category button
local favoritesButton = nil
local isShowingFavorites = false
local originalCatalogData = nil

-- Create the favorites category button
local function CreateFavoritesCategoryButton(categoriesFrame)
    if favoritesButton then return favoritesButton end
    
    local r, g, b = HT.GetThemeColor()
    
    -- Create button frame
    local button = CreateFrame("Button", "HousingTweaksFavoritesButton", categoriesFrame)
    button:SetSize(64, 64)
    
    -- Position at bottom of categories, below the last category button
    -- We'll need to find the existing buttons and position below them
    button:SetPoint("BOTTOM", categoriesFrame, "BOTTOM", 0, 10)
    
    -- Background circle (similar to category buttons)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(58, 58)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Common\\Ring-pointed")
    bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    button.bg = bg
    
    -- Star icon - bigger and brighter
    local star = button:CreateTexture(nil, "ARTWORK")
    star:SetSize(42, 42)
    star:SetPoint("CENTER", 0, 2)
    star:SetAtlas("PetJournal-FavoritesIcon")
    star:SetVertexColor(1, 0.9, 0)  -- Vibrant bright yellow
    button.star = star
    
    -- "HT" text below star
    local htText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HT.ApplyFontString(htText, "GameFontNormalSmall")
    htText:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    htText:SetText("HT")
    htText:SetTextColor(r, g, b)
    button.htText = htText
    
    -- Highlight on hover
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(58, 58)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Common\\Ring-pointed")
    highlight:SetVertexColor(r, g, b, 0.3)
    button.highlight = highlight
    
    -- Selected indicator border
    local selected = button:CreateTexture(nil, "OVERLAY")
    selected:SetSize(62, 62)
    selected:SetPoint("CENTER")
    selected:SetTexture("Interface\\Common\\Ring-pointed")
    selected:SetVertexColor(r, g, b, 1)
    selected:Hide()
    button.selected = selected
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Favorites (Housing Tweaks)")
        GameTooltip:AddLine("Click to show your favorited decor items", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(GetFavoriteCount() .. " items favorited", r, g, b)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click handler
    button:SetScript("OnClick", function(self)
        isShowingFavorites = not isShowingFavorites
        
        if isShowingFavorites then
            -- Show favorites
            self.selected:Show()
            self.star:SetVertexColor(1, 0.82, 0)  -- Gold star
            self.bg:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, 0.9)
            
            -- Clear other category selections visually
            -- and populate with favorites
            Favorites:ShowFavorites()
        else
            -- Return to normal view
            self.selected:Hide()
            self.star:SetVertexColor(0.6, 0.6, 0.6)
            self.bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
            
            -- Restore normal category view
            Favorites:HideFavorites()
        end
        
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    
    favoritesButton = button
    return button
end

-- Update the favorites button theme colors
function Favorites:ApplyTheme()
    local r, g, b = HT.GetThemeColor()
    
    -- Update favorites button colors
    if favoritesButton then
        favoritesButton.htText:SetTextColor(r, g, b)
        favoritesButton.highlight:SetVertexColor(r, g, b, 0.3)
        favoritesButton.selected:SetVertexColor(r, g, b, 1)
        if isShowingFavorites then
            favoritesButton.bg:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, 0.9)
        end
    end
    
    -- Update the category header text if showing favorites
    if isShowingFavorites then
        local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
        if storagePanel and storagePanel.OptionsContainer and storagePanel.OptionsContainer.CategoryText then
            storagePanel.OptionsContainer.CategoryText:SetTextColor(r, g, b)
        end
    end
end

-- Show favorites in the storage panel
function Favorites:ShowFavorites()
    local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
    if not storagePanel then return end
    
    -- Get favorited items that exist in storage
    local favoriteEntries = {}
    local favorites = HousingTweaksDB.favorites or {}
    
    -- We need to search through all owned decor to find matches
    if storagePanel.catalogSearcher then
        local allItems = storagePanel.catalogSearcher:GetAllSearchItems()
        for _, entryID in ipairs(allItems) do
            if entryID.entryType == Enum.HousingCatalogEntryType.Decor then
                if favorites[entryID.recordID] then
                    table.insert(favoriteEntries, entryID)
                end
            end
        end
    end
    
    -- Set custom catalog data to show only favorites (no header text to avoid duplicate)
    if storagePanel.OptionsContainer and storagePanel.OptionsContainer.SetCatalogData then
        storagePanel.OptionsContainer:SetCatalogData(favoriteEntries, false)
    end
    
    -- Update category text with our styled header
    if storagePanel.OptionsContainer and storagePanel.OptionsContainer.CategoryText then
        storagePanel.OptionsContainer.CategoryText:SetText("Housing Tweaks Favorites")
        local r, g, b = HT.GetThemeColor()
        storagePanel.OptionsContainer.CategoryText:SetTextColor(r, g, b)
    end
end

-- Hide favorites and restore normal view
function Favorites:HideFavorites()
    local storagePanel = HouseEditorFrame and HouseEditorFrame.StoragePanel
    if not storagePanel then return end
    
    -- Trigger a refresh by clicking "All" category or running search again
    if storagePanel.catalogSearcher then
        storagePanel.catalogSearcher:RunSearch()
    end
    
    -- Reset category focus
    if storagePanel.Categories then
        storagePanel.Categories:SetFocus(Constants.HousingCatalogConsts.HOUSING_CATALOG_ALL_CATEGORY_ID)
    end
end

-- Add star overlay to decor buttons
local function AddStarToButton(button)
    if button.htFavStar then return end
    
    local star = button:CreateTexture(nil, "OVERLAY", nil, 7)
    star:SetSize(28, 28)
    star:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    star:SetAtlas("PetJournal-FavoritesIcon")
    star:SetVertexColor(0.7, 0.7, 0.7)  -- Light gray, always visible
    star:SetAlpha(0.8)
    star:Show()
    button.htFavStar = star
    
    -- Create clickable area for star
    local starButton = CreateFrame("Button", nil, button)
    starButton:SetSize(32, 32)
    starButton:SetPoint("CENTER", star, "CENTER")
    starButton:SetFrameLevel(button:GetFrameLevel() + 10)
    button.htFavStarButton = starButton
    
    starButton:SetScript("OnClick", function(self, mouseButton)
        local elementData = button.elementData or (button.GetElementData and button:GetElementData())
        if elementData and elementData.entryID and elementData.entryID.recordID then
            ToggleFavorite(elementData.entryID.recordID)
            Favorites:UpdateStarDisplay(button)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end)
    
    starButton:SetScript("OnEnter", function(self)
        local elementData = button.elementData or (button.GetElementData and button:GetElementData())
        local isFav = false
        if elementData and elementData.entryID and elementData.entryID.recordID then
            isFav = IsFavorited(elementData.entryID.recordID)
        end
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if isFav then
            GameTooltip:SetText("Remove from Favorites")
        else
            GameTooltip:SetText("Add to Favorites")
        end
        GameTooltip:Show()
        
        -- Highlight star on hover (bright yellow)
        star:SetVertexColor(1, 1, 0)
        star:SetAlpha(1)
    end)
    
    starButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        Favorites:UpdateStarDisplay(button)
    end)
end

-- Update star display based on favorite status
function Favorites:UpdateStarDisplay(button)
    if not button.htFavStar then return end
    
    local elementData = button.elementData or (button.GetElementData and button:GetElementData())
    if elementData and elementData.entryID and elementData.entryID.recordID then
        local isFav = IsFavorited(elementData.entryID.recordID)
        if isFav then
            button.htFavStar:SetVertexColor(1, 0.9, 0)  -- Bright vivid gold/yellow
            button.htFavStar:SetAlpha(1)
            button.htFavStar:SetSize(32, 32)  -- Bigger when favorited
        else
            button.htFavStar:SetVertexColor(0.8, 0.8, 0.8)  -- Light gray, visible
            button.htFavStar:SetAlpha(0.7)
            button.htFavStar:SetSize(28, 28)  -- Normal size
        end
        button.htFavStar:Show()
    else
        button.htFavStar:Hide()
    end
end

function Favorites:Init()
    -- Ensure favorites table exists
    if not HousingTweaksDB.favorites then
        HousingTweaksDB.favorites = {}
    end
    
    local function SetupFavorites()
        if not HouseEditorFrame then return false end
        
        local storagePanel = HouseEditorFrame.StoragePanel
        if not storagePanel then return false end
        
        local categories = storagePanel.Categories
        if not categories then return false end
        
        -- Create the favorites button at bottom of categories
        CreateFavoritesCategoryButton(categories)
        
        -- Hook into ScrollBox to add stars to decor buttons
        local optionsContainer = storagePanel.OptionsContainer
        if not optionsContainer then return false end
        
        local scrollBox = optionsContainer.ScrollBox
        if not scrollBox then return false end
        
        -- Hook button updates
        local function HookButton(button)
            if not button or button.htFavHooked then return end
            
            AddStarToButton(button)
            
            button.htFavHooked = true
        end
        
        hooksecurefunc(scrollBox, "Update", function(self)
            self:ForEachFrame(function(button)
                HookButton(button)
                Favorites:UpdateStarDisplay(button)
            end)
        end)
        
        -- Hook existing frames
        scrollBox:ForEachFrame(function(button)
            HookButton(button)
            Favorites:UpdateStarDisplay(button)
        end)
        
        -- Reset favorites view when categories change
        if categories.SetFocus then
            hooksecurefunc(categories, "SetFocus", function()
                if isShowingFavorites and favoritesButton then
                    isShowingFavorites = false
                    favoritesButton.selected:Hide()
                    favoritesButton.star:SetVertexColor(0.6, 0.6, 0.6)
                    favoritesButton.bg:SetVertexColor(0.3, 0.3, 0.3, 0.8)
                end
            end)
        end
        
        return true
    end
    
    -- Try immediately
    if SetupFavorites() then
        return
    end
    
    -- Wait for the Blizzard House Editor to load
    HT.WaitForHouseEditor(0, function()
        SetupFavorites()
    end)
end
