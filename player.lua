Vec2 = require 'vec2'
require 'movement'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 16
    self.height = 32

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
    self.fixture:setFriction(0)

    self.foot_shape = love.physics.newCircleShape(
        0,
        self.height / 2 - self.width / 4,
        self.width / 2
    )
    self.foot_fixture = love.physics.newFixture(self.body, self.foot_shape)

    -- self.fixture:setUserData(self)
    self.foot_fixture:setUserData(self)

    self.on_collision_begin = function(self, other, coll)
    end

    self.on_collision_end = function(self, other, coll)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
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
    end

    return self
end

function create_player_controller(player)
    local self = {}

    self.player = player
    self.player.controller = self

    self.movement = create_movement(
        self.player.body,
        self.player.foot_shape
    )

    self.update = function(self, dt)
        self.movement:set_input(
            Input:get_axis("horizontal"),
            Input:get_axis("vertical"),
            Input:get_button("jump")
        )

        if Input:get_button_down("jump") then
            self.movement:request_jump()
        end

        self.movement:update(dt)

        self.player.position.x = self.player.body:getX()
        self.player.position.y = self.player.body:getY()

        -- for _, npc in ipairs(self.selected) do
        --     npc.velocity.x = h
        --     npc.velocity.y = v
        -- end
    end

    return self
end