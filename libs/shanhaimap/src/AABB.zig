const math = @import("math");
pub const AABB = struct {
    min: math.Vec3d,
    max: math.Vec3d,
    const Self = @This();
    pub const ZERO = new(math.Vec3d.ZERO.clone(), math.Vec3d.ZERO.clone());
    pub fn new(minv: math.Vec3d, maxv: math.Vec3d) Self {
        return .{ .min = minv, .max = maxv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .min = self.min,
            .max = self.max,
        };
    }
};
