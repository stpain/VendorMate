

local addonName, vm = ...;

local L = vm.locales;



VendorMateHelpTipMixin = {};
function VendorMateHelpTipMixin:SetText(text)
    self.text:SetText(text)
end
function VendorMateHelpTipMixin:OnShow()

end




VendorMateGridviewItemListviewItemMixin = {}

function VendorMateGridviewItemListviewItemMixin:OnLoad()

    self.fade:SetScript("OnFinished", function()
        self:Hide()
    end)

    self:SetScript("OnEnter", function()
        if self.item then
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetHyperlink(self.item.link)
            GameTooltip:Show()
        end
    end)
    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self:SetScript("OnMouseDown", function(s, button)
        if self.item then
            self.item.ignore = not self.item.ignore;
            self.ignoreIcon:SetAtlas((self.item.ignore == false) and "common-icon-checkmark" or "common-icon-redx")
            vm.ignoreItemGuid[self.item.guid] = self.item.ignore;
            vm:TriggerEvent("Filter_OnChanged")
        end
    end)
    
end

function VendorMateGridviewItemListviewItemMixin:OnItemSold(bagID, slotID)
    if self.item and (self.item.bagID == bagID) and (self.item.slotID == slotID) then
        self.fade:Play()
    end
end

function VendorMateGridviewItemListviewItemMixin:SetDataBinding(binding, height)

    self.ignoreIcon:SetSize(height, height)

    vm:RegisterCallback("Filter_OnItemSold", self.OnItemSold, self)

    self:SetAlpha(1)
    self:Show()

    self.item = binding
    if vm.ignoreItemGuid[self.item.guid] then
        self.ignoreIcon:SetAtlas((vm.ignoreItemGuid[self.item.guid] == false) and "common-icon-checkmark" or "common-icon-redx")
    else
        self.ignoreIcon:SetAtlas((self.item.ignore == false) and "common-icon-checkmark" or "common-icon-redx")
    end

    self.text:SetText(self.item.link)
    
end

function VendorMateGridviewItemListviewItemMixin:ResetDataBinding()
    self.item = nil;
    self.text:SetText(nil)
    self.ignoreIcon:SetTexture(nil)
end



