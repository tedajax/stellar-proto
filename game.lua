local Vec2 = require 'vec2'
Tween = require 'tween'
require 'player'
require 'flag'
require 'npc'
require 'collision'
require 'tilemap'
require 'bullet'
require 'environment'
require 'level'
require 'trigger'

function create_game()
    local self = {}

    self.collision = create_collision()

    self.debug_collision = false

    self.init = function(self)
        self.trigger_manager = create_trigger_manager(100)
        self.npc_manager = create_npc_manager(100)
        self.bullet_manager = create_bullet_manager(100)

        self.player = create_player()
        self.player_controller = create_player_controller(self.player)
        self.player_controller:initialize()

        self.flag = create_flag()
        self.flag_controller = create_flag_controller(self.flag)

        self.noclip_controller = create_player_noclip_controller()

        Camera:set_target(self.player.position)

        self.level = create_level("assets/map1.json")

        local spawn_pos = self.level:get_spawn_position()
        self.player:set_position(spawn_pos)
        self.flag:set_position(spawn_pos)

        self.player_controller.bullet_manager = self.bullet_manager

        self.trigger_manager:add(1168, 1074, love.physics.newRectangleShape(0, 0, 92, 92), "cStaticEnvironment")

        for i = 1, 10 do
            -- self.npc_manager:add(math.random(-300, 300), math.random(-150, 150))
        end
    end

    self.update = function(self, dt)
        Log:debug("FPS: "..tostring(love.timer.getFPS()))
        self.collision:update(dt)
        self.player:update(dt)
        self.flag:update(dt)
        self.bullet_manager:update(dt)
        self.trigger_manager:update(dt)
        self.npc_manager:update(dt)
        self.level:update(dt)
        Tween.update(dt)
    end

    self.render = function(self)
        Camera:push()
        self.player:render()
        self.flag:render()
        self.bullet_manager:render()
        self.npc_manager:render()
        self.level:render()
        if self.debug_collision then
            self.collision:debug_render(false)
            self.trigger_manager:render()
        end
        Camera:pop()

        -- love.graphics.setColor(0, 255, 0)
        -- love.graphics.print(love.timer.getFPS(), 5, 5)
        -- love.graphics.print("Player Position: < "..tostring(self.player.position.x)..", "..tostring(self.player.position.y).." >", 5, 25)
    end

    self.noclip = function(self)
        if self.noclip_controller.actor == nil then
            self.player_controller:unposess()
            self.noclip_controller:posess(self.player)
        else
            self.noclip_controller:unposess()
            self.player_controller:posess(self.player)
        end
    end

    self.on_key_down = function(self, key)
        if key == "n" then
            self:noclip()
        elseif key == "[" then
            Camera:zoom_out(0.25)
        elseif key == "]" then
            Camera:zoom_in(0.25)
        end
    end

    self.on_key_up = function(self, key)
    end

    return self
end