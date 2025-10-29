

local addonName, vm = ...;

local Database = {}
function Database:Init()
    
    if not VendorMateAccount then
        VendorMateAccount = {
            transactions = {},
            config = {
                overridePopup = false,
                minimapButton = {},
                currentProfile = false,
                autoVendorJunk = false,
            },
            profiles = {},
        }
    end

    self.db = VendorMateAccount;

    vm:TriggerEvent("Database_OnInitialised")

    if ViragDevTool_AddData then
        ViragDevTool_AddData(self.db, "VendorMate")
    end

end

function Database:AddMerchantOrder(_profile, order)
    if self.db and self.db.profiles then
        for k, profile in ipairs(self.db.profiles) do
            if profile.pkey == _profile.pkey then
                if profile.merchant == nil then
                    profile.merchant = {}
                end
                table.insert(profile.merchant, order)
                vm:TriggerEvent("Database_OnMerchantOrderItemAdded", profile.merchant)
            end
        end
    end
end

function Database:GetMerchantOrders(profile)
    if self.db.merchant and self.db.merchant[profile] then
        return self.db.merchant[profile];
    end
end

function Database:AddConfig(key, val)
    if self.db and self.db.config then
        if not self.db.config[key] then
            self.db.config[key] = val
        else
            print(string.format("[%s] config %s exists", addonName, key))
        end
    end
end

function Database:ResetAddon()

    self.db = nil;

    VendorMateAccount = {
        transactions = {},
        config = {
            overridePopup = false;
            minimapButton = {},
            currentProfile = false,
        },
        profiles = {},
        merchant = {},
    }

    self.db = VendorMateAccount;
end

function Database:NewProfile(profile)
    if self.db then
        table.insert(self.db.profiles, profile)
    end
end

function Database:DeleteProfile(profile)
    if self.db and self.db.profiles then
        local i;
        for k, v in ipairs(self.db.profiles) do
            if v.pkey == profile.pkey then
                i = k;
            end
        end
        if i then
            table.remove(self.db.profiles, i)
        end
    end
end

function Database:GetProfile(pkey)
    if self.db.profiles then
        for k, profile in ipairs(self.db.profiles) do
            if profile.pkey == pkey then
                return profile;
            end
        end
    end
end

function Database:GetProfiles()
    if self.db then
        return self.db.profiles;
    end
end


function Database:SetConfig(key, val)
    self.db.config[key] = val;
end

function Database:GetConfig(key)
    return self.db.config[key];
end

function Database:AddTransaction(transaction)
    table.insert(self.db.transactions, transaction)
end

function Database:GetAllTransactions()
    return self.db.transactions;
end

function Database:DeleteTransaction(transaction)
    local keyToRemove;
    for k, v in ipairs(self.db.transactions) do
        if (v.timestamp == transaction.timestamp) and (v.action == transaction.action) and (v.profile == transaction.profile) then
            keyToRemove = k;
        end
    end
    if type(keyToRemove) == "number" then
        table.remove(self.db.transactions, keyToRemove)
        vm:TriggerEvent("Database_OnTransactionDeleted")
    end
end

function Database:GetTransactions(from, to, character, action)
    
    if type(from) == "number" and type(to) == "number" then
        local t = {}
        for k, transaction in ipairs(self.db.transactions) do
            if (transaction.timestamp >= from) and (transaction.timestamp <= to) and (transaction.profile == character) and (transaction.action == action) then
                table.insert(t, transaction)
            end
        end
        return t;

    else
        if (type(character) == "string") and (type(action) == "string") then
            local t = {}
            for k, transaction in ipairs(self.db.transactions) do
                if (transaction.profile == character) and (transaction.action == action) then
                    table.insert(t, transaction)
                end
            end
            return t;

        else
            if (type(character) == "string") or (type(action) == "string") then
                local t = {}
                for k, transaction in ipairs(self.db.transactions) do
                    if (transaction.profile == character) or (transaction.action == action) then
                        table.insert(t, transaction)
                    end
                end
                return t;
            end
        end
    end
    return self.db.transactions;
end

vm.database = Database;