local json = require 'dkjson'

local function load(filename)
    local str = love.filesystem.read(filename)
    if str ~= nil then
        return json.decode(str, 1, nil)
    else
        return nil
    end
end

local function save(obj, filename)
    local str = json.encode(obj, { indent = true })
    love.filesystem.write(filename, str)
end

return {
    load = load,
    save = save
}