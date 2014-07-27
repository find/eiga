local ffi = require 'ffi'

local gl = eiga.alias.gl()
local glfw = eiga.alias.glfw()
local soil = eiga.ffi.soil
local physfs = eiga.alias.physfs()

local Math = require 'math3dhelper'
_G.class = require 'middleclass'

local toTable = Math.toTable
local Camera = require 'camera'
local Box    = require 'box'

local fov = math.pi/3
local camera = Camera(vec3(0,2,1), vec3(0,0,0), vec3(0,1,0))
local box = nil
local transforms = {}
local uptime = 0 

eiga.load = function()
    gl.Disable(gl.CULL_FACE)
    gl.Disable(gl.BLEND)
    gl.Enable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LESS)
    box = Box()
    for x=1,10 do
        for y=1,10 do
            local i = (x-1)*10+(y-1)+1
            transforms[i] = mat4.translation(x*2-10, 0, y*2-10)
        end
    end
end


eiga.update = function(dt)
    uptime = uptime + dt
    local x,z = math.cos(uptime*0.5), math.sin(uptime*0.5)*2
    camera.eye.x = x*10
    camera.eye.z = z*10

    for i,v in ipairs(transforms) do
        transforms[i] = mat4.rotation(0.001*i, 0,1,1) * transforms[i]
    end
end

eiga.draw = function()
    box:drawInstanced(camera, transforms, {1,1,1,1})
end

eiga.keypressed = function( key )
  if key == glfw.KEY_ESC or key == glfw.KEY_Q then
    eiga.event.push("quit")
  end
end

eiga.resized = function( width, height )
  gl.Viewport( 0, 0, width, height )
  camera.aspect = width/height
end
