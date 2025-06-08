const std = @import("std");
const lib = @import("./lib.zig");
const mem = @import("./mem.zig");
const zglfw = lib.zglfw;
const zgpu = lib.zgpu;
const wgpu = lib.wgpu;
const zgui = lib.zgui;
const window_title = "zig-gamedev: minimal zgpu zgui";
pub const AppBackend = struct {
    on_init_fn: *const fn () void,
    on_update_fn: *const fn () void,
    on_deinit_fn: *const fn () void,
    title: [:0]const u8 = "SanHi",
    width: i32 = 900,
    height: i32 = 600,
    gctx: *zgpu.GraphicsContext = undefined,
    allocator: std.mem.Allocator = undefined,
    window: *zglfw.Window = undefined,
    const Self = @This();
    pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
        try zglfw.init();

        // zglfw.windowHintUntyped(.client_api, .no_api);

        const window = try zglfw.Window.create(self.width, self.height, self.title, null);
        const gctx = try zgpu.GraphicsContext.create(
            allocator,
            .{
                .window = window,
                .fn_getTime = @ptrCast(&zglfw.getTime),
                .fn_getFramebufferSize = @ptrCast(&zglfw.Window.getFramebufferSize),
                .fn_getWin32Window = @ptrCast(&zglfw.getWin32Window),
                .fn_getX11Display = @ptrCast(&zglfw.getX11Display),
                .fn_getX11Window = @ptrCast(&zglfw.getX11Window),
                .fn_getWaylandDisplay = @ptrCast(&zglfw.getWaylandDisplay),
                .fn_getWaylandSurface = @ptrCast(&zglfw.getWaylandWindow),
                .fn_getCocoaWindow = @ptrCast(&zglfw.getCocoaWindow),
            },
            .{},
        );

        const scale_factor = scale_factor: {
            const scale = window.getContentScale();
            break :scale_factor @max(scale[0], scale[1]);
        };

        zgui.init(allocator);

        _ = zgui.io.addFontFromFile(
            "D:/code/geo/libs/sanhi/static/Roboto-Medium.ttf",
            std.math.floor(16.0 * scale_factor),
        );

        zgui.backend.init(
            window,
            gctx.device,
            @intFromEnum(zgpu.GraphicsContext.swapchain_format),
            @intFromEnum(wgpu.TextureFormat.undef),
        );

        zgui.getStyle().scaleAllSizes(scale_factor);

        self.on_init_fn();
        self.window = window;
        self.gctx = gctx;
        self.allocator = allocator;
    }
    // pub fn startMainLoop(self: *Self) void {
    //     while (!self.window.shouldClose() and self.window.getKey(.escape) != .press) {
    //         zglfw.pollEvents();
    //         self.on_update_fn();
    //     }
    // }
    pub fn deinit(self: *Self) void {
        self.on_deinit_fn();
        zgui.backend.deinit();
        zgui.deinit();
        self.gctx.destroy(self.allocator);
        self.window.destroy();
        zglfw.terminate();
    }
    pub fn getAspectRatio(self: *Self) f32 {
        return @as(f32, @floatFromInt(self.width)) / @as(f32, @floatFromInt(self.height));
    }
};
