

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
local GridView = {}
function GridView:New(parent, itemTemplate)

    local gridview = {
        parent = parent,
        data = {},
        frames = {},
        itemMinWidth = 0,
        itemMaxWidth = 0,
        itemSize = 0,
        colIndex = 0,
        rowIndex = 0,
        numItemsPerRow = 1,
        framePool = CreateFramePool("FRAME", parent, itemTemplate),
    }

    return Mixin(gridview, self)

end

--insert a single item into the gridview and draw the frame at the end
function GridView:Insert(item)

    table.insert(self.data, item)

    local f = self.framePool:Acquire()
    f:SetID(#self.data)

    if f.SetDataBinding then
        f:SetDataBinding(self.data[#self.data])
    end

    f:Show()
    table.insert(self.frames, f)

    self:UpdateLayout()

    print("gridview insert, new frame count", self.framePool:GetNumActive())

end

--insert a table and draw the frames
function GridView:InsertTable(data)
    
    self.data = data;

    self:GetItemSize()

    for i = 1, #self.data do
        local f = self.framePool:Acquire()

        f:ClearAllPoints()
        f:SetSize(self.itemSize, self.itemSize)

        if f.SetDataBinding then
            f:SetDataBinding(self.data[i])
        end
        if f.UpdateLayout then
            f:UpdateLayout()
        end

        f:SetPoint("TOPLEFT", self.itemSize * self.colIndex, -(self.itemSize * self.rowIndex))
        if i < (self.numItemsPerRow * (self.rowIndex + 1)) then
            self.colIndex = self.colIndex + 1
        else
            self.colIndex = 0
            self.rowIndex = self.rowIndex + 1
        end

        f:Show()
        table.insert(self.frames, f)
    end

end

--remove everything and hide
function GridView:Flush()
    print("pre flush release call frame count", self.framePool:GetNumActive())
    self.data = {}
    for k, f in ipairs(self.frames) do
        if f.ResetDataBinding then
            f:ResetDataBinding()
        end
        f:Hide()
    end
    wipe(self.frames)
    self.frames = {}
    self.framePool:ReleaseAll()
    print("post flush release call frame count", self.framePool:GetNumActive())
end

--set the min max widths for items, this is used to calculate a size to use when resizing
function GridView:SetMinMaxWidths(min, max)
    self.itemMinWidth = min;
    self.itemMaxWidth = max;
end

--work out a size for items based on parent width and min max widths
function GridView:GetItemSize()
    local width = self.parent:GetWidth()

    local numItemsPerRowMinWidth = width / self.itemMinWidth;
    local numItemsPerRowMaxWidth = width / self.itemMaxWidth;

    self.numItemsPerRow =  math.ceil(((numItemsPerRowMinWidth + numItemsPerRowMaxWidth) / 2))
    --self.numItemsPerRow =  math.ceil(width / self.itemMinWidth)

    self.itemSize = (width / self.numItemsPerRow)

    -- if self.itemSize < self.itemMinWidth then
    --     self.itemSize = (width / (self.numItemsPerRow - 1))
    -- end
    -- if self.itemSize > self.itemMaxWidth then
    --     self.itemSize = self.itemMaxWidth
    --     self.numItemsPerRow =  math.floor(width / self.itemMaxWidth)
    -- end

end

--update the layout
function GridView:UpdateLayout()

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

--questionable option
function GridView:GetFrames()
    return self.frames;
end

addon.gridview = GridView;