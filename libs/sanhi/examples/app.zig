const sanhi = @import("sanhi");
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const std = sanhi.std;
const ecs = sanhi.ecs;
pub fn main() !void {
    var app = try sanhi.app.App.init(.{});
    defer app.deinit();
    // app.add_plugin(sanhi.plugins.input.plugin);
    try app.add_plugins(&sanhi.plugins.plugins);
    app.run();
}
