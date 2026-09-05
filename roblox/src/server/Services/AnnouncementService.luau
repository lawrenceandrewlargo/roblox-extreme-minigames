--!strict
local Remotes = require(script.Parent.Remotes)
local AnnouncementService = {}
-- kind: "Info" | "Warning" | "Round" | "Event" | "System"
function AnnouncementService:Broadcast(text: string, duration: number?, kind: string?, priority: number?)
	Remotes:FireAll("Announcement", { Text = text, Duration = duration or 4, Kind = kind or "Info", Priority = priority or 1 })
end
function AnnouncementService:Send(player: Player, text: string, duration: number?, kind: string?)
	Remotes:Fire("Announcement", player, { Text = text, Duration = duration or 4, Kind = kind or "Info", Priority = 1 })
end
return AnnouncementService
