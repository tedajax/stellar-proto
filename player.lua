local Vec2 = require 'vec2'
local json = require 'json'
require 'movement'
require 'bullet'
require 'controller'
require 'capsule'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 24
    self.height = 50

    self.controller = nil

    local len = self.height - self.width
    self.collider = create_capsule(Game.collision.world, self.width / 2, len)
    self.collider.body:setFixedRotation(true)
    self.collider.body:setLinearDamping(0.1)
    self.collider:set_filter_data(get_collision_filter("cPlayer"))

    self.collider.body:setMass(1)

    self.on_collision_begin = function(self, other, coll)
    end

    self.on_collision_end = function(self, other, coll)
    end

    self.set_position = function(self, pos)
        self.position.x = pos.x
        self.position.y = pos.y
        self.collider.body:setX(self.position.x)
        self.collider.body:setY(self.position.y)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end
    end

    self.render = function(self)
        love.graphics.setColor(180, 207, 236, 255)
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
        local movementProps = json.load(Defaults.game.movement_props)
        self.movement = create_movement(
            self.actor.collider,
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

        self.actor.position.x = self.actor.collider.body:getX()
        self.actor.position.y = self.actor.collider.body:getY()

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
        self.actor:set_position(pos)
    end

    return self
end

function create_player_noclip_controller(player)
    local self = create_controller(player)

    self.on_posess = function(self)
        self.actor.collider.body:setActive(false)
    end

    self.on_unposess = function(self)
        self.actor.collider.body:setActive(true)
    end

    self.on_update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        self.actor.position.x = self.actor.position.x + 800 * h * dt
        self.actor.position.y = self.actor.position.y + 800 * v * dt

        self.actor.collider.body:setPosition(self.actor.position.x, self.actor.position.y)
    end

    return self
end