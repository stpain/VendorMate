

local addonName, addon = ...;

--[[

GridView

create a gridview widget that will scale with a resizable UI,
frames added to the grid can make use of the following methods

:SetDataBinding, this method is called when adding items

:ResetDataBinding, this method is called before SetDataBinding if you want to tidy up any frame elements

:UpdateLayout, this method is called last and can be used to update the size and layout of elements within the frame

specifically of note is that :UpdateLayout will be called on each frame when calling :UpdateLayout on the gridview itself

]]
VendorMateGridviewMixin = {}
function VendorMateGridviewMixin:OnLoad()
    self.data = {}
    self.frames = {}
    self.itemMinWidth = 0
    self.itemMaxWidth = 0
    self.itemSize = 0
    self.colIndex = 0
    self.rowIndex = 0
    self.numItemsPerRow = 1
end

function VendorMateGridviewMixin:InitFramePool(type, template)
    self.framePool = CreateFramePool(type, self, template);
end

function VendorMateGridviewMixin:SetMinMaxSize(min, max)
    self.itemMinWidth = min;
    self.itemMaxWidth = max;
end

function VendorMateGridviewMixin:Insert(info)
    table.insert(self.data, info)

    local f = self.framePool:Acquire()
    f:SetID(#self.data)

    if f.SetDataBinding then
        f:SetDataBinding(self.data[#self.data])
    end

    f:Show()
    table.insert(self.frames, f)

    self:UpdateLayout()
end

function VendorMateGridviewMixin:RemoveFrame(frame)
    local key;
    for k, f in ipairs(self.frames) do
        if f:GetID() == frame:GetID() then
            if f.ResetDataBinding then
                f:ResetDataBinding()
            end
            key = k;
            self.framePool:Release(f)
        end
    end
    if type(key) == "number" then
        table.remove(self.frames, key)
    end
    self:UpdateLayout()
end

function VendorMateGridviewMixin:InsertTable(tbl)

end

function VendorMateGridviewMixin:Flush()
    self.data = {}
    for k, f in ipairs(self.frames) do
        if f.ResetDataBinding then
            f:ResetDataBinding()
        end
        f:Hide()
    end
    self.frames = {}
    self.framePool:ReleaseAll()
end

function VendorMateGridviewMixin:GetItemSize()
    local width = self:GetWidth()

    local numItemsPerRowMinWidth = width / self.itemMinWidth;
    local numItemsPerRowMaxWidth = width / self.itemMaxWidth;

    self.numItemsPerRow =  math.ceil(((numItemsPerRowMinWidth + numItemsPerRowMaxWidth) / 2))

    self.itemSize = (width / self.numItemsPerRow)

    --[[
        this next bit was a first attempt to fix the min/max sizes
        however having a fixed size means the items wont always 
        adjust to fill each row, so leaving the older math in place
    ]]

    --self.numItemsPerRow =  math.ceil(width / self.itemMinWidth)

    -- if self.itemSize < self.itemMinWidth then
    --     self.itemSize = (width / (self.numItemsPerRow - 1))
    -- end
    -- if self.itemSize > self.itemMaxWidth then
    --     self.itemSize = self.itemMaxWidth
    --     self.numItemsPerRow =  math.floor(width / self.itemMaxWidth)
    -- end
end

function VendorMateGridviewMixin:UpdateLayout()
    self:GetItemSize()

    self.colIndex = 0;
    self.rowIndex = 0;

    for k, f in ipairs(self.frames) do
        f:ClearAllPoints()
        f:SetSize(self.itemSize, self.itemSize)
        f:SetPoint("TOPLEFT", self.itemSize * self.colIndex, -(self.itemSize * self.rowIndex))
        if k < (self.numItemsPerRow * (self.rowIndex + 1)) then
            self.colIndex = self.colIndex + 1
        else
            self.colIndex = 0
            self.rowIndex = self.rowIndex + 1
        end
        if f.UpdateLayout then
            f:UpdateLayout()
        end
        f:Show()
    end
end

function VendorMateGridviewMixin:GetFrames()
    return self.frames;
end