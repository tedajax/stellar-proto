local Vec2 = require 'vec2'
require 'controller'

function create_flag()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 32
    self.height = 64

    self.controller = nil

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setFixedRotation(true)

    self.shape = love.physics.newRectangleShape(
        0,
        self.width / 2,
        self.width,
        self.height - self.width / 2
    )

    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setFriction(0)
    self.fixture:setFilterData(get_collision_filter("cFlag"))

    self.base_shape = love.physics.newCircleShape(
        0,
        self.height / 2,
        self.width / 2
    )
    self.base_fixture = love.physics.newFixture(self.body, self.base_shape)
    self.base_fixture:setFilterData(get_collision_filter("cFlag"))

    self.body:setMass(1)

    self.set_position = function(self, pos)
        self.position.x = pos.x
        self.position.y = pos.y
        self.body:setPosition(pos.x, pos.y)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end
    end

    self.render = function(self)
        local pole_x = self.position.x - self.width / 4

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.line(
            pole_x, self.position.y - self.height / 2,
            pole_x, self.position.y + self.height / 2
        )

        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.polygon(
            "fill",
            pole_x, self.position.y - self.height / 2,
            self.position.x + self.width / 2, self.position.y - self.height / 2 + 5,
            pole_x, self.position.y - self.height / 2 + 10
        )
    end

    return self
end

function create_flag_controller(flag)
    local self = create_controller(flag)

    self.on_update = function(self, dt)
        self.actor.position.x = self.actor.body:getX()
        self.actor.position.y = self.actor.body:getY()
    end

    self.set_position = function(self, position)
        self.actor:set_position(position)
    end

    return self
end