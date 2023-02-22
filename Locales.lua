

local addonName, vm = ...;

local L = {}

L.ADDON_LOADED = "[%s] loaded."

L.HELP_ABOUT = "VendorMate\n\nBags full of junk? Old world epics hiding in plain sight?\n\nNo problems. Go to the Vendor tab and create some filters. Type a filter name into the Add Filter box and tap enter (or click the +). Then you can configure each filter to certain items.\n\nFilters take priority from top left moving accross and then down. This means if an item matches filter 2 and 3, it'll be sorted into filter 2 as it comes first.\n\nYou can vendor filters individually or all together, a dialog will popup with some info and a confirm button. You can also choose to auto click confirm vendor dialogs."
L.AUTO_VENDOR_JUNK = "Auto vendor junk items"

L.TABS_VENDOR = "Vendor"
L.TABS_HISTORY = "History"
L.TABS_OPTIONS = "Options"

L.FILTER_BUTTON_SETTINGS_TT = "Settings"
L.FILTER_BUTTON_VENDOR_TT = "Vendor items"
L.FILTER_BUTTON_LOCK_TOGGLE_TT = "Toggle item lock"

L.DIALOG_VENDOR_CONFIRM = "Auto click confirm warnings?"

L.VENDORING_OVERRIDE_POPUP_WARNING = string.format("%s %s", CreateAtlasMarkup("services-icon-warning", 25, 22),"Vendor popup warning override is |cffFFD100Active|r")

L.HELPTIP_VENDOR_FILTERS = string.format("Filters\n\nYou can click items in this list to toggle between vendor or ignore. Ignored items are not vendored.\n\n%s Filter settings\n%s Delete filter\n%s Item lock toggle\n%s Vendor items",
    CreateAtlasMarkup("mechagon-projects", 16, 16),
    CreateAtlasMarkup("transmog-icon-remove", 16, 16),
    CreateAtlasMarkup("vignetteloot-locked", 16, 16),
    CreateAtlasMarkup("Banker", 16, 16)
)

L.HELPTIP_VENDOR_PROFILES = "Profiles\n\nYou can select a profile here to quickly swap between vendoring systems based on current game activity."

vm.locales = L;