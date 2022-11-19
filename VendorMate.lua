

local addonName, vm = ...;

local Gridview = vm.gridview;
local Database = vm.database;

local NUM_PLAYER_BAGS = 4;

local L = vm.locales;


VendorMateMixin = {
    playerBags = {},
    isRefreshEnabled = false,
    isItemIgnored = {};
}

function VendorMateMixin:OnLoad()

    SLASH_VENDORMATE1 = '/vendormate'
    SLASH_VENDORMATE2 = '/vm8'
    SlashCmdList['VENDORMATE'] = function(msg)
        self:Show()
    end

    vm:RegisterCallback("Player_OnEnteringWorld", self.Player_OnEnteringWorld, self)
    vm:RegisterCallback("Merchant_OnShow", self.Merchant_OnShow, self)
    vm:RegisterCallback("Merchant_OnHide", self.Merchant_OnHide, self)
    vm:RegisterCallback("PlayerBags_OnItemsChanged", self.PlayerBags_OnItemsChanged, self)
    vm:RegisterCallback("Filter_OnChanged", self.Filter_OnChanged, self)
    vm:RegisterCallback("Profile_OnFilterRemoved", self.Profile_OnFilterRemoved, self)
    vm:RegisterCallback("Profile_OnFilterAdded", self.Profile_OnFilterAdded, self)
    vm:RegisterCallback("Profile_OnChanged", self.Profile_OnChanged, self)
    vm:RegisterCallback("Filter_OnIgnoredChanged", self.Filter_OnIgnoredChanged, self)


    self:RegisterForDrag("LeftButton")
    self.resize:Init(self, 400, 400, 800, 620)

    self.resize:HookScript("OnMouseDown", function()
        self.isRefreshEnabled = true;
    end)
    self.resize:HookScript("OnMouseUp", function()
        self.isRefreshEnabled = false;
    end)

    self.numTabs = #self.tabs
    self.tab1:SetText(L.TABS_VENDOR)
    self.tab2:SetText(L.TABS_HISTORY)
    self.tab3:SetText(L.TABS_OPTIONS)

    PanelTemplates_SetNumTabs(self, self.numTabs);
    PanelTemplates_SetTab(self, 1);

    for i = 1, self.numTabs do
        self["tab"..i]:SetScript("OnClick", function()
            PanelTemplates_SetTab(self, i);
            self:TabView(i)
        end)
    end

    local function ProcessDetails(bag, slot)
        vm:TriggerEvent("Filter_OnItemSold", bag, slot)
    end

    if C_Container and C_Container.UseContainerItem then -- Dragonflight
        hooksecurefunc(C_Container, "UseContainerItem", ProcessDetails)
    else
        hooksecurefunc(_G, "UseContainerItem", ProcessDetails)
    end

    -- self:SetScript("OnHide", function()
    --     vm:TriggerEvent("VendorMate_OnHide")
    -- end)

end

function VendorMateMixin:TabView(tabIndex)

    for k, view in ipairs(self.content.views) do
        view:Hide()
    end
    if self.content.views[tabIndex] then
        self.content.views[tabIndex]:Show()
    end

end

function VendorMateMixin:OnUpdate()

    if self.isRefreshEnabled == false then
        return;
    end

    self:UpdateVendorViewLayout()
end


