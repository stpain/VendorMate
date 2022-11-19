

local addonName, vm = ...;

local L = {}

L.ADDON_LOADED = "[%s] loaded."

L.TABS_VENDOR = "Vendor"
L.TABS_HISTORY = "History"
L.TABS_OPTIONS = "Options"

L.FILTER_BUTTON_SETTINGS_TT = "Settings"
L.FILTER_BUTTON_VENDOR_TT = "Vendor items"
L.FILTER_BUTTON_LOCK_TOGGLE_TT = "Toggle item lock"


L.HELPTIP_FILTER_TILE = "You can click items in this list to toggle between vendor or ignore. Ignored items are not vendored."

vm.locales = L;