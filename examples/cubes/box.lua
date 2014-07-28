local gl = eiga.alias.gl()
local Math = require 'math3dhelper'
local toTable = Math.toTable

local i=0.5
local geomData = {
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

  normal = {
      0,0,-1,
      0,0,-1,
      0,0,-1,
      0,0,-1,

      0,0,1,
      0,0,1,
      0,0,1,
      0,0,1,

      -1,0,0,
      -1,0,0,
      -1,0,0,
      -1,0,0,

      1,0,0,
      1,0,0,
      1,0,0,
      1,0,0,

      0,-1,0,
      0,-1,0,
      0,-1,0,
      0,-1,0,

      0,1,0,
      0,1,0,
      0,1,0,
      0,1,0,
  };

  texcoord = { 0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0,
               0, 1, 1, 1, 0, 0, 1, 0 };

  index = { 0, 1, 3, 0, 3, 2,
            4, 5, 7, 4, 7, 6,
            8, 9, 11, 8, 11, 10,
            12, 13, 15, 12, 15, 14,
            16, 17, 19, 16, 19, 18,
            20, 21, 23, 20, 23, 22 }; 

--[[  index = { 0,1,2,3,
            4,5,6,7,
            8,9,10,11,
            12,13,14,15,
            16,17,18,19,
            20,21,22,23 } --]]
}

local flatten = function(tb, receiver)
    local result = receiver or {}
    for _,item in pairs(tb) do
        if type(item) == 'table' then
            flatten(item, result)
        elseif type(item) == 'userdata' then
            for _, sub in pairs(toTable(item)) do
                table.insert(result, sub)
            end
        else
            table.insert(result, item)
        end
    end
    return result
end

local map = function(f, tb)
    local result = {}
    for i,v in pairs(tb) do
        result[i] = f(v)
    end
    return result
end

local foldl = function(f, first, tb)
    if tb==nil or type(tb)~='table' or #tb<1 then
        return nil
    end
    local x = f(first, tb[1])
    for i=2,#tb do
        x = f(x, tb[i])
    end
    return x
end

local Box = class('Box')
Box.initialize = function(self)
    self.mesh  = eiga.graphics.newMesh('vec4 position; vec3 normal', #geomData.position/4, #geomData.index, gl.TRIANGLES)
    self.mesh.buffers.position:setData(geomData.position)
    self.mesh.buffers.normal:setData(geomData.normal)
    self.mesh.buffers.index:setData(geomData.index)

    self.instanceVB = eiga.graphics.newArrayBuffer('mat4', 'world', 100, gl.DYNAMIC_DRAW)
    self.instanceVB.divisor = 1
    self.standardShader   = eiga.graphics.newShader('assets/standard.vert',   'assets/diffuse-fakelighting.frag')
    self.instancingShader = eiga.graphics.newShader('assets/instancing.vert', 'assets/diffuse-fakelighting.frag')
    self.instanceData = {}

    self.mesh:link( self.standardShader )
    self.mesh:linkInstances( self.instancingShader, self.instanceVB )
end

Box.draw = function(self, camera, transform, diffuse)
    self.standardShader:sendMatrix4(toTable(camera:view()), 'view', true)
    self.standardShader:sendMatrix4(toTable(camera:proj()), 'proj', true)
    self.standardShader:sendMatrix4(toTable(transform),     'world', true)
    self.standardShader:sendFloat4 (toTable(diffuse),       'diffuse')
    self.mesh:draw(#geomData.index, self.standardShader)
end

Box.drawInstanced = function(self, camera, transformlist, diffuse)
    if false then
        for _,t in ipairs(transformlist) do
            self:draw(camera, t, diffuse)
        end
    else
        self.instanceData = {}
        self.instanceData = flatten(map(function(m) return m:transposed() end, transformlist), self.instanceData)
        self.instanceVB:setData(self.instanceData)
        local numInstances = #transformlist

        self.instancingShader:sendMatrix4(toTable(camera:view()), 'view', true)
        self.instancingShader:sendMatrix4(toTable(camera:proj()), 'proj', true)
        self.instancingShader:sendFloat4 (toTable(diffuse),       'diffuse')

        self.mesh:drawInstanced(#geomData.index, numInstances, self.instancingShader)
    end
end

return Box

