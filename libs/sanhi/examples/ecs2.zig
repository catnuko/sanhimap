const std = @import("std");
const sanhi = @import("sanhi");
const ecs = sanhi.ecs;
const app = sanhi.app;
const math = sanhi.math;
const Vec3 = math.Vec3f;
const Quat = math.Quatf;
const Mat4 = math.Mat4f;

pub fn main() !void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    const Defense = struct { v: f64 };
    const Health = struct { v: f64 };

    ecs.COMPONENT(world, Health);
    ecs.COMPONENT(world, Defense);

    {
        const name = ecs.get_name(world, ecs.id(Health)).?;
        const name2 = name[0..std.mem.len(name)];
        try std.testing.expect(std.mem.eql(u8, name2, "Health"));
    }
    //defense可被继承
    ecs.add_pair(world, ecs.id(Defense), ecs.OnInstantiate, ecs.Inherit);

    const spaceship = ecs.entity_init(world, &.{
        .name = "spaceship",
        .add = &.{ecs.Prefab},
    });
    _ = ecs.set(world, spaceship, Health, .{ .v = 100 });
    _ = ecs.set(world, spaceship, Defense, .{ .v = 50 });

    const inst_1 = ecs.new_w_pair(world, ecs.IsA, spaceship);
    _ = ecs.set_name(world, inst_1, "inst_1");
    {
        //从inst_1实例上获取health
        const health = ecs.get(world, inst_1, Health).?;
        try std.testing.expect(health.v == 100);
        //从prefab上获取defense
        const defense = ecs.get(world, inst_1, Defense).?;
        try std.testing.expect(defense.v == 50);
    }
    //为inst_2设置defense时覆盖继承来的defense
    const inst_2 = ecs.new_w_pair(world, ecs.IsA, spaceship);
    _ = ecs.set_name(world, inst_2, "inst_2");
    {
        _ = ecs.set(world, inst_2, Defense, Defense{ .v = 30 });
        const defense = ecs.get(world, inst_2, Defense).?;
        try std.testing.expect(defense.v == 30);
    }
    {
        //测试如何修改组件值
        const d = ecs.get_mut(world, inst_2, Defense).?;
        d.v = 40;
        const defense = ecs.get(world, inst_2, Defense).?;
        try std.testing.expect(defense.v == 40);
    }

    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = struct {
            pub fn call(it: *ecs.iter_t) callconv(.C) void {
                var def = ecs.field(it, Defense, 0).?;
                // std.debug.print("DefenseUpdate is running {}\n", .{it.count()});
                for (0..it.count()) |i| {
                    const name = ecs.get_name(it.world, it.entities()[i]).?;
                    const name2 = name[0..std.mem.len(name)];
                    if (std.mem.eql(u8, name2, "inst_1")) {
                        std.testing.expect(def[i].v == 50) catch unreachable;
                    } else if (std.mem.eql(u8, name2, "inst_2")) {
                        std.testing.expect(def[i].v == 40) catch unreachable;
                    }
                    // std.debug.print("name of entity {d} is {s}\n", .{ i, ecs.get_name(it.world, it.entities()[i]).? });
                    // std.debug.print("defense of entity {d} {s} is {d}\n", .{ i, ecs.get_name(it.world, it.entities()[i]).?, def[i].v });
                    def[i].v = 30;
                }
            }
        }.call;
        system_desc.query.expr = "ecs2.main.Defense";
        _ = ecs.SYSTEM(world, "DefenseUpdate", ecs.OnUpdate, &system_desc);
    }
    _ = ecs.progress(world, 0);
    {
        try std.testing.expect(ecs.get(world, inst_1, Defense).?.v == 30);
        try std.testing.expect(ecs.get(world, inst_2, Defense).?.v == 30);
    }

    {
        const Test = struct {
            v: f64 = 0,
            pub const name = "TestComponent";
        };
        ecs.COMPONENT_WITH_NAME(world, Test, Test.name);
        const name = ecs.get_name(world, ecs.id(Test)).?;
        const name2 = name[0..std.mem.len(name)];
        try std.testing.expect(std.mem.eql(u8, name2, Test.name));
    }
    {
        const v1 = "xiaoming";
        const str_template =
            \\name is {s}
        ;
        const fullBanner = std.fmt.comptimePrint(str_template, .{v1});
        try std.testing.expect(std.mem.eql(u8, fullBanner, "name is xiaoming"));
    }
    _ = ecs.import_c(world, module, "SimpleModule");
    {
        const name = ecs.get_name(world, ecs.id(Position)) orelse unreachable;
        std.debug.print("main:{s}\n", .{name});
    }
}
const Position = struct { x: f32, y: f32 };
const Velocity = struct { x: f32, y: f32 };
fn module(world: *ecs.world_t) callconv(.C) void {
    var desc = ecs.component_desc_t{ .entity = 0, .type = .{ .size = 0, .alignment = 0 } };
    _ = ecs.module_init(world, "SimpleModule", &desc);
    const scopeEntity = ecs.lookup(world, "SimpleModule");
    std.testing.expect(scopeEntity == ecs.get_scope(world)) catch unreachable;

    const old_name_prefix = ecs.get_world_info(world).name_prefix;

    _ = ecs.set_name_prefix(world, "SimpleModule");
    ecs.COMPONENT_WITH_NAME(world, Position, "SimpleModulePosition");

    const name = ecs.get_name(world, ecs.id(Position)) orelse unreachable;
    const name2 = name[0..std.mem.len(name)];
    std.testing.expect(std.mem.eql(u8, name2, "Position")) catch unreachable;

    _ = ecs.set_name_prefix(world, old_name_prefix);
}
