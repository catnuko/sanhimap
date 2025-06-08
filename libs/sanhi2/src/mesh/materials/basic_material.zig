const lib = @import("../../lib.zig");
const zmesh = lib.zmesh;
const wgpu = lib.wgpu;
const mesh = @import("../index.zig");
const Mesh = mesh.Mesh;
const Geometry = mesh.Geometry;
const Material = mesh.Material;
const wgsl_vs =
    \\  struct MeshUniforms {
    \\      model: mat4x4<f32>,
    \\      view: mat4x4<f32>,
    \\      projection: mat4x4<f32>,
    \\  }
    \\  @group(0) @binding(0) var<uniform> uniforms: MeshUniforms;
    \\  struct VertexOut {
    \\      @builtin(position) position_clip: vec4<f32>,
    \\      @location(0) uv: vec2<f32>,
    \\  }
    \\  @vertex fn vsMain(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) uv: vec2<f32>,
    \\      @location(2) normal: vec2<f32>,
    \\  ) -> VertexOut {
    \\      var output: VertexOut;
    \\      output.position_clip = uniforms.projection * uniforms.view * uniforms.model * vec4(position, 1.0);
    \\      output.uv = uv;
    \\      return output;
    \\  }
;
const wgsl_fs =
    \\  struct MaterialUniforms{
    \\      color:vec4<f32>,
    \\  }
    \\  @group(1) @binding(0) var<uniform> uniforms:MaterialUniforms;
    \\  @fragment fn fsMain(
    \\      @location(0) uv: vec2<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return uniforms.color;
    \\  }
;
const Uniforms = struct { color: [4]f32 };
pub fn init_basic_material() Material {
    var material = Material{
        .vs = wgsl_vs,
        .fs = wgsl_fs,
        .uniform = Material.Uniform.new(@sizeOf(Uniforms)),
    };
    material.uniform.update_data(Uniforms, .{ .color = .{ 1, 0, 0, 1 } });
    return material;
}
