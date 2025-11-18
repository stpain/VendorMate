

local addonName, vm = ...;

local Gridview = vm.gridview;
local Database = vm.database;

local NUM_PLAYER_BAGS = 4;

local L = vm.locales;


local MainNineSliceLayout =
{
    TopLeftCorner =	{ atlas = "UI-Frame-DiamondMetal-CornerTopLeft", x = -5, y = 5 },
    TopRightCorner =	{ atlas = "UI-Frame-DiamondMetal-CornerTopRight", x = 5, y = 5 },
    BottomLeftCorner =	{ atlas = "UI-Frame-DiamondMetal-CornerBottomLeft", x = -5, y = -5 },
    BottomRightCorner =	{ atlas = "UI-Frame-DiamondMetal-CornerBottomRight", x = 5, y = -5 },
    TopEdge = { atlas = "_UI-Frame-DiamondMetal-EdgeTop", },
    BottomEdge = { atlas = "_UI-Frame-DiamondMetal-EdgeBottom", },
    LeftEdge = { atlas = "!UI-Frame-DiamondMetal-EdgeLeft", },
    RightEdge = { atlas = "!UI-Frame-DiamondMetal-EdgeRight", },
    Center = { layer = "BACKGROUND", atlas = "Tooltip-Glues-NineSlice-Center", x = -20, y = 20, x1 = 20, y1 = -20 },
}


VendorMateMixin = {
    playerBags = {},
    isRefreshEnabled = false,
    isItemIgnored = {};
    isVendoringActive = false;
    bagLocationToItem = {},
    bagLinkToItem = {},
    playerGold = 0,
    temporaryTransaction = {},
    history = {
        selectedProfile = {},
        transactionType = ""
    },
}



function VendorMateMixin:OnLoad()

    SLASH_VENDORMATE1 = '/vendormate'
    SLASH_VENDORMATE2 = '/vm8'
    SlashCmdList['VENDORMATE'] = function(msg)
        self:Show()
    end

    NineSliceUtil.ApplyLayout(self, MainNineSliceLayout)

    vm:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self)
    vm:RegisterCallback("Database_OnTransactionDeleted", self.Database_OnTransactionDeleted, self)
    vm:RegisterCallback("Player_OnEnteringWorld", self.Player_OnEnteringWorld, self)
    vm:RegisterCallback("Player_OnMoneyChanged", self.Player_OnMoneyChanged, self)
    vm:RegisterCallback("Merchant_OnShow", self.Merchant_OnShow, self)
    vm:RegisterCallback("Merchant_OnHide", self.Merchant_OnHide, self)
    vm:RegisterCallback("PlayerBags_OnItemsChanged", self.PlayerBags_OnItemsChanged, self)
    vm:RegisterCallback("Filter_OnChanged", self.Filter_OnChanged, self)
    vm:RegisterCallback("Profile_OnFilterRemoved", self.Profile_OnFilterRemoved, self)
    vm:RegisterCallback("Profile_OnFilterAdded", self.Profile_OnFilterAdded, self)
    vm:RegisterCallback("Profile_OnChanged", self.Profile_OnChanged, self)
    vm:RegisterCallback("Profile_OnDelete", self.Profile_OnDelete, self)
    vm:RegisterCallback("Filter_OnIgnoredChanged", self.Filter_OnIgnoredChanged, self)
    vm:RegisterCallback("Filter_OnVendorStart", self.Filter_OnVendorStart, self)
    vm:RegisterCallback("Filter_OnVendorFinished", self.Filter_OnVendorFinished, self)
    vm:RegisterCallback("Filter_OnItemsAddedToMail", self.Filter_OnItemsAddedToMail, self)
    vm:RegisterCallback("Vendor_OnTransactionStart", self.Vendor_OnTransactionStart, self)
    vm:RegisterCallback("Vendor_OnTransactionFinish", self.Vendor_OnTransactionFinish, self)
    vm:RegisterCallback("Database_OnMerchantOrderItemAdded", self.Database_OnMerchantOrderItemAdded, self)
    vm:RegisterCallback("Database_OnMerchantOrderItemDeleted", self.Database_OnMerchantOrderItemDeleted, self)


    self:RegisterForDrag("LeftButton")
    self.resize:Init(self, 400, 400, 800, 620)

    self.resize:HookScript("OnMouseDown", function()
        self.isRefreshEnabled = true;
    end)
    self.resize:HookScript("OnMouseUp", function()
        self.isRefreshEnabled = false;
    end)

    local function OnTabSelected(tabID)
        self:TabView(tabID)
    end

    self.TabSystem:SetTabSelectedCallback(OnTabSelected)
    self.TabSystem:AddTab(L.TABS_VENDOR)
    self.TabSystem:AddTab(L.TABS_AUTO_MERCHANT)
    self.TabSystem:AddTab(L.TABS_HISTORY)
    self.TabSystem:AddTab(L.TABS_OPTIONS)
    self.TabSystem:SetTab(1)


    self.help:SetScript("OnMouseDown", function()
        
        for k, tip in ipairs(self.content.vendor.helptips) do
            tip:SetShown(not tip:IsVisible())
        end

        -- AuraUtil.ForEachAura("player", "HELPFUL", nil, function(...)
        --     DevTools_Dump({...})
        -- end)

    end)

    local function ProcessDetails(bag, slot)
        self:OnContainerItemUsed(bag, slot)
    end

    -- keep this incase of classic compat
    if C_Container and C_Container.UseContainerItem then
        hooksecurefunc(C_Container, "UseContainerItem", ProcessDetails)
    else
        hooksecurefunc(_G, "UseContainerItem", ProcessDetails)
    end


    -- hooksecurefunc(_G, "MerchantFrame_UpdateBuybackInfo", function()
    
    --     local buyBackLink = GetBuybackItemLink(GetNumBuybackItems())

    --     local item = self.bagLinkToItem[buyBackLink]
    --     if item then
    --         vm:TriggerEvent("Filter_OnItemSold", item.bagID, item.slotID)
    --     end

    -- end)

    self.content.vendor.filterGridview:InitFramePool("FRAME", "VendorMateVendorGridviewItemTemplate")
    self.content.vendor.filterGridview:SetMinMaxSize(250, 260)


    self.content.history:SetScript("OnShow", function()
        self:UpdateHistoryView()
    end)

    self:SetupMerchantTab()

