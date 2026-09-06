--!strict
-- Procedural tile floors used by platform/reaction/memory games. Built inside ctx.Map and cleaned by its Janitor.
local Arena = require(script.Parent.Arena)

local TileGrid = {}
TileGrid.__index = TileGrid

export type Grid = typeof(setmetatable({} :: { Tiles: { { Part } }, Rows: number, Cols: number, Size: number, Origin: Vector3 }, TileGrid))

function TileGrid.new(ctx, rows: number, cols: number, size: number, origin: Vector3, colors: { Color3 }?): Grid
	local self = setmetatable({ Tiles = {}, Rows = rows, Cols = cols, Size = size, Origin = origin }, TileGrid)
	for r = 1, rows do
		self.Tiles[r] = {}
		for c = 1, cols do
			local color = colors and colors[ctx.Rng:NextInteger(1, #colors)] or Color3.fromRGB(200, 200, 210)
			local tile = Arena.Part(ctx, {
				Name = ("Tile_%d_%d"):format(r, c), Size = Vector3.new(size - 0.2, 1, size - 0.2),
				Position = origin + Vector3.new((c - (cols + 1) / 2) * size, 0, (r - (rows + 1) / 2) * size), Color = color, Material = Enum.Material.SmoothPlastic,
			})
			tile:SetAttribute("Row", r); tile:SetAttribute("Col", c)
			self.Tiles[r][c] = tile
		end
	end
	return self :: any
end

function TileGrid:TileUnder(position: Vector3): Part?
	local rel = position - self.Origin
	local c = math.round(rel.X / self.Size + (self.Cols + 1) / 2)
	local r = math.round(rel.Z / self.Size + (self.Rows + 1) / 2)
	local row = self.Tiles[r]
	local tile = row and row[c]
	if tile and tile.Parent and math.abs(position.Y - tile.Position.Y) < 6 then return tile end
	return nil
end

function TileGrid:ForEach(fn: (Part, number, number) -> ())
	for r, row in self.Tiles do for c, t in row do if t.Parent then fn(t, r, c) end end end
end

function TileGrid:Drop(tile: Part, ctx, delaySeconds: number)
	if tile:GetAttribute("Dropping") then return end
	tile:SetAttribute("Dropping", true)
	ctx.Janitor:AddThread(task.delay(delaySeconds, function()
		if tile.Parent then tile.Anchored = false; tile.CanCollide = false; task.delay(3, function() if tile.Parent then tile:Destroy() end end) end
	end))
end

function TileGrid:Remaining(): number
	local n = 0
	self:ForEach(function() n += 1 end)
	return n
end

function TileGrid:Center(): Vector3 return self.Origin + Vector3.new(0, 3, 0) end

return TileGrid
