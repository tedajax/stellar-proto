Vec2 = require 'vec2'
require 'log'
require 'util'

WALL_CONTACTS = {
    cNone = 0,
    cLeft = 1,
    cRight = 2,
}

function create_movement(collider, propertiesObj)
    local self = {}

    self.collider = collider
    self.body = collider.body

    -- movement properties
    self.properties = propertiesObj

    -- properties object includes
    -- self.properties.ground = {}
    -- self.properties.ground.acceleration = 300 -- horizontal acceleration on ground
    -- self.properties.ground.max_speed = 200 -- horizontal speed on ground
    -- self.properties.ground.friction = 0.5 -- how fast we slow down on the ground (horizontal)

    -- self.properties.air = {}
    -- self.properties.air.acceleration = 150 -- horizontal acceleration in air
    -- self.properties.air.max_speed = 800
    -- self.properties.air.friction = 0.1 -- how fast we slow down in air (horizontal)

    -- self.properties.jump_force = 120
    -- self.properties.jump_hold_force = 100

    self.jump_requested = false

    self.is_on_ground = false
    self.on_moving_platform = nil
    self.is_jumping = false
    self.used_jumps = 0
    self.jump_hold_multiplier = 1
    self.against_wall = WALL_CONTACTS.cNone
    self.pushing_against_wall = WALL_CONTACTS.cNone
    self.is_stuck_to_wall = false
    self.stop_wall_slide = false
    self.wall_stick_timer = 0
    self.wall_jump_requested_timer = 0

    self.ramp_angle = 0

    self.movement_time = 0
    self.movement_delay = 0

    -- TODO: more robust input
    self.input = { x = 0, y = 0, jump = false }
    self.prev_input = { x = 0, y = 0, jump = false }

    self.set_input = function(self, x, y, jump)
        self.input.x = x
        self.input.y = y
        self.input.jump = jump or false
    end

    self.request_jump = function(self)
        self.jump_requested = true
    end

    self.raycast_relative = function(self, to, offset, filter)
        offset = offset or Vec2(0, 0)
        local body_pos = (Vec2(self.body:getPosition()))
        local s = offset + body_pos
        local e = s + to
        return Collision:ray_cast(s, e, filter)
    end

    self.check_on_ground = function(self)
        local dist = self.properties.raycasts.ground.distance
        local spread = self.properties.raycasts.ground.spread / 2
        local hits_left = self:raycast_relative(Vec2(0, dist), Vec2(self.collider.feet_shape:getPoint()) + Vec2(-spread, 0), collision_get_mask("cStaticEnvironment", "cEnvironment"))
        local hits_right = self:raycast_relative(Vec2(0, dist), Vec2(self.collider.feet_shape:getPoint()) + Vec2(spread, 0), collision_get_mask("cStaticEnvironment", "cEnvironment"))

        local prev_on_ground = self.is_on_ground

        local best_hit = nil

        if #hits_left > 0 and hits_left[1].distance <= 1 or
           #hits_right > 0 and hits_right[1].distance <= 1 then
            local d_left, d_right = 1, 1
            if hits_left[1] then d_left = hits_left[1].distance end
            if hits_right[1] then d_right = hits_right[1].distance end
            if d_left < d_right then
                best_hit = hits_left[1]
            else
                best_hit = hits_right[1]
            end
            self.is_on_ground = true
        else
            self.is_on_ground = false
        end

        if self.is_on_ground then
            local angle_left = 0
            local angle_right = 0
            if #hits_left > 0 then
                local hit = hits_left[1]
                angle_left = Vec2(0, -1):angle(hit.normal)
            end
            if #hits_right > 0 then
                local hit = hits_right[1]
                angle_right = Vec2(0, -1):angle(hit.normal)
            end
            self.ramp_angle = math.max(angle_left, angle_right)
            Log:debug("ramp angle: "..tostring(self.ramp_angle))
        else
            self.ramp_angle = 0
        end

        self.on_moving_platform = nil

        if best_hit then
            local env = best_hit.fixture:getUserData()
            if env and env.controller then
                self.on_moving_platform = env
            end
        end

        if prev_on_ground ~= self.is_on_ground then
            if self.is_on_ground then
                self:on_land_ground()
            else
                self:on_leave_ground()
            end
        end

        return self.is_on_ground
    end

    self.check_wall_contacts = function(self)
        if self.is_on_ground then
            return
        end

        local dist = self.properties.raycasts.walls.distance
        local spread = self.properties.raycasts.walls.spread / 2

        local right_hits_top = self:raycast_relative(Vec2(dist, 0), Vec2(0, -spread))
        local right_hits_bottom = self:raycast_relative(Vec2(dist, 0), Vec2(0, spread))

        local left_hits_top = self:raycast_relative(Vec2(-dist, 0), Vec2(0, -spread))
        local left_hits_bottom = self:raycast_relative(Vec2(-dist, 0), Vec2(0, spread))

        local on_right = #right_hits_top > 0 or #right_hits_bottom > 0
        local on_left = #left_hits_top > 0 or #left_hits_bottom > 0

        -- favors being against the right wall
        -- if being against both walls at once is a desired thing then this
        -- should be changed to be bitfields
        if on_right == false and on_left == false then
            self.against_wall = WALL_CONTACTS.cNone
        elseif on_right == true then
            local best_hit = nil
            local top, bottom = right_hits_top[1], right_hits_bottom[1]
            local d_top, d_bottom = 1, 1
            if top then d_top = top.distance end
            if bottom then d_bottom = bottom.distance end
            if d_top < d_bottom then best_hit = top else best_hit = bottom end

            local env = best_hit.fixture:getUserData()
            if env and env.controller then
                self.on_moving_platform = env
            end

            self.against_wall = WALL_CONTACTS.cRight
        else
            local best_hit = nil
            local top, bottom = left_hits_top[1], left_hits_bottom[1]
            local d_top, d_bottom = 1, 1
            if top then d_top = top.distance end
            if bottom then d_bottom = bottom.distance end
            if d_top < d_bottom then best_hit = top else best_hit = bottom end

            local env = best_hit.fixture:getUserData()
            if env and env.controller then
                self.on_moving_platform = env
            end

            self.against_wall = WALL_CONTACTS.cLeft
        end
    end

    self.get_value = function(self, name)
        if self.is_on_ground then
            return self.properties.ground[name]
        else
            return self.properties.air[name]
        end
    end

    self.on_leave_ground = function(self)
        self.used_jumps = 1
    end

    self.on_land_ground = function(self)
        self.used_jumps = 0
        self.jump_hold_multiplier = 1
        self.jump_requested = false
    end

    self.on_wall_stick = function(self)
        self.movement_time = 0
        self.movement_delay = self.properties.wall_stick_delay
        self.is_stuck_to_wall = true
        self.wall_stick_timer = self.properties.wall_slide_idle_time
    end

    self.on_wall_unstick = function(self)
        self.is_stuck_to_wall = false
        self.wall_stick_timer = 0
        self.movement_delay = 0
        self.body:setGravityScale(1.0)
        self.stop_wall_slide = false
    end

    self.jump = function(self)
        self.is_jumping = true
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, 0)
        self.body:applyLinearImpulse(0, -self.properties.jump_force)
        self.used_jumps = self.used_jumps + 1
        self.jump_requested = false
        self.jump_hold_multiplier = 1
    end

    self.wall_jump_base = function(self, fx, fy)
        self:on_wall_unstick()
        self.is_jumping = true
        self.used_jumps = 1
        local _, vy = self.body:getLinearVelocity()
        if vy > 0 then vy = 0 end
        self.body:setLinearVelocity(0, vy)
        self.body:applyLinearImpulse(fx, fy)
        self.jump_requested = false
        self.jump_hold_multiplier = 0.5
    end

    self.wall_jump = function(self, scalar)
        self:wall_jump_base(
            scalar * self.properties.wall_jump_force.x,
            -self.properties.wall_jump_force.y
        )
    end

    self.wall_hop = function(self, scalar)
        self:wall_jump_base(
            scalar * self.properties.wall_hop_force.x,
            -self.properties.wall_hop_force.y
        )
    end

    self.update = function(self, dt)
        -- casts ray casts and update state determining ground/wall states
        self:check_on_ground()
        self:check_wall_contacts()

        -- if conditions for jump are met then jump
        if self.used_jumps < self.properties.max_jumps and self.jump_requested and not self.is_stuck_to_wall then
            self:jump()
        end

        -- allow for holding the jump button to float a bit more
        if self.is_jumping then
            if self.input.jump then
                if not self.is_stuck_to_wall then
                    self.body:applyForce(0, -self.properties.jump_hold_force * self.jump_hold_multiplier)
                end
            else
                self.is_jumping = false
            end
        end

        -- handles waiting before moving to accomdate turning around without moving with light taps of keys
        if math.sign(self.input.x) ~= math.sign(self.prev_input.x) then
            self.movement_time = 0
        else
            self.movement_time = self.movement_time + dt
        end

        -- extract values from properties object depending on current state
        local acceleration = self:get_value("acceleration")
        local max_speed = self:get_value("max_speed")

        -- this is used in conjuction with the movement_time stuff to delay movement when facing a new direction
        local move_x = 0
        if self.movement_time >= self.movement_delay then
            move_x = self.input.x
        end
        local velocity = Vec2(move_x, self.input.y)

        velocity = velocity * acceleration * dt

        -- extract the velocity before we apply force
        local preForceVx = self.body:getLinearVelocity()

        -- clamp our velocity from input if the velocity is already at max speeds
        if preForceVx >= max_speed and velocity.x > 0 then
            velocity.x = 0
        elseif preForceVx <= -max_speed and velocity.x < 0 then
            velocity.x = 0
        end
        self.body:applyLinearImpulse(velocity.x, self.ramp_angle * -0.15)

        -- Determine if the player is pushing against a wall
        if self.input.x > 0 and self.against_wall == WALL_CONTACTS.cRight then
            self.pushing_against_wall = WALL_CONTACTS.cRight
        elseif self.input.x < 0 and self.against_wall == WALL_CONTACTS.cLeft then
            self.pushing_against_wall = WALL_CONTACTS.cLeft
        else
            self.pushing_against_wall = WALL_CONTACTS.cNone
        end

        if self.is_on_ground == false then
            local _, vy = self.body:getLinearVelocity()

            if self.is_stuck_to_wall then
                -- if at any time the player is no longer pushing into the wall we unstick
                if self.against_wall == WALL_CONTACTS.cNone then
                    self:on_wall_unstick()
                end

                -- reduce gravity scale when wall sliding
                if vy > 0 then
                    self.body:setGravityScale(self.properties.wall_gravity_modifier)
                end

                -- here's where the wall jump action is
                if self.jump_requested then
                    if self.against_wall == WALL_CONTACTS.cRight then
                        if self.input.x < 0 then
                            self:wall_jump(-1)
                        elseif self.input.x > 0 then
                            self:wall_hop(-1)
                        end
                    elseif self.against_wall == WALL_CONTACTS.cLeft then
                        if self.input.x > 0 then
                            self:wall_jump(1)
                        elseif self.input.x < 0 then
                            self:wall_hop(1)
                        end
                    end

                    if self.wall_jump_requested_timer > 0 then
                        self.wall_jump_requested_timer = self.wall_jump_requested_timer - dt
                        if self.wall_jump_requested_timer <= 0 then
                            self.wall_jump_requested_timer = 0
                            self.jump_requested = false
                        end
                    else
                        self.wall_jump_requested_timer = self.properties.wall_jump_request_window
                    end
                end

                -- the wall stick timer allows for not pushing against the wall for a time so that wall jump commands
                -- can be executed.
                if self.wall_stick_timer > 0 then
                    if self.pushing_against_wall == WALL_CONTACTS.cNone then
                        self.wall_stick_timer = self.wall_stick_timer - dt

                        if self.wall_stick_timer <= 0 then
                            self:on_wall_unstick()
                        end
                    else
                        self.wall_stick_timer = self.properties.wall_slide_idle_time
                    end

                    if self.against_wall == WALL_CONTACTS.cRight and self.input.x < 0 then
                        self.stop_wall_slide = true
                        self.wall_stick_timer = self.properties.wall_slide_idle_time
                    elseif self.against_wall == WALL_CONTACTS.cLeft and self.input.x > 0 then
                        self.stop_wall_slide = true
                        self.wall_stick_timer = self.properties.wall_slide_idle_time
                    else
                        self.stop_wall_slide = false
                    end
                end
            else
                self.body:setGravityScale(1.0)
                -- when the player is not on the ground and pushing against a wall we go into wall stick mode
                if self.pushing_against_wall ~= WALL_CONTACTS.cNone then
                   self:on_wall_stick()
                end
            end
        else
            if self.is_stuck_to_wall then
                self:on_wall_unstick()
            end
        end

        local lvx, lvy = self.body:getLinearVelocity()

        local stop_acceleration = self:get_value("stop_acceleration")

        if self.input.x == 0 then
            if lvx < 0 then
                lvx = lvx + stop_acceleration * dt
                if lvx > 0 then lvx = 0 end
            elseif lvx > 0 then
                lvx = lvx - stop_acceleration * dt
                if lvx < 0 then lvx = 0 end
            end
            -- lvx = lvx * (1 - friction)
        end

        if self.is_stuck_to_wall then
            local max_slide_speed = self.properties.wall_slide_max_speed
            if self.stop_wall_slide then
                max_slide_speed = 0
            end
            if lvy > max_slide_speed then
                lvy = max_slide_speed
            end
        end

        -- if travelling above max_speed slow down speed over time
        if lvx < -max_speed then
            lvx = lvx + self:get_value("max_speed_slow_rate") * dt
            if lvx > -max_speed then
                lvx = -max_speed
            end
        end

        if lvx > max_speed then
            lvx = lvx - self:get_value("max_speed_slow_rate") * dt
            if lvx < max_speed then
                lvx = max_speed
            end
        end

        self.body:setLinearVelocity(
            lvx,
            lvy
        )

        if self.on_moving_platform ~= nil then
            local bx, by = self.body:getX(), self.body:getY()
            if self.on_moving_platform.controller ~= nil then
                local mpv = self.on_moving_platform.controller.velocity
                if Input:get_button("debug") then
                    Log:debug("platform x,y: "..tostring(mpv.x)..", "..tostring(mpv.y))
                end
                bx = bx + mpv.x
                by = by + mpv.y
                self.body:setX(bx)
                self.body:setY(by)
            end
        end

        Log:debug("Wall stick: "..tostring(self.is_stuck_to_wall))
        Log:debug("Is on ground: "..tostring(self.is_on_ground))
        Log:debug("Wall stick timer: "..tostring(self.wall_stick_timer))
        Log:debug("Against wall: "..tostring(self.against_wall))
        Log:debug("Pushging against: "..tostring(self.pushing_against_wall))
        Log:debug("Input X: "..tostring(self.input.x))
        Log:debug("move delay: "..tostring(self.movement_delay))
        Log:debug("move time: "..tostring(self.movement_time))
        Log:debug("on moving platform: "..tostring(self.on_moving_platform ~= nil))

        for k, v in pairs(self.input) do
            self.prev_input[k] = v
        end
    end

    self.setProperties = function(self, propertiesObj)
        self.properties = propertiesObj
    end

    return self
end