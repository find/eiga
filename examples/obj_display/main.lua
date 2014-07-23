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
_G.class = require 'middleclass'


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
local lines=function(str, size)
    local luastr = type(str)=='string' and str or ffi.string(str, size)
    return string.gmatch(luastr, '[^\r\n]+')
end
local map=function(f, list)
    local result = {}
    for i,v in ipairs(list) do
        result[i] = f(v)
    end
    return result
end

-- ref http://lua-users.org/wiki/SplitJoin
string.split=function(self, sSeparator, bRegexp)
    assert(sSeparator ~= '')
    local aRecord = {}
    if bRegexp == nil then bRegexp = true end
    local bPlain = not bRegexp
    if self:len() > 0 then
        local nField=1 nStart=1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        end
        aRecord[nField] = self:sub(nStart)
    end
    return aRecord
end

local Material = class('Material')
Material.initialize = function(self, mtlcontent, name)
    assert(mtlcontent and name)
    self.name          = name
    self.ambient       = {0,0,0}
    self.diffuse       = {1,1,1}
    self.specular      = {0,0,0}
    self.specularPower = 0
    self.transparency  = 1.0
    self.ambientMap    = nil
    self.diffuseMap    = nil
    self.specularMap   = nil
    self.highlightMap  = nil

    local nm = nil
    for line in lines(mtlcontent) do
        local newmtl = line:match('newmtl%s+(%w+)')
        if newmtl and nm==name then
            break -- entering new material section
        elseif newmtl then
            nm = newmtl
        end
        if nm == name then
            local cmd, val = line:match('(%g+)%s+(.+)')
            if cmd=='Ka' then
                self.ambient = map(tonumber, val:split('%s+'))
            elseif cmd=='Kd' then
                self.diffuse = map(tonumber, val:split('%s+'))
            elseif cmd=='Ks' then
                self.specular = map(tonumber, val:split('%s+'))
            elseif cmd=='Ns' then
                self.specularPower = tonumber(val)
            elseif cmd=='d' then
                self.transparency = tonumber(val)
            elseif cmd=='map_Kd' then
                self.diffuseMap = eiga.graphics.newTexture('assets/'..val, gl.LINEAR, gl.LINEAR)
            elseif cmd~='newmtl' then
                print('unknown property:', cmd)
            end
        end
    end
end

local mtllib = nil
local loadMtllib = function(path)
    local mtllib = {}
    local mtlsource = ffi.string(eiga.filesystem.read(path))
    for line in lines(mtlsource) do
        local mtl = line:match('newmtl%s+(%w+)')
        if mtl then
            mtllib[mtl] = Material(mtlsource, mtl)
        end
    end
    return mtllib
end

local MeshPart = class('MeshPart')
MeshPart.initialize = function(self)
    self.start    = 0
    self.length   = 0
    self.material = nil
end

local meshParts = {}
local currentPart = MeshPart()

print('loading model ...')
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
    elseif tp == 'mtllib' then
        if mtllib ~= nil then
            print('mtl lib already loaded')
        else
            print(string.format('loading mtllib "%s" ...', line:match('mtllib%s+(%g+)')))
            mtllib = loadMtllib(line:match('mtllib%s+(%g+)'))
        end
    elseif tp == 'usemtl' then
        currentPart.length = #data.index - currentPart.start
        if( currentPart.length > 0 ) then
            table.insert(meshParts, currentPart)
        end

        currentPart = MeshPart() -- start new material
        currentPart.material = mtllib[line:match('usemtl%s+(%g+)')]
        currentPart.start    = #data.index
    else
        -- pass
    end
end

currentPart.length = #data.index - currentPart.start
if currentPart.length > 0 then
    table.insert(meshParts, currentPart)
end

print('done.')
assert(#data.position == #data.normal, string.format('positions has %d elements, normal has %d elements', #data.position, #data.normal))
assert(#data.position/3 == #data.texcoord/2, string.format('texcoord has %d elements', #data.texcoord))


local mesh = eiga.graphics.newMesh( "vec3 position; vec3 normal; vec2 texcoord", #data.texcoord/2, #data.index )

print('mesh created')

local shader = eiga.graphics.newShader( "assets/effect.vert",
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
    -- m = mat4.scaling(vec3(1,1,2)) * m
    m:set(3,2, 2*m(3,2))
    return m
end


function eiga.load ( args )
  gl.Disable( gl.CULL_FACE )
  -- gl.FrontFace( gl.CW )
  gl.Enable( gl.TEXTURE_2D )
  gl.Enable( gl.BLEND )
  gl.BlendFunc( gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA )
  gl.Enable( gl.DEPTH_TEST )
  gl.DepthFunc( gl.LESS )

  mesh.buffers.position:setData( data.position )
  mesh.buffers.texcoord:setData( data.texcoord )
  mesh.buffers.normal:setData( data.normal )
  mesh.buffers.index:setData( data.index )

  -- free unused memory
  data.position = nil
  data.texcoord = nil
  data.normal   = nil
  print(string.format('%dKB in use', collectgarbage('count')))
  collectgarbage('collect')
  print(string.format('%dKB in use now', collectgarbage('count')))
  mesh:link( shader )

  -- shader:sendTexture( 0, "tex0")
  shader:sendMatrix4( toTable(world), "Model", true )
  shader:sendMatrix4( toTable(view), "View", true )
  shader:sendMatrix4( toTable(toGLProj(proj)), "Projection", true )
end

function eiga.update ( dt )
  shader:sendMatrix4( toTable(world*mat4.fromAxisAngle( vec3(0, 1, 0), eiga.timer.get_time() )) , "Model", true )
end

function eiga.draw ()
  if #meshParts>0 then
    for _,p in ipairs(meshParts) do
      local diffuse = p.material.diffuse
      local ambient = p.material.ambient
      shader:sendFloat4( {diffuse[1], diffuse[2], diffuse[3], p.material.transparency}, 'diffuse' )
      shader:sendFloat4( {ambient[1], ambient[2], ambient[3], 1}, 'ambient' )

      if p.material.diffuseMap~=nil then
        gl.ActiveTexture( gl.TEXTURE0 )
        gl.BindTexture( gl.TEXTURE_2D, p.material.diffuseMap )
        shader:sendTexture( 0, 'diffuseMap' )
        shader:sendBool( true, "hasDiffuseMap" )
      else
        shader:sendBool( false, "hasDiffuseMap" )
      end

      mesh:drawPart( p.start, p.length, shader )
    end
  else
    mesh:draw( #data.index, shader )
  end
end

function eiga.keypressed ( key )
  if key == glfw.KEY_ESC or key == glfw.KEY_Q then
    eiga.event.push("quit")
  end
end

function eiga.resized ( width, height )
  gl.Viewport( 0, 0, width, height )
  proj = mat4.perspectiveFovLH( fov, width/height, 0.5, 100 )
  shader:sendMatrix4( toTable(toGLProj(proj)), "Projection", true )
end
