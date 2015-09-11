function create_capsule(world, radius, length, offset)
    local self = {}

    length = length or radius * 2
    offset = offset or { x = 0, y = 0 }

    self.radius = radius
    self.length = length

    self.body = love.physics.newBody(world, 0, 0, "dynamic")

    self.core_shape = love.physics.newRectangleShape(
        offset.x, offset.y,
        radius * 2 - 2, math.max(length, 1)
    )

    self.core_fixture = love.physics.newFixture(self.body, self.core_shape)

    self.head_shape = love.physics.newCircleShape(
        offset.x,
        offset.y - length / 2,
        radius
    )

    self.head_fixture = love.physics.newFixture(self.body, self.head_shape)

    self.feet_shape = love.physics.newCircleShape(
        offset.x,
        offset.y + length / 2,
        radius
    )

    self.feet_fixture = love.physics.newFixture(self.body, self.feet_shape)

    self.set_friction = function(self, friction)
        self.core_fixture:setFriction(friction)
        self.head_fixture:setFriction(friction)
        self.feet_fixture:setFriction(friction)
    end

    self.set_filter_data = function(self, filter)
        self.core_fixture:setFilterData(unpack(filter))
        self.head_fixture:setFilterData(unpack(filter))
        self.feet_fixture:setFilterData(unpack(filter))
    end

    return self
end