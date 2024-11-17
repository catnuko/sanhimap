const lib = @import("../lib.zig");
const modules = lib.modules;
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector3 = math.Vector3;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3;
const Quaternion = math.Quaternion;
const HeadingPitchRoll = math.HeadingPitchRoll;
const Camera = @import("./Camera.zig");
const Self = @This();
camera: *Camera,
heading: f32 = 0,
pitch: f32 = 0,
roll: f32 = 0,
cursor_pos: [2]f64 = .{ 0, 0 },
pub fn new(camera: *Camera) Self {
    return .{
        .camera = camera,
    };
}
pub fn deinit(_: *Self) void {}
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
    const speed = Vector3.splat(2);
    const delta_time = Vector3.splat(gctx.stats.delta_time);
    const distance = speed.multiply(&delta_time);
    const quat = Quaternion.fromEuler(self.pitch, self.heading, self.roll);
    const rotation = Mat3.fromQuaternion(&quat);
    const forward = rotation.mulVec(&Vector3.new(0, 0, 1)).normalize().negate().multiply(&distance);
    const right = rotation.mulVec(&Vector3.new(1, 0, 0)).normalize().negate().multiply(&distance);
    var cam_pos = self.camera.camera_matrix.getTranslation();
    if (window.getKey(.w) == .press) {
        cam_pos = cam_pos.add(&forward);
    } else if (window.getKey(.s) == .press) {
        cam_pos = cam_pos.subtract(&forward);
    }
    if (window.getKey(.d) == .press) {
        cam_pos = cam_pos.add(&right);
    } else if (window.getKey(.a) == .press) {
        cam_pos = cam_pos.subtract(&right);
    }
    const scale = Vector3.new(1, 1, 1);
    self.camera.camera_matrix = Mat4.fromTranslationQuaternionScale(&cam_pos, &quat, &scale);
    self.camera.update_view_matrix();
}
pub fn updateProjection(self: *Self) void {
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
var control: Self = undefined;
pub fn set_camera(camera: *Camera) void {
    control = Self.new(camera);
}
pub fn module() modules.Module {
    const inputSubsystem = modules.Module{
        .name = "camera-control",
        .pre_draw_fn = on_update,
        .cleanup_fn = on_deinit,
    };
    return inputSubsystem;
}
pub fn on_update(appBackend: *backend.AppBackend) void {
    control.update(appBackend);
}
pub fn on_deinit() !void {
    control.deinit();
}
