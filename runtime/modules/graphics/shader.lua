local Shader = {}
Shader.__index = Shader

local ffi = require 'ffi'

local gl = eiga.alias.gl()

local function checkProgram (program)
  if not program then return false end
  local result = ffi.new("GLint[1]", gl.FALSE)
  gl.GetProgramiv(program, gl.LINK_STATUS, result)
  local infologlength = ffi.new("int[1]")
  gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, infologlength)
  local infolog = ffi.new("char[?]", infologlength[0])
  gl.GetProgramInfoLog(program, infologlength[0], nil, infolog)
  if result[0] ~= gl.TRUE then
    error(string.format("Link error %s:", ffi.string(infolog)))
  end
end

local function checkShader (shader)
  if not shader then return false end
  local result = ffi.new("GLint[1]", gl.FALSE)
  gl.GetShaderiv(shader, gl.COMPILE_STATUS, result)
  local infologlength = ffi.new("int[1]")
  gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, infologlength)
  local infolog = ffi.new("char[?]", infologlength[0])
  gl.GetShaderInfoLog(shader, infologlength[0], nil, infolog)
  if result[0] ~= gl.TRUE then
    error(string.format("Compile error %s:", ffi.string(infolog)))
  end
end

local function compile(type, source)
  local shader = gl.CreateShader(type)
  local cptr_source = ffi.new("const char*[1]", source)
  gl.ShaderSource(shader, 1, cptr_source, nil )
  gl.CompileShader(shader)
  checkShader(shader)
  return shader
end

local function new ( vs_src, fs_src )
  local obj = {
    source = {
      vs = vs_src;
      fs = fs_src;
    };
    shader = {
      vs = compile( gl.VERTEX_SHADER, vs_src );
      fs = compile( gl.FRAGMENT_SHADER, fs_src );
    };
    program = gl.CreateProgram();
    l_cache = {};
    c_cache = {};
    gl_cache = {};
  }

  gl.AttachShader( obj.program, obj.shader.vs )
  gl.AttachShader( obj.program, obj.shader.fs )
  gl.LinkProgram( obj.program )

  return setmetatable( obj, Shader )
end

function Shader:__gc()
  print('shader released')
  if self.shader.vs~=nil and self.shader.vs~=0 then
      gl.DeleteShader( self.shader.vs )
  end
  if self.shader.ps~=nil and self.shader.ps~=0 then
      gl.DeleteShader( self.shader.ps )
  end
  if self.program ~= nil and self.program ~= 0 then
      gl.DeleteProgram( self.program )
  end
end

function Shader:sendMatrix4 ( matrix, name, transposed )
  transposed = transposed or gl.FALSE
  eiga.graphics.useShader( self )
  if matrix ~= self.l_cache[name] then
    self.l_cache[name] = matrix
    self.c_cache[name] = ffi.new( "GLfloat[?]", 16, matrix )
    self.gl_cache[name] = gl.GetUniformLocation(self.program, name)
    assert( self.gl_cache[name] ~= -1, name )
  end

  gl.UniformMatrix4fv( self.gl_cache[name], 1, transposed, self.c_cache[name] )
  eiga.graphics.useShader()
end

function Shader:sendFloat4 ( val, name )
  eiga.graphics.useShader( self )
  if val ~= self.l_cache[name] then
    self.l_cache[name] = val
    self.c_cache[name] = ffi.new( "GLfloat[?]", 4, val )
    self.gl_cache[name] = gl.GetUniformLocation(self.program, name)
    assert( self.gl_cache[name] ~= -1, name )
  end

  gl.Uniform4fv( self.gl_cache[name], 1, self.c_cache[name] )
  eiga.graphics.useShader()
end

function Shader:sendBool ( val, name )
  eiga.graphics.useShader( self )
  if val ~= self.l_cache[name] then
    self.l_cache[name] = val
    self.c_cache[name] = ffi.cast( "GLboolean", val )
    self.gl_cache[name] = gl.GetUniformLocation(self.program, name)
    assert( self.gl_cache[name] ~= -1, name )
  end

  gl.Uniform1i( self.gl_cache[name], self.c_cache[name] )
  eiga.graphics.useShader()
end

function Shader:sendTexture ( texture, name )
  eiga.graphics.useShader( self )
  if not self.l_cache[name] then
    self.l_cache[name] = texture
    self.gl_cache[name] = gl.GetUniformLocation(self.program, name)
    assert( self.gl_cache[name] ~= -1, name )
  end

  gl.Uniform1i( self.gl_cache[name], texture )
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

