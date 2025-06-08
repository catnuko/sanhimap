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
const z = sokol.shape;
const draw = @import("./draw.zig");
const mesh = @import("./mesh.zig");
const camera = @import("./camera.zig");
const Camera = camera.Camera;
const transform = @import("./transform.zig");
const Transform = transform.Transform;
const cube_glsl = @import("../../shaders/cube.main.zig");

pub const plugin_name = "render";
pub fn createCubeGeometry(allocator: std.mem.Allocator) mesh.Geometry {
    const positions_data = [_]f32{
        -1, 1, -1, 1, 1, -1, 1, -1, -1, -1, -1, -1,
        -1, 1, 1,  1, 1, 1,  1, -1, 1,  -1, -1, 1,
    };
    const normals_data = [_]f32{
        0,  0,  -1, 0,  0,  -1, 0,  0,  -1, 0,  0,  -1,
        0,  0,  1,  0,  0,  1,  0,  0,  1,  0,  0,  1,
        -1, 0,  0,  -1, 0,  0,  -1, 0,  0,  -1, 0,  0,
        1,  0,  0,  1,  0,  0,  1,  0,  0,  1,  0,  0,
        0,  1,  0,  0,  1,  0,  0,  1,  0,  0,  1,  0,
        0,  -1, 0,  0,  -1, 0,  0,  -1, 0,  0,  -1, 0,
    };
    const indices_data = [_]u32{
        0, 1, 2, 2, 3, 0,
        4, 5, 6, 6, 7, 4,
        0, 4, 5, 5, 1, 0,
        1, 5, 6, 6, 2, 1,
        2, 6, 7, 7, 3, 2,
        3, 7, 4, 4, 0, 3,
    };

    var positions = std.ArrayList(f32).initCapacity(allocator, positions_data.len) catch unreachable;
    var normals = std.ArrayList(f32).initCapacity(allocator, normals_data.len) catch unreachable;
    var indices = std.ArrayList(u32).initCapacity(allocator, indices_data.len) catch unreachable;

    for (0..positions_data.len) |i| {
        positions.appendAssumeCapacity(positions_data[i]);
        normals.appendAssumeCapacity(normals_data[i]);
    }
    for (indices_data) |index| {
        indices.appendAssumeCapacity(index);
    }

    return mesh.Geometry{
        .positions = positions,
        .normals = normals,
        .indices = indices,
    };
}

fn module(world: *ecs.world_t) callconv(.C) void {
    var desc = ecs.component_desc_t{ .entity = 0, .type = .{ .size = 0, .alignment = 0 } };
    _ = ecs.module_init(world, plugin_name, &desc);
    draw.init_com(world);
    transform.init_com(world);
    mesh.init_com(world);
    camera.init_com(world);

    transform.init_sys(world);
    mesh.init_sys(world);
    camera.init_sys(world);
    draw.init_sys(world);

    _ = ecs.set(world, ecs.id(Camera), Camera, Camera.init(std.math.pi / 3.0, 900.0 / 900.0, 0.1, 10000));
    const cameraMatrix = math.Mat4f.lookAt(&math.vec3f(0, -50, 0), &math.vec3f(0, 0, 0), &math.vec3f(0, 0, 1));
    _ = ecs.set(world, ecs.id(Camera), Transform, Transform{ .local = cameraMatrix, .world = cameraMatrix });
    // const geometry = createCubeGeometry(sanhi.mem.getAllocator());
    zmesh.init(sanhi.mem.getAllocator());
    defer zmesh.deinit();
    var shape = zmesh.Shape.initCube();
    defer shape.deinit();
    shape.translate(-0.5, -0.5, -0.5);
    // shape.scale(2.0, 2.0, 2.0);
    // shape.rotate(45.0 * std.math.pi / 180.0, 0, 0, 1);
    // shape.unweld();
    shape.computeNormals();
    const vertex_length = shape.positions.len;
    var positions = std.ArrayList(f32).initCapacity(sanhi.mem.getAllocator(), vertex_length * 3) catch unreachable;
    var normals = std.ArrayList(f32).initCapacity(sanhi.mem.getAllocator(), vertex_length * 3) catch unreachable;
    var indices = std.ArrayList(u32).initCapacity(sanhi.mem.getAllocator(), shape.indices.len) catch unreachable;

    for (0..vertex_length) |i| {
        const position = shape.positions[i];
        const normal = shape.normals.?[i];
        positions.appendAssumeCapacity(position[0]);
        positions.appendAssumeCapacity(position[1]);
        positions.appendAssumeCapacity(position[2]);
        normals.appendAssumeCapacity(normal[0]);
        normals.appendAssumeCapacity(normal[1]);
        normals.appendAssumeCapacity(normal[2]);
    }
    for (0..shape.indices.len) |i| {
        indices.appendAssumeCapacity(shape.indices[i]);
    }
    const geometry = mesh.Geometry{
        .positions = positions,
        .normals = normals,
        .indices = indices,
    };
    const material = mesh.Material{
        .shader_desc = cube_glsl.cubeShaderDesc(sg.queryBackend()),
    };
    const cube = ecs.new_entity(world, "cube");
    _ = ecs.set(world, cube, mesh.Geometry, geometry);
    _ = ecs.set(world, cube, mesh.Material, material);
    _ = ecs.set(
        world,
        cube,
        transform.Transform,
        transform.Transform.fromTranslation(&math.vec3f(0, 0, 0)),
    );
}

