const backend = @import("./backend.zig");
const plugins = @import("./plugin.zig");
const mem = @import("./mem.zig");
const std = @import("std");
const time = @import("std").time;
const lib = @import("./lib.zig");
const ecs = lib.ecs;

pub const Plugin = struct {
    name: [:0]const u8,
    isUnique: bool = true,
    build: ?*const fn (app: *App) void = null,
    ready: ?*const fn (app: *App) void = null,
    finish: ?*const fn (app: *App) void = null,
    cleanup: ?*const fn (app: *App) void = null,
};
pub const AppConfig = struct {
    title: [:0]const u8 = "SanHi",
    width: i32 = 900,
    height: i32 = 600,

    target_fps: ?i32 = null,
    use_fixed_timestep: bool = false,
    fixed_timestep_delta: f32 = 1.0 / 60.0,
};
pub const App = struct {
    app_backend: backend.AppBackend,
    world: ecs.world_t,
    plugin_registry: std.StringHashMap(Plugin),
    pub fn init(cfg: AppConfig) App {
        mem.init(mem.createDefaultAllocator());
        const app_backend = backend.AppBackend{
            .on_init_fn = on_init,
            .on_deinit_fn = on_deinit,
            .on_update_fn = on_update,
            .width = cfg.width,
            .height = cfg.height,
            .title = cfg.title,
        };
        const world = ecs.init();

        try app_backend.init(mem.getAllocator());
        const appa = App{
            .app_backend = app_backend,
            .world = world,
            .plugin_registry = std.StringHashMap(Plugin).init(mem.getAllocator()),
        };
        return appa;
    }
    pub fn deinit(self: *App) void {
        self.app_backend.deinit();
        self.plugin_registry.deinit();
        mem.deinit();
        ecs.fini(self.world);
    }
    pub fn addPlugin(self: *App, plugin: Plugin) !void {
        if(plugin.isUnique and self.plugin_registry.contains(plugin.name)) {
            @compileError("Plugin already exists");
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
    pub fn get_width(self: App) i32 {
        return self.app_backend.width;
    }
    pub fn get_height(self: App) i32 {
        return self.app_backend.height;
    }
};
var app: App = undefined;

pub fn init(cfg: AppConfig) !void {
    app = App.init(cfg);
}
pub fn deinit() void {
    app.deinit();
}

fn on_init() void {}

fn on_deinit() void {}
fn on_update() void {}
