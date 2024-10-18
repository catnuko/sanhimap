const std = @import("std");
const lib = @import("root.zig");
const testing = @import("std").testing;
const render = lib.render;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    // var mapviwe = try lib.MapView.init(alloc);
    // defer mapviwe.deinit();
    var app = lib.render.App.new(alloc);
    defer app.deinit();
    var core3dPlugin = render.core.Core3dPlugin.new();
    app.addPlugin(core3dPlugin.plugin()) catch unreachable;
    app.run();
}
