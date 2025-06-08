const std = @import("std");
const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Matrix4D;
const Vector3D = math.Vector3D;
const QuaternionD = math.QuaternionD;
const Geometry = @import("./Geometry.zig");
const AttributeData = @import("./attribute.zig").AttributeData;
const sizeOfVertexFormat = @import("./attribute.zig").sizeOfVertexFormat;

const GeometryAttribute = struct {
    data: AttributeData,
    name: []const u8,
};
const Self = @This();
attributes: std.ArrayList(GeometryAttribute),
primitiveTopology: wgpu.PrimitiveTopology = wgpu.PrimitiveTopology.triangle_list,
index: std.ArrayList(u32),

pub fn new() *Self {
    const allocator = lib.mem.getAllocator();
    const self = allocator.create(Self) catch unreachable;
    self.* = .{
        .index = std.ArrayList(u32).init(allocator),
        .attributes = std.ArrayList(GeometryAttribute).init(allocator),
    };
    return self;
}
pub fn deinit(self: *Self) void {
    self.index.deinit();
    for (self.attributes.items) |attribute| {
        attribute.data.deinit();
    }
    self.attributes.deinit();
    lib.mem.getAllocator().destroy(self);
}
pub fn finish(self: *Self) ?Geometry {
    defer self.deinit();
    if (self.attributes.items.len == 0) {
        @panic("geometry has no attribute");
    }
    const allocator = lib.mem.getAllocator();
    var attributes = std.ArrayList(wgpu.VertexAttribute).initCapacity(allocator, self.attributes.items.len) catch unreachable;
    defer attributes.deinit();
    var byte_length: usize = 0;
    var offset: u64 = 0;
    const vertex_count = self.attributes.items[0].data.len();
    for (self.attributes.items, 0..) |attribute, i| {
        const format = attribute.data.format();
        attributes.appendAssumeCapacity(.{ .format = format, .shader_location = @intCast(i), .offset = offset });
        const size = sizeOfVertexFormat(format);
        offset += size;
        byte_length += vertex_count * size;
        if (attribute.data.len() != vertex_count) {
            @panic("All attributes must have the same number.\n");
        }
    }
    const buffer = allocator.alloc(u8, byte_length) catch unreachable;
    defer allocator.free(buffer);
    var byte_offset: usize = 0;
    for (0..vertex_count) |vertex_index| {
        for (self.attributes.items) |attribute| {
            attribute.data.write(buffer, vertex_index, &byte_offset);
        }
    }
    var geometry = Geometry.new(attributes.items);
    geometry.setVertexDataBySliceU8(buffer);
    geometry.setIndexData(u32, self.index.items);
    geometry.primitiveTopology = self.primitiveTopology;
    return geometry;
}

pub fn setAttribute(self: *Self, name: []const u8, data: AttributeData) void {
    var exist = false;
    for (self.attributes.items) |item| {
        if (std.mem.eql(u8, item.name, name)) {
            exist = true;
            break;
        }
    }
    if (exist) {
        @panic("attribute is existed");
    }
    self.attributes.append(.{ .name = name, .data = data }) catch unreachable;
}
pub fn setAttributeBySlice(self: *Self, name: []const u8, comptime T: type, slice: []const T, norm: bool) void {
    self.setAttribute(name, AttributeData.fromSlice(T, slice, norm));
}
pub fn setIndexBySlice(self: *Self, index_data: []const u32) void {
    var list = std.ArrayList(u32).initCapacity(lib.mem.getAllocator(), index_data.len) catch unreachable;
    list.appendSliceAssumeCapacity(index_data);
    self.setIndex(list);
}
pub inline fn setIndex(self: *Self, index_data: std.ArrayList(u32)) void {
    self.index.deinit();
    self.index = index_data;
}
pub fn getAttribute(self: *Self, name: []const u8) ?*GeometryAttribute {
    var get_it: bool = false;
    var targetIndex: usize = 0;
    for (self.attributes.items, 0..) |item, i| {
        if (std.mem.eql(u8, item.name, name)) {
            targetIndex = i;
            get_it = true;
            break;
        }
    }
    if (get_it) {
        return &self.attributes.items[targetIndex];
    }
    return null;
}
