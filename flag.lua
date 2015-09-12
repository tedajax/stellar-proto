local Vec2 = require 'vec2'
require 'controller'
require 'capsule'

function create_flag()
    local self = {}

    self.position = Vec2(0, 0)
    self.width = 32
    self.height = 40

    self.controller = nil

    self.collider = create_capsule(Game.collision.world, self.width / 2, self.height - self.width)
    self.collider.body:setFixedRotation(true)
    self.collider:set_filter_data(get_collision_filter("cFlag"))
    self.collider.body:setMass(1)

    self.flag_trigger = Game.trigger_manager:add(0, 0, love.physics.newCircleShape(0, 0, 32), "cFlagTrigger")
    self.flag_trigger:attach(self)

    self.attached_to = nil
    self.attached_offset = Vec2(0, 0)

    self.set_position = function(self, pos)
        self.position.x = pos.x
        self.position.y = pos.y
        self.collider.body:setPosition(pos.x, pos.y)
    end

    self.on_actor_enter = function(self, sender, actor)
        if actor == nil then return end
        actor.flag = self
    end

    self.on_actor_exit = function(self, sender, actor)
        if actor == nil then return end
        if actor.flag == self then
            actor.flag = nil
        end
    end

    self.is_grabbed = function(self)
        return self.attached_to ~= nil
    end

    self.grab = function(self, actor, offset)
        self.attached_offset:copy(offset)
        self.attached_to = actor
        self.collider.body:setType("kinematic")
    end

    self.drop = function(self)
        self.attached_to = nil
        self.collider.body:setType("dynamic")
    end

    self.throw = function(self, force)
        self:drop()
        self.collider.body:applyLinearImpulse(force:unpack())
    end

    self.set_position = function(self, pos)
        self.position:copy(pos)
        self.collider.body:setPosition(self.position:unpack())
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end

        if self.attached_to then
            self:set_position(self.attached_to.position + self.attached_offset)
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
            self.position.x + self.width / 2 + 10, self.position.y - self.height / 2 + 10,
            pole_x, self.position.y - self.height / 2 + 20
        )
    end

    return self
end

function create_flag_controller(flag)
    local self = create_controller(flag)

    self.on_update = function(self, dt)
        self.actor.position.x = self.actor.collider.body:getX()
        self.actor.position.y = self.actor.collider.body:getY()
    end

    self.set_position = function(self, position)
        self.actor:set_position(position)
    end

    return self
end