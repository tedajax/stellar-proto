function create_controller(actor, name)
    local self = {}

    self.actor = nil
    self.name = nil

    self.posess = function(self, actor, name)
        if self.actor ~= nil then self:unposess() end

        self.actor = actor
        self.name = name or "controller"
        self.actor[self.name] = self

        if type(self.on_posess) == "function" then
            self:on_posess()
        end
    end

    self.unposess = function(self)
        if self.actor == nil then return end

        if type(self.on_unposess) == "function" then
            self:on_unposess()
        end

        self.actor[self.name] = nil
        self.actor = nil
    end

    self.update = function(self, dt)
        if self.actor == nil then return end

        if type(self.on_update) == "function" then
            self:on_update(dt)
        end
    end

    if actor ~= nil then
        self:posess(actor, name)
    end

    return self
end