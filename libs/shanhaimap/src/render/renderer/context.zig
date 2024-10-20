const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;
pub const RenderContext = struct {
    allocator: Allocator,
    width: i32,
    height: i32,
    name: []const u8,
    const Self = @This();
    pub const Options = struct { allocator: Allocator, width: ?i32 = 900, height: ?i32 = 600, name: ?[]const u8 = "shanhaimap" };
    pub fn new(options: Options) Self {
        const self = .{
            .width = options.width,
            .height = options.height,
            .name = options.name,
            .allocator = options.allocator,
        };
        sg.setup(.{
            .environment = sglue.environment(),
        });
        return self;
    }
    pub fn run(self: *const Self) void {
        sapp.run(.{
            // .init_cb = init_cb,
            // .frame_cb = frame_cb,
            .cleanup_cb = cleanup_cb,
            .width = self.width,
            .height = self.height,
            .icon = .{ .sokol_default = true },
            .window_title = self.name,
            .logger = .{ .func = slog.func },
        });
    }
    fn cleanup_cb() void {
        sg.shutdown();
    }
};
