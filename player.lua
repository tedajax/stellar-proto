Vec2 = require 'vec2'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 16
    self.height = 32
    self.select_radius = 64

    self.selected = {}

    self.controller = nil

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setFixedRotation(true)

    self.shape = love.physics.newRectangleShape(
        0,
        0,
        self.width,
        self.height - self.width / 2
    )
    self.fixture = love.physics.newFixture(self.body, self.shape)

    self.foot_shape = love.physics.newCircleShape(
        0,
        self.height / 2 - self.width / 4,
        self.width / 2
    )
    self.foot_fixture = love.physics.newFixture(self.body, self.foot_shape)

    -- self.fixture:setUserData(self)
    self.foot_fixture:setUserData(self)

    self.collision_count = 0

    self.on_collision_begin = function(self, other, coll)
        self.collision_count = self.collision_count + 1
        Log:log_info("Count: "..self.collision_count)
    end

    self.on_collision_end = function(self, other, coll)
        self.collision_count = self.collision_count - 1
        Log:log_info("Count: "..self.collision_count)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
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
            self.position.x,
            self.position.y,
            self.width
        )

        -- love.graphics.setColor(0, 255, 0, 127)
        -- love.graphics.circle(
        --     "fill",
        --     self.position.x,
        --     self.position.y,
        --     self.select_radius
        -- )

        -- love.graphics.setColor(0, 255, 0, 255)
        -- love.graphics.circle(
        --     "line",
        --     self.position.x,
        --     self.position.y,
        --     self.select_radius
        -- )
    end

    return self
end

function create_player_controller(player)
    local self = {}

    self.player = player
    self.player.controller = self

    self.speed = 320
    self.acceleration = 10000
    self.friction = 0.9

    self.update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        local velocity = Vec2(h, v)
        velocity = velocity * self.acceleration * dt

        self.player.body:applyLinearImpulse(velocity.x, 0)

        local lvx, lvy = self.player.body:getLinearVelocity()

        if h == 0 then
            lvx = lvx * (1 - self.friction)
        end

        -- if v == 0 then
        --     lvy = lvy * (1 - self.friction)
        -- end

        self.player.body:setLinearVelocity(
            math.clamp(lvx, -self.speed, self.speed),
            math.clamp(lvy, -self.speed, self.speed)
        )

        self.player.position.x = self.player.body:getX()
        self.player.position.y = self.player.body:getY()

        -- for _, npc in ipairs(self.selected) do
        --     npc.velocity.x = h
        --     npc.velocity.y = v
        -- end
    end

    return self
end