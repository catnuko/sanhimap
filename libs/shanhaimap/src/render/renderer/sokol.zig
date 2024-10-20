const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;

pub const SokolAppConfig = struct {
    on_init_fn: *const fn () void,
    on_frame_fn: *const fn () void,
    on_cleanup_fn: *const fn () void,
    width: ?i32 = 900,
    height: ?i32 = 600,
    title: ?[]const u8 = "shanhaimap",
    buffer_pool_size: i32 = 512,
    shader_pool_size: i32 = 512,
    pipeline_pool_size: i32 = 512,
    image_pool_size: i32 = 256,
    sampler_pool_size: i32 = 128,
    pass_pool_size: i32 = 32,
};

// keep a static version of the app around
var app: App = undefined;

pub const App = struct {
    on_init_fn: *const fn () void,
    on_frame_fn: *const fn () void,
    on_cleanup_fn: *const fn () void,
    width: i32,
    height: i32,
    title: []const u8,
    pub fn init(cfg: SokolAppConfig) void {
        std.debug.print("Creating Sokol App backend", .{});
        app = App{
            .on_init_fn = cfg.on_init_fn,
            .on_frame_fn = cfg.on_frame_fn,
            .on_cleanup_fn = cfg.on_cleanup_fn,
            .width = cfg.width,
            .height = cfg.height,
            .title = cfg.title,
            .buffer_pool_size = cfg.buffer_pool_size,
            .shader_pool_size = cfg.shader_pool_size,
            .pipeline_pool_size = cfg.pipeline_pool_size,
            .image_pool_size = cfg.image_pool_size,
            .sampler_pool_size = cfg.sampler_pool_size,
            .pass_pool_size = cfg.pass_pool_size,
        };
    }

    pub fn deinit() void {
        std.debug.print("Sokol App Backend stopping", .{});
    }

    export fn sokol_init() void {
        std.debug.print("Sokol app context initializing", .{});

        sg.setup(.{
            .environment = sglue.environment(),
            .logger = .{ .func = slog.func },
            .buffer_pool_size = app.buffer_pool_size, // sokol default is 128
            .shader_pool_size = app.shader_pool_size, // sokol default is 64
            .image_pool_size = app.image_pool_size, // sokol default is 128
            .pipeline_pool_size = app.pipeline_pool_size, // sokol default is 64
            .sampler_pool_size = app.sampler_pool_size, // sokol default is 64
            .attachments_pool_size = app.pass_pool_size, // sokol default is 16,
        });

        simgui.setup(.{
            .logger = .{ .func = slog.func },
        });

        std.debug.print("Sokol setup backend: {}", .{sg.queryBackend()});

        // call the callback that will tell everything else to start up
        app.on_init_fn();
    }

    export fn sokol_cleanup() void {
        app.on_cleanup_fn();
        sg.shutdown();
    }

    export fn sokol_frame() void {
        app.on_frame_fn();
    }

    export fn sokol_input(event: ?*const sapp.Event) void {
        const ev = event.?;

        const imgui_did_handle = simgui.handleEvent(ev.*);
        if (imgui_did_handle)
            return;

        if (ev.type == .MOUSE_DOWN) {
            input.onMouseDown(@intFromEnum(ev.mouse_button));
        } else if (ev.type == .MOUSE_UP) {
            input.onMouseUp(@intFromEnum(ev.mouse_button));
        } else if (ev.type == .MOUSE_MOVE) {
            input.onMouseMoved(ev.mouse_x, ev.mouse_y, ev.mouse_dx, ev.mouse_dy);
        } else if (ev.type == .KEY_DOWN) {
            if (!ev.key_repeat)
                input.onKeyDown(@intFromEnum(ev.key_code));
        } else if (ev.type == .KEY_UP) {
            input.onKeyUp(@intFromEnum(ev.key_code));
        } else if (ev.type == .CHAR) {
            input.onKeyChar(ev.char_code);
        } else if (ev.type == .TOUCHES_BEGAN) {
            for (ev.touches) |touch| {
                if (touch.changed)
                    input.onTouchBegin(touch.pos_x, touch.pos_y, touch.identifier);
            }
        } else if (ev.type == .TOUCHES_MOVED) {
            for (ev.touches) |touch| {
                if (touch.changed)
                    input.onTouchMoved(touch.pos_x, touch.pos_y, touch.identifier);
            }
        } else if (ev.type == .TOUCHES_ENDED) {
            for (ev.touches) |touch| {
                if (touch.changed)
                    input.onTouchEnded(touch.pos_x, touch.pos_y, touch.identifier);
            }
        }
    }

    pub fn startMainLoop() void {
        std.debug.print("Sokol app starting main loop", .{});

        sapp.run(.{
            .init_cb = sokol_init,
            .frame_cb = sokol_frame,
            .cleanup_cb = sokol_cleanup,
            .event_cb = sokol_input,
            .width = self.width,
            .height = self.height,
            .icon = .{
                .sokol_default = true,
            },
            .window_title = self.title,
            .logger = .{
                .func = slog.func,
            },
            // .win32_console_attach = true,
        });
    }
};
