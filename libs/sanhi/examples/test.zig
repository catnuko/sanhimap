const std = @import("std");
const sanhi = @import("sanhi");
const zgpu = sanhi.zgpu;
const wgpu = sanhi.wgpu;
const app = sanhi.app;
pub fn main() !void {
    try app.init(.{});
    // try app.addPlugin(sanhi.fps);
    // sanhi.fps.showFPS(true);
    try app.addPlugin(sanhi.input);
    try app.addPlugin(sanhi.meshes);
    app.startMainLoop();
    defer app.deinit();
}
