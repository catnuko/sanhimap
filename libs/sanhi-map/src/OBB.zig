const Rectangle = @import("Rectangle.zig");
const math = @import("./math.zig");
const Vector3 = math.Vector3;
const Mat3 = math.Mat3;
const debug = @import("std").debug;
pub const OBB = struct {
    center: Vector3,
    halfAxes: Mat3,
    const Self = @This();
    pub const ZERO = new(Vector3.zero.clone(), Mat3.identity.clone());
    pub fn new(centerv: Vector3, halfAxesv: Mat3) Self {
        return .{ .center = centerv, .halfAxes = halfAxesv };
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .center = self.center,
            .halfAxes = self.halfAxes,
        };
    }
    pub fn contains(self: *const Self, point: *const Vector3) bool {
        const pointToCenter = point.subtract(&self.center);
        const inverseHalfAxes = self.halfAxes.inverse();
        const localPoint = inverseHalfAxes.mulVec(&pointToCenter);
        return math.abs(localPoint.x()) <= 1.0 and math.abs(localPoint.y()) <= 1.0 and math.abs(localPoint.z()) <= 1.0;
    }
};

const testing = @import("std").testing;
test "OBB.contains" {
    const center = Vector3.new(0, 0, 0);
    // var halfAxes = Mat3.rotateX(30 * math.rad_per_deg);
    var halfAxes = Mat3.identity.clone();
    const scale = Vector3.new(2, 2, 2);
    halfAxes.setScale(&scale);
    const obb = OBB.new(center, halfAxes);

    var point = Vector3.new(1, 1, 1);
    try testing.expect(obb.contains(&point));

    point = Vector3.new(1.9, 1.9, 1.9);
    try testing.expect(obb.contains(&point));

    point = Vector3.new(2.0, 2.0, 2.0);
    try testing.expect(obb.contains(&point));

    point = Vector3.new(-2.0, -2.0, -2.0);
    try testing.expect(obb.contains(&point));

    point = Vector3.new(2.1, 2.1, 2.1);
    try testing.expect(!obb.contains(&point));

    point = Vector3.new(-2.1, -2.1, -2.1);
    try testing.expect(!obb.contains(&point));
}
