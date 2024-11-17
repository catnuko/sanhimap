const math = @import("./math.zig");
pub const AABB = struct {
    min: math.Vector3,
    max: math.Vector3,
    const Self = @This();
    pub const ZERO = new(math.Vector3.zero.clone(), math.Vector3.zero.clone());
    pub fn new(minv: math.Vector3, maxv: math.Vector3) Self {
        return .{ .min = minv, .max = maxv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .min = self.min,
            .max = self.max,
        };
    }
};