function VendorMateMixin:SetupVendorView()

    local vendor = self.content.vendor;

    vendor.nameArtRight:SetRotation(3.14)

    vendor.tilesGridviewContainer.scrollChild:SetSize(vendor:GetWidth(), vendor:GetHeight())

    vendor.tilesGridview = Gridview:New(vendor.tilesGridviewContainer.scrollChild, "VendorMateVendorGridviewItemTemplate")
    vendor.tilesGridview:SetMinMaxWidths(250, 260)

    vendor.newFilterName.label:SetText(ADD_FILTER)
    vendor.newFilterName:SetScript("OntextChanged", function(eb)
        if #eb:GetText() > 0 then
            vendor.addFilter:Show()
            eb.label:Hide()
        else
            vendor.addFilter:Hide()
            eb.label:Show()
        end
    end)

    local function addFilter()
        local name = vendor.newFilterName:GetText()
    
        local prio = #self.selectedProfile.vendor.filters + 1;
        local filter = {
            priority = prio,
            name = name,
            pkey = time(),
            items = {},
            rules = {
                quality = "any",
                classID = "any",
                subClassID = "any",
                ignorePriority = false,
                minEffectiveIlvl = 1,
                maxEffectiveIlvl = 500,
                inventoryType = "any",
                tier = "any",
                bindingType = "any",
                isBound = "any",
            },
        }
        if type(self.selectedProfile) == "table" then
            table.insert(self.selectedProfile.vendor.filters, filter)
            vendor.newFilterName:SetText("")
            vm:TriggerEvent("Profile_OnFilterAdded", filter)
        end
    end

    vendor.newFilterName:SetScript("OnEnterPressed", addFilter)
    vendor.addFilter:SetScript("OnClick", addFilter)

    vendor.deleteAllFilters:SetText(string.format("%s %s", DELETE, FILTERS))
    vendor.vendorAllFilters:SetText(string.format("%s %s", TRANSMOG_SOURCE_3, ALL))

    vendor.vendorAllFilters:SetScript("OnClick", function()

        local vendorItems = {}
        for filterPkey, items in pairs(self.itemsToVendor) do
            for k, v in ipairs(items) do
                table.insert(vendorItems, v)
            end
        end
        local i = #vendorItems;
        C_Timer.NewTicker(0.2, function()
            local item = vendorItems[i]

            if not item then
                return;
            end

            if item.ignore == false then

                C_Item.UnlockItemByGUID(item.guid)
                C_Container.UseContainerItem(item.bagID, item.slotID)

            end

            i = i - 1;

            if i == 0 then
                self:IterAllFilters()
                self:UpdateVendorFilters()
            end

        end, #vendorItems)

    end)

    vendor:SetScript("OnShow", function()
        self:UpdateVendorViewLayout()
        self:IterAllFilters()
        self:UpdateVendorFilters()
    end)

end



function VendorMateMixin:UpdateVendorViewLayout()
    local vendorGridviewWidth = self.content.vendor.tilesGridviewContainer:GetWidth()
    self.content.vendor.tilesGridviewContainer.scrollChild:SetWidth(vendorGridviewWidth)
    self.content.vendor.tilesGridview:UpdateLayout()

    local vendorWidth = self.content.vendor:GetWidth()
    vendorWidth = vendorWidth - 26
    self.content.vendor.newFilterName:SetWidth(vendorWidth / 3)
    self.content.vendor.deleteAllFilters:SetWidth(vendorWidth / 3)
    self.content.vendor.vendorAllFilters:SetWidth(vendorWidth / 3)
end


function VendorMateMixin:SetupOptionsView()

    local options = self.content.options;

    local profiles = Database:GetProfiles()
    local t = {}
    for k, profile in ipairs(profiles) do
        table.insert(t, {
            text = profile.pkey,
            func = function()
                vm:TriggerEvent("Profile_OnChanged", profile)
            end
        })
    end
    options.selectProfileDropdown:SetMenu(t)
    options.selectProfileDropdownLabel:SetText(CHARACTER)


    options.resetSavedVariables:SetScript("OnClick", function()
        
        Database:ResetAddon()
        self:GenerateDefaultProfile()

        local profiles = Database:GetProfiles()
        local t = {}
        for k, profile in ipairs(profiles) do
            table.insert(t, {
                text = profile.pkey,
                func = function()
                    vm:TriggerEvent("Profile_OnChanged", profile)
                end
            })
        end
        options.selectProfileDropdown:SetMenu(t)

        self.content.vendor.tilesGridview:Flush()
    end)


end

function VendorMateMixin:GenerateDefaultProfile()

    local defaultPrimaryKey = string.format("%s.%s.%s", self.character.name, self.character.realm, CHAT_DEFAULT);
    local defaultProfileExists = false;
    for k, profile in ipairs(Database:GetProfiles()) do
        if profile.pkey == defaultPrimaryKey then
            defaultProfileExists = true;
        end
    end
    if defaultProfileExists == false then
        Database:NewProfile({
            pkey = defaultPrimaryKey,
            class = self.character.class,
            name = self.character.name,
            vendor = {
                filters = {
                    {
                        pkey = time(),
                        priority = 0,
                        name = BAG_FILTER_JUNK,
                        items = {},
                        rules = {
                            quality = 0,
                            classID = "any",
                            subClassID = "any",
                            ignorePriority = false,
                            minEffectiveIlvl = 1,
                            maxEffectiveIlvl = 500,
                            inventoryType = "any",
                            tier = "any",
                            bindingType = "any",
                            isBound = "any",
                        },
                    }
                },
            },
            history = {},
        })
    end

end

function VendorMateMixin:Player_OnEnteringWorld(character)

    self.character = character;

    self:SetupVendorView()
    self:SetupOptionsView()

    self:GenerateDefaultProfile()

    local defaultProfile = Database:GetProfile(string.format("%s.%s.%s", character.name, character.realm, CHAT_DEFAULT))
    vm:TriggerEvent("Profile_OnChanged", defaultProfile)

    self:UpdateVendorViewLayout()

    self:SetScript("OnHide", function()

    end)
    self:SetScript("OnShow", function()
        self:PlayerBags_OnItemsChanged()
    end)
end


function VendorMateMixin:Merchant_OnShow()
    self:Show()
    PanelTemplates_SetTab(self, 1);
    self:UpdateVendorViewLayout()
end


function VendorMateMixin:Merchant_OnHide()
    self:UnlockAllBagSlots()
    self:Hide()
end


function VendorMateMixin:Profile_OnChanged(newProfile)
    self.selectedProfile = newProfile;
    self.content.vendor.name:SetText(self.selectedProfile.pkey)

    if self.content.vendor.tilesGridview then
        self.content.vendor.tilesGridview:Flush()

        local filters = self.selectedProfile.vendor.filters;
        for k, filter in ipairs(filters) do
            self.content.vendor.tilesGridview:Insert({
                filter = filter,
            })
        end
    end

    Database:SetConfig("currentProfile", newProfile.pkey)
end


function VendorMateMixin:Profile_OnFilterAdded(filter)

    self.content.vendor.tilesGridview:Insert({
        filter = filter,
    })

    self:IterAllFilters()
    self:UpdateVendorFilters()
end


function VendorMateMixin:Profile_OnFilterRemoved(filter)

    if filter.pkey then
        if type(self.selectedProfile) == "table" then
            local key;
            for k, v in ipairs(self.selectedProfile.vendor.filters) do
                if filter.pkey == v.pkey then
                    key = k;
                end
            end
            if type(key) == "number" then

                table.remove(self.selectedProfile.vendor.filters, key)

                -- adjust priorities for filters, these should follow the ipairs order
                for k, v in ipairs(self.selectedProfile.vendor.filters) do
                    v.priority = k;
                end

                self:IterAllFilters()
                self:UpdateVendorFilters()
            end
        end

        local gridview = self.content.vendor.tilesGridview
        for k, tile in ipairs(gridview:GetFrames()) do
            if filter.pkey == tile:GetFilterPkey() then
                gridview:RemoveFrame(tile)
            end
        end
    end
end


function VendorMateMixin:Filter_OnChanged()
    self:IterAllFilters()
    self:UpdateVendorFilters()
end


function VendorMateMixin:Filter_OnIgnoredChanged(item)
    self.isItemIgnored[item.guid] = item.ignore
    self:IterAllFilters()
    self:UpdateVendorFilters_InfoOnly()
end



function VendorMateMixin:UnlockAllBagSlots()
    for k, item in ipairs(self.playerBags) do
        C_Item.UnlockItemByGUID(item.guid)
    end
end


-- iter all filters and return a table of items, sorted into filters
function VendorMateMixin:IterAllFilters()

    -- first unlock all items
    self:UnlockAllBagSlots()

    -- helper tables
    local itemsFiltered = {}

    self.itemsToVendor = {}

    -- these functions provide the basis of item filtering based on filter rules
    local function generateItemMinEffectiveIlvlCheck(rule)
        return function(item)
            if type(rule.minEffectiveIlvl) == "number" then
                return (item.effectiveIlvl >= rule.minEffectiveIlvl)
            else
                return false;
            end
        end
    end
    local function generateItemMaxEffectiveIlvlCheck(rule)
        return function(item)
            if type(rule.maxEffectiveIlvl) == "number" then
                return (item.effectiveIlvl <= rule.maxEffectiveIlvl)
            else
                return false;
            end
        end
    end
    local function generateItemQualityCheck(rule)
        return function(item)
            if rule.quality == "any" then
                return true;
            else
                return (item.quality == rule.quality)
            end
        end
    end
    local function generateItemClassIdCheck(rule)
        return function(item)
            if rule.classID == "any" then
                return true
            else
                return item.classID == rule.classID and (rule.subClassID == "any" or item.subClassID == rule.subClassID)
            end
        end
    end
    local function generateItemSubClassIdCheck(rule)
        return function(item)
            if rule.subClassID == "any" then
                return true
            else
                return (item.classID == rule.classID and item.subClassID == rule.subClassID)
            end
        end
    end
    local function generateItemInventoryTypeCheck(rule)
        return function(item)
            if rule.inventoryType == "any" then
                return true;
            else
                return (item.inventoryType == rule.inventoryType)
            end
        end
    end
    local function generateItemIsBoundTypeCheck(rule)
        return function(item)
            if (rule.bindingType == "any") and (rule.isBound == "any") then
                return true;
            else
                
                -- was boe, now boe
                if (rule.isBound == false) and (item.isBound == false) and (rule.bindingType == 2) and (item.bindingType == 2) then
                    return true
                end

                -- was boe, now sb
                if (rule.isBound == true) and (item.isBound == true) and (rule.bindingType == 2) and (item.bindingType == 2) then
                    return true
                end

                -- soulbound
                if (rule.isBound == true) and (item.isBound == true) and (rule.bindingType == 1) and (item.bindingType == 1) then
                    return true
                end

                -- soulbound
                if (rule.isBound == true) and (item.isBound == true) and (rule.bindingType == "any") then
                    return true
                end
            end
            return false;
        end
    end

    -- grab the current profile tiles
    local filters = self.selectedProfile.vendor.filters;

    -- get the correct filter priority order
    table.sort(filters, function(a,b)
        return a.priority < b.priority;
    end)

    local goldAllFilters = 0;
    local itemsAllFilters = 0;
    local stacksAllFilters = 0;

    -- loop each filter and scan player bag items applying the filter rules
    for k, filter in ipairs(filters) do

        -- items for current filter
        self.itemsToVendor[filter.pkey] = {}

        -- setup checks for the current filter rules
        local ruleChecks = {
            generateItemMinEffectiveIlvlCheck(filter.rules),
            generateItemMaxEffectiveIlvlCheck(filter.rules),
            generateItemQualityCheck(filter.rules),
            generateItemClassIdCheck(filter.rules),
            generateItemSubClassIdCheck(filter.rules),
            generateItemInventoryTypeCheck(filter.rules),
            generateItemIsBoundTypeCheck(filter.rules),
        }

        -- scan player bags for items that comply with filter rules
        for k, item in ipairs(self.playerBags) do
            if not itemsFiltered[item.guid] then
                local match = true
                for k, check in ipairs(ruleChecks) do
                    if not check(item) then
                        match = false
                    end
                end
                if match then
                    C_Item.LockItemByGUID(item.guid)
                    table.insert(self.itemsToVendor[filter.pkey], item)

                    if item.ignore == false then
                        goldAllFilters = goldAllFilters + (item.count * item.vendorPrice)
                        itemsAllFilters = itemsAllFilters + item.count;
                        stacksAllFilters = stacksAllFilters + 1;
                    end

                    itemsFiltered[item.guid] = true;
                end
            end
        end

        -- apply some basic sorting to items
        table.sort(self.itemsToVendor[filter.pkey], function(a, b)
            if a.name == b.name then
                if a.quality == b.quality then
                    if a.classID == b.classID then
                        return a.subClassID < b.subClassID
                    else
                        return a.classID < b.classID
                    end
                else
                    return a.quality > b.quality
                end
            else
                return a.name < b.name;
            end
        end)

    end

    self.content.vendor.allFiltersInfo:SetText(string.format("%s %s - %s %s - %s %s - %s", #filters, "Filters", stacksAllFilters, "Stacks", itemsAllFilters, "items", GetCoinTextureString(goldAllFilters)))

end


function VendorMateMixin:UpdateVendorFilters()
    local gridviewItems = self.content.vendor.tilesGridview:GetFrames()
    for k, tile in ipairs(gridviewItems) do
        local pkey = tile:GetFilterPkey()
        if self.itemsToVendor[pkey] then

            tile:UpdateItems(self.itemsToVendor[pkey])

            local gold = 0
            local items = 0
            local stacks = 0

            for k, item in ipairs(self.itemsToVendor[pkey]) do            
                if item.ignore == false then
                    gold = gold + (item.count * item.vendorPrice)
                    items = items + item.count;
                    stacks = stacks + 1;
                end
            end

            tile:SetInfoText({
                gold = gold,
                numItems = items,
                numSlots = stacks,
            })
        end
    end
end


function VendorMateMixin:UpdateVendorFilters_InfoOnly()
    local gridviewItems = self.content.vendor.tilesGridview:GetFrames()
    for k, tile in ipairs(gridviewItems) do
        local pkey = tile:GetFilterPkey()
        if self.itemsToVendor[pkey] then
            local gold = 0
            local items = 0
            local stacks = 0

            for k, item in ipairs(self.itemsToVendor[pkey]) do            
                if item.ignore == false then
                    gold = gold + (item.count * item.vendorPrice)
                    items = items + item.count;
                    stacks = stacks + 1;
                end
            end

            tile:SetInfoText({
                gold = gold,
                numItems = items,
                numSlots = stacks,
            })
        end
    end
end


function VendorMateMixin:PlayerBags_OnItemsChanged()

    if not self:IsVisible() then
        return;
    end

    self.playerBags = {};

    local usedSlots = 0;
    
    for bag = 0, NUM_PLAYER_BAGS do        
        usedSlots = usedSlots + (C_Container.GetContainerNumSlots(bag) - C_Container.GetContainerNumFreeSlots(bag))
    end
    
    local slotsQueried = 0;
    for bag = 0, NUM_PLAYER_BAGS do
        
        for slot = 1, C_Container.GetContainerNumSlots(bag) do

            local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if location:IsValid() then

                local info = {};

                info.guid = C_Item.GetItemGUID(location)

                if not self.isItemIgnored[info.guid] then
                    self.isItemIgnored[info.guid] = false;
                end

                info.ignore = self.isItemIgnored[info.guid];

                info.bagID = bag;
                info.slotID = slot;

                info.count = C_Item.GetStackCount(location)
                info.inventoryType = C_Item.GetItemInventoryType(location)
                info.isBound = C_Item.IsBound(location)


                local item = Item:CreateFromBagAndSlot(bag, slot)
                if not item:IsItemEmpty() then
                    item:ContinueOnItemLoad(function()

                        info.name = item:GetItemName()
                        info.link = item:GetItemLink()
                        info.quality = item:GetItemQuality()

                        info.vendorPrice = (select(11, GetItemInfo(info.link)))

                        local effectiveILvl, isPreview, baseILvl = GetDetailedItemLevelInfo(info.link)
                        info.effectiveIlvl = effectiveILvl

                        local _, _, _, _, icon, classID, subClassID = GetItemInfoInstant(info.link)

                        info.bindingType = select(14, GetItemInfo(info.link))

                        info.icon = icon
                        info.classID = classID
                        info.subClassID = subClassID

                        table.insert(self.playerBags, info)

                        slotsQueried = slotsQueried + 1;
                        if slotsQueried == usedSlots then
                            self:IterAllFilters()
                            self:UpdateVendorFilters()
                        end

                    end)
                end
            end
        end
    end

end