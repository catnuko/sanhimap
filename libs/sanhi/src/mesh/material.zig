const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
pub fn Material(comptime Uniforms: type) type {
    return struct {
        const Self = @This();
        vs: [:0]const u8,
        fs: [:0]const u8,
        vs_module: wgpu.ShaderModule = undefined,
        fs_module: wgpu.ShaderModule = undefined,
        uniforms: Uniforms,
        pub fn new(vs: [:0]const u8, fs: [:0]const u8) Self {
            return .{
                .vs = vs,
                .fs = fs,
                .uniforms = Uniforms.new(),
            };
        }
        pub fn deinit(self: *Self) void {
            self.fs_module.release();
            self.vs_module.release();
        }
        pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
            self.vs_module = zgpu.createWgslShaderModule(gctx.device, self.vs, "vs");
            self.fs_module = zgpu.createWgslShaderModule(gctx.device, self.fs, "fs");
        }
    };
}
pub const Object3DUniforms = struct {
    model: Mat4,
    view: Mat4,
    projection: Mat4,
};
