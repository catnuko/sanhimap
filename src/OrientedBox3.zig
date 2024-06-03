const std = @import("std");
const lib = @import("lib.zig");
const math = lib.math;
const Mat3 = math.Mat3;
const Vec3 = math.Vec3;
pub const OrientedBox3 = struct {
    xAxis: Vec3,
    yAxis: Vec3,
    zAxis: Vec3,
    position: Vec3,
    extents: Vec3,
    pub fn new(
        position: Vec3,
        rotation: Mat3,
        extent: Vec3,
    ) OrientedBox3 {
        return .{
            .position = position,
            .xAxis = rotation.getColumn(0),
            .yAxis = rotation.getColumn(1),
            .zAxis = rotation.getColumn(2),
            .extent = extent,
        };
    }
    pub inline fn getCenter(this: OrientedBox3) Vec3 {
        return this.position.clone();
    }
    pub inline fn getSize(this: OrientedBox3) Vec3 {
        return this.extents.clone().scale(2);
    }
    pub inline fn getRotation(this: OrientedBox3) Mat3 {
        return this.half_axis.clone();
    }
    pub fn contains(this: OrientedBox3, point: Vec3) bool {
        const diff = point.sub(this.position);
        const x = math.abs(diff.dot(this.xAxis));
        const y = math.abs(diff.dot(this.yAxis));
        const z = math.abs(diff.dot(this.zAxis));
        if (x > this.extents.x() or y > this.extents.y() or z > this.extents.z()) {
            return false;
        }
        return true;
    }
    pub fn distanceToPoint(this: OrientedBox3, point: Vec3) f64 {
        return math.sqrt(this.distanceToPointSquared(point));
    }
    pub fn distanceToPointSquared(this: OrientedBox3, point: Vec3) f64 {
        const d = point.sub(this.position);
        const lengths = [3]f64{ d.dot(this.xAxis), d.dot(this.yAxis), d.dot(this.zAxis) };
        var result: f64 = 0;
        for (0..3) |i| {
            const length = lengths[i];
            const extent = this.extents.getComponent(i);
            if (length < -extent) {
                const dd = extent + length;
                result += dd * dd;
            } else if (length > extent) {
                const dd = length - extent;
                result += dd * dd;
            }
        }
        return result;
    }
};
