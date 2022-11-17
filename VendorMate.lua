

local addonName, vm = ...;

local Gridview = vm.gridview;
local Database = vm.database;

local NUM_PLAYER_BAGS = 4;

local L = vm.locales;

function vm:debug(...)
    local data = ...;
    if (data) then
        if (type(data) == "table") then
            UIParentLoadAddOn("Blizzard_DebugTools");
            --DevTools_Dump(data);
            DisplayTableInspectorWindow(data);
        else
            print(string.format("[%s] DEBUG: ", addonName), ...);
        end
    end
end



VendorMateDropdownCustomFrameSliderMixin = {}

function VendorMateDropdownCustomFrameSliderMixin:OnLoad()

    local name = self.minEffectiveIlvl:GetName()
    _G[name.."Low"]:SetText(nil)
    _G[name.."High"]:SetText(nil)

    local name = self.maxEffectiveIlvl:GetName()
    _G[name.."Low"]:SetText(nil)
    _G[name.."High"]:SetText(nil)


    self.minEffectiveIlvl:SetScript("OnMouseWheel", function(_, delta)
        self.minEffectiveIlvl:SetValue(self.minEffectiveIlvl:GetValue() + delta)
    end)
    self.maxEffectiveIlvl:SetScript("OnMouseWheel", function(_, delta)
        self.maxEffectiveIlvl:SetValue(self.maxEffectiveIlvl:GetValue() + delta)
    end)

    self.minEffectiveIlvl:SetScript("OnValueChanged", function()
        self.minEffectiveIlvlLabel:SetText(math.ceil(self.minEffectiveIlvl:GetValue()))
        if self.tile then
            self.tile.rules.minEffectiveIlvl = math.ceil(self.minEffectiveIlvl:GetValue())
        end
        vm:TriggerEvent("Filter_OnChanged")
    end)
    self.maxEffectiveIlvl:SetScript("OnValueChanged", function()
        self.maxEffectiveIlvlLabel:SetText(math.ceil(self.maxEffectiveIlvl:GetValue()))
        if self.tile then
            self.tile.rules.maxEffectiveIlvl = math.ceil(self.maxEffectiveIlvl:GetValue())
        end
        vm:TriggerEvent("Filter_OnChanged")
    end)

end





VendorMateMixin = {
    playerBags = {},
    isRefreshEnabled = false,
}

