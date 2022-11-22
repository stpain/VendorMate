

local addonName, vm = ...;

local Database = vm.database;

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

Mixin(vm, CallbackRegistryMixin)
vm:GenerateCallbackEvents({

    "Player_OnEnteringWorld",
    "PlayerBags_OnItemsChanged",
    "Player_OnMoneyChanged",

    "Merchant_OnShow",
    "Merchant_OnHide",

    "Filter_OnItemSold",
    "Filter_OnChanged",
    "Filter_OnIgnoredChanged",
    "Filter_OnVendorStart",
    "Filter_OnVendorFinished",

    "Profile_OnChanged",
    "Profile_OnFilterAdded",
    "Profile_OnFilterRemoved",

    -- "VendorMate_OnHide",
    -- "VendorMate_OnShow",
    
})
CallbackRegistryMixin.OnLoad(vm);

local f = CreateFrame("FRAME")

function f:ADDON_LOADED()
    Database:Init()
end

function f:PLAYER_ENTERING_WORLD()

    local name, realm = UnitFullName("player");
    if realm == nil or realm == "" then
        realm = GetNormalizedRealmName();
    end
    local _, class = UnitClass("player")

    vm:TriggerEvent("Player_OnEnteringWorld", {
        name = name,
        realm = realm,
        class = class,
    })
end

function f:PLAYER_MONEY(...)
    vm:TriggerEvent("Player_OnMoneyChanged", GetMoney())
end

function f:MERCHANT_SHOW(...)
    vm:TriggerEvent("Merchant_OnShow")
end

function f:MERCHANT_HIDE(...)
    vm:TriggerEvent("Merchant_OnHide")
end

function f:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(...)
    if ... == Enum.PlayerInteractionType.Merchant then
        vm:TriggerEvent("Merchant_OnShow")
    end
end

function f:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(...)
    if ... == Enum.PlayerInteractionType.Merchant then
        vm:TriggerEvent("Merchant_OnHide")
    end
end

function f:BAG_UPDATE_DELAYED(...)
    vm:TriggerEvent("PlayerBags_OnItemsChanged")
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent('BAG_UPDATE_DELAYED')
f:RegisterEvent('MERCHANT_SHOW')
f:RegisterEvent('MERCHANT_CLOSED')
f:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
f:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')

f:SetScript("OnEvent", function(self, event, ...)
    if f[event] then
        f[event](f, ...)
    end
end)