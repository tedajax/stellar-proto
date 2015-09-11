COLLISION_TAGS = {
    cDefault = 0,
    cPlayer = 1,
    cEnemy = 2,
    cPlayerBullet = 3,
    cEnvironment = 4,
    cStaticEnvironment = 5,
    cFlag = 6
}

COLLISION_FILTERS = {}

function register_collision_filter(tag, category, mask, group)
    COLLISION_FILTERS[tag] = { category = category, mask = mask, group = group }
end

register_collision_filter(COLLISION_TAGS.cDefault,              0x0000, 0x0000,  0)
register_collision_filter(COLLISION_TAGS.cPlayer,               0x0001, 0x0018, -1)
register_collision_filter(COLLISION_TAGS.cEnemy,                0x0002, 0x001D,  0)
register_collision_filter(COLLISION_TAGS.cPlayerBullet,         0x0004, 0x0016, -1)
register_collision_filter(COLLISION_TAGS.cEnvironment,          0x0008, 0xffff,  0)
register_collision_filter(COLLISION_TAGS.cStaticEnvironment,    0x0010, 0xffff,  0)
register_collision_filter(COLLISION_TAGS.cFlag,                 0x0020, 0x0018,  0)

function get_collision_filter(tag)
    local f = COLLISION_FILTERS[COLLISION_TAGS[tag]]
    return { f.category, f.mask, f.group }
end

function collision_filter_test(c1, m1, g1, c2, m2, g2)
    if g1 == g2 and g1 ~= 0 then
        if g1 > 0 then
            return true
        else
            return false
        end
    end

    return bit.band(m1, c2) > 0 and bit.band(m2, c1) > 0
end

function collision_get_mask(...)
    local arg = {...}
    local mask = 0
    for _, t in ipairs(arg) do
        mask = mask + COLLISION_FILTERS[COLLISION_TAGS[t]].category
    end
    return mask
end

function fixture_call(fixture, func, other, coll)
    local obj = fixture:getUserData()
    if type(obj) == "table" then
        if type(obj[func]) == "function" then
            obj[func](obj, other, coll)
        end
    end
end

function on_begin(a, b, coll)
    fixture_call(a, "on_collision_begin", b, coll)
    fixture_call(b, "on_collision_begin", a, coll)
end

function on_end(a, b, coll)
    fixture_call(a, "on_collision_end", b, coll)
    fixture_call(b, "on_collision_end", a, coll)
end

function on_pre_solve(a, b, coll)
end

function on_post_solve(a, b, coll, normal1, tangent1, normal2, tangent2)
end


function create_collision()
    assert(Collision == nil, "Collision already created.")

    local self = {}

    -- Global collision 'singleton'
    -- kind of shitty pattern but it's the only way to ensure the callbacks
    -- end up forwarding to the right thing
    Collision = self

    love.physics.setMeter(100)
    self.world = love.physics.newWorld(0, Defaults.game.world.gravity)

    self.world:setCallbacks(on_begin, on_end, on_pre_solve, on_post_solve)

    -- represents raycasts that were called this frame so we can debug them
    self.frame_ray_casts = {}

    self.ray_cast = function(self, startpoint, endpoint, mask)
        local hit_list = {}

        self.world:rayCast(
            startpoint.x, startpoint.y,
            endpoint.x, endpoint.y,
            function(fixture, x, y, xn, yn, fraction)
                local hit = {}
                hit.position = Vec2(x, y)
                hit.normal = Vec2(xn, yn)
                hit.distance = fraction
                hit.fixture = fixture
                if mask then
                    local category, _, _ = fixture:getFilterData()
                    if bit.band(mask, category) > 0 then
                        table.insert(hit_list, hit)
                        return 0
                    else
                        return 1
                    end
                else
                    table.insert(hit_list, hit)
                    return 1
                end
            end
        )

        table.insert(self.frame_ray_casts, { s = startpoint, e = endpoint })

        return hit_list
    end

    self.update = function(self, dt)
        self.world:update(dt)
    end

    self.debug_render = function(self, show_aabb)
        local bodies = self.world:getBodyList()
        for _, b in pairs(bodies) do
            if b:isActive() then
                local fixtures = b:getFixtureList()
                for _, f in pairs(fixtures) do
                    local shape = f:getShape()

                    love.graphics.setColor(255, 0, 255)

                    local bx = b:getX()
                    local by = b:getY()

                    if shape:getType() == "circle" then
                        local r = shape:getRadius()
                        local cx, cy = shape:getPoint()
                        love.graphics.circle("line", cx + bx, cy + by, r)
                    elseif shape:getType() == "polygon" then
                        love.graphics.push()
                        love.graphics.translate(bx, by)
                        love.graphics.rotate(b:getAngle())
                        local points = { shape:getPoints() }
                        for i = 1, #points - 2, 2 do
                            love.graphics.line(
                                points[i],
                                points[i + 1],
                                points[i + 2],
                                points[i + 3]
                            )
                        end

                        love.graphics.line(
                            points[1],
                            points[2],
                            points[#points - 1],
                            points[#points]
                        )
                        love.graphics.pop()
                    elseif shape:getType() == "edge" then
                        love.graphics.push()
                        love.graphics.translate(bx, by)
                        love.graphics.rotate(b:getAngle())
                        local points = { shape:getPoints() }
                        for i = 1, #points - 2, 2 do
                            love.graphics.line(
                                points[i],
                                points[i + 1],
                                points[i + 2],
                                points[i + 3]
                            )
                        end

                        love.graphics.line(
                            points[1],
                            points[2],
                            points[#points - 1],
                            points[#points]
                        )

                        love.graphics.setColor(0, 255, 0)
                        for i = 1, #points, 2 do
                            love.graphics.circle("fill", points[i], points[i + 1], 4)
                        end

                        love.graphics.pop()
                    end

                    if show_aabb then
                        local tx, ty, bx, by = shape:computeAABB(bx, by, b:getAngle())
                        love.graphics.setColor(255, 255, 0)
                        love.graphics.rectangle(
                            "line",
                            tx,
                            ty,
                            bx - tx,
                            by - ty
                        )
                    end
                end
            end
        end

        love.graphics.setColor(0, 255, 255)
        for _, r in ipairs(self.frame_ray_casts) do
            love.graphics.line(
                r.s.x, r.s.y,
                r.e.x, r.e.y
            )
        end

        self.frame_ray_casts = {}
    end

    return self
end
