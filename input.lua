function create_input()
    local self = {}

    self.axes = {}
    self.buttons = {}

    self.add_axis = function(self, name)
        if self.axes[name] == nil then
            self.axes[name] = create_axis(name)
        end
    end

    self.create_axis_binding = function(self, name, key, value)
        self.axes[name]:create_binding(key, value)
    end

    self.get_axis = function(self, name)
        assert(self.axes[name] ~= nil)
        return self.axes[name].value
    end

    self.add_button = function(self, name)
        if self.buttons[name] == nil then
            self.buttons[name] = create_button(name)
        end
    end

    self.create_button_binding = function(self, name, key)
        self.buttons[name]:create_binding(key)
    end

    self.get_button = function(self, name)
        assert(self.buttons[name] ~= nil)
        return self.buttons[name]:is_down()
    end

    self.get_button_down = function(self, name)
        assert(self.buttons[name] ~= nil)
        return self.buttons[name].down_count > 0 and self.buttons[name].last_down_count == 0
    end

    self.get_button_up = function(self, name)
        assert(self.buttons[name] ~= nil)
        return self.buttons[name].down_count == 0 and self.buttons[name].last_down_count > 0
    end

    self.on_key_down = function(self, key)
        for name, axis in pairs(self.axes) do
            axis:on_key_down(key)
        end

        for name, button in pairs(self.buttons) do
            button:on_key_down(key)
        end
    end

    self.on_key_up = function(self, key)
        for name, axis in pairs(self.axes) do
            axis:on_key_up(key)
        end

        for name, button in pairs(self.buttons) do
            button:on_key_up(key)
        end
    end

    self.update = function(self)
        for n, button in pairs(self.buttons) do
            button.last_down_count = button.down_count
        end
    end

    return self
end

function create_axis(name)
    local self = {}

    self.name = name
    self.value = 0
    self.min = -1
    self.max = 1

    self.bindings = {}
    self.inputs = {}

    self.create_binding = function(self, key, value)
        self.bindings[key] = value
    end

    self.on_key_down = function(self, key)
        if self.bindings[key] == nil then return end

        if self.inputs[key] ~= true then
            self.inputs[key] = true
            self.value = self.value + self.bindings[key]
        end
    end

    self.on_key_up = function(self, key)
        if self.bindings[key] == nil then return end

        if self.inputs[key] == true then
            self.inputs[key] = false
            self.value = self.value - self.bindings[key]
        end
    end

    return self
end

function create_button(name)
    local self = {}

    self.name = name
    self.down_count = 0
    self.last_down_count = 0

    self.bindings = {}
    self.inputs = {}

    self.is_down = function(self)
        return self.down_count > 0
    end

    self.create_binding = function(self, key)
        self.bindings[key] = 1
    end

    self.on_key_down = function(self, key)
        if self.bindings[key] == nil then return end

        if self.inputs[key] ~= true then
            self.inputs[key] = true
            self.down_count = self.down_count + 1
        end
    end

    self.on_key_up = function(self, key)
        if self.bindings[key] == nil then return end

        if self.inputs[key] == true then
            self.inputs[key] = false
            self.down_count = self.down_count - 1
        end
    end

    return self
end
