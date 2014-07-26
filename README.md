# Eiga

Eiga is a small framework for writing cross-platform games, graphical demos, and interactive art.

The framework is built upon the insanely fast LuaJIT compiler and it's native FFI functionality.

## Examples

1. [VAO](https://github.com/find/eiga/tree/master/examples/vertex_array_object_cube_dx_matrix/)
2. [Obj Display](https://github.com/find/eiga/tree/master/examples/obj_display/)

  ![miku](https://raw.githubusercontent.com/find/eiga/master/examples/obj_display/miku.png)

3. [Instancing](https://github.com/find/eiga/tree/master/examples/cubes/)

  ![cubes](https://raw.githubusercontent.com/find/eiga/master/examples/cubes/instancing.png)

## Running the examples

Open a terminal/command-line and cd into eiga's top level director.

###Mac OS X

    ./bin/OSX/x64/luajit runtime/boot.lua examples/obj_display/

###Windows

__64 Bit__

    bin\Windows\x64\luajit.exe runtime\boot.lua examples\obj_display\

__32 Bit__

    bin\Windows\x86\luajit.exe runtime\boot.lua examples\obj_display\

###Linux

__64 Bit__

    ./bin/Linux/x64/luajit runtime/boot.lua examples/obj_display/
__32 Bit__

    ./bin/Linux/x86/luajit runtime/boot.lua examples/obj_display/

## Influences

Eiga's API is heavily influenced by that of [LÖVE](https://love2d.org/), another Lua-based framework.

## Current Status

This project is still very young, and many features still need to be implemented. Feedback, suggestions and bug reports are greatly appreciated.

## License

[MIT License](http://www.opensource.org/licenses/mit-license.html) where applicable. See the docs/legal/ folder.
