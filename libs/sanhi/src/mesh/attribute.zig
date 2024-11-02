const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
pub const AttributeData = union(enum) {
    uint8x2: lib.ArrayList([2]u8),
    uint8x4: lib.ArrayList([4]u8),
    sint8x2: lib.ArrayList([2]i8),
    sint8x4: lib.ArrayList([4]i8),
    unorm8x2: lib.ArrayList([2]u8),
    unorm8x4: lib.ArrayList([4]u8),
    snorm8x2: lib.ArrayList([2]i8),
    snorm8x4: lib.ArrayList([4]i8),
    uint16x2: lib.ArrayList([2]u16),
    uint16x4: lib.ArrayList([4]u16),
    sint16x2: lib.ArrayList([2]i16),
    sint16x4: lib.ArrayList([4]i16),
    unorm16x2: lib.ArrayList([2]u16),
    unorm16x4: lib.ArrayList([4]u16),
    snorm16x2: lib.ArrayList([2]i16),
    snorm16x4: lib.ArrayList([4]i16),
    float16x2: lib.ArrayList([2]f16),
    float16x4: lib.ArrayList([4]f16),
    float32: lib.ArrayList(f32),
    float32x2: lib.ArrayList([2]f32),
    float32x3: lib.ArrayList([3]f32),
    float32x4: lib.ArrayList([4]f32),
    uint32: lib.ArrayList(u32),
    uint32x2: lib.ArrayList([2]u32),
    uint32x3: lib.ArrayList([3]u32),
    uint32x4: lib.ArrayList([4]u32),
    sint32: lib.ArrayList(i32),
    sint32x2: lib.ArrayList([2]i32),
    sint32x3: lib.ArrayList([3]i32),
    sint32x4: lib.ArrayList([4]i32),
    pub fn deinit(self: *AttributeData) void {
        switch (self.*) {
            .uint8x2 => |v| v.deinit(),
            .uint8x4 => |v| v.deinit(),
            .sint8x2 => |v| v.deinit(),
            .sint8x4 => |v| v.deinit(),
            .unorm8x2 => |v| v.deinit(),
            .unorm8x4 => |v| v.deinit(),
            .snorm8x2 => |v| v.deinit(),
            .snorm8x4 => |v| v.deinit(),
            .uint16x2 => |v| v.deinit(),
            .uint16x4 => |v| v.deinit(),
            .sint16x2 => |v| v.deinit(),
            .sint16x4 => |v| v.deinit(),
            .unorm16x2 => |v| v.deinit(),
            .unorm16x4 => |v| v.deinit(),
            .snorm16x2 => |v| v.deinit(),
            .snorm16x4 => |v| v.deinit(),
            .float16x2 => |v| v.deinit(),
            .float16x4 => |v| v.deinit(),
            .float32 => |v| v.deinit(),
            .float32x2 => |v| v.deinit(),
            .float32x3 => |v| v.deinit(),
            .float32x4 => |v| v.deinit(),
            .uint32 => |v| v.deinit(),
            .uint32x2 => |v| v.deinit(),
            .uint32x3 => |v| v.deinit(),
            .uint32x4 => |v| v.deinit(),
            .sint32 => |v| v.deinit(),
            .sint32x2 => |v| v.deinit(),
            .sint32x3 => |v| v.deinit(),
            .sint32x4 => |v| v.deinit(),
        }
    }
    pub fn len(self: *const AttributeData) usize {
        return switch (self.*) {
            .uint8x2 => |v| v.items.len,
            .uint8x4 => |v| v.items.len,
            .sint8x2 => |v| v.items.len,
            .sint8x4 => |v| v.items.len,
            .unorm8x2 => |v| v.items.len,
            .unorm8x4 => |v| v.items.len,
            .snorm8x2 => |v| v.items.len,
            .snorm8x4 => |v| v.items.len,
            .uint16x2 => |v| v.items.len,
            .uint16x4 => |v| v.items.len,
            .sint16x2 => |v| v.items.len,
            .sint16x4 => |v| v.items.len,
            .unorm16x2 => |v| v.items.len,
            .unorm16x4 => |v| v.items.len,
            .snorm16x2 => |v| v.items.len,
            .snorm16x4 => |v| v.items.len,
            .float16x2 => |v| v.items.len,
            .float16x4 => |v| v.items.len,
            .float32 => |v| v.items.len,
            .float32x2 => |v| v.items.len,
            .float32x3 => |v| v.items.len,
            .float32x4 => |v| v.items.len,
            .uint32 => |v| v.items.len,
            .uint32x2 => |v| v.items.len,
            .uint32x3 => |v| v.items.len,
            .uint32x4 => |v| v.items.len,
            .sint32 => |v| v.items.len,
            .sint32x2 => |v| v.items.len,
            .sint32x3 => |v| v.items.len,
            .sint32x4 => |v| v.items.len,
        };
    }
};
pub const Attribute = struct {
    name: []const u8,
    shader_location: u32,
    offset: u64,
    format: wgpu.VertexFormat,
    pub fn new(
        namev: []const u8,
        shader_location: u32,
        offset: u64,
        format: wgpu.VertexFormat,
    ) Attribute {
        return .{
            .name = namev,
            .shader_location = shader_location,
            .offset = offset,
            .format = format,
        };
    }
    pub fn getSize(self: *const Attribute) u64 {
        return sizeOfVertexFormat(self.format);
    }
};
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
pub const ATTRIBUTE_POSITION: Attribute =
    Attribute.new("Vertex_Position", 0, 0, wgpu.VertexFormat.float32x3);
pub const ATTRIBUTE_NORMAL: Attribute =
    Attribute.new("Vertex_Normal", 1, 0, wgpu.VertexFormat.float32x3);
pub const ATTRIBUTE_UV_0: Attribute =
    Attribute.new("Vertex_Uv", 2, 0, wgpu.VertexFormat.float32x2);
pub const ATTRIBUTE_TANGENT: Attribute =
    Attribute.new("Vertex_Tangent", 3, 0, wgpu.VertexFormat.float32x4);
pub const ATTRIBUTE_COLOR: Attribute =
    Attribute.new("Vertex_Color", 4, 0, wgpu.VertexFormat.float32x4);
pub const ATTRIBUTE_JOINT_WEIGHT: Attribute =
    Attribute.new("Vertex_JointWeight", 5, 0, wgpu.VertexFormat.float32x4);
pub const ATTRIBUTE_JOINT_INDEX: Attribute =
    Attribute.new("Vertex_JointIndex", 6, 0, wgpu.VertexFormat.uint16x4);

pub const VertexAttribute = struct {
    attribute: Attribute,
    data: AttributeData,
};
