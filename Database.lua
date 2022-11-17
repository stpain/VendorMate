

local addonName, vm = ...;

local Database = {}
function Database:Init()
    
    if not VendorMateAccount then
        VendorMateAccount = {
            transactions = {},
            config = {},
            profiles = {},
        }
    end

    self.db = VendorMateAccount;

end

function Database:ResetAddon()

    self.db = nil;

    VendorMateAccount = {
        transactions = {},
        config = {},
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


function Database:AddTile(pkey, tile)
    if self.db and self.db.profiles then
        for k, profile in ipairs(self.db.profiles) do
            if profile.pkey == pkey then
                table.insert(profile.tiles, tile)
            end
        end
    end
end


function Database:NewTransaction(event, amount, character, vendor)
    
    if type(event) == "string" and type(amount) == "number" and type(character) == "string" then
        table.insert(VendorMateAccount.transactions, {
            datetime = time(),
            event = event,
            amount = amount,
            character = character,
            vendor = vendor,
        })
    end
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