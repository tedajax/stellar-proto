require 'objectpool'
Vec2 = require 'vec2'

function create_wall()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)
    self.width = 0
    self.height = 0

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "static")
    self.body:setActive(false)
    self.shape = nil
    self.fixture = nil

    self.activate = function(self, l, r, t, b)
        local x = (l + r) / 2
        local y = (t + b) / 2
        self.position = Vec2(x, y)
        self.width = math.abs(r - l)
        self.height = math.abs(b - t)

        self.body:setX(x)
        self.body:setY(y)
        self.body:setActive(true)
        self.body:setAngle(0)
        self.shape = love.physics.newRectangleShape(
            0, 0,
            self.width, self.height
        )
        self.fixture = love.physics.newFixture(self.body, self.shape)
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.shape ~= nil then self.shape:destroy() end
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.render = function(self)
        love.graphics.push()
        love.graphics.translate(self.position.x, self.position.y)
        love.graphics.setColor(0, 255, 0)
        love.graphics.rectangle("fill",
            -self.width / 2,
            -self.height / 2,
            self.width,
            self.height)
        love.graphics.pop()
    end

    return self
end

function create_wall_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_wall, capacity)

    self.wall_width = 32
    self.wall_height = 32

    self.add = function(self, ...)
        return self.pool:add(...)
    end

    self.remove = function(self, wall)
        self.pool:remove(wall)
    end

    self.update = function(self, dt)
        self.pool:remove_flagged()
    end

    self.render = function(self)
        self.pool:execute_obj_func("render")
    end

    self.clear = function(self)
        self.pool:clear()
    end

    return self
end
