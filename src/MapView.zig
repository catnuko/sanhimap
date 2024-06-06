const std = @import("std");
const print = std.debug.print;
const lib = @import("lib.zig");
const zglfw = @import("zglfw");
pub const MapView = struct {
    const Self = @This();
    window: *zglfw.Window,
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,
    name: *const [6]u8 = "MapView",
    pub fn new() !Self {
        try zglfw.init();
        // Change current working directory to where the executable is located.
        {
            var buffer: [1024]u8 = undefined;
            const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
            std.posix.chdir(path) catch {};
        }
        zglfw.windowHintTyped(.client_api, .no_api);
        const window = try zglfw.Window.create(1600, 1000, "test", null);
        window.setSizeLimits(400, 400, -1, -1);
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var self: Self = .{
            .window = window,
            .gpa = gpa,
            .allocator = allocator,
        };
        self.init();
        return self;
    }
    pub fn init(
        self: *Self,
    ) void {
        while (!self.window.shouldClose() and self.window.getKey(.escape) != .press) {
            zglfw.pollEvents();
        }
        self.destroy();
    }
    pub fn update(_: *Self) void {
        print("update", .{});
    }
    pub fn destroy(self: *Self) void {
        _ = self.gpa.deinit();
        self.window.destroy();
        zglfw.terminate();
        print("all destroy", .{});
    }
    pub fn something(self: Self) void {
        print("{s}", .{self.name});
    }
};
