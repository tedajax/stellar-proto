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

    self.world = love.physics.newWorld(0, 0)

    self.world:setCallbacks(on_begin, on_end, on_pre_solve, on_post_solve)

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
                        love.graphics.circle("line", X(bx), Y(by), S(r))
                    elseif shape:getType() == "polygon" then
                        local points = { shape:getPoints() }
                        for i = 1, #points - 2, 2 do
                            love.graphics.line(
                                X(points[i] + bx),
                                Y(points[i + 1] + by),
                                X(points[i + 2] + bx),
                                Y(points[i + 3] + by)
                            )
                        end

                        love.graphics.line(
                            X(points[1] + bx),
                            Y(points[2] + by),
                            X(points[#points - 1] + bx),
                            Y(points[#points] + by)
                        )
                    end

                    if show_aabb then
                        local tx, ty, bx, by = shape:computeAABB(bx, by, 0)
                        love.graphics.setColor(255, 255, 0)
                        love.graphics.rectangle(
                            "line",
                            X(tx),
                            Y(ty),
                            SX(bx - tx),
                            SY(by - ty)
                        )
                    end
                end
            end
        end
    end

    return self
end
