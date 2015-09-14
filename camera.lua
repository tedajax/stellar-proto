function create_camera(x, y)
    local self = {}

    local x = x or 0
    local y = y or 0

    self.position = {
        x = x - love.graphics.getWidth() / 2,
        y = y - love.graphics.getHeight() / 2
    }
    self.shake_pos = { x = 0, y = 0 }
    self.shake_time = 0
    self.shake_magnitude = 0
    self.rotation = 0
    self.zoom = 0
    self.base_zoom = 1
    self.target = nil
    self.follow_bounds = { l = -16, r = 16, t = -16, b = -16 }
    self.level_bounds = nil

    self.move = function(self, x, y)
        local x = x or 0
        local y = y or 0
        self.position.x = self.position.x + x
        self.position.y = self.position.y + y
    end

    self.look_at = function(self, x, y)
        self.position.x = x
        self.position.y = y
    end

    self.rotate = function(self, angle)
        self.rotation = self.rotation + angle
    end

    self.set_rotation = function(self, angle)
        self.rotation = angle
    end

    self.zoom_in = function(self, zoom)
        self.zoom = self.zoom - zoom
    end

    self.zoom_out = function(self, zoom)
        self.zoom = self.zoom + zoom
    end

    self.set_zoom = function(self, zoom)
        self.zoom = zoom
    end

    self.shake = function(self, time, mag)
        self.shake_time = time or 1
        self.shake_magnitude = mag or 1
    end

    self.set_target = function(self, target)
        assert(type(target) == "table")
        assert(type(target.x) == "number")
        assert(type(target.y) == "number")
        self.target = target
    end

    self.update = function(self, dt)
        if self.shake_time > 0 then
            self.shake_time = self.shake_time - dt
            self.shake_pos.x = math.random(
                -self.shake_magnitude,
                self.shake_magnitude
            )
            self.shake_pos.y = math.random(
                -self.shake_magnitude,
                self.shake_magnitude
            )
        else
            self.shake_pos.x = 0
            self.shake_pos.y = 0
        end

        if self.target ~= nil then
            local cx, cy = self.position.x, self.position.y
            local nx, ny = math.lerp(cx, self.target.x, 5 * dt), math.lerp(cy, self.target.y, 5 * dt)

            -- if self.target.x > cx + self.follow_bounds.r then
            --     nx = self.target.x - self.follow_bounds.r
            -- end

            -- if self.target.x < cx + self.follow_bounds.l then
            --     nx = self.target.x - self.follow_bounds.l
            -- end

            -- if self.target.y > cy + self.follow_bounds.b then
            --     ny = self.target.y - self.follow_bounds.b
            -- end

            -- if self.target.y < cy + self.follow_bounds.t then
            --     ny = self.target.y - self.follow_bounds.t
            -- end

            self:look_at(nx, ny)
        end

        if self.level_bounds then
            local cx, cy = self.position.x, self.position.y
            local nx, ny = cx, cy
            if math.abs(self.level_bounds.left - self.level_bounds.right) > love.graphics.getWidth() then
                if cx < self.level_bounds.left + love.graphics.getWidth() / 2 then
                    nx = self.level_bounds.left + love.graphics.getWidth() / 2
                end

                if cx > self.level_bounds.right - love.graphics.getWidth() / 2 then
                    nx = self.level_bounds.right - love.graphics.getWidth() / 2
                end
            end

            if math.abs(self.level_bounds.top - self.level_bounds.bottom) > love.graphics.getHeight() then
                if cy < self.level_bounds.top + love.graphics.getHeight() / 2 then
                    ny = self.level_bounds.top + love.graphics.getHeight() / 2
                end

                if cy > self.level_bounds.bottom - love.graphics.getHeight() / 2 then
                    ny = self.level_bounds.bottom - love.graphics.getHeight() / 2
                end
            end
            self:look_at(nx, ny)
        end
    end

    self.push = function(self)
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        love.graphics.rotate(-math.rad(self.rotation))
        love.graphics.scale(
            math.abs(1 / (self.zoom + self.base_zoom)),
            math.abs(1 / (self.zoom + self.base_zoom))
        )
        love.graphics.translate(
            -(self.position.x + self.shake_pos.x),
            -(self.position.y + self.shake_pos.y)
        )

    end

    self.pop = function(self)
        love.graphics.pop()
    end

    return self
end