fn build(app: *sanhi.app.App) void {
    _ = ecs.import_c(app.world, module, plugin_name);
}
pub const plugin = sanhi.app.Plugin{
    .name = plugin_name,
    .build = build,
};
fn createSphere() void {}

fn createCube() void {
    // const positions = [_]f32{
    //     -1, 1,  -1,
    //     1,  1,  -1,
    //     1,  -1, -1,
    //     -1, -1, -1,

    //     -1, 1,  1,
    //     1,  1,  1,
    //     1,  -1, 1,
    //     -1, -1, 1,
    // };
    // const normals = [_]f32{
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    //     0, 0, 0,
    // };
    // const uvs = [_]f32{
    //     0, 0,
    //     0, 0,
    //     0, 0,
    //     0, 0,
    //     0, 0,
    //     0, 0,
    //     0, 0,
    //     0, 0,
    // };
    // const indices = [_]u32{
    //     0, 1, 1, 2, 2, 3, 3, 0,
    //     4, 5, 5, 6, 6, 7, 7, 4,
    //     0, 4, 1, 5, 2, 6, 3, 7,
    // };
    // var positions_arr = std.ArrayList(math.Vec3f).initCapacity(sanhi.mem.getAllocator(), 8) catch unreachable;
    // var normals_arr = std.ArrayList(math.Vec3f).initCapacity(sanhi.mem.getAllocator(), 8) catch unreachable;
    // var uvs_arr = std.ArrayList(math.Vec2f).initCapacity(sanhi.mem.getAllocator(), 8) catch unreachable;
    // const buffer_cloned = sanhi.mem.getAllocator().alloc(u32, indices.len) catch unreachable;
    // @memcpy(buffer_cloned[0..], indices[0..indices.len]);
    // const indices_arr = std.ArrayList(u32).fromOwnedSlice(sanhi.mem.getAllocator(), buffer_cloned);
    // for (0..8) |i| {
    //     positions_arr.appendAssumeCapacity(math.vec3f(positions[i * 3 + 0], positions[i * 3 + 1], positions[i * 3 + 2]));
    //     normals_arr.appendAssumeCapacity(math.vec3f(normals[i * 3 + 0], normals[i * 3 + 1], normals[i * 3 + 2]));
    //     uvs_arr.appendAssumeCapacity(math.vec2f(uvs[i * 2 + 0], uvs[i * 2 + 0]));
    // }
}
