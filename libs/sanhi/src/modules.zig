const std = @import("std");
const mem = @import("mem.zig");
const ModuleQueue = std.PriorityQueue(Module, void, compareModules);
const backend = @import("./backend.zig");
var modules: ModuleQueue = undefined;
var needs_init: bool = true;

// don't put modules in the main list while iterating
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

/// A Module is a named set of functions that tie into the app lifecycle
pub const Module = struct {
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

    /// Runs the pre draw, draw, and post draw functions for this module. Useful when nesting modules.
    pub fn runFullRenderLifecycle(self: *const Module) void {
        if (self.pre_draw_fn != null) self.pre_draw_fn.?();
        if (self.draw_fn != null) self.draw_fn.?();
        if (self.post_draw_fn != null) self.post_draw_fn.?();
    }
};

fn compareModules(_: void, a: Module, b: Module) std.math.Order {
    return std.math.order(a.priority, b.priority);
}

pub fn deinit() void {
    std.debug.print("Modules system shutting down\n", .{});
    modules.deinit();
    modules_to_add.deinit();
}

/// Registers a module to tie it into the app lifecycle
pub fn registerModule(appBackend: *backend.AppBackend, module: Module) !void {
    if (needs_init) {
        const allocator = mem.getAllocator();
        modules = ModuleQueue.init(allocator, {});
        needs_init = false;
    }

    // only allow one version of a module to be registered!
    for (modules.items) |*m| {
        if (std.mem.eql(u8, module.name, m.name)) {
            std.debug.print("Module {s} is already being registered! Skipping.\n", .{module.name});
            return;
        }
    }

    modules.add(module) catch {
        std.debug.print("Error adding module to initialize: {s}\n", .{module.name});
    };

    std.debug.print("Initializing module: {s}\n", .{module.name});
    if (module.init_fn != null) {
        module.init_fn.?(appBackend) catch {
            std.debug.print("Error initializing module: {s}\n", .{module.name});
        };
    }
    std.debug.print("Registered module: {s}\n", .{module.name});
}

/// Gets a registered module
pub fn getModule(module_name: [:0]const u8) ?*Module {
    for (modules.items) |*module| {
        if (std.mem.eql(u8, module_name, module.name)) {
            return module;
        }
    }
    return null;
}

/// Let all modules know that initialization is done
pub fn startModules() void {
    for (modules.items) |*module| {
        if (module.start_fn != null)
            module.start_fn.?();
    }
}

/// Let all modules know that things are stopping
pub fn stopModules() void {
    for (modules.items) |*module| {
        if (module.stop_fn != null)
            module.stop_fn.?();
    }
}

/// Calls the tick and post-tick function of all modules
pub fn tickModules(delta_time: f32) void {
    for (modules.items) |*module| {
        if (module.tick_fn != null)
            module.tick_fn.?(delta_time);
    }
}

/// Calls the fixed tick and function of all modules
pub fn fixedTickModules(fixed_delta_time: f32) void {
    for (modules.items) |*module| {
        if (module.fixed_tick_fn != null)
            module.fixed_tick_fn.?(fixed_delta_time);
    }
}

/// Calls the pre-draw function of all modules. Happens before rendering
pub fn preDrawModules(appBackend: *backend.AppBackend) void {
    for (modules.items) |*module| {
        if (module.pre_draw_fn != null)
            module.pre_draw_fn.?(appBackend);
    }
}

/// Calls the draw function of all modules
pub fn drawModules(appBackend: *backend.AppBackend) void {
    for (modules.items) |*module| {
        if (module.draw_fn != null) {
            module.draw_fn.?(appBackend);
        }
    }
}

/// Calls the post-draw function of all modules. Happens at the end of a frame, after rendering.
pub fn postDrawModules(appBackend: *backend.AppBackend) void {
    for (modules.items) |*module| {
        if (module.post_draw_fn != null)
            module.post_draw_fn.?(appBackend);
    }
}

/// Calls the cleanup function of all modules
pub fn cleanupModules() void {
    for (modules.items) |*module| {
        if (module.cleanup_fn != null) {
            module.cleanup_fn.?() catch {
                std.debug.print("Error cleaning up module: {s}\n", .{module.name});
                continue;
            };
        }
    }
}
