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
pub const Transform = struct {
    v: math.Mat4,
    pub const name = "render.Transform";
    pub fn fromTranslation(translation: *const math.Vec3) Transform {
        return .{
            .v = math.Mat4.fromTranslation(translation),
        };
    }
};
pub const Local = struct {
    pub const name = "render.Local";
};
pub const World = struct {
    pub const name = "render.World";
};
const apply_transform_name = "render.apply_transform";
fn apply_transform(it: *ecs.iter_t) callconv(.C) void {
    const self_local = ecs.field(it, Transform, 0).?;
    const self_world = ecs.field(it, Transform, 1).?;
    const parent_world = ecs.field(it, Transform, 2);

    const parentTransformCols = ecs.field(it, Transform, 1);
    var parentWorldMatrix = math.Mat4.identity();
    if (parentTransformCols) |parentTransform| {
        parentWorldMatrix = parentTransform[0].world;
    }
    for (0..it.count()) |i| {
        var transform = transformCols[i];
        transform.world = parentWorldMatrix.multiply(&transform.local);
    }
}
pub fn init_com(world: *ecs.world_t) void {
    ecs.TAG_WITH_NAME(world, Local, Local.name);
    ecs.TAG_WITH_NAME(world, World, World.name);
    ecs.COMPONENT_WITH_NAME(world, Transform, Transform.name);
}
pub fn init_sys(world: *ecs.world_t) void {
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = apply_transform;
        system_desc.query.expr =
            \\[in] (render.Local,render.Transform),
            \\[out] (render.World,render.Transform),
            \\[in] ?(render.World,render.Transform)(up|cascade),
        ;
        _ = ecs.SYSTEM(world, apply_transform_name, ecs.OnValidate, &system_desc);
    }
}
