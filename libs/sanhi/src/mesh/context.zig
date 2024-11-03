const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;

gctx: *zgpu.GraphicsContext,
view: Mat4 = Mat4.identity(),
projection: Mat4 = Mat4.identity(),
pass: wgpu.RenderPassEncoder = undefined,
encoder: wgpu.CommandEncoder = undefined,
