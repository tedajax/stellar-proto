local Vec2 = require 'vec2'
local json = require 'json'
require 'movement'
require 'bullet'
require 'controller'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 16
    self.height = 32

    self.controller = nil

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setFixedRotation(true)
    self.body:setLinearDamping(0.1)

    self.shape = love.physics.newRectangleShape(
        0,
        0,
        self.width,
        self.height - self.width / 2
    )
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setFriction(0)
    self.fixture:setFilterData(get_collision_filter("cPlayer"))

    self.foot_shape = love.physics.newCircleShape(
        0,
        self.height / 2 - self.width / 4,
        self.width / 2 + 2
    )
    self.foot_fixture = love.physics.newFixture(self.body, self.foot_shape)
    self.foot_fixture:setFilterData(get_collision_filter("cPlayer"))

    -- self.fixture:setUserData(self)
    self.foot_fixture:setUserData(self)

    self.body:setMass(1)

    self.on_collision_begin = function(self, other, coll)
    end

    self.on_collision_end = function(self, other, coll)
    end

    self.set_position = function(self, pos)
        self.position.x = pos.x
        self.position.y = pos.y
        self.body:setX(self.position.x)
        self.body:setY(self.position.y)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end
    end

    self.render = function(self)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle(
            "fill",
            self.position.x - self.width / 2,
            self.position.y - self.height / 2,
            self.width,
            self.height
        )
    end

    return self
end

function create_player_controller(player)
    local self = create_controller(player)

    self.movement = nil

    self.FACING_DIRECTIONS = { cLeft = 0, cRight = 1 }
    self.facing = self.FACING_DIRECTIONS.cRight

    self.bullet_manager = nil

    self.initialize = function(self)
        local movementProps = json.load("movement.json")
        self.movement = create_movement(
            self.actor.body,
            { shape = self.actor.foot_shape, fixture = self.actor.foot_fixture },
            movementProps
        )
    end

    self.on_update = function(self, dt)
        self.movement:set_input(
            Input:get_axis("horizontal"),
            Input:get_axis("vertical"),
            Input:get_button("jump")
        )

        if Input:get_axis("horizontal") > 0 then
            self.facing = self.FACING_DIRECTIONS.cRight
        elseif Input:get_axis("horizontal") < 0 then
            self.facing = self.FACING_DIRECTIONS.cLeft
        end

        if Input:get_button_down("jump") then
            self.movement:request_jump()
        end

        if Input:get_button_down("fire") and self.bullet_manager ~= nil then
            self:fire()
        end

        self.movement:update(dt)

        self.actor.position.x = self.actor.body:getX()
        self.actor.position.y = self.actor.body:getY()

        -- for _, npc in ipairs(self.selected) do
        --     npc.velocity.x = h
        --     npc.velocity.y = v
        -- end
    end

    self.fire = function(self)
        local bx = self.actor.position.x
        local by = self.actor.position.y
        local radius = 8
        local angle = 0
        if self.facing == self.FACING_DIRECTIONS.cLeft then
            angle = 180
        end
        local speed = 1500
        self.bullet_manager:add(bx, by, radius, angle, speed, BULLET_TAGS.cPlayer)
    end

    self.set_position = function(self, pos)
        self.actor:setPosition(pos)
    end

    return self
end

function create_player_noclip_controller(player)
    local self = create_controller(player)

    self.on_posess = function(self)
        self.actor.body:setActive(false)
    end

    self.on_unposess = function(self)
        self.actor.body:setActive(true)
    end

    self.on_update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        self.actor.position.x = self.actor.position.x + 800 * h * dt
        self.actor.position.y = self.actor.position.y + 800 * v * dt

        self.actor.body:setPosition(self.actor.position.x, self.actor.position.y)
    end

    return self
end