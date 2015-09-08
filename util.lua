local ORIGIN_NAMES = {
    topleft = { 0, 0 },
    topcenter = { 0.5, 0 },
    topright = { 1, 0 },
    centerleft = { 0, 0.5 },
    center = { 0.5, 0.5 },
    centerright = { 1, 0.5 },
    bottomleft = { 0, 1 },
    bottomcenter = { 0.5, 1 },
    bottomright = { 1, 1 },
}

function originNameValues(origin)
    local origin = origin or "center"
    local o = ORIGIN_NAMES[origin] or { 0.5, 0.5 }
    return o[1], o[2]
end

function math.sign(v)
    if v < 0 then
        return -1
    elseif v > 0 then
        return 1
    else
        return 0
    end
end

function math.lerp(a, b, t)
    return (b - a) * t + a
end