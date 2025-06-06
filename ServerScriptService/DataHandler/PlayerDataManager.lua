-- PlayerDataManager.lua
-- Handles player data using ProfileStore (MAD STUDIO by loleris)
-- Place in: ServerScriptService/DataHandler/PlayerDataManager.lua

local ProfileStore = require(script.Parent.Parent.Modules.ProfileStore)

-- ProfileStore setup
local DATASTORE_NAME = "PlayerData"
local PROFILE_TEMPLATE = {
    Coins = 0,
    PlayerStatus = "Player",
    Inventory = {
        {Name = "Carrot Seed", Count = 10, Category = "Seeds", UniqueID = ""},
        {Name = "Apple", Count = 2, Category = "Fruit", UniqueID = "apple_001"},
        {Name = "Shovel", Count = 1, Category = "Tools", UniqueID = ""},
        {Name = "Fluffy Bunny", Count = 1, Category = "Pets", UniqueID = "pet_0001"},
    },
    Toolbar = {
        {Name = "Watering Can", Category = "Tools", UniqueID = "", Count = 1},
        {Name = "Apple Tree Seed", Category = "Seeds", UniqueID = "", Count = 5},
    }
}

local Players = game:GetService("Players")

-- Create the ProfileStore object
local PlayerProfileStore = ProfileStore.New(DATASTORE_NAME, PROFILE_TEMPLATE)

-- Keep track of loaded profiles
local Profiles = {}

-- Helper: Setup leaderstats for live coin tracking
local function setupLeaderstats(player, profile)
    local old = player:FindFirstChild("leaderstats")
    if old then old:Destroy() end

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = profile.Data.Coins or 0
    coins.Parent = leaderstats

    -- Update leaderstats when Coins change
    local prevCoins = coins.Value
    profile.OnAfterSave:Connect(function(savedData)
        if coins.Parent and savedData.Coins ~= prevCoins then
            coins.Value = savedData.Coins
            prevCoins = savedData.Coins
        end
    end)
end

-- Handler: Player Added
Players.PlayerAdded:Connect(function(player)
    -- Use UserId as profile key
    local profile = PlayerProfileStore:StartSessionAsync("Player_" .. player.UserId)
    if not profile then
        player:Kick("Could not load your player data. Please rejoin.")
        return
    end

    profile:AddUserId(player.UserId)
    profile:Reconcile() -- Ensure template fields are present

    Profiles[player] = profile

    -- Setup leaderstats
    setupLeaderstats(player, profile)

    -- Optional: developer status
    if player.UserId == game.CreatorId then
        profile.Data.PlayerStatus = "Developer"
    end
end)

-- Handler: Player Removing
Players.PlayerRemoving:Connect(function(player)
    local profile = Profiles[player]
    if profile then
        profile:EndSession()
        Profiles[player] = nil
    end
end)

-- Cleanup on shutdown (robustness)
game:BindToClose(function()
    for _, profile in pairs(Profiles) do
        profile:EndSession()
    end
end)

-- API: GetProfile for other scripts
function GetProfile(player)
    return Profiles[player]
end

return {
    GetProfile = GetProfile
}
