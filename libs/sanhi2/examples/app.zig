const std = @import("std");
const sanhi = @import("sanhi");
const ecs = sanhi.ecs;
const app = sanhi.app;
const math = sanhi.math;
const Vec3 = math.Vector3;
const Quat = math.Quaternion;
const Mat4 = math.Matrix4;
pub fn main() !void {
    var appa  = try sanhi.app.App.init(.{});
    defer appa.deinit();
    appa.addPlugin(sanhi.plugins.fps.plugin);
    appa.run();
}
