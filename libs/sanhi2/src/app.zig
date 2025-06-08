const backend = @import("./backend.zig");
const mem = @import("./mem.zig");
const std = @import("std");
const time = @import("std").time;
const lib = @import("./lib.zig");
const ecs = lib.ecs;

pub const Plugin = struct {
    name: [:0]const u8,
    isUnique: bool = true,
    build: *const fn (app: *App) void,
    ready: ?*const fn (app: *App) void = null,
    finish: ?*const fn (app: *App) void = null,
    cleanup: ?*const fn (app: *App) void = null,
};
pub const AppConfig = struct {
    title: [:0]const u8 = "SanHi",
    width: i32 = 900,
    height: i32 = 600,

    target_fps: ?f32 = 60,
};
pub const AppContext = struct {
    app: *App,
};
pub const App = struct {
    app_backend: backend.AppBackend,
    world: *ecs.world_t,
    plugin_registry: std.StringHashMap(Plugin),
    target_fps: f32,
    pub fn init(cfg: AppConfig) !App {
        mem.init(mem.createDefaultAllocator());
        var app_backend = backend.AppBackend{
            .on_init_fn = on_init,
            .on_deinit_fn = on_deinit,
            .on_update_fn = on_update,
            .width = cfg.width,
            .height = cfg.height,
            .title = cfg.title,
        };
        const world = ecs.init();

        try app_backend.init(mem.getAllocator());
        var appa = App{
            .app_backend = app_backend,
            .world = world,
            .plugin_registry = std.StringHashMap(Plugin).init(mem.getAllocator()),
            .target_fps = cfg.target_fps orelse 60,
        };
        ecs.COMPONENT(world, AppContext);
        _ = lib.flecs_addon.singleton(world, AppContext, AppContext{ .app = &appa });
        // const render = struct {
        //     pub fn render(_: []AppContext) void {
        //         lib.zglfw.pollEvents();
        //     }
        // }.render;
        // _ = ecs.ADD_SYSTEM(
        //     world,
        //     "render",
        //     ecs.OnStore,
        //     render,
        // );
        return appa;
    }
    pub fn deinit(self: *App) void {
        self.app_backend.deinit();
        self.plugin_registry.deinit();
        mem.deinit();
        _ = ecs.fini(self.world);
    }
    pub fn addPlugin(self: *App, plugin: Plugin) void {
        if (plugin.isUnique and self.plugin_registry.contains(plugin.name)) {
            unreachable;
        }
        plugin.build(self);
        self.plugin_registry.put(plugin.name, plugin) catch unreachable;
    }
    pub fn addPlugins(self: *App, pluginss: []Plugin) !void {
        for (pluginss) |plugin| {
            try self.addPlugin(plugin);
        }
    }
    pub fn finish(self: *App) void {
        const ps = self.plugin_registry.iterator();
        for (ps) |plugin| {
            if (plugin.finish) {
                plugin.finish(&self.app_backend);
            }
        }
    }
    pub fn cleanup(self: *App) void {
        const ps = self.plugin_registry.iterator();
        for (ps) |plugin| {
            if (plugin.cleanup) {
                plugin.cleanup(&self.app_backend);
            }
        }
    }
    pub fn getPlugin(self: *App, name: []const u8) ?Plugin {
        return self.plugin_registry.get(name);
    }
    pub fn get_width(self: *App) i32 {
        return self.app_backend.width;
    }
    pub fn get_height(self: *App) i32 {
        return self.app_backend.height;
    }
    pub fn run(self: *App) void {
        var app_desc = lib.flecs_addon.ecs_app_desc_t{
            .enable_rest = true,
            .target_fps = self.target_fps,
        };
        _ = lib.flecs_addon.app_run(self.world, &app_desc);
    }
};
fn on_init() void {}
fn on_deinit() void {}
fn on_update() void {}
