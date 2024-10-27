const math = @import("../math.zig");
pub const BoundingSphere = struct {
    center: math.Vec3,
    radius: f64,
    const Self = @This();
    pub const ZERO = new(math.Vec3.ZERO.clone(), 0);
    pub fn new(c: math.Vec3, r: f64) Self {
        return .{ .center = c, .radius = r };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .center = self.center,
            .radius = self.radius,
        };
    }
};
