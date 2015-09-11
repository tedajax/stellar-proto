local assert = assert
local sqrt, cos, sin = math.sqrt, math.cos, math.sin

local vec2 = {}
vec2.__index = vec2

local function new(x,y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

local function isvec2(v)
    return getmetatable(v) == vec2
end

function vec2:clone()
    return new(self.x, self.y)
end

function vec2:unpack()
    return self.x, self.y
end

function vec2:__tostring()
    return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vec2.__unm(a)
    return new(-a.x, -a.y)
end

function vec2.__add(a,b)
    assert(
        isvec2(a) and isvec2(b),
        "Add: wrong argument types (<vec2> expected)"
    )
    return new(a.x+b.x, a.y+b.y)
end

function vec2.__sub(a,b)
    assert(
        isvec2(a) and isvec2(b),
        "Sub: wrong argument types (<vec2> expected)"
    )
    return new(a.x-b.x, a.y-b.y)
end

function vec2.__mul(a,b)
    if type(a) == "number" then
        return new(a*b.x, a*b.y)
    elseif type(b) == "number" then
        return new(b*a.x, b*a.y)
    else
        assert(
            isvec2(a) and isvec2(b),
            "Mul: wrong argument types (<vec2> or <number> expected)"
        )
        return a.x*b.x + a.y*b.y
    end
end

function vec2.__div(a,b)
    assert(
        isvec2(a) and type(b) == "number",
        "wrong argument types (expected <vec2> / <number>)"
    )
    return new(a.x / b, a.y / b)
end

function vec2.__eq(a,b)
    return a.x == b.x and a.y == b.y
end

function vec2.__lt(a,b)
    return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vec2.__le(a,b)
    return a.x <= b.x and a.y <= b.y
end

function vec2.permul(a,b)
    assert(
        isvec2(a) and isvec2(b),
        "permul: wrong argument types (<vec2> expected)"
    )
    return new(a.x*b.x, a.y*b.y)
end

function vec2:lensqr()
    return self.x * self.x + self.y * self.y
end

function vec2:len()
    return sqrt(self.x * self.x + self.y * self.y)
end

function vec2:magnitude()
    return self:len()
end

local function dist(a, b)
    assert(
        isvec2(a) and isvec2(b),
        "dist: wrong argument types (<vec2> expected)"
    )
    local dx = a.x - b.x
    local dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
end

local function distsq(a, b)
    assert(
        isvec2(a) and isvec2(b),
        "distsq: wrong argumen types (<vec2> expected)"
    )
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end

local function lerp(a, b, t)
    assert(
        isvec2(a) and isvec2(b),
        "lerp: wrong argument types (<vec2> expected)"
    )
    local lx = a.x + (b.x - a.x) * t
    local ly = a.y + (b.y - a.y) * t
    return new(lx, ly)
end

function vec2:clamp(min, max)
    assert(
        isvec2(min) and isvec2(max),
        "clamp: wrong argument types (<vec2> expected)"
    )
    if self.x < min.x then self.x = min.x end
    if self.x > max.x then self.x = max.x end
    if self.y < min.y then self.y = min.y end
    if self.y > max.y then self.y = max.y end

    return self
end

function vec2:normalize()
    local l = self:len()
    if l > 0 then
        self.x, self.y = self.x / l, self.y / l
    end
    return self
end

function vec2:normalized()
    return self:clone():normalize()
end

function vec2:rotate(phi)
    local c, s = cos(phi), sin(phi)
    self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
    return self
end

function vec2:rotated(phi)
    local c, s = cos(phi), sin(phi)
    return new(c * self.x - s * self.y, s * self.x + c * self.y)
end

function vec2:perpendicular()
    return new(-self.y, self.x)
end

function vec2:angle(v)
    assert(isvec2(v), "angle: wrong argument types (<vec2> expected)")
    local d = self:dot(v)
    local A = self:len()
    local B = v:len()
    return math.deg(math.acos(d / (A * B)))
end

function vec2:project_on(v)
    assert(isvec2(v), "invalid argument: cannot project vec2 on " .. type(v))
    -- (self * v) * v / v:len2()
    local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
    return new(s * v.x, s * v.y)
end

function vec2:mirror_on(v)
    assert(isvec2(v), "invalid argument: cannot mirror vec2 on " .. type(v))
    -- 2 * self:projectOn(v) - self
    local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
    return new(s * v.x - self.x, s * v.y - self.y)
end

function vec2:cross(v)
    assert(isvec2(v), "cross: wrong argument types (<vec2> expected)")
    return self.x * v.y - self.y * v.x
end

function vec2:dot(v)
    assert(isvec2(v), "dot: wrong argument types (<vec2> expected)")
    return self.x * v.x + self.y * v.y
end

function vec2:set(x, y)
    self.x = x
    self.y = y
end

local function new_zero() return new(0, 0) end
local function new_unitx() return new(1, 0) end
local function new_unity() return new(0, 1) end
local function new_one() return new(1, 1) end

-- the module
return setmetatable({
                        new = new,
                        isvec2 = isvec2,
                        dist = dist,
                        lerp = lerp,
                        one = new_one,
                        zero = new_zero,
                        unit_x = new_unitx,
                        unit_y = new_unity
                    },
                    { __call = function(_, ...) return new(...) end })