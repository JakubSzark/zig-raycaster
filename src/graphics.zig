usingnamespace @import("./gl.zig");
const Allocator = @import("std").mem.Allocator;
usingnamespace @import("std").math;

// Color Structure
// ======================================

pub const Color = packed struct 
{
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    /// Creates a color from all RGBA components
    pub fn fromRGBA(red: u8, green: u8, blue: u8, alpha: u8) Color 
    {
        return Color
        {
            .r = red,
            .g = green,
            .b = blue,
            .a = alpha,
        };
    }

    /// Creates a color from RGB components where A is 255
    pub fn fromRGB(red: u8, green: u8, blue: u8) Color 
    {
        return Color
        {
            .r = red,
            .g = green,
            .b = blue,
            .a = 255,
        };
    }
};

// Canvas Structure
// ======================================

pub const Canvas = struct
{
    pixels: []Color,
    width: u32,
    height: u32,
    texture_id: u32,
    allocator: *Allocator,

    pub fn create(allocator: *Allocator, width: u32, height: u32) !Canvas
    {
        var id: u32 = 0;
        const pixels = try allocator.alloc(Color, width * height);

        for (pixels) |*pixel| { 
            pixel.* = Color.fromRGB(0, 0, 0); 
        }

        glEnable(GL.TEXTURE_2D);
        glGenTextures(1, &id);
        glBindTexture(GL.TEXTURE_2D, id);
        glTexImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, 
            height, 0, GL.RGBA, GL.UNSIGNED_BYTE, @ptrCast(GLvoid, pixels));

        glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
        glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP);
        glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP);        

        return Canvas
        {
            .width = width,
            .height = height,
            .pixels = pixels,
            .texture_id = id,
            .allocator = allocator
        };
    }

    pub fn draw(self: Canvas, x: u32, y: u32, color: Color) void 
    {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height)
            self.pixels[y * self.width + x] = color;
    }

    pub fn draw_line(self: Canvas, line: Line, color: Color) void
    {
        var x = line.a.x;
        var y = line.a.y;

        var dx = line.b.x - line.a.x;
        var dy = line.b.y - line.a.y;

        const absDX = absFloat(dx);
        const absDY = absFloat(dy);

        var step = absDX;
        if (absDY > absDX) { step = absDY; }

        dx /= step;
        dy /= step;

        var i: f32 = 1;
        while (i <= step) : (i += 1)
        {
            self.draw(@floatToInt(u32, x), @floatToInt(u32, y), color);
            x += dx;
            y += dy;
        }
    }

    pub fn clear(self: Canvas) void 
    {
        for (self.pixels) |*pixel| {
            pixel.* = Color.fromRGB(0, 0, 0);
        }
    }

    pub fn render(self: Canvas) void
    {
        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GL.COLOR_BUFFER_BIT);
        glBindTexture(GL.TEXTURE_2D, self.texture_id);

        glBegin(GL.QUADS);
            glTexCoord2f(0.0, 0.0); glVertex2f(-1.0, -1.0);
            glTexCoord2f(1.0, 0.0); glVertex2f(1.0, -1.0);
            glTexCoord2f(1.0, 1.0); glVertex2f(1.0, 1.0);
            glTexCoord2f(0.0, 1.0); glVertex2f(-1.0, 1.0);
        glEnd();

        glTexSubImage2D(GL.TEXTURE_2D, 0, 0, 0, self.width, self.height, GL.RGBA,
            GL.UNSIGNED_BYTE, @ptrCast(GLvoid, self.pixels));
    }

    pub fn free(self: Canvas) void {
        self.allocator.free(self.pixels);
    }
};

