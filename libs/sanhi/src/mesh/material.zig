const lib = @import("../lib.zig");
const std = @import("std");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const Context = @import("./index.zig").Context;
pub const Uniform = struct {
    uniform_size: u64,
    data: []u8,
    layout: zgpu.BindGroupLayoutHandle = undefined,
    bind_group: zgpu.BindGroupHandle = undefined,
    const Self = @This();
    pub fn new(uniform_size: u64) Uniform {
        const alloc = lib.mem.getAllocator();
        const buffer = alloc.alloc(u8, uniform_size) catch unreachable;
        return .{
            .uniform_size = uniform_size,
            .data = buffer,
        };
    }
    pub fn deinit(self: *const Uniform) void {
        if (self.data.len != 0) {
            lib.mem.getAllocator().free(self.data);
        }
    }
    pub fn update_data(self: *Uniform, comptime T: type, data: T) void {
        const slice = std.mem.bytesAsSlice(T, @as([]align(@alignOf(T)) u8, @alignCast(self.data)));
        slice[0] = data;
    }
    pub fn write_uniform(self: *const Uniform, ctx: *Context) u32 {
        const mem = ctx.gctx.uniformsAllocate(u8, @intCast(self.data.len));
        std.mem.copyForwards(u8, mem.slice, self.data);
        return mem.offset;
    }
    pub fn upload(self: *Uniform, gctx: *zgpu.GraphicsContext) void {
        self.layout = gctx.createBindGroupLayout(&.{
            zgpu.bufferEntry(0, .{ .fragment = true }, .uniform, true, 0),
        });
        self.bind_group = gctx.createBindGroup(self.layout, &.{
            .{ .binding = 0, .buffer_handle = gctx.uniforms.buffer, .offset = 0, .size = @sizeOf(Mat4) },
        });
    }
};
vs: [:0]const u8,
fs: [:0]const u8,
vs_module: wgpu.ShaderModule = undefined,
fs_module: wgpu.ShaderModule = undefined,
uniform: Uniform,
const Self = @This();
pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
    self.vs_module = zgpu.createWgslShaderModule(gctx.device, self.vs, "vs");
    self.fs_module = zgpu.createWgslShaderModule(gctx.device, self.fs, "fs");
    self.uniform.upload(gctx);
}
pub fn deinit(self: *Self) void {
    self.fs_module.release();
    self.vs_module.release();
    self.uniform.deinit();
}
