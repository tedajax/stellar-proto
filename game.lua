require 'player'
require 'npc'
require 'wall'
require 'collision'

function create_game()
    local self = {}

    self.collision = create_collision()

    self.init = function(self)
        self.player = create_player()
        self.npc_manager = create_npc_manager(100)
        self.wall_manager = create_wall_manager(100)

        for i = 1, 10 do
            self.npc_manager:add(math.random(-300, 300), math.random(-150, 150))
        end

        self.wall_manager:add(0, -320, 320, 32)
    end

    self.update = function(self, dt)
        self.collision:update(dt)
        self.player:update(dt)
        self.npc_manager:update(dt)
    end

    self.render = function(self)
        self.player:render()
        self.npc_manager:render()
        self.wall_manager:render()

        self.collision:debug_render()
    end

    return self
end