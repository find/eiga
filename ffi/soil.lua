local ffi = require 'ffi'
ffi.cdef [[
enum
{
	SOIL_LOAD_AUTO = 0,
	SOIL_LOAD_L = 1,
	SOIL_LOAD_LA = 2,
	SOIL_LOAD_RGB = 3,
	SOIL_LOAD_RGBA = 4
};

enum
{
	SOIL_CREATE_NEW_ID = 0
};

enum
{
	SOIL_FLAG_POWER_OF_TWO = 1,
	SOIL_FLAG_MIPMAPS = 2,
	SOIL_FLAG_TEXTURE_REPEATS = 4,
	SOIL_FLAG_MULTIPLY_ALPHA = 8,
	SOIL_FLAG_INVERT_Y = 16,
	SOIL_FLAG_COMPRESS_TO_DXT = 32,
	SOIL_FLAG_DDS_LOAD_DIRECT = 64,
	SOIL_FLAG_NTSC_SAFE_RGB = 128,
	SOIL_FLAG_CoCg_Y = 256,
	SOIL_FLAG_TEXTURE_RECTANGLE = 512,
	SOIL_FLAG_PVR_LOAD_DIRECT = 1024,
	SOIL_FLAG_ETC1_LOAD_DIRECT = 2048,
	SOIL_FLAG_GL_MIPMAPS = 4096
};

enum
{
	SOIL_SAVE_TYPE_TGA = 0,
	SOIL_SAVE_TYPE_BMP = 1,
	SOIL_SAVE_TYPE_PNG = 2,
	SOIL_SAVE_TYPE_DDS = 3
};

// #define SOIL_DDS_CUBEMAP_FACE_ORDER "EWUDNS"

enum
{
	SOIL_HDR_RGBE = 0,
	SOIL_HDR_RGBdivA = 1,
	SOIL_HDR_RGBdivA2 = 2
};

unsigned int
	SOIL_load_OGL_texture
	(
		const char *filename,
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_cubemap
	(
		const char *x_pos_file,
		const char *x_neg_file,
		const char *y_pos_file,
		const char *y_neg_file,
		const char *z_pos_file,
		const char *z_neg_file,
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_single_cubemap
	(
		const char *filename,
		const char face_order[6],
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_HDR_texture
	(
		const char *filename,
		int fake_HDR_format,
		int rescale_to_max,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_texture_from_memory
	(
		const unsigned char *const buffer,
		int buffer_length,
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_cubemap_from_memory
	(
		const unsigned char *const x_pos_buffer,
		int x_pos_buffer_length,
		const unsigned char *const x_neg_buffer,
		int x_neg_buffer_length,
		const unsigned char *const y_pos_buffer,
		int y_pos_buffer_length,
		const unsigned char *const y_neg_buffer,
		int y_neg_buffer_length,
		const unsigned char *const z_pos_buffer,
		int z_pos_buffer_length,
		const unsigned char *const z_neg_buffer,
		int z_neg_buffer_length,
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_load_OGL_single_cubemap_from_memory
	(
		const unsigned char *const buffer,
		int buffer_length,
		const char face_order[6],
		int force_channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_create_OGL_texture
	(
		const unsigned char *const data,
		int *width, int *height, int channels,
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

unsigned int
	SOIL_create_OGL_single_cubemap
	(
		const unsigned char *const data,
		int width, int height, int channels,
		const char face_order[6],
		unsigned int reuse_texture_ID,
		unsigned int flags
	);

int
	SOIL_save_screenshot
	(
		const char *filename,
		int image_type,
		int x, int y,
		int width, int height
	);

unsigned char*
	SOIL_load_image
	(
		const char *filename,
		int *width, int *height, int *channels,
		int force_channels
	);

unsigned char*
	SOIL_load_image_from_memory
	(
		const unsigned char *const buffer,
		int buffer_length,
		int *width, int *height, int *channels,
		int force_channels
	);

int
	SOIL_save_image
	(
		const char *filename,
		int image_type,
		int width, int height, int channels,
		const unsigned char *const data
	);

void
	SOIL_free_image_data
	(
		unsigned char *img_data
	);

const char*
	SOIL_last_result
	(
		void
	);

void *
	SOIL_GL_GetProcAddress
	(
		const char *proc
	);

int
	SOIL_GL_ExtensionSupported
	(
		const char *extension
	);

unsigned int SOIL_direct_load_DDS(
		const char *filename,
		unsigned int reuse_texture_ID,
		int flags,
		int loading_as_cubemap );

unsigned int SOIL_direct_load_DDS_from_memory(
		const unsigned char *const buffer,
		int buffer_length,
		unsigned int reuse_texture_ID,
		int flags,
		int loading_as_cubemap );

unsigned int SOIL_direct_load_PVR(
		const char *filename,
		unsigned int reuse_texture_ID,
		int flags,
		int loading_as_cubemap );

unsigned int SOIL_direct_load_PVR_from_memory(
		const unsigned char *const buffer,
		int buffer_length,
		unsigned int reuse_texture_ID,
		int flags,
		int loading_as_cubemap );

unsigned int SOIL_direct_load_ETC1(const char *filename,
		unsigned int reuse_texture_ID,
		int flags );

unsigned int SOIL_direct_load_ETC1_from_memory(const unsigned char *const buffer,
		int buffer_length,
		unsigned int reuse_texture_ID,
		int flags );
]]

local platform_path = string.format("bin/%s/%s/libsoil.%s", ffi.os, ffi.arch,
                                    jit.os == "OSX" and "dylib" or
                                    jit.os == "Windows" and "dll" or
                                    jit.os == "Linux" and "so")

return ffi.load( platform_path )
