local json = require 'json'
local Vec2 = require 'vec2'
Tween = require 'tween'
require 'player'
require 'npc'
require 'collision'
require 'tilemap'
require 'bullet'
require 'environment'
require 'level'

function create_game()
    local self = {}

    self.collision = create_collision()

    self.init = function(self)
        self.player = create_player()
        local controller = create_player_controller(self.player)
        controller:initialize()

        Camera:set_target(self.player.position)

        self.npc_manager = create_npc_manager(100)

        local levelObj = json.load("assets/map1.json")
        self.level = create_level(levelObj)

        local spawn_pos = self.level:get_spawn_position()
        self.player:set_position(spawn_pos)

        self.bullet_manager = create_bullet_manager(100)
        controller.bullet_manager = self.bullet_manager

        for i = 1, 10 do
            -- self.npc_manager:add(math.random(-300, 300), math.random(-150, 150))
        end
    end

    self.update = function(self, dt)
        self.collision:update(dt)
        self.player:update(dt)
        self.bullet_manager:update(dt)
        self.npc_manager:update(dt)
        self.level:update(dt)
        Tween.update(dt)
    end

    self.render = function(self)
        self.player:render()
        self.bullet_manager:render()
        self.npc_manager:render()
        self.level:render()

        self.collision:debug_render(false)
    end

    return self
end