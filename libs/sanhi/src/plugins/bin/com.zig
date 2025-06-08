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

pub const Material = struct {
    shader_desc: sg.ShaderDesc,
    layout: sg.VertexLayoutState,
    pub const name = "render.Material";
};
pub const Pipline = struct {
    pip: sg.Pipeline,
};
pub const Renderer = struct {
    bg_texture: sg.Image,
    scene_pass: scene.ScenePass,
    canvas: ecs.entity_t,
    camera: ecs.entity_t,
    pub const name = "render.Renderer";
};
pub const Canvas = struct {
    title: []const u8 = "SanHi",
    width: i32 = 0,
    height: i32 = 0,
    camera: ecs.entity_t = 0,
    pub const name = "render.Canvas";
};
pub const Query = struct {
    query: *ecs.query_t,
    pub const name = "render.Query";
};

pub const Camera = struct {
    position: math.Vec3 = math.Vec3.zero(),
    lookat: math.Vec3 = math.Vec3.zero(),
    up: math.Vec3 = math.Vec3.zero(),
    fov: f64 = 0,
    near: f64 = 0,
    far: f64 = 0,
    aspect: f64 = 0,
    pub const name = "render.Camera";
};

pub const DirectionalLight = struct {
    position: math.Vec3,
    direction: math.Vec3,
    color: math.Vec3,
    intensity: f64,
    pub const name = "render.DirectionalLight";
};
pub const LookAt = struct {
    v: math.Vec3,
    pub const name = "render.LookAt";
};
pub const Rgb = struct {
    v: math.Vec3,
    pub const name = "render.Rgb";
};
pub const Rgba = struct {
    v: math.Vec4,
    pub const name = "render.Rgba";
};
pub const Specular = struct {
    specular_power: f64,
    shininess: f64,
    pub const name = "render.Specular";
};

pub const Emissive = struct {
    v: f64,
    pub const name = "render.Emissive";
};
pub const LightIntensity = struct {
    v: f64,
    pub const name = "render.LightIntensity";
};
pub const Atmosphere = struct {
    intensity: f64,
    planet_radius: f64,
    atmosphere_radius: f64,
    rayleigh_coef: math.Vec3,
    mie_coef: f64,
    rayleigh_scale_height: f64,
    mie_scale_height: f64,
    mie_scatter_dir: f64,
    pub const name = "render.Atmosphere";
};

pub const Posiiton2 = struct {
    v: math.Vec2,
    pub const name = "render.Posiiton2";
};
pub const Posiiton3 = struct {
    v: math.Vec3,
    pub const name = "render.Posiiton3";
};

pub const Scale2 = struct {
    v: math.Vec2,
    pub const name = "render.Scale2";
};
pub const Scale3 = struct {
    v: math.Vec3,
    pub const name = "render.Scale3";
};

pub const Rotation2 = struct {
    v: f64,
    pub const name = "render.Rotation2";
};
pub const Rotation3 = struct {
    v: math.Vec3,
    pub const name = "render.Rotation3";
};
pub const Quaternion = struct {
    v: math.Vec4,
    pub const name = "render.Quaternion";
};

pub const Transform2 = struct {
    v: math.Mat3,
    pub const name = "render.Transform2";
};
pub const Transform3 = struct {
    v: math.Mat4,
    pub const name = "render.Transform3";
};

pub const Project2 = struct {
    v: math.Mat3,
    pub const name = "render.Project2";
};
pub const Project3 = struct {
    v: math.Mat4,
    pub const name = "render.Project3";
};
pub const Line2 = struct {
    start: math.Vec2,
    stop: math.Vec2,
    pub const name = "render.Line2";
};
pub const Line3 = struct {
    start: math.Vec3,
    stop: math.Vec3,
    pub const name = "render.Line3";
};
pub const Rectangle = struct {
    width: f64,
    height: f64,
    pub const name = "render.Rectangle";
};
pub const Square = struct {
    size: f64,
    pub const name = "render.Square";
};
pub const Circle = struct {
    radius: f64,
    pub const name = "render.Circle";
};
pub const Box = struct {
    width: f64,
    height: f64,
    depth: f64,
    pub const name = "render.Box";
};
pub const Mesh = struct {
    vertices: []math.Vec3,
    pub const name = "render.Mesh";
};

pub const SokolRectangleGeometry = struct {
    pub const name = "render.SokolRectangleGeometry";
};

const add_transform_name = "render.add_transform";
fn add_transform(it: *ecs.iter_t) callconv(.C) void {
    const world = it.world;
    const comp = ecs.field_id(it, 1);
    for (0..it.count()) |i| {
        ecs.add(world, it.entities()[i], comp);
    }
}

