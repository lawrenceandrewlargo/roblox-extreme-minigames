--!strict
-- Profile / stats / cosmetics / challenges / settings windows. Opened from a compact side menu (never traps input).
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UIController)
local P = {}

local COSMETICS = { { Id = "TrailNone", Name = "No Trail", Price = 0, Slot = "Trail" }, { Id = "TrailFire", Name = "Fire Trail", Price = 250, Slot = "Trail" }, { Id = "TrailRainbow", Name = "Rainbow Trail", Price = 600, Slot = "Trail" }, { Id = "TitleRookie", Name = "Title: Rookie", Price = 100, Slot = "Title" }, { Id = "TitleChaos", Name = "Title: Agent of Chaos", Price = 900, Slot = "Title" }, { Id = "WinConfetti", Name = "Victory Confetti", Price = 400, Slot = "Victory" } }

function P:Init()
	local screen = UI.Screen :: ScreenGui
	local menu = Instance.new("Frame"); menu.Size = UDim2.new(0, 56, 0, 4 * 52); menu.Position = UDim2.new(1, -66, 0.5, -104); menu.BackgroundTransparency = 1; menu.Parent = screen
	local items = { { "👤", "Profile" }, { "🛍", "Shop" }, { "🎯", "Challenges" }, { "⚙", "Settings" } }
	for i, it in items do UI:Button(menu, it[1], UDim2.fromOffset(48, 44), UDim2.new(0, 0, 0, (i - 1) * 52), function() self:Refresh(); UI:Toggle(it[2]) end) end

	local pb = UI:CreateWindow("Profile", "Profile & Stats", UDim2.fromOffset(420, 320))
	self.ProfileText = UI:Label(pb, "Loading...", UDim2.fromScale(1, 1), UDim2.new(), 17); self.ProfileText.Font = Enum.Font.Gotham; self.ProfileText.TextYAlignment = Enum.TextYAlignment.Top

	local sb = UI:CreateWindow("Shop", "Cosmetics", UDim2.fromOffset(460, 420))
	self.ShopList = Instance.new("ScrollingFrame"); self.ShopList.BackgroundTransparency = 1; self.ShopList.Size = UDim2.fromScale(1, 1); self.ShopList.AutomaticCanvasSize = Enum.AutomaticSize.Y; self.ShopList.CanvasSize = UDim2.new(); self.ShopList.ScrollBarThickness = 6; self.ShopList.Parent = sb
	local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 6); l.Parent = self.ShopList

	local cb = UI:CreateWindow("Challenges", "Challenges & Achievements", UDim2.fromOffset(420, 360))
	self.ChallengeText = UI:Label(cb, "", UDim2.fromScale(1, 1), UDim2.new(), 16); self.ChallengeText.Font = Enum.Font.Gotham; self.ChallengeText.TextYAlignment = Enum.TextYAlignment.Top

	local stb = UI:CreateWindow("Settings", "Settings", UDim2.fromOffset(380, 260))
	local y = 0
	for _, s in { { "MusicVolume", "Music" }, { "SfxVolume", "SFX" } } do
		UI:Label(stb, s[2], UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, y))
		for i, v in { 0, 0.5, 1 } do UI:Button(stb, ({ "Off", "Mid", "Max" })[i], UDim2.fromOffset(70, 32), UDim2.new(0, 110 + (i - 1) * 78, 0, y + 2), function() Net:Invoke("UpdateSettings", { [s[1]] = v }) end) end
		y += 44
	end
	UI:Button(stb, "Toggle Reduce Motion", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, y), function() self:Refresh(); local prof = self._profile; if prof then Net:Invoke("UpdateSettings", { ReduceMotion = not prof.Settings.ReduceMotion }) end end)
end

function P:Refresh()
	local res = Net:Invoke("GetProfile")
	if not res or not res.ok then return end
	local prof = res.profile
	self._profile = prof
	self.ProfileText.Text = ("Level %d   •   %d XP\nCoins: %d   •   Crowns: %d\n\nWins: %d\nRounds played: %d\nAchievements: %d"):format(prof.Level, prof.XP, prof.Coins, prof.Crowns, prof.Stats.Wins, prof.Stats.RoundsPlayed, (function() local n = 0 for _ in prof.Achievements do n += 1 end return n end)())
	for _, c in self.ShopList:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
	for _, item in COSMETICS do
		local owned = prof.Cosmetics.Owned[item.Id]
		local equipped = prof.Cosmetics.Equipped[item.Slot] == item.Id
		UI:Button(self.ShopList, ("%s  —  %s"):format(item.Name, equipped and "Equipped" or owned and "Equip" or (item.Price .. " coins")), UDim2.new(1, -8, 0, 40), UDim2.new(), function()
			if owned then Net:Invoke("EquipCosmetic", item.Id) else Net:Invoke("PurchaseCosmetic", item.Id) end
			self:Refresh()
		end)
	end
	local lines = { "DAILY" }
	for id, v in prof.Challenges.Daily do table.insert(lines, ("  %s: %s"):format(id, v == -1 and "✔ complete" or tostring(v))) end
	table.insert(lines, "WEEKLY")
	for id, v in prof.Challenges.Weekly do table.insert(lines, ("  %s: %s"):format(id, v == -1 and "✔ complete" or tostring(v))) end
	table.insert(lines, "ACHIEVEMENTS")
	for id in prof.Achievements do table.insert(lines, "  🏆 " .. id) end
	self.ChallengeText.Text = table.concat(lines, "\n")
end

function P:Start() end
return P
