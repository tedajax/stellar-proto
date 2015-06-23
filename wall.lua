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

    self.activate = function(self, x, y, w, h)
        self.position = Vec2(x, y)
        self.width = w
        self.height = h

        self.body:setX(x)
        self.body:setY(y)
        self.body:setActive(true)
        self.shape = love.physics.newRectangleShape(0, 0, w, h)
        self.fixture = love.physics.newFixture(self.body, self.shape)
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.shape ~= nil then self.shape:destroy() end
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.render = function(self)
        love.graphics.setColor(0, 255, 0)
        love.graphics.rectangle("fill",
            X(self.position.x - self.width / 2),
            Y(self.position.y - self.height / 2),
            SX(self.width),
            SY(self.height))
    end

    return self
end

function create_wall_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_wall, capacity)

    self.add = function(self, ...)
        self.pool:add(...)
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

    return self
end
