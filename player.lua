Vec2 = require 'vec2'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.radius = 16
    self.select_radius = 64
    self.speed = 320
    self.acceleration = 10000
    self.friction = 1

    self.selected = {}

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    self.fixture:setUserData(self)

    self.on_collision_begin = function(self, other, coll)
    end

    self.on_collision_end = function(self, other, coll)
    end

    self.update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        local velocity = Vec2(h, v)
        velocity = velocity * self.acceleration * dt

        self.body:applyLinearImpulse(velocity.x, velocity.y)

        local lvx, lvy = self.body:getLinearVelocity()

        if h == 0 then
            lvx = lvx * (1 - self.friction)
        end

        if v == 0 then
            lvy = lvy * (1 - self.friction)
        end

        self.body:setLinearVelocity(
            math.clamp(lvx, -self.speed, self.speed),
            math.clamp(lvy, -self.speed, self.speed)
        )

        self.position.x = self.body:getX()
        self.position.y = self.body:getY()

        for _, npc in ipairs(self.selected) do
            npc.velocity.x = h
            npc.velocity.y = v
        end

        if Input:get_button_down("select") then
            self:deselect()

            self.selected = Game.npc_manager:get_all_in_radius(
                self.position,
                self.select_radius
            )

            for _, npc in ipairs(self.selected) do
                npc.is_selected = true
            end
        end

        if Input:get_button_down("cancel") then
            self:deselect()
        end
    end

    self.deselect = function(self)
        for i, npc in ipairs(self.selected) do
            npc.is_selected = false
            npc.velocity.x = 0
            npc.velocity.y = 0
            self.selected[i] = nil
        end
    end

    self.render = function(self)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.circle(
            "fill",
            X(self.position.x),
            Y(self.position.y),
            S(self.radius)
        )

        love.graphics.setColor(0, 255, 0, 127)
        love.graphics.circle(
            "fill",
            X(self.position.x),
            Y(self.position.y),
            S(self.select_radius)
        )

        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.circle(
            "line",
            X(self.position.x),
            Y(self.position.y),
            S(self.select_radius)
        )
    end

    return self
end
