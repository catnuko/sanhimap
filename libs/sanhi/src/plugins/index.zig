const sanhi = @import("../lib.zig");
pub const input = @import("./input.zig");
pub const render = @import("./render/index.zig");

pub var plugins = [_]sanhi.app.Plugin{
    input.plugin,
    render.plugin,
};