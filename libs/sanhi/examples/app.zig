const std = @import("std");
const sanhi = @import("sanhi");
const ecs = sanhi.ecs;
const app = sanhi.app;
pub fn main() !void {
    try app.init(.{});
    try app.addPlugin(sanhi.input);
}
