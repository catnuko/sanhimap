const Rectangle = @import("Rectangle.zig");
const math = @import("math");
const Vec3 = math.Vec3d;
const Mat3 = math.Mat3x3d;
const debug = @import("std").debug;
pub const OBB = struct {
    center: Vec3,
    halfAxes: Mat3,
    const Self = @This();
    pub const ZERO = new(Vec3.ZERO.clone(), Mat3.ident.clone());
    pub fn new(centerv: Vec3, halfAxesv: Mat3) Self {
        return .{ .center = centerv, .halfAxes = halfAxesv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .center = self.center,
            .halfAxes = self.halfAxes,
        };
    }
    pub fn contains(self: *const Self, point: *const Vec3) bool {
        const pointToCenter = point.sub(&self.center);
        const inverseHalfAxes = self.halfAxes.inverse();
        const localPoint = inverseHalfAxes.mulVec(&pointToCenter);
        return math.abs(localPoint.x()) <= 1.0 and math.abs(localPoint.y()) <= 1.0 and math.abs(localPoint.z()) <= 1.0;
    }
};

const testing = @import("std").testing;
test "OBB.contains" {
    const center = Vec3.new(0, 0, 0);
    // var halfAxes = Mat3.rotateX(30 * math.rad_per_deg);
    var halfAxes = Mat3.ident.clone();
    const scale = Vec3.new(2, 2, 2);
    halfAxes.setScale(&scale);
    const obb = OBB.new(center, halfAxes);

    var point = Vec3.new(1, 1, 1);
    try testing.expect(obb.contains(&point));

    point = Vec3.new(1.9, 1.9, 1.9);
    try testing.expect(obb.contains(&point));

    point = Vec3.new(2.0, 2.0, 2.0);
    try testing.expect(obb.contains(&point));

    point = Vec3.new(-2.0, -2.0, -2.0);
    try testing.expect(obb.contains(&point));

    point = Vec3.new(2.1, 2.1, 2.1);
    try testing.expect(!obb.contains(&point));

    point = Vec3.new(-2.1, -2.1, -2.1);
    try testing.expect(!obb.contains(&point));
}
