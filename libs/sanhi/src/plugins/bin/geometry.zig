const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
const scene = @import("./scene.zig");

pub const Geometry = struct {
    vertices: std.ArrayList(f32),
    indices: std.ArrayList(f32),
    normals: ?std.ArrayList(f32) = null,
    uvs: ?std.ArrayList(f32) = null,
    pub const name = "render.Geometry";
};
pub const GpuGeometry = struct {
    vertices: sg.Buffer,
    indices: sg.Buffer,
    normals: ?sg.Buffer = null,
    Uvs: ?sg.Buffer = null,
    pub const name = "render.GpuGeometry";
};
pub const extract_geometry_name = "render.extract_geometry";
pub fn extract_geometry(it: *ecs.iter_t) void {
    const geometryCols = ecs.field(it, Geometry, 0).?;
    for (0..it.count()) |i| {
        const geometry = geometryCols[i];
    }
}
pub fn init_component(world: *ecs.world_t) void {
    ecs.COMPONENT_WITH_NAME(world, Indices, Indices.name);
    ecs.COMPONENT_WITH_NAME(world, Vertices, Vertices.name);
    ecs.COMPONENT_WITH_NAME(world, Normals, Normals.name);
    ecs.COMPONENT_WITH_NAME(world, Uvs, Uvs.name);
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = geometry;
        system_desc.query.expr =
            \\render.Geometry,
        ;
        _ = ecs.SYSTEM(world, extract_geometry_name, ecs.OnUpdate, &system_desc);
    }
}
