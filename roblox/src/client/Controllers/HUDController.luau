--!strict
-- Phase banner, timer, countdown, announcements, minigame intro, results, rewards, generic minigame event feed.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UIController)

local HUD = { _timerEnd = 0 }

function HUD:Init()
	local screen = UI.Screen :: ScreenGui
	local top = Instance.new("Frame"); top.Name = "TopBar"; top.BackgroundTransparency = 1; top.Size = UDim2.new(1, 0, 0, 70); top.Parent = screen
	self.Phase = UI:Label(top, "Lobby", UDim2.new(0.5, 0, 0, 34), UDim2.new(0.25, 0, 0, 8), 24); self.Phase.TextXAlignment = Enum.TextXAlignment.Center; self.Phase.TextStrokeTransparency = 0.5
	self.Timer = UI:Label(top, "", UDim2.new(0.5, 0, 0, 30), UDim2.new(0.25, 0, 0, 40), 20); self.Timer.TextXAlignment = Enum.TextXAlignment.Center
	self.Score = UI:Label(top, "", UDim2.new(0, 200, 0, 30), UDim2.new(1, -216, 0, 12), 18); self.Score.TextXAlignment = Enum.TextXAlignment.Right
	self.Status = UI:Label(top, "", UDim2.new(0, 260, 0, 30), UDim2.new(0, 16, 0, 12), 18)
	self.Countdown = UI:Label(screen, "", UDim2.fromOffset(300, 150), UDim2.new(0.5, -150, 0.35, 0), 96); self.Countdown.TextXAlignment = Enum.TextXAlignment.Center; self.Countdown.TextStrokeTransparency = 0.3
	self.Feed = Instance.new("Frame"); self.Feed.BackgroundTransparency = 1; self.Feed.Size = UDim2.new(0, 360, 0, 200); self.Feed.Position = UDim2.new(0.5, -180, 0, 80); self.Feed.Parent = screen
	local layout = Instance.new("UIListLayout"); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Padding = UDim.new(0, 4); layout.Parent = self.Feed
	self.Banner = UI:Label(screen, "", UDim2.new(0, 700, 0, 60), UDim2.new(0.5, -350, 0.8, 0), 28); self.Banner.TextXAlignment = Enum.TextXAlignment.Center; self.Banner.TextStrokeTransparency = 0.3; self.Banner.BackgroundTransparency = 0.5; self.Banner.BackgroundColor3 = Color3.new(0, 0, 0); self.Banner.Visible = false
	local rb = UI:CreateWindow("Results", "Round Results", UDim2.fromOffset(460, 420))
	self.ResultsList = Instance.new("ScrollingFrame"); self.ResultsList.BackgroundTransparency = 1; self.ResultsList.Size = UDim2.fromScale(1, 1); self.ResultsList.CanvasSize = UDim2.new(0, 0, 0, 0); self.ResultsList.AutomaticCanvasSize = Enum.AutomaticSize.Y; self.ResultsList.ScrollBarThickness = 6; self.ResultsList.Parent = rb
	local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 4); ll.Parent = self.ResultsList
	local ib = UI:CreateWindow("Intro", "Next Up", UDim2.fromOffset(520, 260))
	self.IntroTitle = UI:Label(ib, "", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), 32)
	self.IntroDesc = UI:Label(ib, "", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 50), 18); self.IntroDesc.Font = Enum.Font.Gotham
	self.IntroMeta = UI:Label(ib, "", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 140), 16); self.IntroMeta.TextColor3 = Color3.fromRGB(180, 190, 255)
end

function HUD:Toast(text: string, color: Color3?, duration: number?)
	local l = UI:Label(self.Feed, text, UDim2.new(1, 0, 0, 28), UDim2.new(), 18); l.TextXAlignment = Enum.TextXAlignment.Center; l.TextColor3 = color or Color3.new(1, 1, 1); l.TextStrokeTransparency = 0.4
	task.delay(duration or 3, function() TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play(); task.wait(0.4); l:Destroy() end)
end

function HUD:ShowBanner(text: string, duration: number)
	self.Banner.Text = text; self.Banner.Visible = true
	self._bannerToken = (self._bannerToken or 0) + 1
	local token = self._bannerToken
	task.delay(duration, function() if self._bannerToken == token then self.Banner.Visible = false end end)
end

