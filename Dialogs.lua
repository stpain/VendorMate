

local addonName, vm = ...;

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