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
    \\      @location(0) color: vec3<f32>,
    \\  }
    \\  @vertex fn vsMain(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) color: vec3<f32>,
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
    \\      @location(0) color: vec3<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return vec4<f32>(color,1.0);
    \\  }
;
const Uniforms = struct { a: f32 = 0 };
pub fn init_basic_line_material() Material {
    var material = Material{
        .vs = wgsl_vs,
        .fs = wgsl_fs,
        .uniform = Material.Uniform.new(@sizeOf(Uniforms)),
    };
    material.uniform.update_data(Uniforms, .{});
    return material;
}
