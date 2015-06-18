function create_game()
    local self = {}

    self.x = -10
    self.delta = 1

    self.init = function(self)
    end

    self.update = function(self, dt)
        self.x = self.x + (10 * self.delta * dt)
        if self.x < -10 and self.delta < 0 then
            self.delta = 1
            self.x = -10
        end
        if self.x > 10 and self.delta > 0 then
            self.x = 10
            self.delta = -1
        end
    end

    self.render = function(self)
        love.graphics.circle("line", X(0), Y(0), S(5))
        love.graphics.circle("line", X(self.x), Y(0), S(5))
    end

    return self
end