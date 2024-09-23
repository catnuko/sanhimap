const Rectangle = @import("Rectangle.zig");
const math = @import("math");
pub const OrientedBoundingBox = struct {
    center: math.Vec3d,
    halfAxes: math.Mat3x3d,
    const Self = @This();
    pub const ZERO = new(math.Vec3d.ZERO.clone(), math.Mat3x3d.clone());
    pub fn new(centerv: math.Vec3d, halfAxesv: math.Mat3x3d) Self {
        return .{ .center = centerv, .halfAxes = halfAxesv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .center = self.center,
            .halfAxes = self.halfAxes,
        };
    }
    pub fn fromRectangle(rectangle: *const Rectangle, minHeight: f64, maxHeight: f64) OrientedBoundingBox {}
};
