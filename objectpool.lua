
function create_object_pool(create_func, capacity)
    assert_object_poolable(create_func(0     ))

    local self = {}

    self.objects = {}
    self.free_indices = {}
    self.capacity = capacity
    self.create_func = create_func

    for i = 1, capacity do
        self.free_indices[i] = i
        self.objects[i] = self.create_func()
        self.objects[i].handle = i
    end

    self.free_head = capacity

    self.pop_index = function(self)
        assert(self.free_head > 0, "No more free space in pool with capacity "..tostring(self.capacity)..".  Increase capacity.")
        local result = self.free_indices[self.free_head]
        self.free_head = self.free_head - 1
        return result
    end

    self.push_index = function(self, index)
        self.free_head = self.free_head + 1
        self.free_indices[self.free_head] = index
    end

    self.add = function(self, ...)
        local index = self:pop_index()
        self.objects[index]:activate(...)
        self.objects[index].active = true
        return self.objects[index]
    end

    self.remove = function(self, obj)
        if type(self.objects[obj.handle].on_release) == "function" then
            self.objects[obj.handle]:on_release()
        end
        self.objects[obj.handle]:release()
        self.objects[obj.handle].active = false
        self.objects[obj.handle].destroy_flag = false
        self:push_index(obj.handle)
    end

    self.clear = function(self)
        self.objects = {}
        self.free_indices = {}
        self.create_func = create_func

        for i = 1, capacity do
            self.free_indices[i] = i
            self.objects[i] = self.create_func()
            self.objects[i].handle = i
        end

        self.free_head = self.capacity
    end

    self.remove_flagged = function(self)
        for i = 1, self.capacity do
            if self.objects[i].active and self.objects[i].destroy_flag then
                self:remove(self.objects[i])
            end
        end
    end

    self.execute = function(self, func)
        for i = 1, self.capacity do
            if self.objects[i].active then
                func(self.objects[i])
            end
        end
    end

    self.execute_obj_func = function(self, func_name, ...)
        for i = 1, self.capacity do
            if self.objects[i].active then
                self.objects[i][func_name](self.objects[i], ...)
            end
        end
    end

    self.filter = function(self, func)
        assert(type(func) == "function", "Attempt to filter with invalid function.")
        local result = {}
        for i = 1, self.capacity do
            if self.objects[i].active and func(self.objects[i]) then
                table.insert(result, self.objects[i])
            end
        end
        return result
    end

    return self
end

function assert_object_poolable(obj)
    assert(type(obj.handle) == "number")
    assert(type(obj.active) == "boolean")
    assert(type(obj.destroy_flag) == "boolean")
    assert(type(obj.activate) == "function")
    assert(type(obj.release) == "function")
end