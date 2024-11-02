const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
pub const Context = struct {
    gctx: *zgpu.GraphicsContext,
};
