local json = require 'json'
require 'environment'

function create_tile_layer(levelProps, layerProps)
    local self = {}

    assert(layerProps.type == "tilelayer")

    self.name = layerProps.name
    self.type = layerProps.type
    self.visible = layerProps.visible
    self.simulate = true

    local tilemap_properties = {
        data = layerProps.data,
        width = layerProps.width,
        height = layerProps.height,
        tile_width = levelProps.tilewidth,
        tile_height = levelProps.tileheight,
        root_dir = levelProps.root_dir,
    }

    self.wall_manager = create_wall_manager(layerProps.width * layerProps.height)

    self.tilemap = create_tilemap(tilemap_properties, levelProps.tilesets[1])
    self.tilemap:recalculate(self.wall_manager)

    self.update = function(self, dt)
        self.wall_manager:update(dt)
    end

    self.render = function()
        self.tilemap:render()
    end

    return self
end

function create_control(x, y, name, type, props)
    return {
        position = Vec2(x, y),
        name = name,
        type = type,
        properties = props
    }
end

function create_object_group_layer(levelProps, layerProps)
    local self = {}

    assert(layerProps.type == "objectgroup")

    self.name = layerProps.name
    self.type = layerProps.type
    self.visible = layerProps.visible
    self.simulate = true

    self.platform_manager = create_platform_manager(#layerProps.objects)
    self.controls = {}

    for i, v in ipairs(layerProps.objects) do
        if v.type == "platform" then
            local controller = parse_platform_controller(v.properties)
            local x = v.x + v.width / 2
            local y = v.y + v.height / 2
            self.platform_manager:add(x, y, v.width, v.height, v.rotation, controller)
        elseif v.type == "control" then
            table.insert(self.controls, create_control(v.x, v.y, v.name, v.properties.control_type, v.properties))
        else
            assert(false, "Unknown type for object.")
        end
    end

    self.update = function(self, dt)
        self.platform_manager:update(dt)
    end

    self.render = function()
        self.platform_manager:render()
    end

    return self
end

LAYER_TYPE_FUNCTIONS = {
    tilelayer = create_tile_layer,
    objectgroup = create_object_group_layer,
}

function create_level(filename)
    local self = {}

    self.properties = json.load(filename)
    assert(self.properties, "Unable to load level file: "..filename)

    self.filename = filename
    self.properties.root_dir = self.filename:match("(.*/)(.*)")

    self.layers = {}

    for _, layer in ipairs(self.properties.layers) do
        table.insert(self.layers, (LAYER_TYPE_FUNCTIONS[layer.type](self.properties, layer)))
    end

    self.get_spawn_position = function(self)
        for _, layer in ipairs(self.layers) do
            Console:print(layer.type)
            if layer.type == "objectgroup" then
                for _, control in ipairs(layer.controls) do
                    Console:print(control.type)
                    if control.type == "spawn_point" then
                        return control.position
                    end
                end
            end
        end
        return Vec2(0, 0)
    end

    self.update = function(self, dt)
        for i, layer in ipairs(self.layers) do
            if layer.simulate then
                layer:update(dt)
            end
        end
    end

    self.render = function(self)
        for i, layer in ipairs(self.layers) do
            if layer.visible then
                layer:render()
            end
        end
    end

    return self
end