pub usingnamespace @import("./app.zig");
pub usingnamespace @import("./plugin.zig");
pub const core = @import("./core/index.zig");
pub const graph = @import("./graph/index.zig");
test {
    _ = graph;
    _ = core;
}