end

function VendorMateMixin:Database_OnInitialised()
    Database:AddConfig("autoVendorJunk", false)
    self:SetupHistoryView()
end

function VendorMateMixin:Database_OnTransactionDeleted()
    self:UpdateHistoryView()
end

function VendorMateMixin:Vendor_OnTransactionStart()

    local vendor = MerchantFrameTitleText:GetText() or "-"

    self.temporaryTransaction = {
        vendor = vendor,
        items = {},
        profile = self.selectedProfile.pkey,
    }
end

function VendorMateMixin:Vendor_OnTransactionFinish()
    
    local transaction = {}
    transaction.profile = self.temporaryTransaction.profile;
    transaction.vendor = self.temporaryTransaction.vendor;

    local transactionValue = 0;
    local transactionItems = {}

    for link, info in pairs(self.temporaryTransaction.items) do
        transactionValue = transactionValue + info.vendorPrice;
        table.insert(transactionItems, {
            link = info.link,
            count = info.count,
            vendorPrice = info.vendorPrice
        })
    end

    transaction.items = transactionItems;
    transaction.value = transactionValue;
    transaction.timestamp = time()
    transaction.action = "vendor"

    Database:AddTransaction(transaction)

    self.temporaryTransaction = {}
end

function VendorMateMixin:Player_OnMoneyChanged(gold)
    
end

