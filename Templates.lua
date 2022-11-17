

local addonName, vm = ...;

VendorMateGridviewItemListviewItemMixin = {}

function VendorMateGridviewItemListviewItemMixin:OnLoad()

    self.fade:SetScript("OnFinished", function()
        self:Hide()
    end)
    
end

function VendorMateGridviewItemListviewItemMixin:OnItemSold(bagID, slotID)
    if self.item and (self.item.bagID == bagID) and (self.item.slotID == slotID) then
        self.fade:Play()
    end
end

function VendorMateGridviewItemListviewItemMixin:SetDataBinding(binding)

    vm:RegisterCallback("Filter_OnItemSold", self.OnItemSold, self)

    self:SetAlpha(1)

    self.item = binding

    self.text:SetText(binding.link)

    self:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetHyperlink(binding.link)
        GameTooltip:Show()
    end)
    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    
end

function VendorMateGridviewItemListviewItemMixin:ResetDataBinding()
    self.item = nil;
end



VendorMateFilterDropDownMenuMixin = {}
function VendorMateFilterDropDownMenuMixin:OnLoad()



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
            if self.tile then

                for i = 0, 8 do
                    self["quality"..i].selected:Hide()
                end

                if self.tile.rules.quality == i then
                    self.tile.rules.quality = "any";
                else
                    self.tile.rules.quality = i;
                    s.selected:Show()
                end
                vm:TriggerEvent("Filter_OnChanged")

            end
        end)
    end

    for i = 1, 5 do
        self["tier"..i]:SetNormalAtlas(string.format("Professions-ChatIcon-Quality-Tier%s", i))
    end

    _G[self.minEffectiveIlvl:GetName().."Low"]:SetText(" ")
    _G[self.minEffectiveIlvl:GetName().."High"]:SetText(" ")
    _G[self.minEffectiveIlvl:GetName().."Text"]:SetText(" ")

    _G[self.maxEffectiveIlvl:GetName().."Low"]:SetText(" ")
    _G[self.maxEffectiveIlvl:GetName().."High"]:SetText(" ")
    _G[self.maxEffectiveIlvl:GetName().."Text"]:SetText(" ")


    local classIdMenuList = {}
    table.insert(classIdMenuList, {
        text = CLUB_FINDER_ANY_FLAG,
        func = function()
            if self.tile then
                self.tile.rules.classID = "any";
                self.tile.rules.subClassID = "any";
                vm:TriggerEvent("Filter_OnChanged")

                self.subClassDropdown:SetMenu({})
            end
        end,
    })
    for classID = 0, 19 do
        table.insert(classIdMenuList, {
            text = GetItemClassInfo(classID),
            func = function()
                if self.tile then
                    self.tile.rules.classID = classID;
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
                                    if self.tile then
                                        self.tile.rules.classID = classID;
                                        self.tile.rules.subClassID = "any";
                                        vm:TriggerEvent("Filter_OnChanged")
                                    end
                                end,
                            })
                            anyAdded = true
                        end
                        table.insert(subClassIdMenuList, {
                            text = GetItemSubClassInfo(classID, subClassID),
                            func = function()
                                if self.tile then
                                    self.tile.rules.classID = classID;
                                    self.tile.rules.subClassID = subClassID;
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
            if self.tile then
                self.tile.rules.inventoryType = "any";
                vm:TriggerEvent("Filter_OnChanged")
            end
        end,
    })
    for k, invType in ipairs(inventorySlots) do
        table.insert(inventoryTypeMenuList, {
            text = invType.global,
            func = function()
                self.tile.rules.inventoryType = invType.id
                vm:TriggerEvent("Filter_OnChanged")
            end,
        })
    end
    self.inventorySlotDropdown:SetMenu(inventoryTypeMenuList)

end




VendorMateVendorGridviewItemMixin = {}

function VendorMateVendorGridviewItemMixin:OnLoad()

    self.itemsLocked = true;

    self.settings:SetScript("OnClick", function()

        self:InitDropdownMenu()

    end)

    self.vendorItems:SetScript("OnClick", function()
        self:VendorAllItems()
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

    settings.tile = self.tile;

    for i = 0, 8 do
        settings["quality"..i].selected:Hide()
    end
    if type(self.tile.rules.quality) == "number" then
        settings["quality"..self.tile.rules.quality].selected:Show()
    end

    settings.minEffectiveIlvl:SetValue(self.tile.rules.minEffectiveIlvl)
    settings.maxEffectiveIlvl:SetValue(self.tile.rules.maxEffectiveIlvl)

    settings:ClearAllPoints()
    settings:SetPoint("TOPLEFT", self.settings, "TOPLEFT", 12, -12)
    settings:Show()

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

        vm.vendorLocked = true;

        local i = #self.items;
        C_Timer.NewTicker(0.2, function()
            local item = self.items[i]

            if not item then
                return;
            end

            C_Item.UnlockItemByGUID(item.guid)                
            C_Container.UseContainerItem(item.bagID, item.slotID)


            -- local f = self.listview.scrollView:FindFrame(item)
            -- if f then
            --     f.fade:Play()
            -- end

            i = i - 1;

            if i == 0 then
                self.listview.DataProvider:Flush()
                vm.vendorLocked = false;

                vm:TriggerEvent("Filter_OnAllItemsSold")
            end
        end, #self.items)

            -- if popupOverride then
            --     if StaticPopup1Button1:IsVisible() then
            --         StaticPopup1Button1:Click()
            --     end
            -- end
    end
end

function VendorMateVendorGridviewItemMixin:SetDataBinding(binding)
    self.tile = binding.tile;
    self.name:SetText(binding.tile.name)
    --self:UpdateItems(binding.listviewData)
end

function VendorMateVendorGridviewItemMixin:UpdateItems(items)
    self.items = items;
    local gold = 0;
    for k, item in ipairs(self.items) do
        if item.count and item.vendorPrice then
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
    return self.tile.pkey;
end

function VendorMateVendorGridviewItemMixin:UpdateLayout()

end

function VendorMateVendorGridviewItemMixin:ResetDataBinding()
    self.tile = nil;
    self.listview.DataProvider:Flush()
end
