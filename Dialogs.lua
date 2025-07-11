

local addonName, vm = ...;

local L = vm.locales;

StaticPopupDialogs["VendorMateDialogDeleteFilterConfirm"] = {
    text = string.format("%s %s", DELETE, "%s"),
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(self, filter)
        vm:TriggerEvent("Profile_OnFilterRemoved", filter)
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}

StaticPopupDialogs["VendorMateDialogDeleteProfileConfirm"] = {
    text = string.format("%s %s", DELETE, "%s"),
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(self, profile)
        vm:TriggerEvent("Profile_OnDelete", profile)
    end,
    OnCancel = function(self)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}

local function vendorItems(items, overridePopup)

    vm:TriggerEvent("Vendor_OnTransactionStart")

    if MerchantFrame:IsVisible() or SendMailFrame:IsVisible() then
        local i = #items;
        C_Timer.NewTicker(0.2, function()
            local item = items[i]

            if not item then
                return;
            end

            if item.ignore == false then

                C_Item.UnlockItemByGUID(item.guid)
                C_Container.UseContainerItem(item.bagID, item.slotID)

                if overridePopup then
                    if StaticPopup1Button1:IsVisible() then
                        StaticPopup1Button1:Click()
                    end
                end

            end

            i = i - 1;

            if i == 0 then
                if MerchantFrame:IsVisible() then
                    vm:TriggerEvent("Filter_OnVendorFinished")
                    vm:TriggerEvent("Vendor_OnTransactionFinish")

                elseif SendMailFrame:IsVisible() then
                    vm:TriggerEvent("Filter_OnItemsAddedToMail")
                end
            end

        end, #items)
    end
end

StaticPopupDialogs["VendorMateDialogVendorItemsConfirm"] = {
    text = string.format("%s %s %s\n\n%s\n\n%s", TRANSMOG_SOURCE_3, "%s", FILTERS, "%s", L.DIALOG_VENDOR_CONFIRM),
    button1 = YES,
    button2 = NO,
    button3 = CANCEL,
    OnAccept = function(self, items)
        vendorItems(items, true)
    end,
    OnAlt = function(self, items)

    end,
    OnCancel = function(self, items)
        vendorItems(items, false)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    showAlert = 1,
}