const math = @import("../math.zig");
pub const BoundingRectangle = struct {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    const Self = @This();
    pub const ZERO = new(0, 0, 0, 0);
    pub fn new(xv: f64, yv: f64, widthv: f64, heightv: f64) Self {
        return .{ .x = xv, .y = yv, .width = widthv, .height = heightv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
        };
    }
};
