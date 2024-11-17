const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Matrix4;
const Vector3 = math.Vector3;
const Quaternion = math.Quaternion;

gctx: *zgpu.GraphicsContext,
view: Mat4 = Mat4.fromIdentity(),
projection: Mat4 = Mat4.fromIdentity(),
pass: wgpu.RenderPassEncoder = undefined,
encoder: wgpu.CommandEncoder = undefined,
