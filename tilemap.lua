require 'environment'
require 'util'
Vec2 = require 'vec2'

TILE_TYPES = {
    cEmpty = 0,
    cWall = 1,
    cRampBR = 2,
    cRampBL = 3,
    cRampTL = 4,
    cRampTR = 5,
    cSpike = 6,
}

function create_tilemap(tilemapObj, tileset)
    local self = {}

    self.width = tilemapObj.width
    self.height = tilemapObj.height
    self.tile_width = tilemapObj.tile_width
    self.tile_height = tilemapObj.tile_height

    local originObj = tilemapObj.origin or { x = 0, y = 0 }
    local offsetObj = tilemapObj.offset or { x = 0, y = 0 }
    self.origin = Vec2(originObj.x, originObj.y) + Vec2(offsetObj.x, offsetObj.y)

    self.tiles = {}

    -- hacky and very fragile, make better
    self.tileset = {}
    self.tileset[0] = { type = TILE_TYPES.cEmpty, image = nil }
    for tilekey, tile in pairs(tileset.tiles) do
        local index = tonumber(tilekey) + 1
        self.tileset[index] = {
            type = TILE_TYPES[tileset.tileproperties[tilekey].type],
            image = love.graphics.newImage(tilemapObj.root_dir..tile.image)
        }
    end

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

    -- goes through the tile data and recreates walls and everything
    -- expensive, only call after setting tile data!
    self.recalculate = function(self, wall_manager)
        wall_manager:clear()

        local usedTiles = {}
        for i, _ in ipairs(self.tiles) do table.insert(usedTiles, false) end

        local walls = {}

        for current, v in ipairs(self.tiles) do
            local t = self.tileset[v].type
            local col, row = self:index_to_xy(current):unpack()
            if usedTiles[current] then
                goto continue
            end
            if t == TILE_TYPES.cWall then
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
            elseif t >= TILE_TYPES.cRampBR and t <= TILE_TYPES.cRampTR then
                usedTiles[current] = true

                local dy = 0
                if t == TILE_TYPES.cRampBR or t == TILE_TYPES.cRampTL then
                    dy = -1
                else
                    dy = 1
                end

                -- decrease current column until we can't anymore
                local c = col
                local r = row

                local first = Vec2(col, row)
                local last = Vec2(col, row)

                while true do
                    c = c - 1
                    r = r - dy
                    local i = self:xy_to_index(c, r)

                    if i < 1 or i >= #self.tiles or usedTiles[i] or self.tileset[self.tiles[i]].type ~= t then
                        break
                    end
                    first.x = c
                    first.y = r

                end

                c = col
                r = row

                while true do
                    c = c + 1
                    r = r + dy
                    local i = self:xy_to_index(c, r)
                    if i < 1 or i >= #self.tiles or usedTiles[i] or self.tileset[self.tiles[i]].type ~= t then
                        break
                    end
                    last.x = c
                    last.y = r
                end

                local y = first.y
                for x = first.x, last.x do
                    local i = self:xy_to_index(x, y)

                    -- don't consider wall blocks beneath floor ramps
                    if t == TILE_TYPES.cRampBL or t == TILE_TYPES.cRampBR then
                        local i2 = self:xy_to_index(x, y + 1)
                        if i2 > 0 and i2 <= #self.tiles and self.tileset[self.tiles[i2]].type == TILE_TYPES.cWall then
                            usedTiles[i2] = true
                        end
                    end

                    y = y + dy
                    usedTiles[i] = true
                end

                local first_origin = "topleft"
                local last_origin = "bottomright"

                if t == TILE_TYPES.cRampBR or t == TILE_TYPES.cRampTL then
                    first_origin = "bottomleft"
                    last_origin = "topright"
                end

                local properties = {
                    type = "ramp",
                    first = self:tile_to_world_space(Vec2(first.x, first.y), first_origin),
                    last = self:tile_to_world_space(Vec2(last.x, last.y), last_origin),
                    direction = t - TILE_TYPES.cRampBR
                }

                wall_manager:add(properties)
            elseif t == TILE_TYPES.cSpike then
                usedTiles[current] = true
                local left = col
                local right = left
                for x = left + 1, self.width - 1 do
                    local i = self:xy_to_index(x, math.floor(current / self.width))
                    if usedTiles[i] == true or self.tiles[i] ~= TILE_TYPES.cSpike then
                        break
                    else
                        right = right + 1
                    end
                end

                local top = row
                local bottom = row
                table.insert(walls, { l = left, r = right, t = top, b = bottom, filter = "cEnvironmentTriggers", tag = "kill", sensor = true })
                for x = left, right do
                    local i = self:xy_to_index(x, top)
                    usedTiles[i] = true
                end
            end
            ::continue::
        end

        -- local p = {
        --     type = "ramp",
        --     first = Vec2(200, 320),
        --     last = Vec2(400, 270),
        --     direction = 0
        -- }
        -- wall_manager:add(p)

        -- local p2 = {
        --     type = "ramp",
        --     first = Vec2(200, 320),
        --     last = Vec2(400, 220),
        --     direction = 1
        -- }
        -- wall_manager:add(p2)

        for i, w in ipairs(walls) do
            local tl = self:tile_to_world_space(Vec2(w.l, w.t), "topleft")
            local br = self:tile_to_world_space(Vec2(w.r, w.b), "bottomright")
            local properties = {
                type = "normal",
                l = tl.x, r = br.x, t = tl.y, b = br.y,
                filter = w.filter or "cStaticEnvironment",
                tag = w.tag,
                sensor = w.sensor or false,
            }
            wall_manager:add(properties)
        end

    end

    self.render = function(self)
        love.graphics.setColor(255, 255, 255)
        for i, v in ipairs(self.tiles) do
            local image = self.tileset[v].image
            if image ~= nil then
                local tcoord = self:index_to_xy(i)
                local wcoord = self:tile_to_world_space(tcoord, "topleft")
                love.graphics.draw(image, wcoord.x, wcoord.y)
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