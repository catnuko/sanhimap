const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const mesh = @import("./index.zig");
const Mesh = mesh.Mesh;
const Geometry = mesh.Geometry;
const Material = mesh.Material;
const math = @import("math");
const Mat4 = math.Matrix4;
const Vector3 = math.Vector3;
const wgsl_vs =
    \\  struct MeshUniforms {
    \\      model: mat4<f32>,
    \\      view: mat4<f32>,
    \\      projection: mat4<f32>,
    \\  }
    \\  @group(0) @binding(0) var<uniform> uniforms: MeshUniforms;
    \\  struct VertexOut {
    \\      @builtin(position) position_clip: vec4<f32>,
    \\      @location(0) color: vec4<f32>,
    \\  }
    \\  @vertex fn vsMain(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) color: vec4<f32>,
    \\  ) -> VertexOut {
    \\      var output: VertexOut;
    \\      output.position_clip = uniforms.projection * uniforms.view * uniforms.model * vec4(position, 1.0);
    \\      output.color = color;
    \\      return output;
    \\  }
;
const wgsl_fs =
    \\  struct MaterialUniforms{
    \\      a:f32,
    \\  }
    \\  @group(1) @binding(0) var<uniform> uniforms:MaterialUniforms;
    \\  @fragment fn fsMain(
    \\      @location(0) color: vec4<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return vec4<f32>(color.rgb,uniforms.a);
    \\  }
;
const TriangleUniforms = extern struct {
    a: f32,
};
pub fn initTriangleMesh() *Mesh {
    var geometry = Geometry.new(
        &[_]wgpu.VertexAttribute{
            .{
                .format = wgpu.VertexFormat.float32x3,
                .shader_location = 0,
                .offset = 0,
            },
            .{
                .format = wgpu.VertexFormat.float32x4,
                .shader_location = 1,
                .offset = 12,
            },
        },
    );
    const data = [_]f32{ 0.0, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 1.0 };
    geometry.set_vertex_data(f32, &data);
    const indices = [_]u32{ 0, 1, 2 };
    geometry.set_index_data(u32, &indices);
    var material = Material{
        .vs = wgsl_vs,
        .fs = wgsl_fs,
        .uniform = Material.Uniform.new(@sizeOf(TriangleUniforms)),
    };
    material.uniform.update_data(TriangleUniforms, .{ .a = 0.5 });
    const triangle_mesh = Mesh.new(geometry, material);
    return triangle_mesh;
}