VendorMateFilterDropDownMenuMixin = {}
function VendorMateFilterDropDownMenuMixin:OnLoad()

    self:SetScript("OnEnter", function()
        if self.fadeTimer then
            self.fadeTimer:Cancel()
        end
        self.fade:Stop()
        self:SetAlpha(1)
    end)
    self:SetScript("OnLeave", function()
        self.fadeTimer = C_Timer.NewTimer(0.4, function()
            if not self:IsMouseOver() then
                self.fade:Play()
            end
        end)
    end)
    self.fade:SetScript("OnFinished", function()
        self:Hide()
    end)

    self:SetScript("OnHide", function()
        self.filter = nil;
    end)

    for i = 0, 8 do
        self["quality"..i].icon:SetColorTexture(ITEM_QUALITY_COLORS[i].r, ITEM_QUALITY_COLORS[i].g, ITEM_QUALITY_COLORS[i].b)
        
        self["quality"..i]:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:SetText(_G['ITEM_QUALITY'..i..'_DESC'])
            GameTooltip:Show()
        end)
        self["quality"..i]:SetScript("OnLeave", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
        self["quality"..i]:SetScript("OnClick", function(s)
            if self.filter then

                for i = 0, 8 do
                    self["quality"..i].selected:Hide()
                end

                if self.filter.rules.quality == i then
                    self.filter.rules.quality = "any";
                else
                    self.filter.rules.quality = i;
                    s.selected:Show()
                end
                vm:TriggerEvent("Filter_OnChanged")

            end
        end)
    end

    for i = 1, 5 do
        self["tier"..i]:SetNormalAtlas(string.format("Professions-ChatIcon-Quality-Tier%s", i))
    end

    local sliders = {
        "minEffectiveIlvl",
        "maxEffectiveIlvl",
    }

    for k, slider in ipairs(sliders) do

        _G[self[slider]:GetName().."Low"]:SetText(" ")
        _G[self[slider]:GetName().."High"]:SetText(" ")
        _G[self[slider]:GetName().."Text"]:SetText(" ")

        self[slider]:SetScript("OnMouseWheel", function(s, delta)
            s:SetValue(s:GetValue() + delta)
        end)

        self[slider]:SetScript("OnValueChanged", function(s)
            s.value:SetText(math.ceil(s:GetValue()))
            if self.filter then
                self.filter.rules[slider] = self[slider]:GetValue()
                vm:TriggerEvent("Filter_OnChanged")
            end
        end)
    end


    local classIdMenuList = {}
    table.insert(classIdMenuList, {
        text = CLUB_FINDER_ANY_FLAG,
        func = function()
            if self.filter then
                self.filter.rules.classID = "any";
                self.filter.rules.subClassID = "any";
                vm:TriggerEvent("Filter_OnChanged")

                self.subClassDropdown:SetMenu({})
            end
        end,
    })
    for classID = 0, 19 do
        table.insert(classIdMenuList, {
            text = GetItemClassInfo(classID),
            func = function()
                if self.filter then
                    self.filter.rules.classID = classID;
                    vm:TriggerEvent("Filter_OnChanged")
                end

                local subClassIdMenuList = {}
                local anyAdded = false;
                for _, subClassID in pairs(C_AuctionHouse.GetAuctionItemSubClasses(classID)) do
                    if subClassID then
                        if anyAdded == false then
                            table.insert(subClassIdMenuList, {
                                text = CLUB_FINDER_ANY_FLAG,
                                -- this sets the subClass option to any btu needs to keep the classID of its parent
                                func = function()
                                    if self.filter then
                                        self.filter.rules.classID = classID;
                                        self.filter.rules.subClassID = "any";
                                        vm:TriggerEvent("Filter_OnChanged")
                                    end
                                end,
                            })
                            anyAdded = true
                        end
                        table.insert(subClassIdMenuList, {
                            text = GetItemSubClassInfo(classID, subClassID),
                            func = function()
                                if self.filter then
                                    self.filter.rules.classID = classID;
                                    self.filter.rules.subClassID = subClassID;
                                    vm:TriggerEvent("Filter_OnChanged")
                                end
                            end,
                        })
                    end
                end

                self.subClassDropdown:SetMenu(subClassIdMenuList)
            end,
        })
    end

    self.classDropdown:SetMenu(classIdMenuList)


    local inventorySlots = {}
    for k, v in pairs(Enum.InventoryType) do
        local slot = string.sub(k, 6, -5):upper()
        if _G[string.format("INVTYPE_%s", slot)] then
            table.insert(inventorySlots, {
                id = v,
                global = _G[string.format("INVTYPE_%s", slot)]
            })
        end
    end
    table.sort(inventorySlots, function(a, b)
        return a.id < b.id
    end)
    local inventoryTypeMenuList = {}
    table.insert(inventoryTypeMenuList, {
        text = CLUB_FINDER_ANY_FLAG,
        func = function()
            if self.filter then
                self.filter.rules.inventoryType = "any";
                vm:TriggerEvent("Filter_OnChanged")
            end
        end,
    })
    for k, invType in ipairs(inventorySlots) do
        table.insert(inventoryTypeMenuList, {
            text = invType.global,
            func = function()
                if self.filter then
                    self.filter.rules.inventoryType = invType.id
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        })
    end
    self.inventorySlotDropdown:SetMenu(inventoryTypeMenuList)


    local bindMenu = {
        {
            text = CLUB_FINDER_ANY_FLAG,
            func = function()
                if self.filter then
                    self.filter.rules.isBound = "any";
                    self.filter.rules.bindingType = "any";
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "BoE",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = false;
                    self.filter.rules.bindingType = 2;
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (BoE)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = 2;
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (BoP)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = 1;
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (All)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = "any";
                    vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
    }

    self.bindTypeDropdown:SetMenu(bindMenu)


end




VendorMateVendorGridviewItemMixin = {}

function VendorMateVendorGridviewItemMixin:OnLoad()

    self.itemsLocked = true;

    self.settings:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.settings, "ANCHOR_TOP")
        GameTooltip:SetText(L.FILTER_BUTTON_SETTINGS_TT)
        GameTooltip:Show()
    end)
    self.settings:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self.settings:SetScript("OnClick", function()
        self:InitDropdownMenu()
    end)

    self.deleteFilter:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.deleteFilter, "ANCHOR_TOP")
        GameTooltip:SetText(DELETE)
        GameTooltip:Show()
    end)
    self.deleteFilter:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self.deleteFilter:SetScript("OnClick", function()
        if self.filter then
            StaticPopup_Show("VendorMateDialogDeleteFilterConfirm", self.filter.name, nil, self.filter)
        end
    end)

    self.vendorItems:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.vendorItems, "ANCHOR_TOP")
        GameTooltip:SetText(L.FILTER_BUTTON_VENDOR_TT)
        GameTooltip:Show()
    end)
    self.vendorItems:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self.vendorItems:SetScript("OnClick", function()
        self:VendorAllItems()
    end)

    self.lockUnlockItems:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.lockUnlockItems, "ANCHOR_TOP")
        GameTooltip:SetText(L.FILTER_BUTTON_LOCK_TOGGLE_TT)
        GameTooltip:Show()
    end)
    self.lockUnlockItems:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self.lockUnlockItems:SetScript("OnClick", function()
        self.itemsLocked = not self.itemsLocked;
        self:ToggleItemsLock(self.itemsLocked)
    end)

    self:SetScript("OnHide", function()
        self.itemsLocked = false;
        self:ToggleItemsLock(self.itemsLocked)
    end)
    