function VendorMateMixin:OnContainerItemUsed(bag, slot)

    local item = self.bagLocationToItem[string.format("%s-%s", bag, slot)]

    if not item then
        return;
    end


    if MerchantFrame:IsVisible() then

        --print(item.itemID)

        --print(string.format("%s %s %s %s", item.itemID, item.link, item.count, GetCoinTextureString(item.vendorPrice * item.count)))

        if self.temporaryTransaction.items then
            if not self.temporaryTransaction.items[item.itemID] then
                self.temporaryTransaction.items[item.itemID] = {
                    count = item.count,
                    vendorPrice = item.vendorPrice * item.count,
                    link = item.link,
                }
                --print("new id")
            else
                self.temporaryTransaction.items[item.itemID].count = self.temporaryTransaction.items[item.itemID].count + 1
                --print(GetCoinTextureString(self.temporaryTransaction.items[item.itemID].vendorPrice))
                self.temporaryTransaction.items[item.itemID].vendorPrice = self.temporaryTransaction.items[item.itemID].vendorPrice + (item.count * item.vendorPrice)
                --print(GetCoinTextureString(self.temporaryTransaction.items[item.itemID].vendorPrice), GetCoinTextureString(item.count * item.vendorPrice))
                --print("updated id")
            end 
        end

        --local vendor = MerchantFrameTitleText:GetText() or "-"

        vm:TriggerEvent("Filter_OnItemSold", bag, slot)

    end

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

function VendorMateMixin:UpdateVendorViewProfileDropdown()
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
    self.content.vendor.selectProfileDropdown:SetMenu(t)
end

function VendorMateMixin:SetupVendorView()

    local vendor = self.content.vendor;

    vendor.filterHelptip:SetText(L.HELPTIP_VENDOR_FILTERS)
    vendor.profileSelectHelptip:SetText(L.HELPTIP_VENDOR_PROFILES)

    self:UpdateVendorViewProfileDropdown()

    vendor.deleteProfile:SetScript("OnClick", function()
        if self.selectedProfile then
            StaticPopup_Show("VendorMateDialogDeleteProfileConfirm", self.selectedProfile.pkey, nil, self.selectedProfile)
        end
    end)

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
                maxEffectiveIlvl = 800,
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

    vendor.deleteAllFilters:SetScript("OnClick", function()
        if type(self.selectedProfile) == "table" then
            self.selectedProfile.filters = {};
            self.content.vendor.filterGridview:Flush()
        end
    end)


    vendor.vendorAllFilters:SetText(string.format("%s %s", TRANSMOG_SOURCE_3, ALL))

    vendor.vendorAllFilters:SetScript("OnClick", function()

        self.isVendoringActive = true;

        local vendorItems = {}
        local numFilters = 0;
        local gold = 0;
        local slots = 0;
        local numItems = 0;
        for filterPkey, items in pairs(self.itemsToVendor) do
            numFilters = numFilters + 1;
            for k, item in ipairs(items) do
                if item.ignore == false then
                    gold = gold + item.count * item.vendorPrice;
                    slots = slots + 1;
                    numItems = numItems + item.count;
                    table.insert(vendorItems, item)
                end
            end
        end

        StaticPopup_Show("VendorMateDialogVendorItemsConfirm", ALL, string.format("%s %s - %s %s - %s %s\n\n%s", numFilters, FILTERS, slots, "Slots", numItems, ITEMS, C_CurrencyInfo.GetCoinTextureString(gold)) or "-", vendorItems)

    end)

    vendor:SetScript("OnShow", function()
        self:UpdateVendorViewLayout()
        self:IterAllFilters()
        self:UpdateVendorFilters()
    end)

end



function VendorMateMixin:UpdateVendorViewLayout()
    self.content.vendor.filterGridview:UpdateLayout()

    local vendorWidth = self.content.vendor:GetWidth()
    vendorWidth = vendorWidth - 26
    self.content.vendor.newFilterName:SetWidth(vendorWidth / 3)
    self.content.vendor.deleteAllFilters:SetWidth(vendorWidth / 3)
    self.content.vendor.vendorAllFilters:SetWidth(vendorWidth / 3)

    local autoVendorJunk = Database:GetConfig("autoVendorJunk")

end


function VendorMateMixin:SetupOptionsView()

    local options = self.content.options;

    options.helpAbout:SetText(L.HELP_ABOUT)

    options.newProfile:SetScript("OnTextChanged", function(eb)
        if #eb:GetText() > 0 then
            eb.addProfile:Show()
            eb.label:Hide()
        else
            eb.addProfile:Hide()
            eb.label:Show()
        end
    end)
    options.newProfile.addProfile:SetScript("OnClick", function()
        local text = options.newProfile:GetText()
        if #text > 0 and text ~= " " then
            self:GenerateProfile(text)
            options.newProfile:SetText("")
        end
    end)

    options.autoVendorJunk.label:SetText(L.AUTO_VENDOR_JUNK)
    options.autoVendorJunk:SetChecked(Database:GetConfig("autoVendorJunk") or false)
    options.autoVendorJunk:SetScript("OnClick", function(cb)
        Database:SetConfig("autoVendorJunk", cb:GetChecked())
    end)


    options.resetSavedVariables:SetScript("OnClick", function()
        
        Database:ResetAddon()
        self:GenerateProfile()

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
        self.content.vendor.selectProfileDropdown:SetMenu(t)

        self.content.vendor.filterGridview:Flush()
    end)


