const std = @import("std");
const shm = @import("../lib.zig");
const sanhi = @import("sanhi");
const wgpu = sanhi.wgpu;
const Mesh = sanhi.mesh.Mesh;
const Vector3 = sanhi.math.Vector3;
const Material = sanhi.mesh.Material;
const GeometryBuilder = sanhi.mesh.GeometryBuilder;
const AttributeData = sanhi.mesh.AttributeData;
const DataSourceImpl = shm.datasource.DataSource;

pub fn subdivisionModifier(
    allocator: std.mem.Allocator,
    geometry_builder: *GeometryBuilder,
    shouldSplitTriangle: fn (*const Vector3, *const Vector3, *const Vector3) u8,
) void {
    var position = if (geometry_builder.getAttribute("position")) |position_attr| position_attr.data.float32x3 orelse unreachable;

    const uv = if (geometry_builder.getAttribute("uv")) |attr| &attr.data.float32x2 orelse undefined;

    const edge = if (geometry_builder.getAttribute("edge")) |attr| &attr.data.float32 orelse undefined;

    const wall = if (geometry_builder.getAttribute("wall")) |attr| &attr.data.float32 orelse undefined;

    var indices = geometry_builder.index;

    var cache = std.AutoHashMap(u64, usize).init(std.heap.page_allocator);
    defer cache.deinit();

    const MiddleVertexContext = struct {
        position: *std.ArrayList([3]f32),
        uv: ?*std.ArrayList([2]f32),
        edge: ?*std.ArrayList(f32),
        wall: ?*std.ArrayList(f32),
        cache: *std.AutoHashMap(u64, usize),

        fn middleVertex(self: *@This(), i: usize, j: usize) !usize {
            const key = @min(i, j) | (@max(i, j) << 32);
            if (self.cache.get(key)) |index| {
                return index;
            }

            const index = self.position.len / 3;
            self.position.appendSlice(&[_]f32{
                (self.position[i * 3 + 0] + self.position[j * 3 + 0]) / 2,
                (self.position[i * 3 + 1] + self.position[j * 3 + 1]) / 2,
                (self.position[i * 3 + 2] + self.position[j * 3 + 2]) / 2,
            }) catch unreachable;
            self.cache.put(key, index) catch unreachable;

            if (self.uv) |uvAttr| {
                uvAttr.appendSlice(&[_]f32{
                    (uvAttr[i * 2 + 0] + uvAttr[j * 2 + 0]) / 2,
                    (uvAttr[i * 2 + 1] + uvAttr[j * 2 + 1]) / 2,
                }) catch unreachable;
            }

            if (self.edge) |edgeAttr| {
                if (edgeAttr[i] == j) {
                    edgeAttr.append(j) catch unreachable;
                } else if (edgeAttr[j] == i) {
                    edgeAttr.append(i) catch unreachable;
                    edgeAttr.items[j] = index;
                } else {
                    edgeAttr.append(-1) catch unreachable;
                }
            }
            if (self.wall) |wallAttr| {
                if (wallAttr[i] == j) {
                    wallAttr.append(j) catch unreachable;
                } else if (wallAttr[j] == i) {
                    wallAttr.append(i) catch unreachable;
                    wallAttr.items[j] = index;
                } else {
                    wallAttr.append(-1) catch unreachable;
                }
            }
            return index;
        }
    };

    var context = MiddleVertexContext{
        .position = &position,
        .uv = uv,
        .edge = edge,
        .wall = wall,
        .cache = &cache,
    };

    var newIndices = std.ArrayList(u32).init(allocator);
    defer newIndices.deinit();

    while (indices.len >= 3) {
        const v0 = indices.orderedRemove(0);
        const v1 = indices.orderedRemove(0);
        const v2 = indices.orderedRemove(0);

        const tmpVectorA = Vector3.new(position.items[v0 * 3], position.items[v0 * 3 + 1], position.items[v0 * 3 + 2]);
        const tmpVectorB = Vector3.new(position.items[v1 * 3], position.items[v1 * 3 + 1], position.items[v1 * 3 + 2]);
        const tmpVectorC = Vector3.new(position.items[v2 * 3], position.items[v2 * 3 + 1], position.items[v2 * 3 + 2]);

        switch (shouldSplitTriangle(&tmpVectorA, &tmpVectorB, &tmpVectorC)) {
            0 => {
                const v3 = context.middleVertex(v0, v1);
                indices.appendSlice(&.{ v0, v3, v2, v3, v1, v2 }) catch unreachable;
            },
            1 => {
                const v3 = context.middleVertex(v1, v2);
                indices.appendSlice(&.{ v0, v1, v3, v0, v3, v2 }) catch unreachable;
            },
            2 => {
                const v3 = context.middleVertex(v2, v0);
                indices.appendSlice(&.{ v0, v1, v3, v3, v1, v2 }) catch unreachable;
            },
            3 => {//undefined
                newIndices.appendSlice(&.{ v0, v1, v2 }) catch unreachable;
            },
            else => {
                @panic("failed to subdivide the given geometry");
            },
        }
    }
    geometry_builder.setIndex(newIndices);
}
