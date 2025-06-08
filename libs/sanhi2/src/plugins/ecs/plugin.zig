const lib = @import("../../lib.zig");
const math = @import("math");
const Matrix3D = math.Matrix3D;
const Matrix4D = math.Matrix4D;
const Vector3D = math.Vector3D;
const QuaternionD = math.QuaternionD;
const plugins = lib.plugins;
const backend = lib.backend;
const ecs = lib.ecs;
const State = struct {
    world: ecs.world_t,
    scene: ecs.entity_t,
};
var state: State = undefined;
pub const Transform = struct {
    local: Matrix4D,
    world: Matrix4D,
};

fn on_init(_: *backend.AppBackend) !void {
    const world = ecs.init();
    state.world = world;
    
}
fn on_draw(_: *backend.AppBackend) void {}
fn on_deinit() !void {
    _ = ecs.fini(state.world);
}
fn on_pre_draw(_: *backend.AppBackend) void {
    // state.camera.update(app_backend);
}
fn on_post_draw(_: *backend.AppBackend) void {}
fn on_tick(_: f32) void {}
pub const plugin = plugins.Plugin{
    .name = "ecs",
    .pre_draw_fn = on_pre_draw,
    .post_draw_fn = on_post_draw,
    .tick_fn = on_tick,
    .draw_fn = on_draw,
    .init_fn = on_init,
    .cleanup_fn = on_deinit,
};
