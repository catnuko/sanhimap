const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const attr = @import("./attribute.zig");
const VertexAttribute = attr.VertexAttribute;
const Attribute = attr.Attribute;
const AttributeData = attr.AttributeData;
pub fn Geometry(comptime Vertex: type) type {
    return struct {
        const Attributes = lib.StringHashMap(VertexAttribute);
        attributes: Attributes,
        indices: lib.ArrayList(u32) = undefined,
        primitiveTopology: wgpu.PrimitiveTopology,
        vertex_buffer: zgpu.BufferHandle = undefined,
        index_buffer: zgpu.BufferHandle = undefined,
        vertextAttributes: []wgpu.VertexAttribute = undefined,
        const Self = @This();
        pub fn new(primitiveTopology: wgpu.PrimitiveTopology) Self {
            const alloc = lib.mem.getAllocator();
            return .{
                .attributes = Attributes.init(alloc),
                .primitiveTopology = primitiveTopology,
            };
        }
        pub fn deinit(self: *Self) void {
            var iter = self.attributes.iterator();
            while (iter.next()) |entry| {
                entry.value_ptr.data.deinit();
            }
            self.attributes.deinit();
            self.indices.deinit();
            const alloc = lib.mem.getAllocator();
            alloc.free(self.vertextAttributes);
        }
        pub inline fn addAttribute(self: *Self, attribute: Attribute, data: AttributeData) void {
            return self.attributes.put(
                attribute.name,
                VertexAttribute{ .attribute = attribute, .data = data },
            ) catch unreachable;
        }
        pub inline fn getAttribute(self: *const Self, name: []const u8) ?*VertexAttribute {
            return self.attributes.getPtr(name);
        }
        pub inline fn removeAttribute(self: *Self, name: []const u8) bool {
            return self.attributes.remove(name);
        }
        pub inline fn hasAttribute(self: *const Self, name: []const u8) bool {
            if (self.attributes.get(name)) |_| {
                return true;
            } else {
                return false;
            }
        }
        pub fn vertexBufferLayout(self: *Self) wgpu.VertexBufferLayout {
            const alloc = lib.mem.getAllocator();
            var arr = lib.ArrayList(wgpu.VertexAttribute).init(alloc);
            defer arr.deinit();
            var array_stride: u64 = 0;
            var iter = self.attributes.iterator();
            var shader_location: u32 = 0;
            var offset: u64 = 0;
            while (iter.next()) |entry| {
                const attribute = entry.value_ptr.attribute;
                arr.append(.{ .format = attribute.format, .shader_location = shader_location, .offset = offset }) catch unreachable;
                offset = attribute.getSize();
                array_stride += offset;
                shader_location += 1;
            }
            const vertextAttributes = arr.toOwnedSlice() catch unreachable;
            const vertextBufferLayout: wgpu.VertexBufferLayout = .{
                .array_stride = array_stride,
                .attribute_count = vertextAttributes.len,
                .attributes = vertextAttributes.ptr,
            };
            self.vertextAttributes = vertextAttributes;
            return vertextBufferLayout;
        }
        fn computeNumberOfVertices(self: *const Self) u64 {
            var iter = self.attributes.iterator();
            var numberOfVertices: u64 = 0;
            while (iter.next()) |entry| {
                const data = entry.value_ptr.data;
                const num = data.len();
                if (numberOfVertices != num and numberOfVertices != 0) {
                    lib.print("All attribute lists must have the same number of attributes.\n", .{});
                    return 0;
                }
                numberOfVertices = num;
            }
            return numberOfVertices;
            // return 3;
        }
        pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
            // Create a vertex buffer.
            const total_num_vertices = self.computeNumberOfVertices();
            const vertex_buf = gctx.createBuffer(.{
                .usage = .{ .copy_dst = true, .vertex = true },
                .size = total_num_vertices * @sizeOf(Vertex),
            });
            const alloc = lib.mem.getAllocator();
            {
                var vertex_data = lib.ArrayList(Vertex).init(alloc);
                defer vertex_data.deinit();
                vertex_data.resize(total_num_vertices) catch unreachable;
                Vertex.write(&vertex_data, self, total_num_vertices);
                gctx.queue.writeBuffer(gctx.lookupResource(vertex_buf).?, 0, Vertex, vertex_data.items);
            }
            const total_num_indices = self.indices.items.len;
            const index_buf = gctx.createBuffer(.{
                .usage = .{ .copy_dst = true, .index = true },
                .size = total_num_indices * @sizeOf(u32),
            });
            gctx.queue.writeBuffer(gctx.lookupResource(index_buf).?, 0, u32, self.indices.items);
            self.vertex_buffer = vertex_buf;
            self.index_buffer = index_buf;
        }
    };
}
