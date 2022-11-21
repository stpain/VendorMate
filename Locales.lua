

local addonName, vm = ...;

local L = {}

L.ADDON_LOADED = "[%s] loaded."

L.TABS_VENDOR = "Vendor"
L.TABS_HISTORY = "History"
L.TABS_OPTIONS = "Options"

L.FILTER_BUTTON_SETTINGS_TT = "Settings"
L.FILTER_BUTTON_VENDOR_TT = "Vendor items"
L.FILTER_BUTTON_LOCK_TOGGLE_TT = "Toggle item lock"

L.DIALOG_VENDOR_CONFIRM = "Auto click confirm warnings?"

L.VENDORING_OVERRIDE_POPUP_WARNING = string.format("%s %s", CreateAtlasMarkup("services-icon-warning", 25, 22),"Vendor popup warning override is |cffFFD100Active|r")

L.HELPTIP_FILTER_TILE = "You can click items in this list to toggle between vendor or ignore. Ignored items are not vendored."

vm.locales = L;