end


function VendorMateVendorGridviewItemMixin:InitDropdownMenu()

    local settings = VendorMateFilterDropDownMenu;

    if settings.filter and (settings.filter.pkey == self.filter.pkey) then
        settings:Hide()
        settings.filter = nil;
        return;

    else
        settings.filter = self.filter;
        settings:SetAlpha(1)

        for i = 0, 8 do
            settings["quality"..i].selected:Hide()
        end
        if type(self.filter.rules.quality) == "number" then
            settings["quality"..self.filter.rules.quality].selected:Show()
        end
    
        settings.minEffectiveIlvl:SetValue(self.filter.rules.minEffectiveIlvl)
        settings.maxEffectiveIlvl:SetValue(self.filter.rules.maxEffectiveIlvl)
    
        settings:ClearAllPoints()
        settings:SetPoint("TOPLEFT", self.settings, "TOPLEFT", 4, -4)
        settings:Show()
    end

end


function VendorMateVendorGridviewItemMixin:ToggleItemsLock(locked)
    if type(self.items) == "table" then
        for k, item in ipairs(self.items) do
            if locked then
                C_Item.LockItemByGUID(item.guid)
            else
                C_Item.UnlockItemByGUID(item.guid)
            end
        end
        if locked then
            self.lockUnlockItems:SetNormalAtlas("vignetteloot-locked")
        else
            self.lockUnlockItems:SetNormalAtlas("vignetteloot")
        end
    end
end


-- loop the tiles items and attempt to vendor each
-- also plays a fade out animation, then flushes the listview
-- applies vendorLock to prevent any tile updates while vendoring
function VendorMateVendorGridviewItemMixin:VendorAllItems()
    if MerchantFrame:IsVisible() and type(self.items) == "table" then

        if #self.items == 0 then
            --vm:TriggerEvent("Filter_OnAllItemsSold")

        else

            vm.vendorLocked = true;

            local i = #self.items;
            C_Timer.NewTicker(0.2, function()
                local item = self.items[i]
    
                if not item then
                    return;
                end
    
                if item.ignore == false then
    
                    C_Item.UnlockItemByGUID(item.guid)                
                    C_Container.UseContainerItem(item.bagID, item.slotID)
    
    
                end
    
                i = i - 1;
    
                if i == 0 then
                    self.listview.DataProvider:Flush()
                    vm.vendorLocked = false;
    
                    --vm:TriggerEvent("Filter_OnAllItemsSold")
                end
            end, #self.items)
    
                -- if popupOverride then
                --     if StaticPopup1Button1:IsVisible() then
                --         StaticPopup1Button1:Click()
                --     end
                -- end
        end

    else
        --vm:TriggerEvent("Filter_OnAllItemsSold")

    end
end

function VendorMateVendorGridviewItemMixin:SetDataBinding(binding)
    self.filter = binding.filter;
    self.name:SetText(string.format("%s [%s]", binding.filter.name, binding.filter.priority))
    --self:UpdateItems(binding.listviewData)
end

function VendorMateVendorGridviewItemMixin:UpdateItems(items)
    self.items = items;
    local gold = 0;
    for k, item in ipairs(self.items) do
        if item.count and item.vendorPrice and (item.ignore == false) then
            gold = gold + (item.count * item.vendorPrice)
        end
    end
    self.itemsLocked = true
    self.lockUnlockItems:SetNormalAtlas("vignetteloot-locked")
    self.vendorValue:SetText(GetCoinTextureString(gold))
    self.listview.DataProvider:Flush()
    self.listview.DataProvider:InsertTable(self.items)
end

function VendorMateVendorGridviewItemMixin:GetTilePkey()
    return self.filter.pkey;
end

function VendorMateVendorGridviewItemMixin:UpdateLayout()

end

function VendorMateVendorGridviewItemMixin:ResetDataBinding()
    self.filter = nil;
    self.listview.DataProvider:Flush()
end
