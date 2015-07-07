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
    self.world = love.physics.newWorld(0, 6000)

    self.world:setCallbacks(on_begin, on_end, on_pre_solve, on_post_solve)

    -- represents raycasts that were called this frame so we can debug them
    self.frame_ray_casts = {}

    self.ray_cast = function(self, startpoint, endpoint)
        local hit_list = {}

        self.world:rayCast(
            startpoint.x, startpoint.y,
            endpoint.x, endpoint.y,
            function(fixture, x, y, xn, yn, fraction)
                local hit = {}
                hit.position = Vec2(x, y)
                hit.normal = Vec2(xn, yn)
                hit.distance = fraction
                table.insert(hit_list, hit)
                return 1
            end
        )

        if #hit_list > 0 then
            print(#hit_list)
        end

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
