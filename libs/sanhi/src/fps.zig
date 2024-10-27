const std = @import("std");
const lib = @import("./lib.zig");
const backend = lib.backend;
const zgui = lib.zgui;
const modules = lib.modules;
var show_fps: bool = false;
var last_fps_str: ?[:0]u8 = null;
var last_fps: i32 = -1;
pub fn showFPS(enabled: bool) void {
    show_fps = enabled;
}
pub fn toggleFPS() void {
    show_fps = !show_fps;
}
pub fn drawFPS(appBackend: *backend.AppBackend) void {
    if (!show_fps) {
        return;
    }
    const draw_list = zgui.getBackgroundDrawList();
    draw_list.addText(
        .{ 10, 10 },
        0xff_ff_ff_ff,
        "{d:.3} ms/frame ({d:.1} fps)",
        .{ appBackend.gctx.stats.average_cpu_time, appBackend.gctx.stats.fps },
    );
}
pub fn module() modules.Module {
    const fps = modules.Module{
        .name = "fps",
        .draw_fn = drawFPS,
    };
    return fps;
}
