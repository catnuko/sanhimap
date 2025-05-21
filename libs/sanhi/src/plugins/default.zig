const ecs = @import("./ecs/index.zig"); 
const p = @import("../plugin.zig");

pub const plugins = []const p.Plugin{
    ecs.plugin,
};