pub const GL = struct {
    pub const COLOR_BUFFER_BIT: u32 = 0x00004000;
    pub const STENCIL_BUFFER_BIT: u32 = 0x00000400;
    pub const DEPTH_BUFFER_BIT: u32 = 0x00000100;
    pub const QUADS: u32 = 0x0007;
    pub const TEXTURE_2D: u32 = 0x0DE1;
    pub const RGBA: u32 = 0x1908;
    pub const UNSIGNED_BYTE: u32 = 0x1401;
    pub const TEXTURE_MIN_FILTER: u32 = 0x2801;
    pub const TEXTURE_MAG_FILTER: u32 = 0x2800;
    pub const TEXTURE_WRAP_S: u32 = 0x2802;
    pub const TEXTURE_WRAP_T: u32 = 0x2803;
    pub const CLAMP: u32 = 0x2900;
    pub const NEAREST: u32 = 0x2600;
};

pub const GLvoid = *const @OpaqueType();

pub extern "opengl32" fn glClearColor(r: f32, g: f32, b: f32, a: f32) void;
pub extern "opengl32" fn glClear(mask: u32) void;
pub extern "opengl32" fn glBegin(mask: u32) void;
pub extern "opengl32" fn glEnd() void;
pub extern "opengl32" fn glTexCoord2f(x: f32, y: f32) void;
pub extern "opengl32" fn glVertex2f(x: f32, y: f32) void;
pub extern "opengl32" fn glGenTextures(amount: u32, id: *u32) void;
pub extern "opengl32" fn glBindTexture(mask: u32, id: u32) void;
pub extern "opengl32" fn glEnable(mask: u32) void;
pub extern "opengl32" fn glTexParameteri(mask: u32, filter: u32, s: u32) void;
pub extern "opengl32" fn glTexImage2D(
    mask: u32,
    level: u32,
    internalFormat: i32,
    width: u32,
    height: u32,
    border: i32,
    format: i32,
    cType: i32,
    pixels: GLvoid,
) void;
pub extern "opengl32" fn glTexSubImage2D(mask: u32, level: u32, 
    offsetX: u32, offsetY: u32, width: u32, height: u32, format: i32,
        cType: i32, pixels: GLvoid) void;