const apply_transform3_name = "render.apply_transform3";
fn apply_transform3(it: *ecs.iter_t) callconv(.C) void {
    // while (ecs.query_next_table(it)) {
    //     if (!ecs.query_changed(it)) {
    //         ecs.iter_skip(it);
    //         continue;
    //     }
    //     ecs.query_populate(it, true);
    //     const m = ecs.field(it, Transform3, 1).?;
    //     const m_parentLO = ecs.field(it, Transform3, 2);
    //     const p = ecs.field(it, Posiiton3, 3).?;
    //     const r = ecs.field(it, Rotation3, 4);
    //     const s = ecs.field(it, Scale2, 5);
    //     if (m_parentLO) |m_parentL| {
    //         const my_parent = m_parentL[0];
    //         if (ecs.field_is_self(it, 3)) {
    //             for (0..it.count()) |i| {
    //                 // m[i].v = math.Mat4.fromTranslation(&p[i].v);

    //             }
    //         } else {
    //             for (0..it.count()) |i| {
    //                 m[i].v = math.Mat4.fromTranslation(&p[0].v);
    //             }
    //         }
    //     } else {
    //         if (ecs.field_is_self(it, 3)) {
    //             for (0..it.count()) |i| {
    //                 m[i].v = math.Mat4.fromTranslation(&p[i].v);
    //             }
    //         } else {
    //             for (0..it.count()) |i| {
    //                 m[i].v = math.Mat4.fromTranslation(&p[0].v);
    //             }
    //         }
    //     }
    // }
}
const init_material_name = "render.init_material";
fn init_material(it: *ecs.iter_t) void {
    const ms = ecs.field(it, Material, 0).?;
    for (0..it.count()) |i| {
        const m = ms[i];
        const id = m.shader_desc.label;
        var pip = sg.makePipeline(.{
            .shader = sg.makeShader(m.shader_desc),
            .layout = m.layout,
            .index_type = sg.IndexType.UINT32,
            .cull_mode = sg.CullMode.BACK,
            .sample_count = 1,
            .depth = .{ .pixel_format = .DEPTH, .compare = .LESS_EQUAL, .write_enabled = true },
            .label = id,
        });
        ecs.set(world, it.entities()[i], Pipline, Pipline{ .pip = pip });
    }
}
pub fn init_component(world: *ecs.world_t) void {
    //graphics
    ecs.COMPONENT_WITH_NAME(world, DirectionalLight, DirectionalLight.name);
    ecs.COMPONENT_WITH_NAME(world, LookAt, LookAt.name);
    ecs.COMPONENT_WITH_NAME(world, Rgb, Rgb.name);
    ecs.COMPONENT_WITH_NAME(world, Rgba, Rgba.name);
    ecs.COMPONENT_WITH_NAME(world, Specular, Specular.name);
    ecs.COMPONENT_WITH_NAME(world, Emissive, Emissive.name);
    ecs.COMPONENT_WITH_NAME(world, LightIntensity, LightIntensity.name);
    ecs.COMPONENT_WITH_NAME(world, Atmosphere, Atmosphere.name);

    //transform
    ecs.COMPONENT_WITH_NAME(world, Posiiton2, Posiiton2.name);
    ecs.COMPONENT_WITH_NAME(world, Posiiton3, Posiiton3.name);
    ecs.COMPONENT_WITH_NAME(world, Scale2, Scale2.name);
    ecs.COMPONENT_WITH_NAME(world, Scale3, Scale3.name);
    ecs.COMPONENT_WITH_NAME(world, Rotation2, Rotation2.name);
    ecs.COMPONENT_WITH_NAME(world, Rotation3, Rotation3.name);
    ecs.COMPONENT_WITH_NAME(world, Quaternion, Quaternion.name);
    ecs.COMPONENT_WITH_NAME(world, Transform2, Transform2.name);
    ecs.COMPONENT_WITH_NAME(world, Transform3, Transform3.name);
    ecs.COMPONENT_WITH_NAME(world, Project2, Project2.name);
    ecs.COMPONENT_WITH_NAME(world, Project3, Project3.name);
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = add_transform;
        system_desc.query.expr =
            \\[out] !render.Transform3,
            \\[filter] render.Position3(self|up) ||
            \\[filter] render.Rotation3(self|up) || 
            \\[filter] render.Scale3(self|up))
        ;
        _ = ecs.SYSTEM(world, add_transform_name, ecs.PostLoad, &system_desc);
    }
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = apply_transform3;
        system_desc.query.expr =
            \\[out] render.Transform3,
            \\[in] ?render.Transform3(parent|cascade),
            \\[in] render.Position3(self|super),
            \\[in] ?render.Rotation3,
            \\[in] ?render.Scale3);
        ;
        _ = ecs.SYSTEM(world, apply_transform3_name, ecs.OnValidate, &system_desc);
    }
    //geometry
    ecs.COMPONENT_WITH_NAME(world, Line2, Line2.name);
    ecs.COMPONENT_WITH_NAME(world, Line3, Line3.name);
    ecs.COMPONENT_WITH_NAME(world, Rectangle, Rectangle.name);
    ecs.COMPONENT_WITH_NAME(world, Square, Square.name);
    ecs.COMPONENT_WITH_NAME(world, Circle, Circle.name);
    ecs.COMPONENT_WITH_NAME(world, Box, Box.name);
    ecs.COMPONENT_WITH_NAME(world, Mesh, Mesh.name);
    ecs.COMPONENT_WITH_NAME(world, Geometry, Geometry.name);

    //material
    // ecs.COMPONENT_WITH_NAME(world, Material, Material.name);
    // {
    //     var system_desc = ecs.system_desc_t{};
    //     system_desc.callback = init_material;
    //     system_desc.query.expr =
    //         \\render.Material
    //     ;
    //     _ = ecs.SYSTEM(world, init_material_name, ecs.PostLoad, &system_desc);
    // }
}
