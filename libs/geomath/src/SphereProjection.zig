const std = @import("std");
const math = @import("math");
const Vec3 = math.Vec3d;
const Cartographic = @import("./Cartographic.zig").Cartographic;
const Mat4 = math.Mat4x4d;
const AxisAlignedBoundingBox = @import("./AxisAlignedBoundingBox.zig").AxisAlignedBoundingBox;
const earth = @import("Earth.zig");
const Projection = @import("Projection.zig").Projection;
pub const ProjectionType = enum { Planar, Spherical };
/// convert geo coordinate to world point
pub fn innerProject(geopoint: *const Cartographic, unit_scale: f64) Vec3 {
    const radius = unit_scale + geopoint.height;
    const latitude = geopoint.lat;
    const longitude = geopoint.lon;
    const cosLatitude = math.cos(latitude);
    return Vec3.new(radius * cosLatitude * math.cos(longitude), radius * cosLatitude * math.sin(longitude), radius * math.sin(latitude));
}
pub const SphereProjection = struct {
    const Self = @This();
    unit_scale: f64,
    pub fn new(unit_scale: f64) SphereProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn worldExtent(
        self: *SphereProjection,
        _: f64,
        max_elevation: f64,
    ) AxisAlignedBoundingBox {
        const radius = self.unit_scale + max_elevation;
        const min = Vec3.new(-radius, -radius, -radius);
        const max = Vec3.new(radius, radius, radius);
        return AxisAlignedBoundingBox.new(min, max);
    }
    pub fn project(self: *SphereProjection, geopoint: *const Cartographic) Vec3 {
        return innerProject(geopoint, self.unit_scale);
    }
    pub fn unproject(self: *SphereProjection, worldpoint: *const Vec3) Cartographic {
        const parallelRadiusSq = worldpoint.x() * worldpoint.x() + worldpoint.y() * worldpoint.y();
        const parallelRadius = math.sqrt(parallelRadiusSq);
        const v = worldpoint.z() / parallelRadius;

        if (math.isNan(v)) {
            return Cartographic.new(0, 0, -self.unit_scale);
        }
        const radius = math.sqrt(parallelRadiusSq + worldpoint.z() * worldpoint.z());
        return Cartographic.new(math.atan2(worldpoint.y(), worldpoint.x()), math.atan(v), radius - self.unit_scale);
    }
    pub fn unprojectAltitude(self: *SphereProjection, worldpoint: *const Vec3) f64 {
        _ = self;
        return worldpoint.len() - earth.EQUATORIAL_RADIUS;
    }
    pub fn groundDistance(self: *SphereProjection, worldpoint: *const Vec3) f64 {
        return worldpoint.len() - self.unit_scale;
    }
    pub fn scalePointToSurface(self: *SphereProjection, worldpoint: *const Vec3) Vec3 {
        var length = worldpoint.len();
        if (length == 0) {
            length = 1.0;
        }
        const scale = self.unit_scale / length;
        return worldpoint.mulScalar(scale);
    }
    pub fn localTagentSpace(self: *SphereProjection, geo_point: *const Cartographic) Mat4 {
        const world_point = self.project(geo_point);
        const latitude = geo_point.lat;
        const longitude = geo_point.lon;
        const cosLongitude = math.cos(longitude);
        const sinLongitude = math.sin(longitude);
        const cosLatitude = math.cos(latitude);
        const sinLatitude = math.sin(latitude);
        var slice = [1]f64{0} ** 16;
        //x axis
        slice[0] = -sinLongitude;
        slice[1] = cosLongitude;
        slice[2] = 0;
        slice[3] = 0;
        //y axis
        slice[4] = -cosLongitude * sinLongitude;
        slice[5] = -sinLongitude * sinLatitude;
        slice[6] = cosLatitude;
        slice[7] = 0;
        //z axis
        slice[8] = cosLongitude * cosLatitude;
        slice[9] = sinLongitude * cosLatitude;
        slice[10] = sinLatitude;
        slice[11] = 0;
        //point
        slice[12] = world_point.x();
        slice[13] = world_point.y();
        slice[14] = world_point.z();
        slice[15] = 1;
        return Mat4.fromArray(&slice);
    }
    pub fn projectionI(self: *Self) Projection {
        return Projection.new(self);
    }
};
var innerSphereProjection = SphereProjection.new(earth.EQUATORIAL_RADIUS);
pub const sphereProjection = innerSphereProjection.projectionI();
test "SphereProjection.projectAndunproject" {
    const testing = @import("std").testing;
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.lon, std.math.degreesToRadians(-122.4410209359072));
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    const geoPoint2 = sphereProjection.unproject(&worldPoint);
    try testing.expectApproxEqAbs(geoPoint.lat, geoPoint2.lat, epsilon);
    try testing.expectApproxEqAbs(geoPoint.lon, geoPoint2.lon, epsilon);
    try testing.expectApproxEqAbs(geoPoint.height, geoPoint2.height, epsilon);
}

test "SphereProjection.groundDistance" {
    const testing = @import("std").testing;
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(&worldPoint), 12, epsilon);
}

test "SphereProjection.scalePointToSurface" {
    const testing = @import("std").testing;
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    const worldPoint2 = sphereProjection.scalePointToSurface(&worldPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(&worldPoint2), 0, epsilon);
}

test "SphereProjection.vectorCopy" {
    const testing = @import("std").testing;
    const ele_4 = @Vector(4, i32);

    // 向量必须拥有编译期已知的长度和类型
    const a = ele_4{ 1, 2, 3, 4 };
    var d: @Vector(4, i32) = a;
    d[0] = 10;
    try testing.expectEqual(d[0], 10);
    try testing.expectEqual(a[0], 1);
}

test "SphereProjection.worldExtent" {
    const testing = @import("std").testing;
    const v = sphereProjection.worldExtent(0, 0);
    try testing.expectEqual(v.min.x(), -earth.EQUATORIAL_RADIUS);
}
