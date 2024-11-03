const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const Geometry = @import("./Geometry.zig");
const attr = @import("./attribute.zig");
const VertexAttribute = attr.VertexAttribute;
const Attribute = attr.Attribute;
const AttributeData = attr.AttributeData;
const sizeOfVertexFormat = attr.sizeOfVertexFormat;

attributes: []const wgpu.VertexAttribute,
primitiveTopology: wgpu.PrimitiveTopology,
index_data: []const u8 = undefined,
index_buffer: zgpu.BufferHandle = undefined,
vertex_data: []const u8 = undefined,
vertex_buffer: zgpu.BufferHandle = undefined,
const Self = @This();
pub fn new(primitiveTopology: wgpu.PrimitiveTopology, attributes: []const wgpu.VertexAttribute) Self {
    return .{
        .primitiveTopology = primitiveTopology,
        .attributes = attributes,
    };
}
pub fn deinit(_: *Self) void {}
pub fn vertexBufferLayout(self: *Self) wgpu.VertexBufferLayout {
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
    const gpu_data = @as([*]const u8, @ptrCast(data.ptr));
    const size = @as(u64, @intCast(data.len)) * @sizeOf(T);
    self.vertex_data = gpu_data[0..size];
}
pub fn set_index_data(self: *Self, comptime T: type, data: []const T) void {
    const gpu_data = @as([*]const u8, @ptrCast(data.ptr));
    const size = @as(u64, @intCast(data.len)) * @sizeOf(T);
    self.index_data = gpu_data[0..size];
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