function HUD:Start()
	Net:On("PhaseChanged", function(phase: string, duration: number, round: number)
		self.Phase.Text = ({ Lobby = "Lobby", Intermission = "Next round soon", Voting = "VOTE: stand on a platform!", MapSelection = "Selecting map...", Intro = "Get ready", Countdown = "Starting", Gameplay = "GO!", Results = "Results", Rewards = "Rewards" })[phase] or phase
		self._timerEnd = duration > 0 and os.clock() + duration or 0
		if phase == "Lobby" or phase == "Intermission" then UI:Close("Results"); UI:Close("Intro"); self.Score.Text = ""; self.Status.Text = "" end
		if phase == "Gameplay" then UI:Close("Intro") end
	end)
	Net:On("Countdown", function(n: number) self.Countdown.Text = n > 0 and tostring(n) or "GO!"; if n == 0 then task.delay(0.8, function() if self.Countdown.Text == "GO!" then self.Countdown.Text = "" end end) end end)
	Net:On("Announcement", function(a) self:Toast(a.Text, a.Kind == "Warning" and Color3.fromRGB(255, 120, 90) or a.Kind == "Event" and Color3.fromRGB(255, 220, 90) or nil, a.Duration) if a.Priority >= 3 then self:ShowBanner(a.Text, a.Duration) end end)
	Net:On("MinigameIntro", function(info) self.IntroTitle.Text = info.DisplayName; self.IntroDesc.Text = info.Description; self.IntroMeta.Text = ("Map: %s   •   Modifier: %s"):format(info.MapId, info.ModifierId); UI:Open("Intro") end)
	Net:On("HUDUpdate", function(d) if d.Score then self.Score.Text = "Score: " .. tostring(math.floor(d.Score)) end end)
	Net:On("PlayerStateChanged", function(state: string, role: string?, team: string?) self.Status.Text = (role and (role .. "  ") or "") .. (team and ("[" .. team .. "]  ") or "") .. state end)
	Net:On("Results", function(result)
		for _, c in self.ResultsList:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
		for _, e in result.Entries do
			local p = Players:GetPlayerByUserId(e.UserId)
			local l = UI:Label(self.ResultsList, ("#%d  %s  —  %d pts%s"):format(e.Placement, p and p.DisplayName or tostring(e.UserId), math.floor(e.Score), e.Won and "  👑" or ""), UDim2.new(1, -8, 0, 30), UDim2.new(), 18)
			if e.UserId == Players.LocalPlayer.UserId then l.TextColor3 = Color3.fromRGB(255, 230, 120) end
		end
		UI:Open("Results")
	end)
	Net:On("RewardsGranted", function(r, placement: number, level: number?) self:Toast(("+%d XP  +%d coins%s"):format(r.XP, r.Coins, r.Crowns > 0 and ("  +%d 👑"):format(r.Crowns) or ""), Color3.fromRGB(150, 255, 170), 4) end)
	Net:On("MinigameEvent", function(event: string, a, b, c)
		local me = Players.LocalPlayer.UserId
		local function name(id) local p = id and Players:GetPlayerByUserId(id) return p and p.DisplayName or "?" end
		if event == "Eliminated" then self:Toast(name(a) .. " eliminated" .. (b and (" (" .. tostring(b) .. ")") or ""), Color3.fromRGB(255, 140, 140))
		elseif event == "Finished" then self:Toast(name(a) .. " finished #" .. tostring(b), Color3.fromRGB(150, 255, 170))
		elseif event == "BombHolder" then self.Status.Text = a == me and "YOU HAVE THE BOMB!" or ("Bomb: " .. name(a))
		elseif event == "BombTick" and type(a) == "number" and a <= 5 then self.Countdown.Text = tostring(a); task.delay(0.6, function() if self.Countdown.Text == tostring(a) then self.Countdown.Text = "" end end)
		elseif event == "BombExplode" then self:ShowBanner("💥 " .. name(a) .. " exploded!", 2)
		elseif event == "ColorCall" then self:ShowBanner((c and "WAIT— " or "") .. "GET TO " .. tostring(a):upper() .. "!", b)
		elseif event == "Light" then self:ShowBanner(a == "Green" and "🟢 GREEN LIGHT" or a == "Red" and "🔴 RED LIGHT" or "🟡 ...", 1.5)
		elseif event == "Simon" then self:ShowBanner((b and "Simon says: " or "") .. tostring(a), c)
		elseif event == "Phase" then self:ShowBanner(tostring(a) .. " phase!", 2)
		elseif event == "Disaster" or event == "HazardWarning" then self:ShowBanner("⚠ " .. tostring(a), 3)
		elseif event == "Memorize" then self:ShowBanner("Memorize!", a) elseif event == "Go" then self:ShowBanner("GO!", 1)
		elseif event == "Lives" then self.Status.Text = "Lives: " .. tostring(a) elseif event == "Ammo" then self.Status.Text = "Ammo: " .. tostring(a)
		elseif event == "TugPosition" then self.Score.Text = "Rope: " .. tostring(a) elseif event == "TeamScore" then self.Score.Text = ("Red %d — Blue %d"):format(a, b)
		elseif event == "PullPrompt" then task.delay(a, function() self:ShowBanner("PULL!", b) end)
		elseif event == "RoundOver" then self:ShowBanner("Round over", 2)
		elseif event == "CutTimer" and a <= 3 then self:Toast("Elimination in " .. tostring(a), Color3.fromRGB(255, 140, 140), 0.9)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local rem = self._timerEnd - os.clock()
			self.Timer.Text = rem > 0 and ("%d:%02d"):format(math.floor(rem / 60), math.floor(rem % 60)) or ""
		end
	end)
end

return HUD
