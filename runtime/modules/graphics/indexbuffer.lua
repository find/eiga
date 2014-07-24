local IndexBuffer = {}
IndexBuffer.__index = IndexBuffer

local ffi = require 'ffi'

local gl = eiga.alias.gl()

local function new ( size, usage )
  local tp = size>=0xffff and 'GLuint' or 'GLushort'
  print(string.format('using %s as index buffer', tp))
  local ffi_length_signature = string.format("%s[?]", tp)
  local type_size = ffi.sizeof( tp )
  local buffer_size = type_size * size
  local buffer_id = ffi.new ( "GLuint[1]" )

  usage = usage or gl.STATIC_DRAW

  gl.GenBuffers( 1, buffer_id  )
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, buffer_id[0] )
  gl.BufferData( gl.ELEMENT_ARRAY_BUFFER, buffer_size, nil, usage )
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, 0 )

  local obj = {
    buffer_id   = buffer_id;
    buffer_size = buffer_size;
    type_size   = type_size;
    gl_type     = tp == 'GLushort' and gl.UNSIGNED_SHORT or gl.UNSIGNED_INT;
    usage       = usage;
    ffi_length_signature = ffi_length_signature;
  }

  return setmetatable( obj, IndexBuffer )
end

function IndexBuffer:release()
    if self.buffer_id ~= nil and self.buffer_id[0] ~= 0 then
        gl.DeleteBuffers(1, self.buffer_id)
    end
    self.buffer_id = nil
end

function IndexBuffer:__gc()
    self:release()
end

function IndexBuffer:setData( data )
  assert(self.buffer_size >= #data*self.type_size)
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, self.buffer_id[0] )
  ffi.copy(
    gl.MapBuffer( gl.ELEMENT_ARRAY_BUFFER, gl.WRITE_ONLY ),
    ffi.new( self.ffi_length_signature, #data, data ),
    self.type_size * #data )
  gl.UnmapBuffer( gl.ELEMENT_ARRAY_BUFFER )
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, 0 )
end


function IndexBuffer:enable( )
  gl.BindBuffer( gl.ELEMENT_ARRAY_BUFFER, self.buffer_id[0] )
end

return setmetatable(
  {
    new = new
  },
  {
    __call = function( _, ... ) return new( ... )  end
  }
)
