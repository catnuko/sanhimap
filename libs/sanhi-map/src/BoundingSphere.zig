const math = @import("../math.zig");
pub const BoundingSphere = struct {
    center: math.Vector3,
    radius: f64,
    const Self = @This();
    pub const ZERO = new(math.Vector3.zero.clone(), 0);
    pub fn new(c: math.Vector3, r: f64) Self {
        return .{ .center = c, .radius = r };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .center = self.center,
            .radius = self.radius,
        };
    }
};
