const std = @import("std");
const print = std.debug.print;
const zglfw = @import("zglfw");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zgui = @import("zgui");
pub const MapView = struct {
    const Self = @This();
    window: *zglfw.Window,
    allocator: std.mem.Allocator,
    gctx: *zgpu.GraphicsContext,
    pub fn init(allocator: std.mem.Allocator) !Self {
        //init window
        try zglfw.init();

        zglfw.windowHintTyped(.client_api, .no_api);
        const window = try zglfw.Window.create(1600, 1000, "MapView", null);
        window.setSizeLimits(400, 400, -1, -1);

        //init zgpu and zgui
        const gctx = try newGraphicsContext(allocator, window);
        const scale_factor = scale_factor: {
            const scale = window.getContentScale();
            break :scale_factor @max(scale[0], scale[1]);
        };

        zgui.init(allocator);
        _ = zgui.io.addFontFromFile(
            "static/Roboto-Medium.ttf",
            std.math.floor(16.0 * scale_factor),
        );
        zgui.backend.init(
            window,
            gctx.device,
            @intFromEnum(zgpu.GraphicsContext.swapchain_format),
            @intFromEnum(wgpu.TextureFormat.undef),
        );
        zgui.getStyle().scaleAllSizes(scale_factor);

        var self: Self = .{
            .gctx = gctx,
            .window = window,
            .allocator = allocator,
        };
        self.startLoop();
        return self;
    }
    pub fn deinit(self: *Self) void {
        zgui.backend.deinit();
        zgui.deinit();
        const gctx = self.gctx;
        gctx.destroy(self.allocator);
        self.window.destroy();
        zglfw.terminate();
        print("all destroy", .{});
    }
    pub fn startLoop(
        self: *Self,
    ) void {
        while (!self.window.shouldClose() and self.window.getKey(.escape) != .press) {
            zglfw.pollEvents();
            self.update();
        }
    }
    pub fn update(self: *Self) void {
        const gctx = self.gctx;
        zgui.backend.newFrame(
            gctx.swapchain_descriptor.width,
            gctx.swapchain_descriptor.height,
        );
        const draw_list = zgui.getBackgroundDrawList();
        draw_list.addText(
            .{ 10, 10 },
            0xff_ff_ff_ff,
            "{d:.3} ms/frame ({d:.1} fps)",
            .{ gctx.stats.average_cpu_time, gctx.stats.fps },
        );

        const swapchain_texv = gctx.swapchain.getCurrentTextureView();
        defer swapchain_texv.release();

        const commands = commands: {
            const encoder = gctx.device.createCommandEncoder(null);
            defer encoder.release();
            {
                const pass = zgpu.beginRenderPassSimple(encoder, .load, swapchain_texv, null, null, null);
                defer zgpu.endReleasePass(pass);
                zgui.backend.draw(pass);
            }

            break :commands encoder.finish(null);
        };
        defer commands.release();

        gctx.submit(&.{commands});
        _ = gctx.present();
    }

    pub fn something(self: Self) void {
        print("{s}", .{self.name});
    }
};

pub fn newGraphicsContext(
    allocator: std.mem.Allocator,
    window: *zglfw.Window,
) !*zgpu.GraphicsContext {
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
    errdefer gctx.destroy(allocator);
    return gctx;
}

/// Change current working directory to where the executable is located.
pub fn changeWorkdDir() void {
    var buffer: [1024]u8 = undefined;
    const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
    std.posix.chdir(path) catch {};
}
