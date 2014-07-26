local ArrayBuffer = {}
ArrayBuffer.__index = ArrayBuffer

local ffi = require 'ffi'

local gl = eiga.alias.gl()

local BUFFER_LENGTH = 1024 -- 256 vertices, 4-component vectors

local BUFFER_DATA_TYPE = {
  short  = gl.SHORT,
  ushort = gl.UNSIGNED_SHORT,
  int    = gl.INT,
  uint   = gl.UNSIGNED_INT,
  float  = gl.FLOAT,
  vec    = gl.FLOAT,
  mat    = gl.FLOAT,
}

local BUFFER_DATA_DIMENSION = {
  short  = 1,
  ushort = 1,
  int    = 1,
  uint   = 1,
  float  = 1,
  vec    = 1,
  mat    = 2,
}

local FFI_LENGTH_SIGNATURE = {
  [gl.SHORT]          = "GLshort[?]",
  [gl.UNSIGNED_SHORT] = "GLushort[?]",
  [gl.INT]            = "GLint[?]",
  [gl.UNSIGNED_INT]   = "GLuint[?]",
  [gl.FLOAT]          = "GLfloat[?]",
}

local TYPE_IDENTIFIER = {
  [gl.SHORT]          = "GLshort",
  [gl.UNSIGNED_SHORT] = "GLushort",
  [gl.INT]            = "GLint",
  [gl.UNSIGNED_INT]   = "GLuint",
  [gl.FLOAT]          = "GLfloat",
}

local function parse ( format )
  local component_type, component_count = format:match("([^%d%s]+)(%d*)")
  assert( component_type )
  return component_type, tonumber(component_count)
end

local function new ( format, name, size, usage )
  local component_type, component_count = parse( format )
  local attribute_location = nil
  assert( component_type )
  component_count = component_count or 1

  do
    local cc = 1
    for d=1,BUFFER_DATA_DIMENSION[component_type] do
      cc = cc * component_count
    end
    component_count = cc
  end
  -- if name ~= "texcoord" then
  --   assert( component_count == 4, string.format("For now, buffers need to be homogeneous: %d", component_count) )
  -- end

  usage = usage or gl.STATIC_DRAW

  local attribute_pointer_type = BUFFER_DATA_TYPE[ component_type ]
  local ffi_length_signature = FFI_LENGTH_SIGNATURE[ attribute_pointer_type ]
  local type_size = ffi.sizeof( TYPE_IDENTIFIER[ attribute_pointer_type ] )
  local buffer_size = size * type_size * component_count
  local buffer_id = ffi.new ( "GLuint[1]" )
  local attribute_string = name
  local component_count = component_count

  print(string.format('new ArrrayBuffer of type %s(%d), named %s', TYPE_IDENTIFIER[attribute_pointer_type], component_count, name ))

  gl.GenBuffers( 1, buffer_id  )
  gl.BindBuffer( gl.ARRAY_BUFFER, buffer_id[0] )
  gl.BufferData( gl.ARRAY_BUFFER, buffer_size , nil, usage )
  gl.BindBuffer( gl.ARRAY_BUFFER, 0 )

  local obj = {
    lua_data = {};
    c_data = {};
    divisor = 0;
    buffer_id = buffer_id;
    attribute_string = attribute_string;
    buffer_size = buffer_size;
    type_size = type_size;
    usage = usage;
    ffi_length_signature = ffi_length_signature;
    attribute_pointer_type = attribute_pointer_type;
    component_count = component_count;
  }

  return setmetatable( obj, ArrayBuffer )
end

function ArrayBuffer:release()
    if self.buffer_id ~= nil and self.buffer_id[0] ~= 0 then
        gl.DeleteBuffers(1, self.buffer_id)
    end
    self.buffer_id = nil
end

function ArrayBuffer:__gc()
    self:release()
end

function ArrayBuffer:setData( data )
  -- check if our buffer has enough room the incoming data
  if #data * self.type_size > self.buffer_size then
    print('ArrayBuffer::setData: data too long, re-creating buffer')
    -- compute new size of buffer
    self.buffer_size = #data * self.type_size
    gl.BindBuffer( gl.ARRAY_BUFFER, self.buffer_id[0] )
    -- set the buffer to a null pointer, essentially flagging it for gc
    gl.BufferData( gl.ARRAY_BUFFER, self.buffer_size , nil, self.usage )
    -- Map the buffer, and add memcopy data
    do
      ffi.copy(
        gl.MapBuffer( gl.ARRAY_BUFFER, gl.WRITE_ONLY ),
        ffi.new( self.ffi_length_signature, #data, data ),
        self.buffer_size)
      gl.UnmapBuffer( gl.ARRAY_BUFFER )
    end
    gl.BindBuffer( gl.ARRAY_BUFFER, 0 )
  else
    -- The incoming data will fit into our existing buffer.
    gl.BindBuffer( gl.ARRAY_BUFFER, self.buffer_id[0] )
    -- Map the buffer and memcopy
    ffi.copy(
      gl.MapBuffer( gl.ARRAY_BUFFER, gl.WRITE_ONLY ),
      ffi.new( self.ffi_length_signature, #data, data ),
      #data*self.type_size)
    gl.UnmapBuffer( gl.ARRAY_BUFFER )
    gl.BindBuffer( gl.ARRAY_BUFFER, 0 )
  end
end


function ArrayBuffer:enable( effect )
  gl.BindBuffer( gl.ARRAY_BUFFER, self.buffer_id[0] )
  if not self.attribute_location then
    self.attribute_location = gl.GetAttribLocation( effect.program, self.attribute_string )
  end
  gl.VertexAttribPointer( self.attribute_location, self.component_count, self.attribute_pointer_type, gl.FALSE, 0, nil )
  gl.EnableVertexAttribArray( self.attribute_location )
  gl.VertexAttribDivisor( self.attribute_location, self.divisor )
  gl.BindBuffer( gl.ARRAY_BUFFER, 0 )
end

return setmetatable(
  {
    new = new
  },
  {
    __call = function( _, ... ) return new( ... )  end
  }
)
