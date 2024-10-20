const math = @import("./math.zig");
pub const AABB = struct {
    min: math.Vec3,
    max: math.Vec3,
    const Self = @This();
    pub const ZERO = new(math.Vec3.ZERO.clone(), math.Vec3.ZERO.clone());
    pub fn new(minv: math.Vec3, maxv: math.Vec3) Self {
        return .{ .min = minv, .max = maxv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .min = self.min,
            .max = self.max,
        };
    }
};
