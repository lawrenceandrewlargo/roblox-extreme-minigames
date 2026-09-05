--!strict
-- Server-validated cosmetic purchases and equips. Cosmetics never affect gameplay.
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)

local CosmeticService = {}
CosmeticService.Catalog = {
	TrailNone = { Price = 0, Slot = "Trail" }, TrailFire = { Price = 250, Slot = "Trail" }, TrailRainbow = { Price = 600, Slot = "Trail" },
	TitleRookie = { Price = 100, Slot = "Title" }, TitleChaos = { Price = 900, Slot = "Title" }, WinConfetti = { Price = 400, Slot = "Victory" },
}

function CosmeticService:Init()
	Remotes:SetCallback("PurchaseCosmetic", function(player, id)
		if type(id) ~= "string" then return { ok = false, error = "invalid" } end
		local item = self.Catalog[id]
		local prof = DataService:Get(player)
		if not item or not prof then return { ok = false, error = "unknown" } end
		if prof.Cosmetics.Owned[id] then return { ok = false, error = "owned" } end
		if prof.Coins < item.Price then return { ok = false, error = "insufficient_coins" } end
		prof.Coins -= item.Price
		prof.Cosmetics.Owned[id] = true
		DataService:MarkDirty(player)
		return { ok = true, coins = prof.Coins }
	end)
	Remotes:SetCallback("EquipCosmetic", function(player, id)
		if type(id) ~= "string" then return { ok = false, error = "invalid" } end
		local item = self.Catalog[id]
		local prof = DataService:Get(player)
		if not item or not prof or not prof.Cosmetics.Owned[id] then return { ok = false, error = "not_owned" } end
		prof.Cosmetics.Equipped[item.Slot] = id
		player:SetAttribute("Cosmetic_" .. item.Slot, id)
		DataService:MarkDirty(player)
		return { ok = true }
	end)
end
return CosmeticService
