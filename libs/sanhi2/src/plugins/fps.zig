const std = @import("std");
const lib = @import("../lib.zig");
const backend = lib.backend;
const zgui = lib.zgui;
const ecs = lib.ecs;
// var show_fps: bool = false;
// var last_fps_str: ?[:0]u8 = null;
// var last_fps: i32 = -1;
// pub fn showFPS(enabled: bool) void {
//     show_fps = enabled;
// }
// pub fn toggleFPS() void {
//     show_fps = !show_fps;
// }
// pub fn drawFPS(appBackend: *backend.AppBackend) void {
//     if (!show_fps) {
//         return;
//     }
//     const draw_list = zgui.getBackgroundDrawList();
//     draw_list.addText(
//         .{ 10, 10 },
//         0xff_ff_ff_ff,
//         "{d:.3} ms/frame ({d:.1} fps)",
//         .{ appBackend.gctx.stats.average_cpu_time, appBackend.gctx.stats.fps },
//     );
// }

// pub const plugin = plugins.Plugin{
//     .name = "fps",
//     .draw_fn = drawFPS,
// };

const ShowFPS = struct {};
fn fps_system(showFPS: []ShowFPS, ctxs: []lib.app.AppContext) void {
    if (showFPS.len > 0) {
        _ = ctxs[0];
        std.debug.print("fps\n", .{});
        // const draw_list = zgui.getBackgroundDrawList();
        // const app_backend = ctx.app.app_backend;
        // draw_list.addText(
        //     .{ 10, 10 },
        //     0xff_ff_ff_ff,
        //     "{d:.3} ms/frame ({d:.1} fps)",
        //     .{ app_backend.gctx.stats.average_cpu_time, app_backend.gctx.stats.fps },
        // );
    }
}
// fn fps_system(showFPS: []ShowFPS) void {
//     if (showFPS.len > 0) {
//         std.debug.print("sdfs\n", .{});
//     }
// }
fn build(app: *lib.app.App) void {
    ecs.TAG(app.world, ShowFPS);
    const fps = ecs.new_entity(app.world, "fps");
    _ = ecs.set(app.world,fps, ShowFPS, .{});
    _ = ecs.ADD_SYSTEM(app.world, "fps", ecs.OnUpdate, fps_system);
}

pub const plugin = lib.app.Plugin{
    .name = "fps",
    .build = build,
};
