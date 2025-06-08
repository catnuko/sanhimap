const sanhi = @import("../../lib.zig");
const std = sanhi.std;
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
const scene = @import("./scene.zig");

/// 命名规则：
/// 1. 由两级组成，插件-标识符
/// 2. 组件的标识符用ComponentName，组件必须带有const name:[]const u8静态字段
/// 3. 系统用test_system，系统上方一行必须要有系统名字test_system_name
/// 4. Query初始化必须是render.MaterialQuery，末尾加上Query
///
/// 注意：
/// 1. 禁止设置名字前缀
pub const GeometryQuery = struct {
    component: ecs.entity_t,
    parent_query: *ecs.query_t,
    solid: *ecs.query_t,
    emissive: *ecs.query_t,
    pub const name = "render.GeometryQuery";
};
pub const GeometryBuffers = struct {
    colors_data: std.ArrayList(Rgb),
    transforms_data: std.ArrayList(math.Mat4),
    materials_data: std.ArrayList(Material),
    colors: sg.Buffer,
    transforms: sg.Buffer,
    materials: sg.Buffer,
    instance_count: i32,
};

pub const Geometry = struct {
    vertices: sg.Buffer,
    normals: sg.Buffer,
    indices: sg.Buffer,
    index_count: i32,
    solid: GeometryBuffers,
    emissive: GeometryBuffers,
    allocator: std.mem.Allocator,
    pub const name = "render.Geometry";
    pub fn dtor(self: @This()) void {
        sg.destroyBuffer(self.vertices);
        sg.destroyBuffer(self.normals);
        sg.destroyBuffer(self.vertices);
    }
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

pub const MaterialId = struct {
    v: u32,
    pub const name = "render.MaterialId";
};
pub const Material = struct {
    specular_power: f64 = 0,
    shininess: f64 = 0,
    emissive: f64 = 0,
    pub const name = "render.Material";
};
pub const SOKOL_MAX_MATERIALS = 255;
pub const Materials = struct {
    changed: bool = false,
    array: [SOKOL_MAX_MATERIALS]Material = Material{} ** SOKOL_MAX_MATERIALS,
    pub const name = "render.Materials";
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
const init_materials_name = "render.init_materials";
fn init_materials(it: *ecs.iter_t) callconv(.C) void {
    const q = ecs.field(it, Query, 0).?[0];
    const materials = ecs.field(it, Materials, 1).?[0];
    materials.changed = true;
    materials.array[0].specular_power = 0.0;
    materials.array[0].shininess = 1.0;
    materials.array[0].emissive = 0.0;

    if (!ecs.query_changed(q.query)) {
        materials.changed = false;
        return;
    }
    const qit = ecs.query_iter(it.world, q.query);
    while (ecs.query_next(qit)) {
        const mat = ecs.field(it, MaterialId, 0).?;
        const specsO = ecs.field(it, Specular, 1);
        const emO = ecs.field(it, Emissive, 2);
        if (specsO) |specs| {
            for (0..qit.count()) |i| {
                const id = mat[i].v;
                materials.array[id].specular_power = specs[i].specular_power;
                materials.array[id].shininess = specs[i].shininess;
            }
        } else {
            for (0..qit.count()) |i| {
                const id = mat[i].v;
                materials.array[id].specular_power = 0;
                materials.array[id].shininess = 1;
            }
        }
        if (emO) |em| {
            for (0..qit.count()) |i| {
                const id = mat[i].v;
                materials.array[id].emissive = em[i].v;
            }
        } else {
            for (0..qit.count()) |i| {
                const id = mat[i].v;
                materials.array[id].emissive = 0;
            }
        }
    }
}
const register_materialId_name = "register_materialId";
/// 为带有Specular或者Emissive的Entity创建一个SokolMaterialId
fn register_materialId(it: *ecs.iter_t) callconv(.C) void {
    var next_material: u32 = 1;
    for (0..it.count()) |i| {
        ecs.set(it.world, it.entities()[i], MaterialId, MaterialId{ .v = next_material });
        next_material += 1;
    }
}

const create_geometry_query_name = "render.create_geometry_query";
/// 查询到Geomety和GeometryQuery组件后创建一个查询，查询内容是
/// Transform3,Rgb,Material,query,Emissive,Position3,并将其写入GeometryQuery
fn create_geometry_query(it: *ecs.iter_t) callconv(.C) void {
    const world = it.world;
    const gq = ecs.field(it, GeometryQuery, 1).?[0];
    for (0..it.count()) |i| {
        var desc = ecs.query_desc_t{};
        desc.terms[0] = ecs.term_t{
            .id = ecs.id(Transform3),
            .src = .{ .id = ecs.Self },
            .inout = ecs.inout_kind_t.In,
        };
        desc.terms[1] = ecs.term_t{
            .id = ecs.id(Rgb),
            .inout = ecs.inout_kind_t.In,
        };
        desc.terms[2] = ecs.term_t{
            .id = ecs.id(Material),
            .src = .{ .id = ecs.Up },
            .trav = ecs.IsA,
            .oper = ecs.oper_kind_t.Optional,
            .inout = ecs.inout_kind_t.In,
        };
        desc.terms[3] = ecs.term_t{
            .id = gq[i].component,
            .inout = ecs.inout_kind_t.In,
        };
        desc.terms[4] = ecs.term_t{
            .id = ecs.id(Emissive),
            .oper = ecs.oper_kind_t.Not,
            .inout = ecs.inout_kind_t.InOutNone,
        };
        desc.terms[5] = ecs.term_t{
            .id = ecs.id(Posiiton3),
            .src = .{ .id = ecs.Self },
            .inout = ecs.inout_kind_t.InOutNone,
        };
        desc.flags = ecs.EcsIterIsInstanced;
        desc.cache_kind = ecs.query_cache_kind_t.QueryCacheAuto;

        desc.entity = ecs.entity_init(
            world,
            &.{
                .name = ecs.get_name(world, gq[i].component),
                .parent = ecs.new_entity(world, "render.geometrySolidQuery"),
            },
        );
        gq[i].solid = try ecs.query_init(world, &desc) catch {
            const component_str = ecs.id_str(world, gq[i].component);
            std.debug.print("sokol: failed to create query for solid {s} geometry\n", .{component_str});
            ecs.os.free(component_str);
        };

        desc.entity = ecs.entity_init(
            world,
            &.{
                .name = ecs.get_name(world, gq[i].component),
                .parent = ecs.new_entity(world, "render.geometryEmissiveQuery"),
            },
        );
        desc.terms[4].oper = 0;
        gq[i].emissive = try ecs.query_init(world, &desc) catch {
            const component_str = ecs.id_str(world, gq[i].component);
            std.debug.print("sokol: failed to create query for emissive {s} geometry\n", .{component_str});
            ecs.os.free(component_str);
        };
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
    //material
    ecs.COMPONENT_WITH_NAME(world, Material, Material.name);
    ecs.COMPONENT_WITH_NAME(world, MaterialId, MaterialId.name);
    ecs.COMPONENT_WITH_NAME(world, Materials, Materials.name);
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = register_materialId;
        system_desc.query.expr =
            \\[out] !render.MaterialId(self),
            \\[in]   render.Specular(self) || render.Emissive(self),
            \\      ?Prefab
        ;
        _ = ecs.SYSTEM(world, register_materialId_name, ecs.PostLoad, &system_desc);
    }
    {
        //用带有MaterialId的Material填充Materials中的数组
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = init_materials;
        system_desc.query.expr =
            \\[in]  render.Query(render.init_materials, render.Materials),
            \\[out] render.Materials,
        ;
        const sys_entity = ecs.SYSTEM(world, init_materials_name, ecs.OnLoad, &system_desc);
        //为init_materials系统设置一个查询，查询的是Specular和Emissive组件
        const query_desc = ecs.query_desc_t{
            .entity = ecs.new_entity(world, "render.materialsQuery"),
            .expr =
            \\[in] render.MaterialId(self),
            \\[in] ?render.Specular(self),
            \\[in] ?render.Emissive(self),
            \\     ?Prefab
            ,
            .cache_kind = ecs.query_cache_kind_t.QueryCacheAuto,
        };
        ecs.set_pair(
            world,
            sys_entity,
            Query,
            Query{ .query = ecs.query_init(world, &query_desc) },
        );
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

    {
        var observer_desc = ecs.observer_desc_t{};
        observer_desc.callback = create_geometry_query;
        observer_desc.query.expr = "render.Geometry,render.GeometryQuery";
        _ = ecs.OBSERVER(world, create_geometry_query_name, ecs.OnSet, observer_desc);
    }
}
