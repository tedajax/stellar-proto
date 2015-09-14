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
    self.collider:set_user_data(self)
    self.collider.body:setMass(1)

    self.sensor = {}
    self.sensor.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.sensor.shape = love.physics.newRectangleShape(0, 0, self.width + 4, self.height + 4)
    self.sensor.fixture = love.physics.newFixture(self.sensor.body, self.sensor.shape)
    self.sensor.fixture:setSensor(true)
    self.sensor.fixture:setUserData(self)
    self.sensor.fixture:setFilterData(unpack(get_collision_filter("cPlayerSensor")))

    self.image =  love.graphics.newImage("assets/test_player_sprite.png")

    self.flagged_for_respawn = false

    self.get_attached_offset = function()
        if self.controller then
            return self.controller:get_attached_offset()
        else
            return Vec2(0, 0)
        end
    end

    self.respawn = function()
        self.flagged_for_respawn = true
    end

    self.on_collision_begin = function(self, other, coll)
        local obj = other:getUserData()
        if obj and obj.tag == "kill" then
            self:respawn()
        end
    end

    self.on_collision_end = function(self, other, coll)
    end

    self.on_trigger_enter = function(self, sender)

    end

    self.set_position = function(self, pos)
        self.position:copy(pos)
        self.collider.body:setPosition(self.position:unpack())
        self.sensor.body:setPosition(self.position:unpack())
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end
        if self.flagged_for_respawn then
            self:set_position(Game.flag.position)
            self.flagged_for_respawn = false
        end
        self.sensor.body:setPosition(self.position:unpack())
    end

    self.render = function(self)
        local sx = 1
        local pos_x = self.position.x - self.width / 2
        if self.controller.facing == 0 then
            sx = -1
            pos_x = self.position.x + self.width/ 2
        end
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.image,
            pos_x,
            self.position.y - self.height / 2,
            self.collider.body:getAngle(),
            sx,
            1)
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

    self.get_attached_offset = function()
        local offset = Vec2(24, -24)
        if self.facing == self.FACING_DIRECTIONS.cRight then
            offset.x = -4
        end
        return offset
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

        if Input:get_button_down("flag") then
            if self.actor.flag then
                if not self.actor.flag:is_grabbed() then
                    self.actor.flag:grab(self.actor)
                else
                    local h = math.sign(Input:get_axis("horizontal"))
                    local v = math.sign(Input:get_axis("vertical"))

                    local force = Vec2(200, 150)

                    if h == 0 then
                        if self.facing == self.FACING_DIRECTIONS.cLeft then
                            force.x = force.x * -1
                        end
                    else
                        force.x = force.x * h
                    end

                    if v > 0 then
                        self.actor.flag:drop()
                        return
                    elseif v == 0 then
                        force.y = force.y + (100 * -Input:get_axis("vertical"))
                    else
                        if h == 0 then force.x = 0 end
                        force.y = force.y + (100 * -Input:get_axis("vertical"))
                    end
                    force.y = force.y * -1
                    self.actor.flag:throw(force)
                end
            end
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
        local side_scalar = 1
        local angle = 0
        if self.facing == self.FACING_DIRECTIONS.cLeft then
            angle = 180
            side_scalar = -1
        end

        local radius = 8
        local bx = self.actor.position.x --+ (self.actor.width / 2 + radius) * side_scalar
        local by = self.actor.position.y

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
        self.actor.collider.body:setLinearVelocity(0, 0)
    end

    self.on_update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        self.actor.position.x = self.actor.position.x + Defaults.debug.noclip_speed * h * dt
        self.actor.position.y = self.actor.position.y + Defaults.debug.noclip_speed * v * dt

        self.actor.collider.body:setPosition(self.actor.position.x, self.actor.position.y)
    end

    return self
end