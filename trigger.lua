local Vec2 = require 'vec2'
require 'objectpool'

function create_trigger()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "static")
    self.body:setActive(false)
    self.shape = nil
    self.fixture = nil

    -- will be pretty fragile should switch to keeping track of what objects are inside
    self.count = 0

    self.activate = function(self, x, y, shape, filter)
        self.position:set(x, y)

        self.body:setPosition(x, y)
        self.body:setActive(true)
        self.body:setAngle(0)
        self.shape = shape
        self.fixture = love.physics.newFixture(self.body, self.shape)
        self.fixture:setFilterData(unpack(get_collision_filter(filter or "cDefault")))
        self.fixture:setSensor(true)
        self.fixture:setUserData(self)

        self.count = 0
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    self.render = function(self)
        if self.count <= 0 then
            love.graphics.setColor(0, 255, 0)
        else
            love.graphics.setColor(255, 0, 0)
        end

        Game.collision:draw_body(self.body)
    end

    self.on_collision_begin = function(self, other, coll)
        -- do triggery things
        self.count = self.count + 1
    end

    self.on_collision_end = function(self, other, coll)
        -- do triggery things
        self.count = self.count - 1
    end

    return self
end

function create_trigger_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_trigger, capacity)

    self.add = function(self, ...)
        return self.pool:add(...)
    end

    self.remove = function(self, wall)
        self.pool:remove(wall)
    end

    self.update = function(self, dt)
        self.pool:remove_flagged()
    end

    self.render = function(self, dt)
        self.pool:execute_obj_func("render")
    end

    self.clear = function(self)
        self.pool:clear()
    end

    return self
end