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
    self.collider:set_user_data(self)
    self.collider.body:setMass(1)
    self.collider:set_friction(0)

    self.flag_trigger = Game.trigger_manager:add(0, 0, love.physics.newCircleShape(0, 0, 32), "cFlagTrigger")
    self.flag_trigger:attach(self)

    self.attached_to = nil

    self.flagged_for_respawn = false

    self.is_on_ground = function(self)
        local s = self.position
        local e = s + Vec2(0, 26)
        local hits = Collision:ray_cast(s, e, collision_get_mask("cStaticEnvironment", "cEnvironment"))
        return #hits > 0
    end

    self.respawn = function(self)
        self.flagged_for_respawn = true
    end

    self.on_collision_begin = function(self, other, coll)
        local obj = other:getUserData()
        if obj and obj.tag == "kill" then
            self:respawn()
        end
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

    self.grab = function(self, actor)
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
        self.collider.body:setLinearVelocity(0, 0)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end

        if self.flagged_for_respawn then
            self.flagged_for_respawn = false
            self:set_position(Game.level:get_spawn_position())
            self.attached_to = nil
        end

        if self.attached_to then
            self:set_position(self.attached_to.position + self.attached_to:get_attached_offset())
        else
            if self:is_on_ground() then
                self.collider.body:setLinearVelocity(0, 0)
            end
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