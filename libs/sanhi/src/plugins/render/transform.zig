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
    local: math.Mat4f = math.Mat4f.identity(),
    world: math.Mat4f = math.Mat4f.identity(),
    pub const name = "render.Transform";
    pub fn fromTranslation(translation: *const math.Vec3f) Transform {
        return .{
            .local = math.Mat4f.fromTranslation(translation),
        };
    }
};
const apply_transform_name = "render.apply_transform";
fn apply_transform(it: *ecs.iter_t) callconv(.C) void {
    const transformCols = ecs.field(it, Transform, 0).?;
    const parentTransformCols = ecs.field(it, Transform, 1);
    var parentWorldMatrix = math.Mat4f.identity();
    if (parentTransformCols) |parentTransform| {
        parentWorldMatrix = parentTransform[0].world;
    } else {
        // std.debug.print("{s}\n", .{ecs.get_name(it.world, it.entities()[0]).?});
    }
    for (0..it.count()) |i| {
        var transform = transformCols[i];
        transform.world = parentWorldMatrix.multiply(&transform.local);
    }
}
pub fn init_com(world: *ecs.world_t) void {
    ecs.COMPONENT_WITH_NAME(world, Transform, Transform.name);
}
pub fn init_sys(world: *ecs.world_t) void {
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = apply_transform;
        system_desc.query.expr =
            \\[out] render.Transform,
            \\[in] ?render.Transform(up|cascade),
        ;
        _ = ecs.SYSTEM(world, apply_transform_name, ecs.OnValidate, &system_desc);
    }
}
