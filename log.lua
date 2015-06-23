require 'objectpool'

LogLevel = {
    cInfo = 0,
    cDebug = 1,
    cWarning = 2,
    cError = 3,
    cPanic = 4,
}

LogLevelColors = {}
LogLevelColors[LogLevel.cInfo]      = { 255, 255, 255 }
LogLevelColors[LogLevel.cDebug]     = {   0, 255,   0 }
LogLevelColors[LogLevel.cWarning]   = { 255, 255,   0 }
LogLevelColors[LogLevel.cError]     = { 255,   0,   0 }
LogLevelColors[LogLevel.cPanic]     = { 255,   0,   0 }

function create_log_message()
    local self = {}

    self.handle = 0
    self.active = false
    self.destroy_flag = false

    self.string = ""
    self.timer = 0
    self.index = 0
    self.level = LogLevel.cInfo

    self.activate = function(self, level, string, timer, index)
        self.level = level
        self.string = string
        self.timer = timer
        self.index = index

        if self.level == LogLevel.cPanic then
            self.string = self.string:upper()
        end
    end

    self.release = function(self)
    end

    self.update = function(self, dt, manager)
        self.timer = self.timer - dt

        if self.timer <= 0 then
            self.destroy_flag = true
            manager:remove_log()
        end
    end

    self.render = function(self, logx, logy, spacing)
        local alpha = 255
        if self.timer <= 1 then
            alpha = 255 * self.timer
        end

        if self.level == LogLevel.cPanic then
            love.graphics.setColor(255, 255, 255)
            love.graphics.rectangle("fill",
                logx - 2, logy + self.index * spacing - 2,
                love.graphics.getFont():getWidth(self.string) + 4,
                love.graphics.getFont():getHeight(self.string) + 4)
        end

        local r, g, b = unpack(LogLevelColors[self.level])
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.print(self.string, logx, logy + self.index * spacing)
    end

    return self
end

function create_log()
    local self = {}

    self.pool = create_object_pool(create_log_message, 128)
    self.log_time = 3

    self.current_index = 0

    self.log = function(self, level, message)
        print("Log: "..message)
        self.pool:add(level, message, self.log_time, self.current_index)
        self.current_index = self.current_index + 1
    end

    self.log_info = function(self, message)
        self:log(LogLevel.cInfo, message)
    end

    self.log_debug = function(self, message)
        self:log(LogLevel.cDebug, message)
    end

    self.log_warning = function(self, message)
        self:log(LogLevel.cWarning, message)
    end

    self.log_error = function(self, message)
        self:log(LogLevel.cError, message)
    end

    self.log_panic = function(self, message)
        self:log(LogLevel.cPanic, message)
    end

    self.remove_log = function(self)
        self.current_index = self.current_index - 1
        self.pool:execute(function(log)
            log.index = log.index - 1
        end)
    end

    self.update = function(self, dt)
        self.pool:execute_obj_func("update", dt, self)
        self.pool:remove_flagged()
    end

    self.render = function(self)
        self.pool:execute_obj_func("render", 5, 5, 20)
    end

    return self
end