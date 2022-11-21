

local addonName, vm = ...;

local Database = {}
function Database:Init()
    
    if not VendorMateAccount then
        VendorMateAccount = {
            transactions = {},
            config = {
                overridePopup = false;
                minimapButton = {},
                currentProfile = false,
            },
            profiles = {},
        }
    end

    self.db = VendorMateAccount;

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
    }

    self.db = VendorMateAccount;
end

function Database:NewProfile(profile)
    if self.db then
        table.insert(self.db.profiles, profile)
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

function Database:NewTransaction(event, amount, count, character, vendor, link)
    
    if type(event) == "string" and type(amount) == "number" and type(count) == "number" and type(character) == "string" and type(character) == "string" then
        table.insert(VendorMateAccount.transactions, {
            datetime = time(),
            event = event,
            amount = amount,
            count = count,
            character = character,
            vendor = vendor,
            link = link,
        })
    end
end

function Database:GetAllTransactions()
    local t = {}
    for k, transaction in ipairs(self.db.transactions) do
        table.insert(t, transaction)
    end
    return t;
end

function Database:GetTransactions(from, to)
    
    if type(from) == "number" and type(to) == "number" then
        local t = {}
        for k, transaction in ipairs(self.db.transactions) do
            if (transaction.datetime >= from) and (transaction.datetime <= to) then
                table.insert(t, transaction)
            end
        end
        return t;

    else
        return self.db.transactions;
    end
end

vm.database = Database;