const lib = @import("../lib.zig");
const mesh = @import("./index.zig");
const Mesh = mesh.Mesh;
const Geometry = mesh.Geometry;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const zgpu = lib.zgpu;
const wgsl_vs =
    \\  @group(0) @binding(0) var<uniform> object_to_clip: mat4x4<f32>;
    \\  struct VertexOut {
    \\      @builtin(position) position_clip: vec4<f32>,
    \\      @location(0) color: vec4<f32>,
    \\  }
    \\  @vertex fn vsMain(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) color: vec4<f32>,
    \\  ) -> VertexOut {
    \\      var output: VertexOut;
    \\      output.position_clip = object_to_clip * vec4(position, 1.0);
    \\      output.color = color;
    \\      return output;
    \\  }
;
const wgsl_fs =
    \\  @fragment fn fsMain(
    \\      @location(0) color: vec4<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return color;
    \\  }
    // zig fmt: on
;

pub const TriangleVertex = struct {
    position: [3]f32,
    color: [4]f32,
    pub fn write(vertex_data: *lib.ArrayList(TriangleVertex), geometry: *const Geometry(TriangleVertex), total_num_vertices: u64) void {
        const positions = geometry.getAttribute(mesh.ATTRIBUTE_POSITION.name).?.data.float32x3;
        const colors = geometry.getAttribute(mesh.ATTRIBUTE_COLOR.name).?.data.float32x4;
        for (0..total_num_vertices) |i| {
            vertex_data.items[i].position = positions.items[i];
            vertex_data.items[i].color = colors.items[i];
        }
    }
};
pub const TriangleUniforms = extern struct {
    mvp: Mat4,
    const Self = @This();
    pub fn new() Self {
        return .{ .mvp = Mat4.ident.clone() };
    }
    pub fn getSize(_: Self) u64 {
        return @sizeOf(Mat4);
    }
    pub fn update(self: *Self, gctx: *zgpu.GraphicsContext) void {
        const fb_width = gctx.swapchain_descriptor.width;
        const fb_height = gctx.swapchain_descriptor.height;
        const t = @as(f32, @floatCast(gctx.stats.time));

        const cam_world_to_view = Mat4.lookAt(
            Vec3.new(3.0, 3.0, -3.0),
            Vec3.new(0.0, 0.0, 0.0),
            Vec3.new(0.0, 1.0, 0.0),
        );
        const cam_view_to_clip = Mat4.perspective(
            math.pi / 3.0,
            @as(f32, @floatFromInt(fb_width)) / @as(f32, @floatFromInt(fb_height)),
            0.01,
            200.0,
        );
        const cam_world_to_clip = cam_view_to_clip.mul(&cam_world_to_view);
        const object_to_world = Mat4.translate(Vec3.new(-1.0, 0.0, 0.0)).mul(&Mat4.rotateY(t));
        const object_to_clip = cam_world_to_clip.mul(&object_to_world);
        self.mvp = object_to_clip;
    }
};
pub const TriangleMesh = Mesh(TriangleVertex, TriangleUniforms);
pub fn initTriangleMesh() TriangleMesh {
    var geometry = TriangleMesh.MeshGeometry.new(.triangle_list);
    const ps = [_][3]f32{ [3]f32{ 0.0, 0.5, 0.0 }, [3]f32{ -0.5, -0.5, 0.0 }, [3]f32{ 0.5, -0.5, 0.0 } };
    geometry.addAttribute(mesh.ATTRIBUTE_POSITION, .{ .float32x3 = lib.utils.to_list([3]f32, ps) });

    const colors = [_][4]f32{ [4]f32{ 1.0, 0.0, 0.0, 1.0 }, [4]f32{ 0.0, 1.0, 0.0, 1.0 }, [4]f32{ 0.0, 0.0, 1.0, 1.0 } };
    geometry.addAttribute(mesh.ATTRIBUTE_COLOR, .{ .float32x4 = lib.utils.to_list([4]f32, colors) });

    const indices = [_]u32{ 0, 1, 2 };
    geometry.indices = lib.utils.to_list(u32, indices);
    const material = TriangleMesh.MeshMaterial.new(
        wgsl_vs,
        wgsl_fs,
    );
    const triangle_mesh = TriangleMesh.new(geometry, material);
    return triangle_mesh;
}
