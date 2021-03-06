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

local i = 0.25

local data = {
  position = {   i,  -i,   -i, 1, --back
                -i,  -i,   -i, 1,
                 i,   i,   -i, 1,
                -i,   i,   -i, 1,

                -i,  -i,   i,  1, --front
                 i,  -i,   i,  1,
                -i,   i,   i,  1,
                 i,   i,   i,  1,

                -i,  -i,  -i,  1, --left
                -i,  -i,   i,  1,
                -i,   i,  -i,  1,
                -i,   i,   i,  1,

                 i,  -i,   i,  1, --right
                 i,  -i,  -i,  1,
                 i,   i,   i,  1,
                 i,   i,  -i,  1,

                -i,  -i,  -i,  1, --bottom
                 i,  -i,  -i,  1,
                -i,  -i,   i,  1,
                 i,  -i,   i,  1,

                -i,   i,   i,  1, --top
                 i,   i,   i,  1,
                -i,   i,  -i,  1,
                 i,   i,  -i,  1 };
  texcoord = { 0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0 };
--[[  index = { 0, 1, 3, 0, 3, 2,
            4, 5, 7, 4, 7, 6,
            8, 9, 11, 8, 11, 10,
            12, 13, 15, 12, 15, 14,
            16, 17, 19, 16, 19, 18,
            20, 21, 23, 20, 23, 22 }; --]]
  index = { 0,1,2,3,
            4,5,6,7,
            8,9,10,11,
            12,13,14,15,
            16,17,18,19,
            20,21,22,23 }
}

local mesh = eiga.graphics.newMesh( "vec4 position;vec2 texcoord", #data.texcoord/2, #data.index, gl.QUAD_STRIP )

local shader = eiga.graphics.newShader( "assets/effect.vert",
                                        "assets/effect.frag" );

local world = mat4.scaling ( vec3(2.0, 2.0, 2.0) )
local view = mat4.lookAtLH( vec3( 0, 0, -3 ),
                            vec3( 0, 0, 0 ),
                            vec3( 0, 1, 0 ) )
local fov = 3.14159265358979*60.0/180.0
local proj = mat4.perspectiveFovLH( fov, 1, 0.5, 100 )

view:set(0,0, -view(0,0)) -- flip x axis
local toGLProj = function(m)
    m = mat4(m)
    m:set(3,2, 2*m(3,2))
    return m
end
local toTable = Math.toTable


function eiga.load ( args )
  gl.Enable( gl.CULL_FACE )
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
  mesh.buffers.index:setData( data.index )
  mesh:link( shader )

  shader:sendTexture( 0, "tex0")
  shader:sendMatrix4( toTable(world:transposed()), "Model" )
  shader:sendMatrix4( toTable(view:transposed()), "View" )
  shader:sendMatrix4( toTable(toGLProj(proj):transposed()), "Projection" )
end

function eiga.update ( dt )
  shader:sendMatrix4( toTable((world*mat4.fromAxisAngle( vec3(0.3, 1, 0), eiga.timer.get_time() )):transposed()) , "Model" )
end

function eiga.draw ()
  mesh:draw( #data.index, shader )
end

function eiga.keypressed ( key )
  if key == glfw.KEY_ESC or key == glfw.KEY_Q then
    eiga.event.push("quit")
  end
end

function eiga.resized ( width, height )
  gl.Viewport( 0, 0, width, height )
  proj = mat4.perspectiveFovLH( fov, width/height, 0.5, 100 )
  shader:sendMatrix4( toTable(toGLProj(proj):transposed()), "Projection" )
end
