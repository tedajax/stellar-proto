Vec2 = require 'vec2'

function create_player()
    local self = {}

    self.position = Vec2(0, 0)
    self.radius = 0.25
    self.select_radius = 2
    self.speed = 10

    self.selected = {}

    self.update = function(self, dt)
        local h = Input:get_axis("horizontal")
        local v = Input:get_axis("vertical")

        local velocity = Vec2(h, v)
        velocity = velocity * self.speed * dt
        self.position = self.position + velocity

        for _, npc in ipairs(self.selected) do
            npc.velocity.x = h
            npc.velocity.y = v
        end

        if Input:get_button_down("select") then
            self:deselect()

            self.selected = Game.npc_manager:get_all_in_radius(self.position, self.select_radius)

            for _, npc in ipairs(self.selected) do
                npc.is_selected = true
            end
        end

        if Input:get_button_down("cancel") then
            self:deselect()
        end
    end

    self.deselect = function(self)
        for i, npc in ipairs(self.selected) do
            npc.is_selected = false
            npc.velocity.x = 0
            npc.velocity.y = 0
            self.selected[i] = nil
        end
    end

    self.render = function(self)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.circle("fill", X(self.position.x), Y(self.position.y), S(self.radius))

        love.graphics.setColor(0, 255, 0, 127)
        love.graphics.circle("fill", X(self.position.x), Y(self.position.y), S(self.select_radius))

        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.circle("line", X(self.position.x), Y(self.position.y), S(self.select_radius))
    end

    return self
end
