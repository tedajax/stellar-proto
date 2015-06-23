require 'objectpool'
Vec2 = require 'vec2'

function create_npc()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.position = Vec2(0, 0)
    self.radius = 8

    self.speed = 260
    self.velocity = Vec2(0, 0)

    self.is_selected = false

    self.activate = function(self, x, y)
        self.position.x = x
        self.position.y = y
        self.is_selected = false
    end

    self.release = function(self)
    end

    self.update = function(self, dt)
        self.position = self.position + self.velocity * self.speed * dt
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

