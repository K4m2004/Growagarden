-- InventoryNetworkHandler.lua
-- Handles all inventory/toolbar remote events from clients

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryHandler = require(script.Parent.InventoryHandler)

local Remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")

-- Add item to toolbar
Remotes.RequestAddToToolbar.OnServerEvent:Connect(function(player, itemData)
	local success, msg = InventoryHandler.MoveItemToToolbar(player, itemData)
	Remotes.GetPlayerToolbar:InvokeClient(player, InventoryHandler.GetToolbar(player))
	Remotes.GetPlayerInventory:InvokeClient(player, InventoryHandler.GetInventory(player))
end)

-- Remove item from toolbar
Remotes.RequestRemoveFromToolbar.OnServerEvent:Connect(function(player, slotIndex)
	local success, msg = InventoryHandler.RemoveItemFromToolbar(player, slotIndex)
	Remotes.GetPlayerToolbar:InvokeClient(player, InventoryHandler.GetToolbar(player))
	Remotes.GetPlayerInventory:InvokeClient(player, InventoryHandler.GetInventory(player))
end)

-- Use toolbar item
Remotes.RequestUseToolbarItem.OnServerEvent:Connect(function(player, slotIndex, count)
	local success, msg = InventoryHandler.UseToolbarItem(player, slotIndex, count)
	Remotes.GetPlayerToolbar:InvokeClient(player, InventoryHandler.GetToolbar(player))
	Remotes.GetPlayerInventory:InvokeClient(player, InventoryHandler.GetInventory(player))
end)

-- Add item to inventory (optional/test)
Remotes.RequestAddToInventory.OnServerEvent:Connect(function(player, itemData)
	local success, msg = InventoryHandler.AddItemToInventory(player, itemData)
	Remotes.GetPlayerInventory:InvokeClient(player, InventoryHandler.GetInventory(player))
end)

-- Respond to inventory requests
Remotes.GetPlayerInventory.OnServerInvoke = function(player)
	return InventoryHandler.GetInventory(player)
end

Remotes.GetPlayerToolbar.OnServerInvoke = function(player)
	return InventoryHandler.GetToolbar(player)
end
