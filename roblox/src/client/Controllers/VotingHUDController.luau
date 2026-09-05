--!strict
-- Supplementary HUD for the physical voting platforms: shows the 3 candidates, live counts, your current vote, and an arrow hint.
local Players = game:GetService("Players")
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UIController)

local V = {}

function V:Init()
	local screen = UI.Screen :: ScreenGui
	self.Panel = Instance.new("Frame"); self.Panel.Name = "VotePanel"; self.Panel.Size = UDim2.new(0, 280, 0, 170); self.Panel.Position = UDim2.new(0, 16, 1, -190); self.Panel.BackgroundColor3 = Color3.fromRGB(24, 26, 36); self.Panel.BackgroundTransparency = 0.2; self.Panel.Visible = false; self.Panel.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = self.Panel
	UI:Label(self.Panel, "Stand on a platform to vote", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 4), 15).TextColor3 = Color3.fromRGB(180, 190, 255)
	self.Rows = {}
	for i = 1, 3 do
		local row = UI:Label(self.Panel, "", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 30 + (i - 1) * 44), 16)
		row.Font = Enum.Font.Gotham
		self.Rows[i] = row
	end
end

function V:Start()
	Net:On("VotingState", function(active: boolean, candidates, duration: number, winnerId: string?)
		self.Panel.Visible = active
		self._candidates = candidates or {}
		if active then
			for i, row in self.Rows do
				local cnd = candidates[i]
				row.Text = cnd and ("%d.  %s  —  %s"):format(i, cnd.DisplayName, cnd.Category) or ""
				row.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end)
	Net:On("VoteCountsChanged", function(counts: { number }, votes: { [any]: number })
		if not self.Panel.Visible then return end
		local mine = votes[tostring(Players.LocalPlayer.UserId)] or votes[Players.LocalPlayer.UserId]
		local leader, best = 0, -1
		for i, n in counts do if n > best then best = n; leader = i end end
		for i, row in self.Rows do
			local cnd = self._candidates and self._candidates[i]
			if cnd then
				row.Text = ("%d.  %s  —  %d vote%s%s"):format(i, cnd.DisplayName, counts[i] or 0, (counts[i] or 0) == 1 and "" or "s", mine == i and "   ◀ you" or "")
				row.TextColor3 = (i == leader and best > 0) and Color3.fromRGB(255, 230, 90) or Color3.new(1, 1, 1)
			end
		end
	end)
end

return V