// Vector2
// =========================================
pub const Vector2 = packed struct
{
    x: f32, y: f32,

    pub fn new(x: f32, y: f32) Vector2 {
        return Vector2 { .x = x, .y = y };
    }

    pub fn add(self: Vector2, rhs: Vector2) Vector2 {
        return Vector2 { .x = self.x + rhs.x, .y = self.y + rhs.y };
    }

    pub fn sub(self: Vector2, rhs: Vector2) Vector2 {
        return Vector2 { .x = self.x - rhs.x, .y = self.y - rhs.y };
    }

    pub fn scale(self: Vector2, scalar: f32) Vector2 {
        return Vector2 { .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn dot(self: Vector2, rhs: Vector2) f32 {
        return (self.x * rhs.x) + (self.y * rhs.y);
    }

    pub fn dist(self: Vector2, rhs: Vector2) f32
    {
        return @sqrt((rhs.x - self.x) * (rhs.x - self.x) + 
                     (rhs.y - self.y) * (rhs.y - self.y));
    }

    pub fn mag(self: Vector2) f32 {
        return @sqrt((self.x * self.x) + (self.y * self.y));
    }

    pub fn angle(self: Vector2) f32 {
        return atan2(f32, self.y, self.x);
    }
};

// Vector3
// =========================================

pub const Vector3 = packed struct
{
    x: f32, y: f32, z: f32,

    pub fn new(x: f32, y: f32, z: f32) Vector3 {
        return Vector3 { .x = x, .y = y, .z = z };
    }

    pub fn add(self: Vector3, rhs: Vector3) Vector3
    {
        return Vector3 
        { 
            .x = self.x + rhs.x, 
            .y = self.y + rhs.y, 
            .z = self.z + rhs.z 
        };
    }

    pub fn sub(self: Vector3, rhs: Vector3) Vector3
    {
        return Vector3 
        { 
            .x = self.x - rhs.x, 
            .y = self.y - rhs.y, 
            .z = self.z - rhs.z 
        };
    }

    pub fn scale(self: Vector3, sc: f32) Vector3 
    {
        return Vector3
        {
            .x = self.x * sc,
            .y = self.y * sc,
            .z = self.z * sc,
        };
    }

    pub fn dot(self: Vector3, rhs: Vector3) f32 {
        return (self.x * rhs.x) + (self.y * rhs.y) + (self.z * rhs.z);
    }

    pub fn cross(self: Vector3, rhs: Vector3) Vector3
    {
        return Vector3
        { 
            .x = (self.y * rhs.z) - (self.z * rhs.y),
            .y = (self.z * rhs.x) - (self.x * rhs.z),
            .z = (self.x * rhs.y) - (self.y * rhs.x)
        };
    }

    pub fn dist(self: Vector3, rhs: Vector3) f32
    {
        return @sqrt((rhs.x - self.x) * (rhs.x - self.x) + 
                     (rhs.y - self.y) * (rhs.y - self.y) +
                     (rhs.z - self.z) * (rhs.z - self.z));
    }
};

// Line
// =========================================

pub const Line = packed struct
{
    a: Vector2,
    b: Vector2,

    pub fn new(x0: f32, y0: f32, x1: f32, y1: f32) Line
    {
        return Line
        {
            .a = Vector2.new(x0, y0),
            .b = Vector2.new(x1, y1)
        };
    }

    pub fn intersecting(self: Line, pos: Vector2, dir: Vector2) bool
    {
        return 0;
    }
};

// Triangle
// =========================================

pub const Triangle = packed struct
{
    v1: Vector3,
    v2: Vector3,
    v3: Vector3,

    pub fn getNormal(self: Triangle) Vector3
    {
        const ab = self.v1.sub(self.v2);
        const bc = self.v2.sub(self.v3);
        return ab.cross(bc);
    }

    const EPSILON = 0.000001;

    pub fn getIntersection(self: Triangle, point: Vector3, dir: Vector3, out: *Vector3) bool
    {
        const n = self.getNormal();

        const edge1 = self.v2.sub(self.v1);
        const edge2 = self.v3.sub(self.v1);
        const h = dir.cross(edge2);
        const a = edge1.dot(h);

        if (a > -EPSILON and a < EPSILON)
            return false;

        const f = 1.0 / a;
        const s = point.sub(self.v1);
        const u = f * s.dot(h);

        if (u < 0.0 or u > 1.0)
            return false;
        
        const q = s.cross(edge1);
        const v = f * dir.dot(q);

        if (v < 0.0 or u + v > 1.0)
            return false;
        
        const t = f * edge2.dot(q);

        if (t > EPSILON)
        {
            out.* = point.add(dir.scale(t));
            return true;
        }

        return false;
    }
};