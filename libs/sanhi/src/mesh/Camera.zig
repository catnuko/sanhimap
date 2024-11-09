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
heading: f32 = 0,
pitch: f32 = 0,
roll: f32 = 0,
cursor_pos: [2]f64 = .{ 0, 0 },
pub fn new(fovy: f32, aspect: f32, near: f32, far: f32) Self {
    var self: Self = .{ .fovy = fovy, .aspect = aspect, .near = near, .far = far };
    self.update_projection_matrix();
    return self;
}
pub fn update(self: *Self, app_backend: *backend.AppBackend) void {
    const gctx = app_backend.gctx;
    const window = app_backend.window;
    const cursor_pos = window.getCursorPos();
    const delta_x = @as(f32, @floatCast(cursor_pos[0] - self.cursor_pos[0]));
    const delta_y = @as(f32, @floatCast(cursor_pos[1] - self.cursor_pos[1]));
    self.cursor_pos = cursor_pos;
    if (window.getMouseButton(.left) == .press) {
        self.pitch += 0.0025 * delta_y;
        self.heading += 0.0025 * delta_x;
        self.pitch = @min(self.pitch, 0.48 * math.pi);
        self.pitch = @max(self.pitch, -0.48 * math.pi);
        self.heading = modAngle32(self.heading);
    }
    const speed = Vec3.splat(2);
    const delta_time = Vec3.splat(gctx.stats.delta_time);
    const distance = speed.mul(&delta_time);

    const quat = Quat.fromEuler(self.pitch, self.heading, self.roll);
    const rotation = Mat3.fromQuaternion(&quat);
    const forward = rotation.mulVec(&Vec3.new(0, 0, 1)).normalize().negate().mul(&distance);
    const right = rotation.mulVec(&Vec3.new(1, 0, 0)).normalize().negate().mul(&distance);
    var cam_pos = self.camera_matrix.getTranslation();
    if (window.getKey(.w) == .press) {
        cam_pos = cam_pos.add(&forward);
    } else if (window.getKey(.s) == .press) {
        cam_pos = cam_pos.sub(&forward);
    }
    if (window.getKey(.d) == .press) {
        cam_pos = cam_pos.add(&right);
    } else if (window.getKey(.a) == .press) {
        cam_pos = cam_pos.sub(&right);
    }
    const scale = Vec3.new(1, 1, 1);
    self.camera_matrix = Mat4.fromTranslationQuaternionRotationScale(&cam_pos, &quat, &scale);
    self.update_view_matrix();
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
pub fn modAngle32(in_angle: f32) f32 {
    const angle = in_angle + math.pi;
    var temp: f32 = @abs(angle);
    temp = temp - (2.0 * math.pi * @as(f32, @floatFromInt(@as(i32, @intFromFloat(temp / math.pi)))));
    temp = temp - math.pi;
    if (angle < 0.0) {
        temp = -temp;
    }
    return temp;
}
