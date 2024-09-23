const math = @import("math");
const stdmath = @import("std").math;
const Cartographic = @import("Cartographic.zig").Cartographic;
pub const NvectorEllipsoidal = struct {
    v: math.Vec3d,
    h: f64,
    const Self = @This();
    pub fn new(x: f64, y: f64, z: f64, hv: f64) Self {
        return .{
            .v = math.vec3d(x, y, z).normalize(),
            .h = hv,
        };
    }
    pub fn toCartographic(self: *const Self) Cartographic {
        const x = self.v.x();
        const y = self.v.y();
        const z = self.v.z();
        const a = stdmath.atan2(z, stdmath.sqrt(x * x + y * y));
        const b = stdmath.atan2(y, x);
        return Cartographic.new(a, b, self.h);
    }
};