function VendorMateMixin:OnLoad()

    SLASH_VENDORMATE1 = '/vendormate'
    SLASH_VENDORMATE2 = '/vm8'
    SlashCmdList['VENDORMATE'] = function(msg)
        self:Show()
    end

    vm:RegisterCallback("Player_OnEnteringWorld", self.Player_OnEnteringWorld, self)
    vm:RegisterCallback("Merchant_OnShow", self.Merchant_OnShow, self)
    vm:RegisterCallback("PlayerBags_OnItemsChanged", self.PlayerBags_OnItemsChanged, self)
    vm:RegisterCallback("Filter_OnChanged", self.Filter_OnChanged, self)
    vm:RegisterCallback("Profile_OnFilterRemoved", self.Profile_OnFilterRemoved, self)
    vm:RegisterCallback("Profile_OnFilterAdded", self.Profile_OnFilterAdded, self)
    vm:RegisterCallback("Profile_OnChanged", self.Profile_OnChanged, self)
    vm:RegisterCallback("Filter_OnAllItemsSold", self.Filter_OnAllItemsSold, self)


    self:RegisterForDrag("LeftButton")
    self.resize:Init(self, 400, 400, 800, 600)

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

    vendor.name:SetText("")

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
    
        local prio = #self.selectedProfile.vendor.tiles + 1;
        local tile = {
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
            },
        }
        if type(self.selectedProfile) == "table" then
            table.insert(self.selectedProfile.vendor.tiles, tile)
            vendor.newFilterName:SetText("")
            vm:TriggerEvent("Profile_OnFilterAdded")
        end
    end

    vendor.newFilterName:SetScript("OnEnterPressed", addFilter)
    vendor.addFilter:SetScript("OnClick", addFilter)

    vendor.deleteAllFilters:SetText(string.format("%s %s", DELETE, FILTERS))
    vendor.vendorAllFilters:SetText(string.format("%s %s", TRANSMOG_SOURCE_3, ALL))

    vendor.vendorAllFilters:SetScript("OnClick", function()
    
        local filters = vendor.tilesGridview:GetFrames()
        filters[1]:VendorAllItems()

        -- set this to try vendoring filter 2 as filter 1 was just processed
        self.nextFilterToVendor = 2

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
                tiles = {
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

    self:GenerateDefaultProfile()

    self:SetupVendorView()
    self:SetupOptionsView()

    self:UpdateVendorViewLayout()

    local defaultProfile = Database:GetProfile(string.format("%s.%s.%s", character.name, character.realm, CHAT_DEFAULT))
    vm:TriggerEvent("Profile_OnChanged", defaultProfile)

    self:SetScript("OnHide", function()

    end)
    self:SetScript("OnShow", function()
        self:PlayerBags_OnItemsChanged()
        self:UpdateFilters()
    end)
end


function VendorMateMixin:Merchant_OnShow()
    self:Show()
    PanelTemplates_SetTab(self, 1);
    self:UpdateVendorViewLayout()
    self:UpdateFilters()
end


function VendorMateMixin:Profile_OnChanged(newProfile)
    self.content.vendor.tilesGridview:Flush()
    self.selectedProfile = newProfile;
    self.content.vendor.name:SetText(self.selectedProfile.pkey)
    self:UpdateFilters()
end


function VendorMateMixin:Profile_OnFilterAdded()
    self:UpdateFilters()
end


function VendorMateMixin:Profile_OnFilterRemoved(tile)
    self.content.vendor.tilesGridview:Flush()
    if tile.pkey then
        if type(self.selectedProfile) == "table" then
            local key;
            for k, v in ipairs(self.selectedProfile.vendor.tiles) do
                if tile.pkey == v.pkey then
                    key = k;
                end
            end
            if type(key) == "number" then

                table.remove(self.selectedProfile.vendor.tiles, key)

                -- adjust priorities for filters, these should follow the ipairs order
                for k, v in ipairs(self.selectedProfile.vendor.tiles) do
                    v.priority = k;
                end

                self:UpdateFilters()
            end
        end
    end
end


function VendorMateMixin:Filter_OnChanged()
    self:UpdateFilters()
end




function VendorMateMixin:Filter_OnAllItemsSold()

    local filters = self.content.vendor.tilesGridview:GetFrames()

    if filters[self.nextFilterToVendor] then
        filters[self.nextFilterToVendor]:VendorAllItems()
        self.nextFilterToVendor = self.nextFilterToVendor + 1;
    end
    
end


-- this should update all tiles listviews of items and total gold value
function VendorMateMixin:UpdateFilters()

    -- first unlock all items
    for k, item in ipairs(self.playerBags) do
        C_Item.UnlockItemByGUID(item.guid)
    end
    
    -- grab the current profile tiles
    local tiles = self.selectedProfile.vendor.tiles;

    -- get the correct tile priority order
    table.sort(tiles, function(a,b)
        return a.priority < b.priority;
    end)

    -- helper tables
    local items = {}
    local itemsFiltered = {}

    -- these functions provide the basis of item filtering based on tile rules
    local function generateItemMinEffectiveIlvlCheck(rule)
        return function(item)
            return (item.effectiveIlvl >= rule.minEffectiveIlvl)
        end
    end
    local function generateItemMaxEffectiveIlvlCheck(rule)
        return function(item)
            return (item.effectiveIlvl <= rule.maxEffectiveIlvl)
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

    local gridviewItems = self.content.vendor.tilesGridview:GetFrames()

    -- loop each tile and scan player bag items applying the tile rules
    for k, tile in ipairs(tiles) do

        -- items for current tile
        items[tile.pkey] = {}

        -- setup checks for the current tile rules
        local ruleChecks = {
            generateItemMinEffectiveIlvlCheck(tile.rules),
            generateItemMaxEffectiveIlvlCheck(tile.rules),
            generateItemQualityCheck(tile.rules),
            generateItemClassIdCheck(tile.rules),
            generateItemSubClassIdCheck(tile.rules),
            generateItemInventoryTypeCheck(tile.rules),
        }

        -- scan player bags for items that comply with tile rules
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
                    table.insert(items[tile.pkey], item)
                    itemsFiltered[item.guid] = true;
                end
            end
        end

        -- apply some basic sorting to items
        table.sort(items[tile.pkey], function(a, b)
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

        -- add to gridview
        if not gridviewItems[k] then
            self.content.vendor.tilesGridview:Insert({
                tile = tile,
            })
        end

    end

    for k, tile in ipairs(gridviewItems) do
        local pkey = tile:GetTilePkey()
        if items[pkey] then
            tile:UpdateItems(items[pkey])
        end
    end

    --self.content.vendor.tilesGridview:UpdateLayout()

end



function VendorMateMixin:PlayerBags_OnItemsChanged()

    if vm.vendorLocked == true then
        return;
    end

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

                info.bagID = bag;
                info.slotID = slot;

                info.guid = C_Item.GetItemGUID(location)
                info.count = C_Item.GetStackCount(location)
                info.inventoryType = C_Item.GetItemInventoryType(location)

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

                        info.icon = icon
                        info.classID = classID
                        info.subClassID = subClassID

                        table.insert(self.playerBags, info)

                        slotsQueried = slotsQueried + 1;
                        if slotsQueried == usedSlots then
                            self:UpdateFilters()
                        end

                    end)
                end
            end
        end
    end

end