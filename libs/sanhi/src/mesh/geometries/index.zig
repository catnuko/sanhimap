const lib = @import("../../lib.zig");
const zmesh = lib.zmesh;
const wgpu = lib.wgpu;
const mesh = @import("../index.zig");
const Mesh = mesh.Mesh;
const Geometry = mesh.Geometry;
const Material = mesh.Material;

pub fn init_sphere_geometry(slices: i32, stacks: i32) Geometry {
    var geometry = Geometry.new(
        &[_]wgpu.VertexAttribute{
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 0, .offset = 0 },
            .{ .format = wgpu.VertexFormat.float32x2, .shader_location = 1, .offset = 12 },
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 2, .offset = 20 },
        },
    );
    const shape = zmesh.Shape.initParametricSphere(slices, stacks);
    defer shape.deinit();
    const vertex_length = shape.positions.len;
    var buffer = lib.ArrayList(f32).initCapacity(lib.mem.getAllocator(), vertex_length * 8) catch unreachable;
    defer buffer.deinit();
    for (0..vertex_length) |i| {
        const position = shape.positions[i];
        const normal = shape.normals.?[i];
        const texcoord = shape.texcoords.?[i];
        buffer.appendAssumeCapacity(position[0]);
        buffer.appendAssumeCapacity(position[1]);
        buffer.appendAssumeCapacity(position[2]);
        buffer.appendAssumeCapacity(texcoord[0]);
        buffer.appendAssumeCapacity(texcoord[1]);
        buffer.appendAssumeCapacity(normal[0]);
        buffer.appendAssumeCapacity(normal[1]);
        buffer.appendAssumeCapacity(normal[2]);
    }
    geometry.set_vertex_data(f32, buffer.items);
    geometry.set_index_data(u32, shape.indices);
    return geometry;
}

pub fn init_axes_geometry(size: f32) Geometry {
    var geometry = Geometry.new(
        &[_]wgpu.VertexAttribute{
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 0, .offset = 0 },
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 1, .offset = 12 },
        },
    );
    geometry.primitiveTopology = wgpu.PrimitiveTopology.line_list;
    const Vertex = struct {
        position: [3]f32,
        color: [3]f32,
    };
    const vertices = [_]Vertex{
        .{ .position = .{ 0, 0, 0 }, .color = .{ 1, 0, 0 } },
        .{ .position = .{ size, 0, 0 }, .color = .{ 1, 0, 0 } },
        .{ .position = .{ 0, 0, 0 }, .color = .{0, 1, 0 } },
        .{ .position = .{ 0, size, 0  }, .color = .{0, 1, 0 } },
        .{ .position = .{ 0, 0, 0 }, .color = .{ 0, 0, 1 } },
        .{ .position = .{ 0, 0, size }, .color = .{ 0, 0, 1 } },
    };
    geometry.set_vertex_data(Vertex, &vertices);
    const indices = [_]u32{ 0, 1, 2, 3, 4, 5 };
    geometry.set_index_data(u32, &indices);
    return geometry;
}

pub fn init_grid_geometry(size: f32) Geometry {
    const divisions = size;
    const center = divisions / 2;
    const step = size / divisions;
    const halfSize = size / 2;
    var i: f32 = 0;
    var k = -halfSize;
    const allocator = lib.mem.getAllocator();
    const vertex_count: u32 = @intFromFloat((divisions + 1) * 4);
    var buffer = lib.ArrayList(f32).initCapacity(allocator, vertex_count * 6) catch unreachable;
    defer buffer.deinit();
    const color1 = [3]f32{ 68, 68, 68 };
    const color2 = [3]f32{ 136, 136, 136 };
    const indices = allocator.alloc(u32, vertex_count) catch unreachable;
    defer allocator.free(indices);
    while (i <= divisions) {
        var color: [3]f32 = undefined;
        if (i == center) {
            color = color1;
        } else {
            color = color2;
        }
        buffer.appendSliceAssumeCapacity(&[_]f32{ -halfSize, 0, k });
        buffer.appendSliceAssumeCapacity(&color);
        buffer.appendSliceAssumeCapacity(&[_]f32{ halfSize, 0, k });
        buffer.appendSliceAssumeCapacity(&color);
        buffer.appendSliceAssumeCapacity(&[_]f32{ k, 0, -halfSize });
        buffer.appendSliceAssumeCapacity(&color);
        buffer.appendSliceAssumeCapacity(&[_]f32{ k, 0, halfSize });
        buffer.appendSliceAssumeCapacity(&color);
        const i_u32: u32 = @intFromFloat(i * 4);
        indices[i_u32] = i_u32;
        indices[i_u32 + 1] = i_u32 + 1;
        indices[i_u32 + 2] = i_u32 + 2;
        indices[i_u32 + 3] = i_u32 + 3;
        i += 1;
        k += step;
    }
    var geometry = Geometry.new(
        &[_]wgpu.VertexAttribute{
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 0, .offset = 0 },
            .{ .format = wgpu.VertexFormat.float32x3, .shader_location = 1, .offset = 12 },
        },
    );
    geometry.primitiveTopology = wgpu.PrimitiveTopology.line_list;
    geometry.set_vertex_data(f32, buffer.items);
    geometry.set_index_data(u32, indices);
    return geometry;
}
