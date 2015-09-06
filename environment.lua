require 'objectpool'
require 'controller'
Vec2 = require 'vec2'

-- walls are static parts of the environment
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
        self.fixture:setFilterData(get_collision_filter("cEnvironment"))
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.render = function(self)
        -- love.graphics.push()
        -- love.graphics.translate(self.position.x, self.position.y)
        -- love.graphics.setColor(0, 255, 0)
        -- love.graphics.rectangle("fill",
        --     -self.width / 2,
        --     -self.height / 2,
        --     self.width,
        --     self.height)
        -- love.graphics.pop()
    end

    return self
end

-- platforms are kinematic parts of the environment that can be moved by their own behaviors
function create_platform()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)
    self.rotation = 0
    self.width = 0
    self.height = 0

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "kinematic")
    self.body:setActive(false)
    self.shape = nil
    self.fixture = nil

    self.controller = nil

    self.activate = function(self, x, y, w, h, controller)
        self.position = Vec2(x, y)
        self.width = w
        self.height = h
        self.rotation = 0

        self.body:setX(x)
        self.body:setY(y)
        self.body:setActive(true)
        self.body:setAngle(0)
        self.shape = love.physics.newRectangleShape(
            0, 0,
            self.width, self.height
        )
        self.fixture = love.physics.newFixture(self.body, self.shape)
        self.fixture:setFilterData(get_collision_filter("cEnvironment"))

        if controller ~= nil then
            controller:posess(self)
        end
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.set_position = function(self, x, y)
        self.position.x = x
        self.position.y = y
        self.body:setX(x)
        self.body:setY(y)
    end

    self.update = function(self, dt)
        if self.controller ~= nil then
            self.controller:update(dt)
        end
    end

    self.render = function(self)
        love.graphics.push()
        love.graphics.translate(self.position.x, self.position.y)
        love.graphics.rotate(math.rad(self.rotation))
        love.graphics.setColor(0, 255, 255)
        love.graphics.rectangle("fill",
            -self.width / 2,
            -self.height / 2,
            self.width,
            self.height)
        love.graphics.pop()
    end

    return self
end

function create_platform_controller_simple()
    local self = create_controller()

    self.start_x = 0
    self.distance = 100
    self.speed = 50
    self.direction = 1

    self.on_posess = function(self)
        self.start_x = self.actor.position.x
    end

    self.on_update = function(self, dt)
        local x = self.actor.position.x
        if self.direction > 0 then
            x = x + self.speed * dt
            if x >= self.start_x + self.distance then
                x = self.start_x + self.distance
                self.direction = -1
            end
        elseif self.direction < 0 then
            x = x - self.speed * dt
            if x <= self.start_x then
                x = self.start_x
                self.direction = 1
            end
        end
        self.actor:set_position(x, self.actor.position.y)
    end

    return self
end

function create_environment_manager(capacity)
    local self = {}

    self.walls = create_object_pool(create_wall, capacity)
    self.platforms = create_object_pool(create_platform, capacity)

    self.wall_width = 32
    self.wall_height = 32

    self.add_wall = function(self, ...)
        return self.walls:add(...)
    end

    self.add_platform = function(self, ...)
        return self.platforms:add(...)
    end

    self.remove_wall = function(self, wall)
        self.walls:remove(wall)
    end

    self.remove_platform = function(self, platform)
        self.platforms:remove(platform)
    end

    self.update = function(self, dt)
        self.walls:remove_flagged()
        self.platforms:remove_flagged()
        self.platforms:execute_obj_func("update", dt)
    end

    self.render = function(self)
        self.walls:execute_obj_func("render")
        self.platforms:execute_obj_func("render")
    end

    self.clear_walls = function(self)
        self.walls:clear()
    end

    self.clear = function(self)
        self.walls:clear()
        self.platforms:clear()
    end

    return self
end
