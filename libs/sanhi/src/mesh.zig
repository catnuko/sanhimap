const lib = @import("./lib.zig");
const wgpu = lib.wgpu;
pub const Mesh = struct {
    geometry: Geometry,
    const Self = @This();
    pub fn new(geometry: Geometry) Self {
        return .{ .geometry = geometry };
    }
};
pub const Attribute = struct {
    name: []const u8,
    attribute: wgpu.VertexAttribute,
    pub fn new(
        namev: []const u8,
        location: u32,
        offset: u64,
        format: wgpu.VertexFormat,
    ) Attribute {
        return .{
            .name = namev,
            .attribute = .{
                .shader_location = location,
                .offset = offset,
                .format = format,
            },
        };
    }
};
pub const ATTRIBUTE_POSITION: Attribute =
    Attribute.new("Vertex_Position", 0, 0, wgpu.VertexFormat.Float32x3);
pub const ATTRIBUTE_NORMAL: Attribute =
    Attribute.new("Vertex_Normal", 1, 0, wgpu.VertexFormat.Float32x3);
pub const ATTRIBUTE_UV_0: Attribute =
    Attribute.new("Vertex_Uv", 2, 0, wgpu.VertexFormat.Float32x2);
pub const ATTRIBUTE_TANGENT: Attribute =
    Attribute.new("Vertex_Tangent", 3, 0, wgpu.VertexFormat.Float32x4);
pub const ATTRIBUTE_COLOR: Attribute =
    Attribute.new("Vertex_Color", 4, 0, wgpu.VertexFormat.Float32x4);
pub const ATTRIBUTE_JOINT_WEIGHT: Attribute =
    Attribute.new("Vertex_JointWeight", 5, 0, wgpu.VertexFormat.Float32x4);
pub const ATTRIBUTE_JOINT_INDEX: Attribute =
    Attribute.new("Vertex_JointIndex", 6, 0, wgpu.VertexFormat.Uint16x4);

pub const Indices = lib.ArrayList(u32);
pub const Geometry = struct {
    attributes: lib.StringHashMap(Attribute),
    indices: Indices,
    primitiveTopology: wgpu.PrimitiveTopology,
    const Self = @This();
    pub fn addAttribute(self: *Self, attribute: Attribute) !void {
        return self.attributes.put(attribute.name, attribute);
    }
    pub fn removeAttribute(self: *Self, attributeName: []const u8) bool {
        return self.attributes.remove(attributeName);
    }
};
