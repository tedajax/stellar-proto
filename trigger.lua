local Vec2 = require 'vec2'
require 'objectpool'

function create_trigger()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)

    self.body = love.physics.newBody(Game.collision.world, 0, 0, "dynamic")
    self.body:setActive(false)
    self.body:setGravityScale(0)
    self.shape = nil
    self.fixture = nil

    self.attached_actor = nil

    self.subscribers = {}

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

    self.attach = function(self, actor)
        assert(self.attached_actor == nil)
        self.attached_actor = actor
    end

    self.detach = function(self, actor)
        self.attached_actor = nil
    end

    self.subscribe = function(self, sub)
        -- todo: handle multiple subscriptions from same source gracefully
        table.insert(self.subscribers, sub)
    end

    self.unsubscribe = function(self, sub)
        for i = #self.subscribers, 1, -1 do
            if self.subscribers[i] == sub then
                table.remove(self.subscribers, i)
                -- todo: if we disallow duplication we can early terminate here
            end
        end
    end

    self.notify = function(self, msg, ...)
        for _, sub in ipairs(self.subscribers) do
            if type(sub[msg]) == "function" then
                sub[msg](self, ...)
            end
        end
    end

    self.update = function(self, dt)
        if self.attached_actor ~= nil then
            self.body:setPosition(self.attached_actor.position.x, self.attached_actor.position.y)
        end
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
        if self.count == 0 then
            self:notify("on_trigger_activated")
        end
        self.count = self.count + 1

        fixture_call(other, "on_trigger_enter")
    end

    self.on_collision_end = function(self, other, coll)
        self.count = self.count - 1
        if self.count == 0 then
            self:notify("on_trigger_deactivated")
        end

        fixture_call(other, "on_trigger_exit")
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
        self.pool:execute_obj_func("update", dt)
    end

    self.render = function(self, dt)
        self.pool:execute_obj_func("render")
    end

    self.clear = function(self)
        self.pool:clear()
    end

    return self
end