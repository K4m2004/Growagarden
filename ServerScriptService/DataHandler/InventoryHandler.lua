-- InventoryHandler.lua
-- Backend logic for inventory and toolbar management
-- Place in: ServerScriptService/DataHandler/InventoryHandler.lua

local PlayerDataManager = require(script.Parent.PlayerDataManager)
local InventoryHandler = {}

-- Helper: Determines if an item is stackable based on its category
local function isStackable(item)
    return item.Category == "Seeds" or item.Category == "Tools"
end

-- Helper: Find item in a table, for stacking or unique match
local function findItem(tbl, item)
    for i, v in ipairs(tbl) do
        if isStackable(item) then
            if v.Name == item.Name and v.Category == item.Category then
                return i, v
            end
        else
            -- Fruit or Pets: match by uniqueID
            if v.UniqueID and item.UniqueID and v.UniqueID == item.UniqueID then
                return i, v
            end
        end
    end
    return nil
end

-- Add item to inventory (stack if possible)
function InventoryHandler.AddItemToInventory(player, itemData)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return false, "No profile found" end
    local inventory = profile.Data.Inventory

    local idx, existing = findItem(inventory, itemData)
    if isStackable(itemData) then
        if existing then
            existing.Count = (existing.Count or 1) + (itemData.Count or 1)
        else
            table.insert(inventory, {
                Name = itemData.Name,
                Count = itemData.Count or 1,
                Category = itemData.Category,
                UniqueID = itemData.UniqueID or "",
            })
        end
    else
        -- Non-stackable: always add as separate entry
        table.insert(inventory, {
            Name = itemData.Name,
            Count = 1,
            Category = itemData.Category,
            UniqueID = itemData.UniqueID or "",
            Weight = itemData.Weight, -- for fruit
            Mutation = itemData.Mutation, -- for fruit
        })
    end
    profile:Save()
    return true
end

-- Remove items from inventory (by count or uniqueID)
function InventoryHandler.RemoveItemFromInventory(player, itemData, count)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return false, "No profile found" end
    local inventory = profile.Data.Inventory

    local idx, entry = findItem(inventory, itemData)
    if not entry then return false, "Item not found" end

    if isStackable(entry) then
        if (entry.Count or 1) < (count or 1) then
            return false, "Not enough items"
        elseif (entry.Count or 1) == (count or 1) then
            table.remove(inventory, idx)
        else
            entry.Count = entry.Count - (count or 1)
        end
    else
        table.remove(inventory, idx)
    end
    profile:Save()
    return true
end

-- Checks if item is already in toolbar (no stacking, no duplicates)
local function isInToolbar(toolbar, item)
    for _, v in ipairs(toolbar) do
        if isStackable(item) then
            if v.Name == item.Name and v.Category == item.Category then
                return true
            end
        else
            if v.UniqueID and item.UniqueID and v.UniqueID == item.UniqueID then
                return true
            end
        end
    end
    return false
end

-- Finds next available slot (returns index or nil)
local function getNextToolbarSlot(toolbar)
    for i = 1, 6 do
        if not toolbar[i] or not toolbar[i].Name then
            return i
        end
    end
    return nil
end

-- Move item from inventory to toolbar (no duplicates)
function InventoryHandler.MoveItemToToolbar(player, itemData)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return false, "No profile found" end
    local inventory = profile.Data.Inventory
    local toolbar = profile.Data.Toolbar

    -- Check for duplicate in toolbar
    if isInToolbar(toolbar, itemData) then
        return false, "Already in toolbar"
    end

    -- Remove from inventory
    local idx, entry = findItem(inventory, itemData)
    if not entry then return false, "Item not found in inventory" end

    -- Find slot
    local slot = getNextToolbarSlot(toolbar)
    if not slot then return false, "No free toolbar slots" end

    -- For stackable: move whole stack to toolbar, remove from inventory
    -- For non-stackable: move this item to toolbar, remove from inventory
    toolbar[slot] = entry
    table.remove(inventory, idx)
    profile:Save()
    return true
end

-- Remove item from toolbar (puts back to inventory)
function InventoryHandler.RemoveItemFromToolbar(player, slotIndex)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return false, "No profile found" end
    local toolbar = profile.Data.Toolbar
    local inventory = profile.Data.Inventory
    local item = toolbar[slotIndex]
    if not item then return false, "No item in slot" end

    -- Add back to inventory (stack or unique)
    InventoryHandler.AddItemToInventory(player, item)
    toolbar[slotIndex] = nil
    profile:Save()
    return true
end

-- Use (consume) an item from toolbar (decreases count or removes)
function InventoryHandler.UseToolbarItem(player, slotIndex, count)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return false, "No profile found" end
    local toolbar = profile.Data.Toolbar
    local item = toolbar[slotIndex]
    if not item then return false, "No item in slot" end

    count = count or 1

    if isStackable(item) then
        if (item.Count or 1) <= count then
            toolbar[slotIndex] = nil
        else
            item.Count = item.Count - count
        end
    else
        toolbar[slotIndex] = nil
    end

    profile:Save()
    return true
end

function InventoryHandler.GetInventory(player)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return nil end
    return profile.Data.Inventory
end

function InventoryHandler.GetToolbar(player)
    local profile = PlayerDataManager.GetProfile(player)
    if not profile then return nil end
    return profile.Data.Toolbar
end

return InventoryHandler
