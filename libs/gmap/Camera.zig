const lib = @import("lib");
const Vec3 = lib.math.Vec3;
const Mat4 = lib.math.Mat4;
const testing = @import("std").testing;
pub const Camera = struct {
    const Self = @This();
    fov: f64,
    aspect: f64,
    near: f64,
    far: f64,
    projectionMatrix: Mat4 = Mat4.identity(),
    cameraMatrix: Mat4 = Mat4.identity(),
    viewMatrix: Mat4 = Mat4.identity(),
    position: Vec3 = Vec3.zero(),
    pub fn init(fov: f64, aspect: f64, near: f64, far: f64) Self {
        return .{
            .fov = fov,
            .aspect = aspect,
            .naar = near,
            .far = far,
        };
    }
    pub fn updateProjection(self: *Self) void {
        self.projectionMatrix = Mat4.perspective(
            self.fov,
            self.aspect,
            self.near,
            self.far,
        );
    }
    pub fn updateCameraMatrix(self: *Self) void {
        self.cameraMatrix.translate(self.position);
        self.viewMatrix = self.cameraMatrix.inv();
    }
    pub fn setPosiiton(self: Self, position: Vec3) void {
        self.position = position;
    }
};
