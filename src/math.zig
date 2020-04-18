const std = @import("std");

pub const Mat4x4 = struct
{
    data: [16]f32,

    // Returns an Identity Matrix
    pub fn new() Mat4x4
    {
        return Mat4x4
        {
            .data = [16]f32
            {
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            },
        };
    }

    // Prints the Matrix to Console
    pub fn print(self: Mat4x4) void
    {
        var i: u32 = 0;
        while (i < self.data.len) : (i += 1)
        {
            std.debug.warn("{},", .{self.data[i]});
            if ((i + 1) % 4 == 0) std.debug.warn("\n", .{});
        }
    }

    // Multiplies this Matrix by Another
    pub fn mult(self: Mat4x4, rhs: Mat4x4) Mat4x4
    {
        var r = Mat4x4.new();

        var i: u32 = 0;
        while (i < self.data.len) : (i += 1)
        {
            var value: f32 = 0;

            const row = (i / 4) * 4;
            const col = i - row;

            var j: u32 = 0;
            while (j < 4) : (j += 1) {
                value += self.data[j + row] * rhs.data[(j * 4) + col];
            }

            r.data[i] = value;
        }

        return r;
    }

    // Creates a Rotation Matrix on the Z Axis
    pub fn create_rotation_z(angle: f32) Mat4x4
    {
        const cos = @cos(angle);
        const sin = @sin(angle);

        var r = Mat4x4.new();
        r[0] = cos;
        r[1] = sin;
        r[4] = -sin;
        r[5] = cos;
        return r;
    }

    // Create a Translation Matrix
    pub fn create_translation(x: f32, y: f32, z: f32) Mat4x4
    {
        var r = Mat4x4.new();
        r.data[12] = x;
        r.data[13] = y;
        r.data[14] = z;
        return r;
    }

    // Create a Scale Matrix
    pub fn create_scale(x: f32, y: f32, z: f32) Mat4x4
    {
        var r = Mat4x4.new();
        r.data[0] = x;
        r.data[5] = y;
        r.data[9] = z;
        return r;
    }

    // Create a Perspective Matrix from an FOV
    pub fn create_perspective(fov: f32, aspect: f32, depthNear: f32, depthFar: f32) Mat4x4
    {
        const maxY = depthNear * @tan(0.5 * fov);
        const minY = -maxY;
        const minX = minY * aspect;
        const maxX = maxY * aspect;

        return create_perspective_offset(minX, maxX, minY, 
            maxY, depthNear, depthFar);
    }

    // Creates a Perspective Matrix
    fn create_perspective_offset(left: f32, right: f32, bottom: f32, 
        top: f32, depthNear: f32, depthFar: f32) Mat4x4
    {
        var r = Mat4x4.new();

        // Row 0
        r.data[0] = 2.0 * depthNear / (right - left);
        
        // Row 1
        r.data[5] = 2.0 * depthNear / (top - bottom);
        
        // Row 2
        r.data[8] = (right + left) / (right - left);
        r.data[9] = (top + bottom) / (top - bottom);
        r.data[10] = -(depthFar + depthNear) / (depthFar - depthNear);
        
        // Row 3
        r.data[11] = -1;
        r.data[14] = -(2.0 * depthFar * depthNear) / (depthFar - depthNear);

        return r;
    }
};