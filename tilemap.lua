require 'wall'
Vec2 = require 'vec2'

function create_tilemap(tilemapObj)
    local self = {}

    self.width = tilemapObj.width
    self.height = tilemapObj.height
    self.tile_width = tilemapObj.tile_width
    self.tile_height = tilemapObj.tile_height

    local originObj = tilemapObj.origin or { x = -(self.width * self.tile_width) / 2, y = -(self.height * self.tile_height) / 2 }
    local offsetObj = tilemapObj.offset or { x = 0, y = 0 }
    self.origin = Vec2(originObj.x, originObj.y) + Vec2(offsetObj.x, offsetObj.y)

    self.tiles = {}

    for i = 1, self.width * self.height do
        table.insert(self.tiles, tilemapObj.data[i])
    end

    self.wall_manager = create_wall_manager(self.width * self.height + 1)

    self.worldToTileSpace = function(self, wcoord)
        assert(Vec2.isvec2(wcoord))
        local t = wcoord - self.origin
        t.x = math.floor(t.x / self.tile_width)
        t.y = math.floor(t.y / self.tile_height)
        return t
    end

    self.tileToWorldSpace = function(self, tcoord)
        assert(Vec2.isvec2(tcoord))
        local w = tcoord
        w.x = w.x * self.tile_width + (self.tile_width / 2)
        w.y = w.y * self.tile_height + (self.tile_height / 2)
        w = w + self.origin
        return w
    end

    self.xyToIndex = function(self, x, y)
        return y * self.width + x + 1
    end

    self.vecToIndex = function(self, pos)
        return self:xyToIndex(pos.x, pos.y)
    end

    self.indexToXy = function(self, index)
        local x = (index - 1) % self.width
        local y = math.floor((index - 1) / self.width)
        return Vec2(x, y)
    end

    self.setTile = function(self, pos, value)
        local i = self:vecToIndex(pos)
        self.tiles[i] = value
    end

    -- goes through the tile data and recreates walls and everything
    -- expensive, only call after setting tile data!
    self.recalculate = function(self)
        self.wall_manager:clear()

        local usedTiles = {}
        for i, _ in ipairs(self.tiles) do table.insert(usedTiles, false) end

        local walls = {}

        for current, v in ipairs(self.tiles) do
            if v == 1 and usedTiles[current] == false then
                local col, row = self:indexToXy(current):unpack()
                local left = col
                local right = left
                for x = left + 1, self.width - 1 do
                    local i = self:xyToIndex(x, math.floor(current / self.width))
                    print(tostring(x).." "..tostring(i).." "..tostring(right))
                    if usedTiles[i] == true or self.tiles[i] ~= 1 then
                        print("done")
                        break
                    else
                        right = right + 1
                    end
                end

                print("left: "..tostring(left).."  right: "..tostring(right))

                local top = row
                local bottom = top
                for y = top + 1, self.height do
                    local goodRow = true
                    for x = left, right do
                        local i = self:xyToIndex(x, y)
                        print(tostring(x).." "..tostring(y).." "..tostring(i).." "..tostring(self.tiles[i]).." "..tostring(usedTiles[i]))
                        if self.tiles[i] ~= 1 or usedTiles[i] == true then
                            goodRow = false
                            break
                        end
                    end
                    if goodRow then
                        bottom = bottom + 1
                    else
                        break
                    end
                end
                table.insert(walls, { l = left, r = right, t = top, b = bottom })
                for x = left, right do
                    for y = top, bottom do
                        local i = self:xyToIndex(x, y)
                        usedTiles[i] = true
                    end
                end
            end
        end

        for i, w in ipairs(walls) do
            print(tostring(w.l).." "..tostring(w.r).." "..tostring(w.t).." "..tostring(w.b))

        end

        for i, v in ipairs(self.tiles) do
            if v == 1 then
                local tcoord = self:indexToXy(i)
                local wcoord = self:tileToWorldSpace(tcoord)
                self.wall_manager:add(wcoord.x, wcoord.y, self.tile_width, self.tile_height, 0)
            end
        end
    end

    self.render = function(self)
        self.wall_manager:render()
    end

    return self
end