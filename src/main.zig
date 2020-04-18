usingnamespace @import("./window.zig");
usingnamespace @import("./graphics.zig");

const std = @import("std");
usingnamespace std.math;

const Event = Window.Event;
const w = @import("./win32.zig");

const degToRad = 3.145 / 180.0;

const map = [5][5]u8
{
    [_]u8 { '#', '#', '#', '#', '#' },
    [_]u8 { '#', '0', '0', '0', '#' },
    [_]u8 { '#', '0', '0', '0', '#' },
    [_]u8 { '#', '0', '0', '0', '#' },
    [_]u8 { '#', '#', '#', '#', '#' },
};

var camFov: f32 = 60;
var camPos = Vector2.new(2, 1);
var camAng: f32 = 90;

const clipDist = 5;
const step = 0.1;

pub fn main() void 
{
    if (Window.create("Zig Raycaster", 800, 800)) |*window| 
    {
        window.enable_canvas(std.heap.c_allocator, 8); 
        window.set_handler(Window.Event.Render, &onRender);
        window.show();

        // Cleanup
        window.destroy();
    }
}

fn onRender(window: *Window) void 
{
    if (window.get_canvas()) |canvas| 
    {
        canvas.clear();

        const camDir = Vector2.new(@cos(camAng * degToRad),
            @sin(camAng * degToRad)).scale(0.1);

        if (window.get_key(w.VK.RIGHT)) { camAng += 1; }
        if (window.get_key(w.VK.LEFT)) { camAng -= 1; }
        if (window.get_key(w.VK.UP)) { camPos = camPos.add(camDir); }
        if (window.get_key(w.VK.DOWN)) { camPos = camPos.sub(camDir); }

        if (camAng >= 360) { camAng = 0; }

        var x: u32 = 0;
        while (x < canvas.width) : (x += 1)
        {
            const xF = @intToFloat(f32, x);
            const cW = @intToFloat(f32, canvas.width);
            const xP = (xF - (cW * 0.5)) / cW;

            const angX = ((xP * camFov) + camAng) * degToRad;

            const dirX = @cos(angX);
            const dirY = @sin(angX);
        
            var dist: f32 = 0.0;
            var hit = false;

            var rayX: f32 = camPos.x;
            var rayY: f32 = camPos.y;

            while (dist < clipDist and !hit)
            {
                dist += step;

                // Avoid Casting to Negative or Out of Bounds
                rayX = camPos.x + dirX * dist;
                if (rayX <= 0) { break; }
                rayY = camPos.y + dirY * dist;
                if (rayY <= 0) { break; }
                
                const hitX = @floatToInt(usize, @round(rayX));
                if (hitX >= map[0].len) { break; }

                const hitY = @floatToInt(usize, @round(rayY));
                if (hitY >= map.len) { break; }
                
                if (map[hitY][hitX] == '#') { hit = true; }
            }

            dist *= @cos(angX - (camAng * degToRad));
            
            var div = dist / clipDist;
            if (div > 1) { div = 1; }
            else if (div < 0) { div = 0; }

            const cH = @intToFloat(f32, canvas.height);
            const sDist = @floatToInt(u32, div * (cH * 0.5));
            const cVal = @floatToInt(u8, (1 - div) * 255.0);

            var y: u32 = 0;
            while (y < canvas.height) : (y += 1) 
            {
                const yF = @intToFloat(f32, y);
                const groundVal = 1 - (yF / (cH * 0.5));
                const skyVal = 1 - (((yF + (cH * 0.5)) / cH) - 1);

                if (y >= sDist and y <= canvas.height - sDist) {
                    canvas.draw(x, y, Color.fromRGB(cVal, cVal, cVal));
                }
                else if (y < sDist) 
                {
                    const ground = @floatToInt(u8, groundVal * 255.0);
                    canvas.draw(x, y, Color.fromRGB(96, ground, 0));
                }
                else 
                {
                    const sky = @floatToInt(u8, skyVal * 255.0);
                    canvas.draw(x, y, Color.fromRGB(135, 206, sky));
                }
            }
        }
    }
}

