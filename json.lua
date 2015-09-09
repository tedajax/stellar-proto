local json = require 'dkjson'

local function load(filename)
    local str = love.filesystem.read(filename)
    return json.decode(str, 1, nil)
end

local function save(obj, filename)
    local str = json.encode(obj, { indent = true })
    love.filesystem.write(filename, str)
end

return {
    load = load,
    save = save
}