end

function VendorMateMixin:GenerateProfile(profileName)

    if not profileName then
        profileName = CHAT_DEFAULT
    end

    local profilePk = string.format("%s.%s.%s", self.character.name, self.character.realm, profileName);
    local defaultProfileExists = false;
    for k, profile in ipairs(Database:GetProfiles()) do
        if profile.pkey == profilePk then
            defaultProfileExists = true;
        end
    end
    if defaultProfileExists == false then
        Database:NewProfile({
            pkey = profilePk,
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
                            maxEffectiveIlvl = 800,
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
        self:UpdateVendorViewProfileDropdown()
    end

end

function VendorMateMixin:Player_OnEnteringWorld(character)

    self.character = character;

    self:SetupVendorView()
    self:SetupOptionsView()

    self:GenerateProfile()

    local defaultProfile = Database:GetProfile(string.format("%s.%s.%s", self.character.name, self.character.realm, CHAT_DEFAULT))
    vm:TriggerEvent("Profile_OnChanged", defaultProfile)

    if defaultProfile.merchant then
        self:Database_OnMerchantOrderItemAdded(defaultProfile.merchant)
    end

    self:UpdateVendorViewLayout()

    self:SetScript("OnHide", function()

    end)
    self:SetScript("OnShow", function()
        self:PlayerBags_OnItemsChanged()
    end)
end


function VendorMateMixin:Merchant_OnShow()
    self:Show()
    self:UpdateVendorViewLayout()

    local autoVendorJunk = Database:GetConfig("autoVendorJunk")
    if autoVendorJunk == true then
        
    end

    self:CheckMerchantOrders()
end


function VendorMateMixin:Merchant_OnHide()
    self:UnlockAllBagSlots()
    self:Hide()
end

function VendorMateMixin:Profile_OnDelete(profile)
    Database:DeleteProfile(profile)
    self:UpdateVendorViewProfileDropdown()

    local profiles = Database:GetProfiles()
    if #profiles == 0 then
        self:GenerateProfile()
    end
    self:Profile_OnChanged(profiles[#profiles])
end

function VendorMateMixin:Profile_OnChanged(newProfile)
    self.selectedProfile = newProfile;

    self.content.vendor.selectProfileDropdown.label.text:SetText(self.selectedProfile.pkey)

    if self.content.vendor.filterGridview then
        self.content.vendor.filterGridview:Flush()

        local filters = self.selectedProfile.vendor.filters;
        for k, filter in ipairs(filters) do
            self.content.vendor.filterGridview:Insert({
                filter = filter,
            })
        end

        self:IterAllFilters()
        self:UpdateVendorFilters()
    end

    Database:SetConfig("currentProfile", newProfile.pkey)

end


function VendorMateMixin:Profile_OnFilterAdded(filter)

    self.content.vendor.filterGridview:Insert({
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

        local gridview = self.content.vendor.filterGridview
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


function VendorMateMixin:Filter_OnVendorStart()
    self.isVendoringActive = true;
end


function VendorMateMixin:Filter_OnVendorFinished()
    self.isVendoringActive = false;
    C_Timer.After(0.5, function()
        self:PlayerBags_OnItemsChanged()
    end)
end


function VendorMateMixin:Filter_OnItemsAddedToMail()
    self.isVendoringActive = false;
end



function VendorMateMixin:UnlockAllBagSlots()
    for k, item in ipairs(self.playerBags) do
        C_Item.UnlockItemByGUID(item.guid)
    end
end


-- iter all filters 
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
                return true;
            elseif rule.classID == "invEquip" and (item.classID == 2 or item.classID == 4) then
                return true;
            else
                return item.classID == rule.classID and (rule.subClassID == "any" or item.subClassID == rule.subClassID)
            end
        end
    end
    local function generateItemSubClassIdCheck(rule)
        return function(item)
            if rule.subClassID == "any" then
                return true;
            elseif rule.subClassID == "invEquip" then
                return true;
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

    self.content.vendor.allFiltersInfo:SetText(string.format("%s %s - %s %s - %s %s - %s", #filters, "Filters", stacksAllFilters, "Stacks", itemsAllFilters, "items", C_CurrencyInfo.GetCoinTextureString(goldAllFilters)))

end


function VendorMateMixin:UpdateVendorFilters()
    local gridviewItems = self.content.vendor.filterGridview:GetFrames()
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
    local gridviewItems = self.content.vendor.filterGridview:GetFrames()
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

function VendorMateMixin:GetNumUsedBagSlots()
    local usedSlots = 0;
    for bag = 0, NUM_PLAYER_BAGS do        
        usedSlots = usedSlots + (C_Container.GetContainerNumSlots(bag) - C_Container.GetContainerNumFreeSlots(bag))
    end
    return usedSlots;
end

function VendorMateMixin:PlayerBags_OnItemsChanged()

    if not self:IsVisible() then
        return;
    end

    if self.isVendoringActive then
        return
    end

    self.playerBags = {};
    self.bagLocationToItem = {};

    self.usedSlots = 0;
    
    for bag = 0, NUM_PLAYER_BAGS do        
        self.usedSlots = self.usedSlots + (C_Container.GetContainerNumSlots(bag) - C_Container.GetContainerNumFreeSlots(bag))
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
                        info.itemID = item:GetItemID()

                        info.vendorPrice = (select(11, C_Item.GetItemInfo(info.link)))

                        local effectiveILvl, isPreview, baseILvl = C_Item.GetDetailedItemLevelInfo(info.link)
                        info.effectiveIlvl = effectiveILvl

                        local _, _, _, _, icon, classID, subClassID = C_Item.GetItemInfoInstant(info.link)

                        info.bindingType = select(14, C_Item.GetItemInfo(info.link))

                        info.icon = icon
                        info.classID = classID
                        info.subClassID = subClassID

                        table.insert(self.playerBags, info)

                        self.bagLocationToItem[string.format("%s-%s", bag, slot)] = self.playerBags[#self.playerBags]
                        self.bagLinkToItem[info.link] = self.playerBags[#self.playerBags]

                        slotsQueried = slotsQueried + 1;
                        if slotsQueried == self.usedSlots then
                            self:IterAllFilters()
                            self:UpdateVendorFilters()
                        end

                    end)
                end
            end
        end
    end

end





function VendorMateMixin:SetupHistoryView()
    
    local view = self.content.history;

    local profiles = Database:GetProfiles()
    local t = {}
    for k, profile in ipairs(profiles) do
        table.insert(t, {
            text = profile.pkey,
            func = function()
                self:SetHistoryProfile(profile)
            end
        })
    end
    view.profileSelectDropdown:SetMenu(t)

    local transactionTypes = {
        {
            text = "Vendor",
            func = function()
                self:SetHistoryTransaction("vendor")
            end,
        },
    }
    view.transactionSelectDropdown:SetMenu(transactionTypes)




end


function VendorMateMixin:UpdateHistoryView()
    
    if self.history.transactionType and self.history.selectedProfile then
        local transactions = Database:GetTransactions(0, time() + time(), self.history.selectedProfile.pkey, self.history.transactionType)

        local t = {}
        for k, v in ipairs(transactions) do
            table.insert(t, {
                label = string.format("%s [%s]", date("%y-%m-%d - %H:%M:%S", v.timestamp), v.vendor),
                labelRight = C_CurrencyInfo.GetCoinTextureString(v.value),
                backgroundRGB = {r = 196/255, g= 148/255, b = 28/255},
                backgroundAlpha = 0.4,
                onMouseDown = function(f, but)
                    if but == "RightButton" then
                        Database:DeleteTransaction(v)
                    end
                end,
            })
            table.sort(v.items, function(a, b)
                return (a.vendorPrice * a.count) > (b.vendorPrice * b.count)
            end)
            for _, item in ipairs(v.items) do
                table.insert(t, {
                    label = string.format("  [%d] %s", item.count, item.link),
                    labelRight = C_CurrencyInfo.GetCoinTextureString(item.vendorPrice),
                    onMouseEnter = function(f)
                        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(item.link)
                        GameTooltip:Show()
                    end
                })
            end
        end

        self.content.history.listview.scrollView:SetDataProvider(CreateDataProvider(t))
    end
end

function VendorMateMixin:SetHistoryProfile(profile)
    self.history.selectedProfile = profile;
    self:UpdateHistoryView()
end

function VendorMateMixin:SetHistoryTransaction(transaction)
    self.history.transactionType = transaction;
    self:UpdateHistoryView()
end

function VendorMateMixin:SetupMerchantTab()

    self.content.merchant.dropFrame:RegisterEvent("GLOBAL_MOUSE_UP")
    self.content.merchant.dropFrame:SetScript("OnEvent", function(s, e, ...)
        if e == "GLOBAL_MOUSE_UP" then
            if self.content.merchant.dropFrame:IsMouseOver() and self.content.merchant.dropFrame:IsVisible() then
                local order = {
                    minStock = 1,
                    autoPurchase = true,
                }
                local infoType, a, b = GetCursorInfo()
                if infoType == "merchant" then
                    --a=merchantIndex
                    local itemID = GetMerchantItemID(a)
                    --local link = GetMerchantItemLink(a)
                    order.itemID = itemID;
                elseif infoType == "item" then
                    --a=itemID b=itemLink
                    order.itemID = a
                end
                if order.itemID then
                    local thisCharacterProfile = Database:GetProfile(string.format("%s.%s.%s", self.character.name, self.character.realm, CHAT_DEFAULT))
                    Database:AddMerchantOrder(thisCharacterProfile, order)
                end
                ClearCursor()
            end
        end
    end)

end

function VendorMateMixin:Database_OnMerchantOrderItemAdded(profileMerchant)
    self.content.merchant.listview.scrollView:SetDataProvider(CreateDataProvider(profileMerchant))
end

function VendorMateMixin:Database_OnMerchantOrderItemDeleted(order)
    local thisCharacterProfile = Database:GetProfile(string.format("%s.%s.%s", self.character.name, self.character.realm, CHAT_DEFAULT))
    if thisCharacterProfile and thisCharacterProfile.merchant then
        local indexToRemove;
        for k, v in ipairs(thisCharacterProfile.merchant) do
            if v.itemID == order.itemID then
                indexToRemove = k;
            end
        end
        if indexToRemove then
            table.remove(thisCharacterProfile.merchant, indexToRemove)
        end
        self.content.merchant.listview.scrollView:SetDataProvider(CreateDataProvider(thisCharacterProfile.merchant))
    end
end


function VendorMateMixin:CheckMerchantOrders()
    --GetMerchantItemMaxStack(index)
    --BuyMerchantItem(index[, quantity])

    local merchantItems, itemID, maxStack, itemLink = {}, nil, nil, nil
    for i = 1, GetMerchantNumItems() do
        itemID = GetMerchantItemID(i)
        itemLink = GetMerchantItemLink(i)
        maxStack = GetMerchantItemMaxStack(i)
        merchantItems[itemID] = {
            slotIndex = i,
            itemLink = itemLink,
            maxStack = maxStack,
        }
    end

    --print("MERCHANT ORDERS........")

    local thisCharacterProfile = Database:GetProfile(string.format("%s.%s.%s", self.character.name, self.character.realm, CHAT_DEFAULT))
    if thisCharacterProfile and thisCharacterProfile.merchant then
        for _, order in ipairs(thisCharacterProfile.merchant) do

            if merchantItems[order.itemID] then
                local currentStock = C_Item.GetItemCount(order.itemID)
                if currentStock < order.minStock then
                    print(string.format("VendorMate: Buying %d %s", (order.minStock - currentStock), merchantItems[order.itemID].itemLink))
                    BuyMerchantItem(merchantItems[order.itemID].slotIndex, (order.minStock - currentStock))
                else
                    --print("Have enough in stock")
                end
            end
        end
    end
end