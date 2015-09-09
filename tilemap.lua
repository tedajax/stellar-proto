require 'environment'
require 'util'
Vec2 = require 'vec2'

TILE_TYPES = {
    cEmpty = 0,
    cWall = 1,
    cSpawn = 2,
}

function create_tilemap(tilemapObj)
    local self = {}

    self.width = tilemapObj.width
    self.height = tilemapObj.height
    self.tile_width = tilemapObj.tile_width
    self.tile_height = tilemapObj.tile_height

    local originObj = tilemapObj.origin or { x = 0, y = 0 }
    local offsetObj = tilemapObj.offset or { x = 0, y = 0 }
    self.origin = Vec2(originObj.x, originObj.y) + Vec2(offsetObj.x, offsetObj.y)

    self.tiles = {}

    self.spawn_point = 0

    self.tile_image = love.graphics.newImage("assets/tile_orange.png")

    for i = 1, self.width * self.height do
        table.insert(self.tiles, tilemapObj.data[i])
    end

    self.world_to_tile_space = function(self, wcoord)
        assert(Vec2.isvec2(wcoord))
        local t = wcoord - self.origin
        t.x = math.floor(t.x / self.tile_width)
        t.y = math.floor(t.y / self.tile_height)
        return t
    end

    self.tile_to_world_space = function(self, tcoord, origin)
        assert(Vec2.isvec2(tcoord))
        local origin = origin or "center"
        local ox, oy = originNameValues(origin)
        local w = tcoord
        w.x = w.x * self.tile_width + (self.tile_width * ox)
        w.y = w.y * self.tile_height + (self.tile_height * oy)
        w = w + self.origin
        return w
    end

    self.xy_to_index = function(self, x, y)
        return y * self.width + x + 1
    end

    self.vec_to_index = function(self, pos)
        return self:xy_to_index(pos.x, pos.y)
    end

    self.index_to_xy = function(self, index)
        local x = (index - 1) % self.width
        local y = math.floor((index - 1) / self.width)
        return Vec2(x, y)
    end

    self.setTile = function(self, pos, value)
        local i = self:vec_to_index(pos)
        self.tiles[i] = value
    end

    self.get_spawn_position = function(self)
        if self.spawn_point < 1 then
            return Vec2(0, 0)
        else
            return self:tile_to_world_space(self:index_to_xy(self.spawn_point), "centertop")
        end
    end

    -- goes through the tile data and recreates walls and everything
    -- expensive, only call after setting tile data!
    self.recalculate = function(self, wall_manager)
        wall_manager:clear()

        local usedTiles = {}
        for i, _ in ipairs(self.tiles) do table.insert(usedTiles, false) end

        local walls = {}

        for current, v in ipairs(self.tiles) do
            if v == TILE_TYPES.cWall and usedTiles[current] == false then
                local col, row = self:index_to_xy(current):unpack()
                local left = col
                local right = left
                for x = left + 1, self.width - 1 do
                    local i = self:xy_to_index(x, math.floor(current / self.width))
                    if usedTiles[i] == true or self.tiles[i] ~= 1 then
                        break
                    else
                        right = right + 1
                    end
                end

                local top = row
                local bottom = top
                for y = top + 1, self.height do
                    local goodRow = true
                    for x = left, right do
                        local i = self:xy_to_index(x, y)
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
                        local i = self:xy_to_index(x, y)
                        usedTiles[i] = true
                    end
                end
            elseif v == TILE_TYPES.cSpawn then
                self.spawn_point = current
            end
        end

        for i, w in ipairs(walls) do
            local tl = self:tile_to_world_space(Vec2(w.l, w.t), "topleft")
            local br = self:tile_to_world_space(Vec2(w.r, w.b), "bottomright")
            wall_manager:add(tl.x, br.x, tl.y, br.y)
        end

    end

    self.render = function(self)
        love.graphics.setColor(255, 255, 255)
        for i, v in ipairs(self.tiles) do
            if v == TILE_TYPES.cWall then
                local tcoord = self:index_to_xy(i)
                local wcoord = self:tile_to_world_space(tcoord, "topleft")
                love.graphics.draw(self.tile_image, wcoord.x, wcoord.y)
            end
        end
    end

    self.render_grid = function(self)
        love.graphics.setColor(255, 255, 0)
        for x = 0, self.width do
            local t = self:tile_to_world_space(Vec2(x, 0), "topleft")
            local b = self:tile_to_world_space(Vec2(x, self.height - 1), "bottomleft")
            love.graphics.line(t.x, t.y, b.x, b.y)
        end

        for y = 0, self.height do
            local l = self:tile_to_world_space(Vec2(0, y), "topleft")
            local r = self:tile_to_world_space(Vec2(self.width - 1, y), "topright")
            love.graphics.line(l.x, l.y, r.x, r.y)
        end
    end

    return self
end