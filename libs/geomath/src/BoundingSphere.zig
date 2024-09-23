const math = @import("math");
pub const BoundingSphere = struct {
    center: math.Vec3d,
    radius: f64,
    const Self = @This();
    pub const ZERO = new(math.Vec3d.ZERO.clone(), 0);
    pub fn new(c: math.Vec3d, r: f64) Self {
        return .{ .center = c, .radius = r };
    }
    pub fn clone(self:* const Self)Self{
        return .{
          .center = self.center,
          .radius = self.radius,  
        };
    }
};
