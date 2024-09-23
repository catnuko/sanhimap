const Cartographic = @import("Cartographic.zig").Cartographic;
const math = @import("math");
const stdmath = @import("std").math;
pub const Sphere = struct {
    radius: f64,
    const Self = @This();
    pub fn new(r: f64) Self {
        return .{ .radius = r };
    }
    pub fn distanceTo(self: *const Self, a: *const Cartographic, b: *const Cartographic) f64 {
        const R = self.radius;
        const a1 = a.lat;
        const b1 = a.lon;
        const a2 = b.lat;
        const b2 = b.lon;
        const da = a2 - a1;
        const db = b2 - b1;

        const aa = stdmath.sin(da / 2) * stdmath.sin(da / 2) + stdmath.cos(a1) * stdmath.cos(a2) * stdmath.sin(db / 2) * stdmath.sin(db / 2);
        const c = 2 * stdmath.atan2(stdmath.sqrt(aa), stdmath.sqrt(1 - aa));
        const d = R * c;
        return d;
    }
    // pub fn initialBearingTo(self: *const Self, a: *const Cartographic, b: *const Cartographic) f64 {}
};
