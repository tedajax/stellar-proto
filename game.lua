require 'player'
require 'npc'
require 'wall'
require 'collision'

function create_game()
    local self = {}

    self.collision = create_collision()

    self.init = function(self)
        self.player = create_player()
        create_player_controller(self.player)
        self.npc_manager = create_npc_manager(100)
        self.wall_manager = create_wall_manager(100)

        for i = 1, 10 do
            self.npc_manager:add(math.random(-300, 300), math.random(-150, 150))
        end

        local wall_width = 32

        self.wall_manager:add(0, -355, 1280, wall_width, 0)
        self.wall_manager:add(0, 355, 1280, wall_width, 0)
        self.wall_manager:add(-635, 0, 720, wall_width, 90)
        self.wall_manager:add(635, 0, 720, wall_width, 90)

        self.wall_manager:add(-400, 260, 200, wall_width, 90)
        self.wall_manager:add(400, 260, 200, wall_width, 90)

        self.wall_manager:add(225, 272, 400, wall_width, -30)
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

        self.collision:debug_render(false)
    end

    return self
end