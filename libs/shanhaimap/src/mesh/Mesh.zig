const StringHashMap = @import("std").StringHashMap;
const mem = @import("std").mem;
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
pub const Mesh = struct {
    pub const Attributes = StringHashMap(MeshAttribute);
    primitiveoTpology: wgpu.PrimitiveTopology,
    attributes: Attributes,
    indices: ?Indices = null,
    const Self = @This();
    pub fn new(allocator: mem.Allocator, primitiveoTpologyv: wgpu.PrimitiveTopology) Self {
        return Self{
            .attributes = Attributes.init(allocator),
            .primitiveoTpology = primitiveoTpologyv,
            .indices = null,
        };
    }
    pub inline fn insertAttribute(self: *Self, attribute: MeshAttribute) void {
        try self.attributes.put(attribute.name, attribute);
    }
    pub inline fn removeAttribute(self: *Self, name: []const u8) bool {
        return self.attributes.remove(name);
    }
    pub inline fn containAttribute(self: *const Self, name: []const u8) bool {
        return self.attributes.contains(name);
    }
    pub inline fn setIndices(self: *Self, indices: Indices) void {
        self.indices = indices;
    }
    pub fn deinit(self: *Self) void {
        self.attributes.deinit();
    }
};
pub const MeshAttribute = struct {
    name: []const u8,
    attribute: wgpu.VertexAttribute,
    value: ?VertexAttributeValues,
    const Self = @This();
    pub fn new(namev: []const u8, location: u32, format: wgpu.VertexFormat) Self {
        return Self{ .name = namev, .attribute = .{
            .format = format,
            .offset = 0,
            .shader_location = location,
            .value = null,
        } };
    }
    pub fn setValue(self: *Self, value: VertexAttributeValues) void {
        self.value = value;
    }
};
pub const VertexAttributeValues = union(enum) {
    Float32: []f32,
    Sint32: []i32,
    Uint32: []u32,
    Float32x2: [][2]f32,
    Sint32x2: [][2]i32,
    Uint32x2: [][2]u32,
    Float32x3: [][3]f32,
    Sint32x3: [][3]i32,
    Uint32x3: [][3]u32,
    Float32x4: [][4]f32,
    Sint32x4: [][4]i32,
    Uint32x4: [][4]u32,
    Sint16x2: [][2]i16,
    Snorm16x2: [][2]i16,
    Uint16x2: [][2]u16,
    Unorm16x2: [][2]u16,
    Sint16x4: [][4]i16,
    Snorm16x4: [][4]i16,
    Uint16x4: [][4]u16,
    Unorm16x4: [][4]u16,
    Sint8x2: [][2]i8,
    Snorm8x2: [][2]i8,
    Uint8x2: [][2]u8,
    Unorm8x2: [][2]u8,
    Sint8x4: [][4]i8,
    Snorm8x4: [][4]i8,
    Uint8x4: [][4]u8,
    Unorm8x4: [][4]u8,
};
pub const Indices = union(enum) {
    U16: []u16,
    U32: []u32,
    const Self = @This();
    pub fn len(self: *const Self) usize {
        switch (self) {
            .U16 => |v| return v.len,
            .U32 => |v| return v.len,
        }
    }
    pub fn isEmpty(self: *const Self) bool {
        return self.len() == 0;
    }
};
