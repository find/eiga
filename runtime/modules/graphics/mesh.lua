local Mesh = {}
Mesh.__index = Mesh

local ffi = require 'ffi'

local gl = eiga.alias.gl()

local parseFormatString = function(format)
    local parts = {}
    for p in string.gmatch(format, '[^;]+') do
        if p==nil or p=='' then
            break
        end
        local type,name = p:match('%s*(%w+)%s+(%w+)')
        assert(type~=nil and name~=nil, string.format('bad format string "%s"', p))
        table.insert(parts, {type=type, name=name})
    end
    return parts
end

local function new ( format, vbSize, ibSize, mode, usage )
  print(string.format('new mesh of format "%s", vbSize=%d, ibSize=%d', format, vbSize, ibSize))
  mode = mode or gl.TRIANGLES
  usage = usage or gl.STATIC_DRAW
  
  local obj = {
    vertex_array = eiga.graphics.newVertexArray();
    buffers = {
      index = eiga.graphics.newIndexBuffer( ibSize, usage )
    };
    mode = mode
  }
  local elements = parseFormatString(format)
  for i,v in pairs(elements) do
    obj.buffers[v.name] = eiga.graphics.newArrayBuffer(v.type, v.name, vbSize, usage)
  end

  return setmetatable( obj, Mesh )
end

function Mesh:release()
  for _, b in pairs(self.buffers) do
    b:release()
  end
  self.buffers={}
  gl.DeleteVertexArrays(1, self.vertex_array)
  self.vertex_array=nil
end

function Mesh:__gc()
  self:release()
end

function Mesh:link( shader )
  gl.BindVertexArray( self.vertex_array[0] )
    for _, buffer in pairs( self.buffers ) do
      buffer:enable( shader )
    end
    self.buffers.index:enable()
  gl.BindVertexArray( 0 )
end

function Mesh:draw( count, shader )
  eiga.graphics.useShader( shader )
  gl.BindVertexArray( self.vertex_array[0] )
  gl.DrawElements( self.mode, count, self.buffers.index.gl_type, nil);
  gl.BindVertexArray( 0 )
  eiga.graphics.useShader()
end

function Mesh:drawPart( start, count, shader )
  eiga.graphics.useShader( shader )
  gl.BindVertexArray( self.vertex_array[0] )
  gl.DrawElements( self.mode, count, self.buffers.index.gl_type, ffi.cast('void*', self.buffers.index.type_size*start) );
  gl.BindVertexArray( 0 )
  eiga.graphics.useShader()
end

return setmetatable(
  {
    new = new
  },
  {
    __call = function( _, ... ) return new( ... )  end
  }
)
