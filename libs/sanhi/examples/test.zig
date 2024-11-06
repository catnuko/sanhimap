const std = @import("std");
const sanhi = @import("sanhi");
const Mat4 = sanhi.math.math.Mat4x4;
const Vec3 = sanhi.math.math.Vec3;
pub fn main() !void {
    var sanhi_app = try sanhi.Sanhi.new();
    sanhi_app.camera.world_matrix = Mat4.lookAt(
        Vec3.new(3.0, 3.0, -3.0),
        Vec3.new(0.0, 0.0, 0.0),
        Vec3.new(0.0, 1.0, 0.0),
    );
    sanhi_app.startMainLoop();
    defer sanhi_app.deinit();
}
