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
extern "c" fn ecs_app_run_frame(world: *ecs.world_t, app_desc: *ecs_app_desc_t) c_int;
pub inline fn app_run_frame(world: *ecs.world_t, app_desc: *ecs_app_desc_t) i32 {
    return ecs_app_run_frame(world, app_desc);
}

pub fn OBSERVER(
    world: *ecs.world_t,
    name: [*:0]const u8,
    phase: ecs.entity_t,
    observer_desc: *ecs.observer_desc_t,
) ecs.entity_t {
    var entity_desc = ecs.entity_desc_t{};
    entity_desc.id = ecs.new_id(world);
    entity_desc.name = name;

    const first = if (phase != 0) ecs.pair(ecs.EcsDependsOn, phase) else 0;
    const second = phase;
    entity_desc.add = &.{ first, second, 0 };

    observer_desc.entity = ecs.entity_init(world, &entity_desc);
    return ecs.observer_init(world, observer_desc);
}

// pub fn module_init(world: *ecs.world_t, module_name: []const u8) void {
//     var desc = ecs.component_desc_t{ .entity = 0, .type = .{ .size = 0, .alignment = 0 } };
//     _ = ecs.module_init(world, module_name, &desc);
// }


pub fn assert_name(world: *const ecs.world_t, comptime T: type, n: []const u8) void {
    assert_name_id(world, ecs.id(T), n);
}
pub fn assert_name_id(world: *const ecs.world_t, id: ecs.entity_t, n: []const u8) void {
    const n0 = ecs.get_name(world, id).?;
    const n1 = n0[0..std.mem.len(n0)];
    std.testing.expect(std.mem.eql(u8, n1, n)) catch unreachable;
}