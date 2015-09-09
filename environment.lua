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
        self.fixture:setFilterData(get_collision_filter("cStaticEnvironment"))
    end

    self.release = function(self)
        self.body:setActive(false)
        if self.fixture ~= nil then self.fixture:destroy() end
    end

    return self
end

PLATFORM_CONTROLLERS = {}

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

    self.activate = function(self, x, y, w, h, r, controller)
        self.position = Vec2(x, y)
        self.width = w
        self.height = h
        self.rotation = r

        self.body:setX(self.position.x)
        self.body:setY(self.position.y)
        self.body:setActive(true)
        self.body:setAngle(math.rad(self.rotation))
        self.shape = love.physics.newRectangleShape(
            0, 0,
            self.width, self.height
        )
        self.fixture = love.physics.newFixture(self.body, self.shape)
        self.fixture:setFilterData(get_collision_filter("cEnvironment"))
        self.fixture:setUserData(self)

        if controller ~= nil then
            local c = create_platform_controller(controller)
            c:posess(self)
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

function register_platform_controller(typename, createfunc, parserfunc)
    assert(PLATFORM_CONTROLLERS[typename] == nil)
    PLATFORM_CONTROLLERS[typename] = {}
    PLATFORM_CONTROLLERS[typename].create = createfunc
    PLATFORM_CONTROLLERS[typename].parse = parserfunc
end

function create_platform_controller(properties)
    local f = PLATFORM_CONTROLLERS[properties.type]
    assert(type(f) == "table", "Unable to find platform controller given by type.")
    assert(type(f.create) == "function", "Unable to find platform controller given by type.")
    return f.create(properties)
end

function parse_platform_controller(controllerProps)
    if controllerProps == nil then return nil end

    local f = PLATFORM_CONTROLLERS[controllerProps.controller]
    assert(type(f) == "table", "Unable to find platform controller given by type '"..tostring(controllerProps.controller).."'.")
    assert(type(f.parse) == "function", "Unable to find platform controller parser given by type '"..tostring(controllerProps.controller).."'.")
    return f.parse(controllerProps)
end

function create_platform_controller_tween_position(properties)
    local self = create_controller()

    self.properties = properties
    self.tween = nil
    self.base_position = Vec2(0, 0)
    self.end_position = Vec2(0, 0)
    self.last_position = Vec2(0, 0)
    self.velocity = Vec2(0, 0)

    self.on_posess = function(self)
        self.base_position.x = self.actor.position.x
        self.base_position.y = self.actor.position.y
        self.last_position.x = self.base_position.x
        self.last_position.y = self.base_position.y
        self.end_position.x = self.base_position.x + self.properties.endpoint_offset.x
        self.end_position.y = self.base_position.y + self.properties.endpoint_offset.y
        self.tween = Tween.add_properties(self.properties.tween)
    end

    self.on_update = function(self, dt)
        local t = self.tween:evaluate()

        local x = math.lerp(self.base_position.x, self.end_position.x, t)
        local y = math.lerp(self.base_position.y, self.end_position.y, t)

        self.actor:set_position(x, y)

        self.velocity.x = x - self.last_position.x
        self.velocity.y = y - self.last_position.y

        self.last_position.x = x
        self.last_position.y = y
    end

    return self
end

function parse_platform_controller_type(controllerProps)
    return {
        type = controllerProps.controller
    }
end

function parse_platform_controller_tween_position(controllerProps)
    local properties = parse_platform_controller_type(controllerProps)

    properties.endpoint_offset = {
        x = controllerProps.endpoint_offset_x,
        y = controllerProps.endpoint_offset_y,
    }

    properties.tween = {
        start   = tonumber(controllerProps.tween_start),
        dest    = tonumber(controllerProps.tween_dest),
        time    = tonumber(controllerProps.tween_duration),
        func    = controllerProps.tween_function,
        reverse = not not controllerProps.tween_reverse, -- "not not X" is a conversion of string -> boolean believe it or not...
        count   = tonumber(controllerProps.tween_loops),
    }

    return properties
end

register_platform_controller("tween_position", create_platform_controller_tween_position, parse_platform_controller_tween_position)

function create_wall_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_wall, capacity)

    self.add = function(self, ...)
        return self.pool:add(...)
    end

    self.remove = function(self, wall)
        self.pool:remove(wall)
    end

    self.update = function(self, dt)
        self.pool:remove_flagged()
    end

    self.clear = function(self)
        self.pool:clear()
    end

    return self
end

function create_platform_manager(capacity)
    local self = {}

    self.pool = create_object_pool(create_platform, capacity)

    self.add = function(self, ...)
        return self.pool:add(...)
    end

    self.remove = function(self, platform)
        self.pool:remove(platform)
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
