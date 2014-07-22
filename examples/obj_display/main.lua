-- Copyright (C) 2012 Nicholas Carlson
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local ffi = require 'ffi'

local gl = eiga.alias.gl()
local glfw = eiga.alias.glfw()
local soil = eiga.ffi.soil
local physfs = eiga.alias.physfs()

local Math = require 'math3dhelper'

local data = {
    position = {},
    normal   = {},
    texcoord = {},
    index    = {}
}
local insertEach = function(t, ...)
    for _,v in ipairs({...}) do
        table.insert(t, v)
    end
end

local lines=function(str)
    local luastr = ffi.string(str)
    return string.gmatch(luastr, '[^\r\n]+')
end
for line in lines(eiga.filesystem.read('assets/Miku_Hatsune_Ver2.obj')) do
    local tp=line:match('(%w+)')
    if tp == 'v' then
        local x,y,z = line:match('%w+%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)')
        insertEach(data.position, tonumber(x), tonumber(y), tonumber(z))
    elseif tp == 'vn' then
        local x,y,z = line:match('%w+%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)')
        insertEach(data.normal, tonumber(x), tonumber(y), tonumber(z))
    elseif tp == 'vt' then
        local x,y = line:match('%w+%s+([^%s]+)%s+([^%s]+)')
        insertEach(data.texcoord, tonumber(x), tonumber(y))
    elseif tp == 'f' then
        local x,y,z = line:match('%w+%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)')
        for _, f in ipairs({x,y,z}) do
            local i1, i2, i3 = f:match('(%d+)/(%d+)/(%d+)')
            assert(i1==i2 and i1==i3)
            table.insert(data.index, tonumber(i1)-1)
        end
    else
        -- pass
    end
end
assert(#data.position == #data.normal, string.format('positions has %d elements, normal has %d elements', #data.position, #data.normal))
assert(#data.position/3 == #data.texcoord/2, string.format('texcoord has %d elements', #data.texcoord))


local mesh = eiga.graphics.newMesh( "vec3 position; vec3 normal; vec2 texcoord", #data.texcoord/2, #data.index )

local effect = eiga.graphics.newEffect( "assets/effect.vert",
                                        "assets/effect.frag" );

local world = mat4.identity()
local view = mat4.lookAtLH( vec3( 0, 12, -25 ),
                            vec3( 0, 8, 0 ),
                            vec3( 0, 1, 0 ) )
local fov = 3.14159265358979*60.0/180.0
local proj = mat4.perspectiveFovLH( fov, 1, 0.5, 100 )

view:set(0,0, -view(0,0)) -- flip x axis

local toTable = Math.toTable

local toGLProj = function(m)
    m = mat4(m)
    m:set(3,2, 2*m(3,2))
    return m
end

function eiga.load ( args )
  gl.Enable( gl.CULL_FACE )
  -- gl.FrontFace( gl.CW )
  gl.Enable( gl.TEXTURE_2D )
  gl.Enable( gl.BLEND )
  gl.BlendFunc( gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA )
  gl.Enable( gl.DEPTH_TEST )
  gl.DepthFunc( gl.LESS )

  gl.ActiveTexture( gl.TEXTURE0 )
  stone_texture = eiga.graphics.newTexture( "assets/stone.png", gl.NEAREST, gl.NEAREST )
  gl.BindTexture( gl.TEXTURE_2D, stone_texture )

  mesh.buffers.position:setData( data.position )
  mesh.buffers.texcoord:setData( data.texcoord )
  mesh.buffers.normal:setData( data.normal )
  mesh.buffers.index:setData( data.index )
  mesh:link( effect )

  -- effect:sendTexture( 0, "tex0")
  effect:sendMatrix4( toTable(world:transposed()), "Model" )
  effect:sendMatrix4( toTable(view:transposed()), "View" )
  effect:sendMatrix4( toTable(toGLProj(proj):transposed()), "Projection" )
end

function eiga.update ( dt )
  effect:sendMatrix4( toTable((world*mat4.fromAxisAngle( vec3(0, 1, 0), eiga.timer.get_time() )):transposed()) , "Model" )
end

function eiga.draw ()
  mesh:draw( #data.index, effect )
end

function eiga.keypressed ( key )
  if key == glfw.KEY_ESC or key == glfw.KEY_Q then
    eiga.event.push("quit")
  end
end

function eiga.resized ( width, height )
  gl.Viewport( 0, 0, width, height )
  proj = mat4.perspectiveFovLH( fov, width/height, 0.5, 100 )
  effect:sendMatrix4( toTable(toGLProj(proj):transposed()), "Projection" )
end
