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

local function new ( format, vbSize, ibSize )
  print(string.format('new mesh of format "%s", vbSize=%d, ibSize=%d', format, vbSize, ibSize))
  
  local obj = {
    vertex_array = eiga.graphics.newVertexArray();
    buffers = {
      index = eiga.graphics.newIndexBuffer( ibSize )
    }
  }
  local elements = parseFormatString(format)
  for i,v in pairs(elements) do
    obj.buffers[v.name] = eiga.graphics.newArrayBuffer(v.type, v.name, vbSize)
  end

  return setmetatable( obj, Mesh )
end

function Mesh:link( effect )
  gl.BindVertexArray( self.vertex_array[0] )
    for _, buffer in pairs( self.buffers ) do
      buffer:enable( effect )
    end
    self.buffers.index:enable()
  gl.BindVertexArray( 0 )
end

function Mesh:draw( count, effect )
  eiga.graphics.useEffect( effect )
  gl.BindVertexArray( self.vertex_array[0] )
  gl.DrawElements( gl.TRIANGLES, count, self.buffers.index.gl_type, nil);
  gl.BindVertexArray( 0 )
  eiga.graphics.useEffect()
end

return setmetatable(
  {
    new = new
  },
  {
    __call = function( _, ... ) return new( ... )  end
  }
)
