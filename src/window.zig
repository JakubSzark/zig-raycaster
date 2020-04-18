const std = @import("std");
const Allocator = std.mem.Allocator;

const gfx = @import("./graphics.zig");
const Canvas = gfx.Canvas;
const Vector2 = gfx.Vector2;

usingnamespace std.os.windows;
usingnamespace std.math;

usingnamespace @import("./win32.zig");
usingnamespace @import("./gdi.zig");
usingnamespace @import("./gl.zig");

// Default Win32 Structures
// ======================================

fn getDefaultClass() WNDCLASSEXA 
{
    return WNDCLASSEXA
    {
        .style = CS.HREDRAW | CS.VREDRAW | CS.OWNDC,
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = @ptrCast(HINSTANCE, GetModuleHandleA(null)),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = "DesktopApp",
        .hIconSm = null,
    };
}

const default_style = WS.OVERLAPPED | WS.CAPTION | 
    WS.SYSMENU | WS.THICKFRAME | WS.MINIMIZEBOX;

const default_pfd = PIXELFORMATDESCRIPTOR 
{
    .dwFlags = PFD.DRAW_TO_WINDOW | 
        PFD.SUPPORT_OPENGL | PFD.DOUBLEBUFFER,
    .iLayerType = PFD.MAIN_PLANE,
    .iPixelType = PFD.TYPE_RGBA,
    .cColorBits = 32,
    .cStencilBits = 8,
    .cDepthBits = 24,
};

// Default Window Procedure
// ======================================

pub fn WndProc(hWnd: HWND, uMsg: WM, 
    wParam: WPARAM, lParam: LPARAM) callconv(.Stdcall) LRESULT 
{
    switch (uMsg)
    {
        WM.CLOSE => PostQuitMessage(0),
        else => {}
    }

    return DefWindowProcA(hWnd, uMsg, wParam, lParam);
}

// Keys
// ======================================

pub const KeyState = struct {
    key: VK, action: WM
};

pub const Point = struct {
    x: u32, y: u32
};

// Window Struct
// ======================================

pub const Window = struct 
{
    pub const Event = enum {
        Created, Destroyed, Render
    };

    const eventCnt = @typeInfo(Event).Enum.fields.len;

    // A Function that can handle window events
    pub const Handler = *const fn (*Window) void;

    hWnd: HWND,
    handlers: [eventCnt]?Handler,
    canvas: ?Canvas,
    height: u32,
    width: u32,
    allocator: ?*Allocator,
    pixel_size: u32,
    key_state: KeyState,
    mouse_pos: Point,

    // Creates a Win32 Window 
    pub fn create(title: [*:0]const u8, width: u32, height: u32) ?Window 
    {
        // Register the default window class
        const class = getDefaultClass();
        if (RegisterClassExA(&class) == 0) {
            switch (kernel32.GetLastError()) {
                else => |err| return null,
            }
        }

        // Return the created window
        if (CreateWindowExA(
            0, class.lpszClassName, title, default_style, 0, 
            0, @intCast(i32, width), @intCast(i32, height), 
            null, null, class.hInstance, null)
        ) |hWnd| 
        {
            return Window
            {
                .hWnd = hWnd,
                .width = width,
                .height = height,
                .handlers = [_]?Handler{null} ** eventCnt,
                .canvas = null,
                .pixel_size = 1,
                .allocator = null,
                .key_state = KeyState {
                    .key = VK.A, .action = WM.KEYDOWN,
                },
                .mouse_pos = Point {.x=0, .y=0},
            };
        } 
        else { return null; }
    }

    // Sets the handler of the window
    pub fn set_handler(self: *Window, event: Event, handler: Handler) void {
        self.handlers[@enumToInt(event)] = handler;
    }

    // Calls an event for the handler to recieve
    fn dispatch_event(self: *Window, event: Event) void 
    {
        if (self.handlers[@enumToInt(event)]) |handler| { 
            handler.*(self); 
        }
    }

    // Creates a canvas object
    pub fn enable_canvas(self: *Window, 
        allocator: *Allocator, pixel_size: u32) void
    {
        self.allocator = allocator;
        self.pixel_size = pixel_size;
    }

    // Cleans up resources
    pub fn destroy(self: *Window) void {
        if (self.canvas) |c| { c.free(); }
    }

    // Returns the canvas if it was created
    pub fn get_canvas(self: *Window) ?*Canvas 
    {
        if (self.canvas) |*canvas| { return canvas; }
        else { return null; }
    }

    // Return current state of the keyboard
    pub fn get_key_state(self: *Window) KeyState {
        return self.key_state;
    }

    // Whether a key is being pressed
    pub fn get_key(self: *Window, key: VK) bool 
    {
        const state = self.get_key_state();
        return state.key == key and state.action == WM.KEYDOWN;
    }

    // Shows the window on screen
    pub fn show(self: *Window) void 
    {
        var isVisible = true;
        const hdc = GetDC(self.hWnd);
        var msg: MSG = .{};

        // Show the window
        _ = ShowWindow(self.hWnd, SW.SHOW);
        _ = UpdateWindow(self.hWnd);

        // Make Win32 work with OpenGL
        const format = ChoosePixelFormat(hdc.?, &default_pfd);
        _ = SetPixelFormat(hdc.?, format, &default_pfd);

        // Create an OpenGL context
        const context = wglCreateContext(hdc);

        // Make OpenGL current to this window
        _ = wglMakeCurrent(hdc, context);

        if (self.allocator) |a|
        {
            const width = @divExact(self.width, self.pixel_size);
            const height = @divExact(self.height, self.pixel_size);

            if (Canvas.create(a, width, height)) |c| {
                self.canvas = c; 
            } 
            else |_| { return; }
        }

        self.dispatch_event(Event.Created);

        while (isVisible) 
        {
            // Main Messaging Loop
            if (PeekMessageA(&msg, null, 0, 0, PM.REMOVE)) 
            {
                _ = TranslateMessage(&msg);
                _ = DispatchMessageA(&msg);

                switch (msg.message)
                {
                    WM.QUIT => {
                        isVisible = false;
                    },
                    WM.KEYDOWN, WM.KEYUP => 
                    {
                        const keyCode = @intCast(c_uint, msg.wParam);
                        const vk = @intToEnum(VK, keyCode);
                        self.key_state = KeyState {
                            .key = vk, .action = msg.message
                        };
                    },
                    WM.MOUSEMOVE =>
                    {
                        var LP = @ptrToInt(msg.lParam);
                        const x: u32 = @intCast(u32, maxInt(u16) & LP);
                        const y: u32 = @intCast(u32, LP >> 16);
                        self.mouse_pos = Point {
                            .x = x, .y = self.width - y
                        };
                    },
                    else => {}
                }
            } 

            self.dispatch_event(Event.Render);
            if (self.canvas) |c| { c.render(); }
            _ = SwapBuffers(hdc);
        }

        self.dispatch_event(Event.Destroyed);
    }
};


