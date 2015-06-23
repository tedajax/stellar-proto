require 'objectpool'
Vec2 = require 'vec2'

function create_npc()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)
    self.radius = 8

    self.speed = 280
    self.acceleration = 10000
    self.friction = 1
    self.velocity = Vec2(0, 0)

    self.is_selected = false

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setActive(false)
    self.shape = love.physics.newCircleShape(self.radius)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    self.activate = function(self, x, y)
        self.position.x = x
        self.position.y = y
        self.is_selected = false
        self.body:setActive(true)
        self.body:setX(x)
        self.body:setY(y)
    end

    self.release = function(self)
        self.body:setActive(false)
    end

    self.update = function(self, dt)
        local velocity = self.velocity * self.acceleration * dt

        self.body:applyLinearImpulse(velocity.x, velocity.y)

        local lvx, lvy = self.body:getLinearVelocity()

        if self.velocity.x == 0 then
            lvx = lvx * (1 - self.friction)
        end

        if self.velocity.y == 0 then
            lvy = lvy * (1 - self.friction)
        end

        self.body:setLinearVelocity(
            math.clamp(lvx, -self.speed, self.speed),
            math.clamp(lvy, -self.speed, self.speed)
        )

        self.position.x = self.body:getX()
        self.position.y = self.body:getY()
    end

    self.render = function(self)
        if self.is_selected then
            love.graphics.setColor(255, 255, 0)
        else
            love.graphics.setColor(255, 255, 255)
        end
        love.graphics.circle(
            "fill",
            X(self.position.x),
            Y(self.position.y),
            S(self.radius)
        )
    end

    return self
end

function create_npc_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_npc, capacity)

    self.add = function(self, ...)
        self.pool:add(...)
    end

    self.remove = function(self, npc)
        self.pool:remove(npc)
    end

    self.update = function(self, dt)
        self.pool:remove_flagged()
        self.pool:execute_obj_func("update", dt)
    end

    self.render = function(self)
        self.pool:execute_obj_func("render")
    end

    self.get_all_in_radius = function(self, pos, radius)
        return self.pool:filter(function(obj)
            return Vec2.dist(pos, obj.position) <= radius + obj.radius
        end)
    end

    return self
end

