local m=require('math3d')
getmetatable(m.vec2()).__tostring=function(v) return string.format('(%f, %f)', v.x, v.y) end
getmetatable(m.vec3()).__tostring=function(v) return string.format('(%f, %f, %f)', v.x, v.y, v.z) end
getmetatable(m.vec4()).__tostring=function(v) return string.format('(%f, %f, %f, %f)', v.x, v.y, v.z, v.w) end
getmetatable(m.quat()).__tostring=function(v) return string.format('(%f, %f, %f, %f)', v.w, v.x, v.y, v.z) end
getmetatable(m.plane()).__tostring=function(p) return string.format('%f x + %f y + % f z + (%f) = 0', p.a, p.b, p.c, p.d) end
getmetatable(m.mat3()).__tostring=function(m) return string.format([[
    %f %f %f
    %f %f %f
    %f %f %f ]],
    m(0,0), m(0,1), m(0,2),
    m(1,0), m(1,1), m(1,2),
    m(2,0), m(2,1), m(2,2))
end
getmetatable(m.mat4()).__tostring=function(m) return string.format([[
    %f %f %f %f
    %f %f %f %f
    %f %f %f %f
    %f %f %f %f ]],
    m(0,0), m(0,1), m(0,2), m(0,3),
    m(1,0), m(1,1), m(1,2), m(1,3),
    m(2,0), m(2,1), m(2,2), m(2,3),
    m(3,0), m(3,1), m(3,2), m(3,3))
end

_G.vec2=m.vec2
_G.vec3=m.vec3
_G.vec4=m.vec4
_G.quat=m.quat
_G.plane=m.plane
_G.mat3=m.mat3
_G.mat4=m.mat4


local mat4_table = function(m)
    return{ m(0,0), m(0,1), m(0,2), m(0,3),
            m(1,0), m(1,1), m(1,2), m(1,3),
            m(2,0), m(2,1), m(2,2), m(2,3),
            m(3,0), m(3,1), m(3,2), m(3,3) }
end
local mat3_table = function(m)
    return{ m(0,0), m(0,1), m(0,2),
            m(1,0), m(1,1), m(1,2),
            m(2,0), m(2,1), m(2,2) }
end
local vec4_table = function(v)
    return{ v.x, v.y, v.z, v.w }
end
local vec3_table = function(v)
    return{ v.x, v.y, v.z }
end
local vec2_table = function(v)
    return{ v.x, v.y }
end

local toTable = function(x)
    if type(x)=='table' then
        return x
    end
    t = getmetatable(x)
    if type(x)=='userdata' and t then
        tp = t['.type']
        if tp == 'vec2' then
            return vec2_table(x)
        elseif tp == 'vec3' then
            return vec3_table(x)
        elseif tp == 'vec4' or tp == 'quat' then
            return vec4_table(x)
        elseif tp == 'mat3' then
            return mat3_table(x)
        elseif tp == 'mat4' then
            return mat4_table(x)
        end
    end
    error(string.format('unknown type (%s) of (%s)', type(x), x))
    return nil
end

local _T = {
    toTable = toTable
}
for i,v in pairs(m) do _T[i] = v end

return _T
