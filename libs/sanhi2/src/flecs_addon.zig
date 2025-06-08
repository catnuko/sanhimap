const std = @import("std");
const ecs = @import("zflecs");

pub const ecs_app_desc_t = extern struct {
    target_fps: f32 = 0,
    delta_time: f32 = 0,
    threads: c_int = 0,
    frames: c_int = 0,
    enable_rest: bool = false,
    enable_monitor: bool = false,
    init: ?*anyopaque = null,
    ctx: ?*anyopaque = null,
};

extern "c" fn ecs_app_run(world: *ecs.world_t, app_desc: *ecs_app_desc_t) c_int;
pub inline fn app_run(world: *ecs.world_t, app_desc: *ecs_app_desc_t) i32 {
    return ecs_app_run(world, app_desc);
}

pub inline fn singleton(world: *ecs.world_t, comptime T: type, val: T) ecs.entity_t {
    return ecs.set(world, ecs.id(T), T, val);
}

pub inline fn get_singleton_mut(world: *ecs.world_t, comptime T: type) ?*T {
    return ecs.get_mut(world, ecs.id(T), T);
}