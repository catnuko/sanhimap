const std = @import("std");
const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Matrix4D;
const Vector3D = math.Vector3D;
const QuaternionD = math.QuaternionD;
const Geometry = @import("./Geometry.zig");

attributes: []const wgpu.VertexAttribute,
primitiveTopology: wgpu.PrimitiveTopology = wgpu.PrimitiveTopology.triangle_list,
index_data: []const u8 = undefined,
index_buffer: zgpu.BufferHandle = undefined,
index_count: u32 = 0,
vertex_data: []const u8 = undefined,
vertex_buffer: zgpu.BufferHandle = undefined,
const Self = @This();
pub fn new(attributes: []const wgpu.VertexAttribute) Self {
    return .{
        .attributes = attributes,
    };
}
pub fn deinit(self: *Self) void {
    self.release();
}
pub fn release(self: *const Self) void {
    const allocator = lib.mem.getAllocator();
    allocator.free(self.vertex_data);
    allocator.free(self.index_data);
}
pub fn vertexBufferLayout(self: *const Self) wgpu.VertexBufferLayout {
    var array_stride: u64 = 0;
    for (self.attributes) |attribute| {
        array_stride += sizeOfVertexFormat(attribute.format);
    }
    return .{
        .array_stride = array_stride,
        .attribute_count = self.attributes.len,
        .attributes = self.attributes.ptr,
    };
}
pub fn set_vertex_data(self: *Self, comptime T: type, data: []const T) void {
    self.vertex_data = lib.utils.erase_list(lib.mem.getAllocator(), T, data);
}
pub fn set_index_data(self: *Self, comptime T: type, data: []const T) void {
    self.index_count = @intCast(data.len);
    self.index_data = lib.utils.erase_list(lib.mem.getAllocator(), T, data);
}
pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
    const vertex_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .vertex = true },
        .size = self.vertex_data.len,
    });
    gctx.queue.writeBuffer(
        gctx.lookupResource(vertex_buffer).?,
        0,
        u8,
        self.vertex_data,
    );
    const index_buf = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .index = true },
        .size = self.index_data.len,
    });
    gctx.queue.writeBuffer(gctx.lookupResource(index_buf).?, 0, u8, self.index_data);
    self.index_buffer = index_buf;
    self.vertex_buffer = vertex_buffer;
}

pub fn sizeOfVertexFormat(format: wgpu.VertexFormat) u64 {
    return switch (format) {
        .undef => 0,
        .uint8x2 => 2,
        .uint8x4 => 4,
        .sint8x2 => 2,
        .sint8x4 => 4,
        .unorm8x2 => 2,
        .unorm8x4 => 4,
        .snorm8x2 => 2,
        .snorm8x4 => 4,
        .uint16x2 => 4,
        .uint16x4 => 8,
        .sint16x2 => 4,
        .sint16x4 => 8,
        .unorm16x2 => 4,
        .unorm16x4 => 8,
        .snorm16x2 => 4,
        .snorm16x4 => 8,
        .float16x2 => 2,
        .float16x4 => 8,
        .float32 => 4,
        .float32x2 => 8,
        .float32x3 => 12,
        .float32x4 => 16,
        .uint32 => 4,
        .uint32x2 => 8,
        .uint32x3 => 12,
        .uint32x4 => 16,
        .sint32 => 4,
        .sint32x2 => 8,
        .sint32x3 => 12,
        .sint32x4 => 16,
    };
}
