local econ_item_quality = {
    AE_UNDEFINED = -1,

    AE_NORMAL = 0,
    AE_RARITY1 = 1, -- Genuine
    AE_RARITY2 = 2, -- Customized (unused)
    AE_VINTAGE = 3, -- Vintage has to stay at 3 for backwards compatibility
    AE_RARITY3 = 4, -- Artisan
    AE_UNUSUAL = 5, -- Unusual
    AE_UNIQUE = 6,
    AE_COMMUNITY = 7,
    AE_DEVELOPER = 8,
    AE_SELFMADE = 9,
    AE_CUSTOMIZED = 10, -- (unused)
    AE_STRANGE = 11,
    AE_COMPLETED = 12,
    AE_HAUNTED = 13,
    AE_COLLECTORS = 14,
    AE_PAINTKITWEAPON = 15,

    AE_RARITY_DEFAULT = 16,
    AE_RARITY_COMMON = 17,
    AE_RARITY_UNCOMMON = 18,
    AE_RARITY_RARE = 19,
    AE_RARITY_MYTHICAL = 20,
    AE_RARITY_LEGENDARY = 21,
    AE_RARITY_ANCIENT = 22,
 }

local econ_item_origin = {
    kEconItemOrigin_Invalid = -1, -- should never be stored in the DB! used to indicate "invalid" for in-memory objects only

    kEconItemOrigin_Drop = 0,
    kEconItemOrigin_Achievement = 1,
    kEconItemOrigin_Purchased = 2,
    kEconItemOrigin_Traded = 3,
    kEconItemOrigin_Crafted = 4,
    kEconItemOrigin_StorePromotion = 5,
    kEconItemOrigin_Gifted = 6,
    kEconItemOrigin_SupportGranted = 7,
    kEconItemOrigin_FoundInCrate = 8,
    kEconItemOrigin_Earned = 9,
    kEconItemOrigin_ThirdPartyPromotion = 10,
    kEconItemOrigin_GiftWrapped = 11,
    kEconItemOrigin_HalloweenDrop = 12,
    kEconItemOrigin_PackageItem = 13,
    kEconItemOrigin_Foreign = 14,
    kEconItemOrigin_CDKey = 15,
    kEconItemOrigin_CollectionReward = 16,
    kEconItemOrigin_PreviewItem = 17,
    kEconItemOrigin_SteamWorkshopContribution = 18,
    kEconItemOrigin_PeriodicScoreReward = 19,
    kEconItemOrigin_MvMMissionCompletionReward = 20, -- includes loot from both "mission completed" and "tour completed" events
    kEconItemOrigin_MvMSquadSurplusReward = 21,
    kEconItemOrigin_RecipeOutput = 22,
    kEconItemOrigin_QuestDrop = 23,
    kEconItemOrigin_QuestLoanerItem = 24,
    kEconItemOrigin_TradeUp = 25,
    kEconItemOrigin_ViralCompetitiveBetaPassSpread = 26,

    kEconItemOrigin_Max = 27
 }

local itemdef
do
    local function fn( item_definition )
        if not itemdef and item_definition:IsWearable() then
            itemdef = item_definition
            return
        end
    end
    itemschema.Enumerate( fn )
end

-- min item level: 0x100, max item level: 0xfff (tho defined in src leak was 100)
-- for getting current inventory position, could either Enumerate entire inventory

local itemID64, level = -1, 254

local quality = econ_item_quality.AE_HAUNTED
local origin = econ_item_origin.kEconItemOrigin_Drop -- doesn't matter. 
local pickupOrPosition, isNewItem = 1, true

inventory.CreateFakeItem( itemdef, pickupOrPosition, itemID64, quality, origin, level, isNewItem )
