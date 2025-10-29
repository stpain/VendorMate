

local addonName, vm = ...;

local L = vm.locales;



VendorMateHelpTipMixin = {};
function VendorMateHelpTipMixin:SetText(text)
    self.text:SetText(text)
end
function VendorMateHelpTipMixin:OnShow()

end




VendorMateHistoryListviewItemTemplateMixin = {}

function VendorMateHistoryListviewItemTemplateMixin:OnLoad()

end

function VendorMateHistoryListviewItemTemplateMixin:SetDataBinding(binding, height)

    self.text:SetText(binding.link)

    -- self.icon:SetSize(height - 2, height - 2)

    -- self.icon:SetTexture(select(5, GetItemInfoInstant(binding.link)))

    -- local d = date("%y-%m-%d - %H:%M:%S", binding.datetime)

    -- self.text:SetText(string.format("%s %s %s - x%s %s", d, binding.link, binding.vendor, binding.count, GetCoinTextureString(binding.count * binding.amount)))
end

function VendorMateHistoryListviewItemTemplateMixin:ResetDataBinding()

end





VendorMateGridviewItemListviewItemMixin = {}

function VendorMateGridviewItemListviewItemMixin:OnLoad()

    self.fade:SetScript("OnFinished", function()
        self.item = nil;
        self.text:SetText(nil)
        self:Hide()
    end)

    self:SetScript("OnEnter", function()
        if self.item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
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
            --vm.ignoreItemGuid[self.item.guid] = self.item.ignore;
            vm:TriggerEvent("Filter_OnIgnoredChanged", self.item)
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

    self:Show()
    self.show:Play()

    self.item = binding
    self.ignoreIcon:SetAtlas((self.item.ignore == false) and "common-icon-checkmark" or "common-icon-redx")
    
    -- if vm.ignoreItemGuid[self.item.guid] then
    --     self.ignoreIcon:SetAtlas((vm.ignoreItemGuid[self.item.guid] == false) and "common-icon-checkmark" or "common-icon-redx")
    -- else
    --     self.ignoreIcon:SetAtlas((self.item.ignore == false) and "common-icon-checkmark" or "common-icon-redx")
    -- end

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
        vm:TriggerEvent("Filter_OnChanged")
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
                --vm:TriggerEvent("Filter_OnChanged")

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
                --vm:TriggerEvent("Filter_OnChanged")
            end
        end)
    end


    local classIdMenuList = {
        {
            text = L.ANY,
            func = function()
                if self.filter then
                    self.filter.rules.classID = "any";
                    self.filter.rules.subClassID = "any";
                    --vm:TriggerEvent("Filter_OnChanged")
    
                    self.subClassDropdown:SetMenu({})
                end
            end, 
        },
        {
            text = string.format("%s + %s", C_Item.GetItemClassInfo(2), C_Item.GetItemClassInfo(4)),
            func = function()
                if self.filter then
                    self.filter.rules.classID = "invEquip";
                    self.filter.rules.subClassID = "invEquip";
                    --vm:TriggerEvent("Filter_OnChanged")
    
                    self.subClassDropdown:SetMenu({})
                end
            end, 
        },
    }

    for classID = 0, 19 do
        table.insert(classIdMenuList, {
            text = C_Item.GetItemClassInfo(classID),
            func = function()
                if self.filter then
                    self.filter.rules.classID = classID;
                    --vm:TriggerEvent("Filter_OnChanged")
                end

                local subClassIdMenuList = {}
                local anyAdded = false;
                for _, subClassID in pairs(C_AuctionHouse.GetAuctionItemSubClasses(classID)) do
                    if subClassID then
                        if anyAdded == false then
                            table.insert(subClassIdMenuList, {
                                text = L.ANY,
                                -- this sets the subClass option to any btu needs to keep the classID of its parent
                                func = function()
                                    if self.filter then
                                        self.filter.rules.classID = classID;
                                        self.filter.rules.subClassID = "any";
                                        --vm:TriggerEvent("Filter_OnChanged")
                                    end
                                end,
                            })
                            anyAdded = true
                        end
                        table.insert(subClassIdMenuList, {
                            text = C_Item.GetItemSubClassInfo(classID, subClassID),
                            func = function()
                                if self.filter then
                                    self.filter.rules.classID = classID;
                                    self.filter.rules.subClassID = subClassID;
                                    --vm:TriggerEvent("Filter_OnChanged")
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
        text = L.ANY,
        func = function()
            if self.filter then
                self.filter.rules.inventoryType = "any";
                --vm:TriggerEvent("Filter_OnChanged")
            end
        end,
    })
    for k, invType in ipairs(inventorySlots) do
        table.insert(inventoryTypeMenuList, {
            text = invType.global,
            func = function()
                if self.filter then
                    self.filter.rules.inventoryType = invType.id
                    --vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        })
    end
    self.inventorySlotDropdown:SetMenu(inventoryTypeMenuList)


    local bindMenu = {
        {
            text = L.ANY,
            func = function()
                if self.filter then
                    self.filter.rules.isBound = "any";
                    self.filter.rules.bindingType = "any";
                    --vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "BoE",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = false;
                    self.filter.rules.bindingType = 2;
                    --vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (BoE)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = 2;
                    --vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (BoP)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = 1;
                    --vm:TriggerEvent("Filter_OnChanged")
                end
            end,
        },
        {
            text = "Soulbound (All)",
            func = function()
                if self.filter then
                    self.filter.rules.isBound = true;
                    self.filter.rules.bindingType = "any";
                    --vm:TriggerEvent("Filter_OnChanged")
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
        GameTooltip:SetText(string.format("%s %s", DELETE, FILTER))
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
        StaticPopup_Show("VendorMateDialogVendorItemsConfirm", self.filter.name, string.format("%s - %s", self.itemCount:GetText() or "-", self.vendorValue:GetText() or "-"), self.items)
    end)

    SendMailFrame:HookScript("OnShow", function()
        self.vendorItems:GetNormalTexture():SetAtlas("UI-HUD-Minimap-Mail-Up")
    end)
    SendMailFrame:HookScript("OnHide", function()
        self.vendorItems:GetNormalTexture():SetAtlas("Banker")
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
            self.lockUnlockItems:SetNormalAtlas("Legionfall_Padlock")
        else
            self.lockUnlockItems:SetNormalAtlas("VignetteLoot")
        end
    end
end



function VendorMateVendorGridviewItemMixin:SetDataBinding(binding)
    self.filter = binding.filter;
    self.name:SetText(binding.filter.name)
    --self:UpdateItems(binding.listviewData)
end

function VendorMateVendorGridviewItemMixin:UpdateItems(items)
    self.items = items;

    self.itemsLocked = true
    self.lockUnlockItems:SetNormalAtlas("Legionfall_Padlock")

    self.listview.DataProvider = CreateDataProvider();
    self.listview.scrollView:SetDataProvider(self.listview.DataProvider);

    self.listview.DataProvider:InsertTable(self.items)
end

function VendorMateVendorGridviewItemMixin:GetFilterPkey()
    return self.filter.pkey;
end

function VendorMateVendorGridviewItemMixin:SetInfoText(info)
    self.vendorValue:SetText(C_CurrencyInfo.GetCoinTextureString(info.gold))
    self.itemCount:SetText(string.format("%s %s %s %s", info.numSlots, "Slots", info.numItems, ITEMS))
end

function VendorMateVendorGridviewItemMixin:ResetDataBinding()
    self.filter = nil;
    self.listview.DataProvider:Flush()
end
















VendorMateMerchantOrderListviewItemMixin = {}
function VendorMateMerchantOrderListviewItemMixin:OnLoad()
    
end
function VendorMateMerchantOrderListviewItemMixin:SetDataBinding(binding, height)   
    if binding.itemID then
        local item = Item:CreateFromItemID(binding.itemID)
        if item and (not item:IsItemEmpty()) then
            item:ContinueOnItemLoad(function()
                self.icon:SetTexture(item:GetItemIcon())
                self.text:SetText(item:GetItemLink())
            end)
        end

        self.stockLevel:SetText(binding.minStock)

        self.deleteOrder:SetScript("OnClick", function()
            vm:TriggerEvent("Database_OnMerchantOrderItemDeleted", binding)
        end)
        self.increaseOrder:SetScript("OnClick", function()
            binding.minStock = binding.minStock + 1
            self.stockLevel:SetText(binding.minStock)
        end)
        self.decreaseOrder:SetScript("OnClick", function()
            binding.minStock = binding.minStock - 1
            if binding.minStock < 0 then
                binding.minStock = 0
            end
            self.stockLevel:SetText(binding.minStock)
        end)
    end
end
function VendorMateMerchantOrderListviewItemMixin:ResetDataBinding()
    
end