const std = @import("std");
const mem = @import("mem.zig");
const ModuleQueue = std.PriorityQueue(Plugin, void, comparePlugins);
const backend = @import("./backend.zig");
var plugins: ModuleQueue = undefined;
var needs_init: bool = true;

// don't put plugins in the main list while iterating
var modules_to_add: ModuleQueue = undefined;

// Some easy to work with priorities
pub const Priority = struct {
    pub const first: i32 = -50;
    pub const highest: i32 = 0;
    pub const high: i32 = 50;
    pub const normal: i32 = 100;
    pub const low: i32 = 150;
    pub const lowest: i32 = 200;
    pub const last: i32 = 250;
};

/// A Plugin is a named set of functions that tie into the app lifecycle
pub const Plugin = struct {
    name: [:0]const u8,
    init_fn: ?*const fn (appBackend: *backend.AppBackend) anyerror!void = null,
    start_fn: ?*const fn () void = null,
    stop_fn: ?*const fn () void = null,
    tick_fn: ?*const fn (f32) void = null,
    fixed_tick_fn: ?*const fn (f32) void = null,
    pre_draw_fn: ?*const fn (appBackend: *backend.AppBackend) void = null,
    draw_fn: ?*const fn (appBackend: *backend.AppBackend) void = null,
    post_draw_fn: ?*const fn (appBackend: *backend.AppBackend) void = null,
    cleanup_fn: ?*const fn () anyerror!void = null,
    priority: i32 = 100, // lower priority runs earlier!

    /// Runs the pre draw, draw, and post draw functions for this plugin. Useful when nesting plugins.
    pub fn runFullRenderLifecycle(self: *const Plugin) void {
        if (self.pre_draw_fn != null) self.pre_draw_fn.?();
        if (self.draw_fn != null) self.draw_fn.?();
        if (self.post_draw_fn != null) self.post_draw_fn.?();
    }
};

fn comparePlugins(_: void, a: Plugin, b: Plugin) std.math.Order {
    return std.math.order(a.priority, b.priority);
}

pub fn deinit() void {
    std.debug.print("Plugins system shutting down\n", .{});
    plugins.deinit();
    modules_to_add.deinit();
}

/// Registers a plugin to tie it into the app lifecycle
pub fn registerPlugin(appBackend: *backend.AppBackend, plugin: Plugin) !void {
    if (needs_init) {
        const allocator = mem.getAllocator();
        plugins = ModuleQueue.init(allocator, {});
        needs_init = false;
    }

    // only allow one version of a plugin to be registered!
    for (plugins.items) |*m| {
        if (std.mem.eql(u8, plugin.name, m.name)) {
            std.debug.print("Plugin {s} is already being registered! Skipping.\n", .{plugin.name});
            return;
        }
    }

    plugins.add(plugin) catch {
        std.debug.print("Error adding plugin to initialize: {s}\n", .{plugin.name});
    };

    std.debug.print("Initializing plugin: {s}\n", .{plugin.name});
    if (plugin.init_fn != null) {
        plugin.init_fn.?(appBackend) catch {
            std.debug.print("Error initializing plugin: {s}\n", .{plugin.name});
        };
    }
    std.debug.print("Registered plugin: {s}\n", .{plugin.name});
}

/// Gets a registered plugin
pub fn getPlugin(module_name: [:0]const u8) ?*Plugin {
    for (plugins.items) |*plugin| {
        if (std.mem.eql(u8, module_name, plugin.name)) {
            return plugin;
        }
    }
    return null;
}

/// Let all plugins know that initialization is done
pub fn startPlugins() void {
    for (plugins.items) |*plugin| {
        if (plugin.start_fn != null)
            plugin.start_fn.?();
    }
}

/// Let all plugins know that things are stopping
pub fn stopPlugins() void {
    for (plugins.items) |*plugin| {
        if (plugin.stop_fn != null)
            plugin.stop_fn.?();
    }
}

/// Calls the tick and post-tick function of all plugins
pub fn tickPlugins(delta_time: f32) void {
    for (plugins.items) |*plugin| {
        if (plugin.tick_fn != null)
            plugin.tick_fn.?(delta_time);
    }
}

/// Calls the fixed tick and function of all plugins
pub fn fixedTickPlugins(fixed_delta_time: f32) void {
    for (plugins.items) |*plugin| {
        if (plugin.fixed_tick_fn != null)
            plugin.fixed_tick_fn.?(fixed_delta_time);
    }
}

/// Calls the pre-draw function of all plugins. Happens before rendering
pub fn preDrawPlugins(appBackend: *backend.AppBackend) void {
    for (plugins.items) |*plugin| {
        if (plugin.pre_draw_fn != null)
            plugin.pre_draw_fn.?(appBackend);
    }
}

/// Calls the draw function of all plugins
pub fn drawPlugins(appBackend: *backend.AppBackend) void {
    for (plugins.items) |*plugin| {
        if (plugin.draw_fn != null) {
            plugin.draw_fn.?(appBackend);
        }
    }
}

/// Calls the post-draw function of all plugins. Happens at the end of a frame, after rendering.
pub fn postDrawPlugins(appBackend: *backend.AppBackend) void {
    for (plugins.items) |*plugin| {
        if (plugin.post_draw_fn != null)
            plugin.post_draw_fn.?(appBackend);
    }
}

/// Calls the cleanup function of all plugins
pub fn cleanupPlugins() void {
    for (plugins.items) |*plugin| {
        if (plugin.cleanup_fn != null) {
            plugin.cleanup_fn.?() catch {
                std.debug.print("Error cleaning up plugin: {s}\n", .{plugin.name});
                continue;
            };
        }
    }
}
