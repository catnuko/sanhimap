pub const ecs_key_state_t = struct {
    pressed: bool,
    state: bool,
    current: bool,
    down: bool,
};
pub const ecs_mouse_coord_t = struct {
    x: f32,
    y: f32,
};
pub const ecs_mouse_state_t = struct {
    left: ecs_key_state_t,
    right: ecs_key_state_t,
    wnd: ecs_mouse_coord_t,
    rel: ecs_mouse_coord_t,
    view: ecs_mouse_coord_t,
    scroll: ecs_mouse_coord_t,
};
pub const EcsInput = struct {
    keys: [128]ecs_key_state_t,
    mouse: ecs_mouse_state_t,
};

const sanhi = @import("../lib.zig");
const ecs = sanhi.ecs;

pub const plugin_name = "input";
fn module(world: *ecs.world_t) callconv(.C) void {
    var desc = ecs.component_desc_t{ .entity = 0, .type = .{ .size = 0, .alignment = 0 } };
    _ = ecs.module_init(world, plugin_name, &desc);

    ecs.COMPONENT(world, EcsInput);
    ecs.COMPONENT(world, ecs_mouse_state_t);
    ecs.COMPONENT(world, ecs_mouse_coord_t);
    ecs.COMPONENT(world, ecs_key_state_t);
    ecs.singleton_add(world, EcsInput);
}

fn build(app: *sanhi.app.App) void {
    _ = ecs.import_c(app.world, module, plugin_name);
}
pub const plugin = sanhi.app.Plugin{
    .name = plugin_name,
    .build = build,
};
