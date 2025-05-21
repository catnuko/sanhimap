const std = @import("std");
const sanhi = @import("sanhi");
const ecs = sanhi.ecs;
const app = sanhi.app;
const math = sanhi.math;
const Vec3 = math.Vector3;
const Quat = math.Quaternion;
const Mat4 = math.Matrix4;
pub const LocalTransform = struct { position: Vec3, rotation: Quat, scale: Vec3 };
pub const ObjectTransform = struct {
    local: LocalTransform = LocalTransform{
        .position = Vec3.zero.clone(),
        .rotation = Quat.zero.clone(),
        .scale = Vec3.one.clone(),
    },
    world: Mat4 = Mat4.fromIdentity(),
    pub const name: []const u8 = @typeName(ObjectTransform);
};
pub fn main() !void {
    std.debug.print("local: {any}\n", .{@alignOf(ObjectTransform)});

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, ObjectTransform);

    const scene = ecs.new_entity(world, "scene");
    _ = ecs.set(world, scene, ObjectTransform, .{});

    const child1 = ecs.new_entity(world, "child1");
    _ = ecs.set(world, child1, ObjectTransform, .{});

    ecs.add_pair(world, child1, ecs.ChildOf, scene);

    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = struct {
            pub fn updateObjectTransforms(it: *ecs.iter_t) callconv(.C) void {
                const parent = ecs.field(it, ObjectTransform, 0).?;
                const objects = ecs.field(it, ObjectTransform, 1).?;
                for (0..it.count()) |i| {
                    var object = objects[i];
                    const position = object.local.position;
                    const scale = object.local.scale;
                    const rotation = object.local.rotation;
                    const s = Mat4.fromTranslationQuaternionScale(&position, &rotation, &scale);
                    object.world = Mat4.multiply(&parent[i].world, &s);
                    object.world.print();
                }
            }
        }.updateObjectTransforms;
        // system_desc.query.expr = "app.ObjectTransform(up|cascade), app.ObjectTransform";
        system_desc.query.expr = ObjectTransform.name ++ "(up|cascade), " ++ ObjectTransform.name;
        // system_desc.query.terms[0].id = ecs.id(ObjectTransform);
        // system_desc.query.terms[0].src.id = ecs.Up | ecs.Cascade;
        // system_desc.query.terms[0].trav = ecs.ChildOf; // 默认的遍历关系是 ChildOf

        // // 第二个 term: ObjectTransform
        // system_desc.query.terms[1].id = ecs.id(ObjectTransform);
        _ = ecs.SYSTEM(world, "updateObjectTransforms", ecs.OnUpdate, &system_desc);
    }

    // _ = ecs.progress(world, 0);
    // _ = ecs.progress(world, 0);
    var app_desc = sanhi.flecs_addon.ecs_app_desc_t{
        .enable_rest = true,
    };

    _ = sanhi.flecs_addon.app_run(world, &app_desc);
}
