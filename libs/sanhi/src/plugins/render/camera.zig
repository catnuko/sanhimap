const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
const zmesh = sanhi.zmesh;
const draw = @import("./draw.zig");
const mesh = @import("./mesh.zig");
const Transform = @import("./transform.zig").Transform;
pub const Camera = struct {
    fov: f32 = 0,
    near: f32 = 0,
    far: f32 = 0,
    aspect: f32 = 0,
    projection: math.Mat4f = math.Mat4f.identity(),
    pub const name = "render.Camera";
    pub fn init(fov: f32, aspect: f32, near: f32, far: f32) Camera {
        const projection = math.Mat4f.perspective(fov, aspect, near, far);
        return Camera{
            .fov = fov,
            .aspect = aspect,
            .near = near,
            .far = far,
            .projection = projection,
        };
    }
};
pub fn init_com(world: *ecs.world_t) void {
    ecs.COMPONENT_WITH_NAME(world, Camera, Camera.name);
}
pub fn init_sys(world: *ecs.world_t) void {
    _ = world;
    // {
    //     var system_desc = ecs.system_desc_t{};
    //     system_desc.callback = generate_geometry_buffer;
    //     system_desc.query.expr =
    //         \\render.Geometry,
    //     ;
    //     _ = ecs.OBSERVER(world, generate_geometry_buffer_name, ecs.OnSet, &system_desc);
    // }
}
