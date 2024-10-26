const std = @import("std");
const sanhi = @import("sanhi");
const zgpu = sanhi.zgpu;
const wgpu = sanhi.wgpu;
pub fn main() !void {
    try sanhi.app.init(.{});
    try sanhi.app.addPlugin(sanhi.fps);
    sanhi.app.startMainLoop();
    defer sanhi.app.deinit();
}
