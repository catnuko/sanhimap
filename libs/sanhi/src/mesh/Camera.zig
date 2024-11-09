const lib = @import("../lib.zig");
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vec3 = math.Vec3;
const Mat4 = math.Mat4x4;
const Mat3 = math.Mat3x3;
const Quat = math.Quat;
const HeadingPitchRoll = math.HeadingPitchRoll;
const Self = @This();
fovy: f32,
aspect: f32,
near: f32,
far: f32,
projection_matrix: Mat4 = undefined,
inverse_projection_matrix: Mat4 = undefined,
camera_matrix: Mat4 = Mat4.identity(),
view_matrix: Mat4 = Mat4.identity(),
pub fn new(fovy: f32, aspect: f32, near: f32, far: f32) Self {
    var self: Self = .{ .fovy = fovy, .aspect = aspect, .near = near, .far = far };
    self.update_projection_matrix();
    return self;
}
pub fn update_projection_matrix(self: *Self) void {
    self.projection_matrix = Mat4.perspective(
        self.fovy,
        self.aspect,
        self.near,
        self.far,
    );
    self.inverse_projection_matrix = self.projection_matrix.inverse();
}
pub fn update_view_matrix(self: *Self) void {
    self.view_matrix = self.camera_matrix.inverse();
}
