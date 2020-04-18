const windows = @import("std").os.windows;
usingnamespace @import("./win32.zig");

pub const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: windows.WORD = @sizeOf(PIXELFORMATDESCRIPTOR),
    nVersion: windows.WORD = 1,
    dwFlags: windows.DWORD = 0,
    iPixelType: windows.BYTE = 0,
    cColorBits: windows.BYTE = 0,
    cRedBits: windows.BYTE = 0,
    cRedShift: windows.BYTE = 0,
    cGreenBits: windows.BYTE = 0,
    cGreenShift: windows.BYTE = 0,
    cBlueBits: windows.BYTE = 0,
    cBlueShift: windows.BYTE = 0,
    cAlphaBits: windows.BYTE = 0,
    cAlphaShift: windows.BYTE = 0,
    cAccumBits: windows.BYTE = 0,
    cAccumRedBits: windows.BYTE = 0,
    cAccumGreenBits: windows.BYTE = 0,
    cAccumBlueBits: windows.BYTE = 0,
    cAccumAlphaBits: windows.BYTE = 0,
    cDepthBits: windows.BYTE = 0,
    cStencilBits: windows.BYTE = 0,
    cAuxBuffers: windows.BYTE = 0,
    iLayerType: windows.BYTE = 0,
    bReserved: windows.BYTE = 0,
    dwLayerMask: windows.DWORD = 0,
    dwVisibleMask: windows.DWORD = 0,
    dwDamageMask: windows.DWORD = 0,
};

pub const HDC = *@OpaqueType();
pub const HGLRC = *@OpaqueType();

pub extern "gdi32" fn SetPixelFormat(
    hdc: HDC,
    format: i32,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(.Stdcall) bool;

pub extern "gdi32" fn ChoosePixelFormat(
    hdc: HDC,
    ppfd: ?*const PIXELFORMATDESCRIPTOR,
) callconv(.Stdcall) i32;

pub extern "gdi32" fn wglCreateContext(
    hdc: ?HDC,
) callconv(.Stdcall) HGLRC;

pub extern "gdi32" fn wglMakeCurrent(
    hdc: ?HDC,
    hglrc: ?HGLRC,
) callconv(.Stdcall) bool;

pub extern "gdi32" fn SwapBuffers(
    hdc: ?HDC,
) callconv(.Stdcall) bool;
