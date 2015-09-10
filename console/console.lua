local print = print
module(..., package.seeall)
local IN  = require 'console.console-input'
local OUT = require 'console.console-output'
require 'util'

local console = {}
console.__index = console

local function split_str(str, pattern)
    local result = {}
    for w in str:gmatch(pattern) do table.insert(result, w) end
    return result
end

local function split_str_whitespace(str)
    local result = {}
    for w in str:gmatch("%S+") do table.insert(result, w) end
    return result
end

local function trim_str(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end


function new(font, width, height, spacing, unfocus_cb)
    local self = setmetatable({}, console)
    self._out = OUT.new(font, width, height, spacing)
    self._in  = IN.new()
    self._in.onCommand = function(_, cmd)
        return self:onCommand(cmd)
    end
    self._in.unfocus = function(_)
        return self:unfocus()
    end
    self._in.complete_add_parens = true
    self._in.complete_base = _G

    self.prompt1 = "> "
    self.prompt2 = "| "
    self._prompt = self.prompt1
    self.x = 0
    self.y = -1
    self.on_x = 0
    self.on_y = height - 1
    self.off_x = 0
    self.off_y = -1
    self.lerpVal = 0
    self.lerpSpeed = 4
    self.width = width
    self.height = height
    self.enabled = false

    self.commands = {}

    self.unfocus_callback = unfocus_cb or nil
    return self
end

function console:set_font(fontdata)
    self._out:set_font(fontdata)
end

function console:print(...)
    local n_args, s = select('#', ...), {...}
    for i = 1,n_args do
        s[i] = (s[i] == nil) and "nil" or tostring(s[i])
    end
    if n_args == 0 then s = {" "} end
    self._out:push(table.concat(s, "    "))
end

function console:error(...)
    self:print("Error: ", ...)
end

function console:print_intro(name, version)
    self:print(" "..name.." version "..version.." -- ".._VERSION)
    self:print()
    self:print(" <Escape> or ~ leaves the console. Call quit() or exit() to quit.")
    self:print(" Call help() for additional information.")
    self:print()
end


function console:clear()
    self._out:clear()
end

function console:onCommand(cmd)
    self._out:push(self._prompt, cmd)
    cmd = cmd:gsub("^=%s?", "return "):gsub("^return%s+(.*)(%s*)$", "print(%1)%2")
    self.chunk = self.chunk and table.concat({self.chunk, cmd}, " ") or cmd

    local tokens = split_str(self.chunk, "([^%s]+)")
    if #tokens > 0 and self.commands[tokens[1]] ~= nil then
        local params = {}
        for i, p in ipairs(tokens) do
            if i > 1 then
                table.insert(params, p)
            end
        end
        local cmdFuncTable = self.commands[tokens[1]]
        if type(cmdFuncTable) == "table" and #cmdFuncTable > 0 and type(cmdFuncTable[1]) == "function" then
            cmdFuncTable[1](unpack(params))
            self.chunk = nil
            return
        end
    end

    local ok, out = pcall(function() assert(loadstring(self.chunk))() end)
    if not ok and out:match("'<eof>'") then
        local tokens = split_str(cmd, "%p")
        if tokens ~= nil then
            local table = _G
            for i, t in ipairs(tokens) do
                if table[t] ~= nil then
                    table = table[t]
                else
                    break
                end
            end

            if type(table) ~= "table" then
                self:print(table)

                self._prompt = self.prompt1
                self._in.history[#self._in.history] = self.chunk
                self.chunk = nil

                return
            end
        end

        self._prompt = self.prompt2
        self._in.history[#self._in.history] = nil
    else
        self._prompt = self.prompt1
        if out and out:len() > 0 then
            self._out:push(out)
        end
        self._in.history[#self._in.history] = self.chunk
        self.chunk = nil
    end
end

function console:update(dt)
    if self.enabled then
        if self.lerpVal < 1 then
            self.lerpVal = self.lerpVal + self.lerpSpeed * dt
            if self.lerpVal > 1 then self.lerpVal = 1 end
        end
    else
        if self.lerpVal > 0 then
            self.lerpVal = self.lerpVal - self.lerpSpeed * dt
            if self.lerpVal < 0 then self.lerpVal = 0 end
        end
    end
    self.x = self.off_x + (self.on_x - self.off_x) * self.lerpVal
    self.y = self.off_y + (self.on_y - self.off_y) * self.lerpVal
end

function console:render()
    local inp = table.concat{self._prompt, self._in:current(), " "}
    local n = self._out:push(inp)
    self._out:draw(self.x, self.y, self._in:pos())
    self._out:pop(n)
end

local _current_focus
function console:focus()
    if _current_focus then
        _current_focus:unfocus()
    end
    love.keyboard.setKeyRepeat(0.5, 0.01)
    self._keypressed = love.keypressed
    self._textinput = love.textinput
    love.keypressed = function(...) self._in:keypressed(...) end
    love.textinput = function(...) self._in:textinput(...) end
    _current_focus = self

    self.enabled = true
end

function console:has_focus()
    return self.enabled
end

function console:unfocus()
    love.keyboard.setKeyRepeat()
    self.y = -1
    love.keypressed = self._keypressed
    love.textinput = self._textinput
    _current_focus = nil

    self.enabled = false

    if self.unfocus_callback then self.unfocus_callback() end
end

function console:keypressed(...)
    self._in:keypressed(...)
end

function console:textinput(...)
    self._in:textinput(...)
end
