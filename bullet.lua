require 'objectpool'
Vec2 = require 'vec2'

BULLET_TAGS = {
    cUnknown = 0,
    cPlayer = 1,
    cEnemy = 2
}

function create_bullet()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)
    self.radius = 0

    self.tag = BULLET_TAGS.cUnknown

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setActive(false)
    self.body:setGravityScale(0)
    self.shape = nil
    self.fixture = nil

    self.activate = function(self, x, y, rad, angle, speed, tag)
        self.position = Vec2(x, y)
        self.radius = rad
        self.tag = tag or BULLET_TAGS.cUnknown

        self.body:setX(x)
        self.body:setY(y)
        self.shape = love.physics.newCircleShape(
            0, 0,
            self.radius
        )
        self.fixture = love.physics.newFixture(self.body, self.shape)
        self.fixture:setUserData(self)
        self.fixture:setFilterData(unpack(get_collision_filter("cPlayerBullet")))

        self.body:setActive(true)

        local radians = math.rad(angle)
        local velocity = Vec2(math.cos(radians), math.sin(radians))
        velocity = velocity * speed

        self.body:setLinearVelocity(velocity:unpack())
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.on_collision_begin = function(self, other, coll)
        self.destroy_flag = true
    end

    self.update = function(self, dt)
        self.position.x = self.body:getX()
        self.position.y = self.body:getY()
    end

    self.render = function(self)
        love.graphics.push()
        love.graphics.translate(self.position.x, self.position.y)
        love.graphics.setColor(255, 0, 255)
        love.graphics.circle("line",
            0, 0,
            self.radius)
        love.graphics.pop()
    end

    return self
end

function create_bullet_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_bullet, capacity)

    self.add = function(self, ...)
        self.pool:add(...)
    end

    self.remove = function(self, bullet)
        self.pool:remove(bullet)
    end

    self.update = function(self, dt)
        self.pool:remove_flagged()
        self.pool:execute_obj_func("update", dt)
    end

    self.render = function(self)
        self.pool:execute_obj_func("render")
    end

    self.clear = function(self)
        self.pool:clear()
    end

    return self
end