const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const lib = @import("./lib.zig");
const Box3 = lib.Box3;
const Vec3 = lib.Vec3;
const Mat4 = lib.Mat4;
const GeoCoordinates = lib.GeoCoordinates;
const earth = lib.earth;

pub const ProjectionType = enum { Planar, Spherical };
/// convert geo coordinate to world point
pub fn project(geopoint: GeoCoordinates, unit_scale: f64) Vec3 {
    const radius = unit_scale + (geopoint.altitude orelse 0);
    const latitude = stdmath.degreesToRadians(geopoint.latitude);
    const longitude = stdmath.degreesToRadians(geopoint.longitude);
    const cosLatitude = stdmath.cos(latitude);
    return Vec3.new(radius * cosLatitude * stdmath.cos(longitude), radius * cosLatitude * stdmath.sin(longitude), radius * stdmath.sin(latitude));
}
pub const SphereProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) SphereProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn worldExtent(
        self: SphereProjection,
        max_elevation: f64,
    ) Box3 {
        const radius = self.unit_scale + max_elevation;
        Box3.new(Vec3.new(
            -radius,
            -radius,
            -radius,
        ), Vec3.new(
            radius,
            radius,
            radius,
        ));
    }
    pub fn projectPoint(self: SphereProjection, geopoint: GeoCoordinates) Vec3 {
        return project(geopoint, self.unit_scale);
    }
    pub fn unprojectPoint(self: SphereProjection, worldpoint: Vec3) GeoCoordinates {
        const parallelRadiusSq = worldpoint.x() * worldpoint.x() + worldpoint.y() * worldpoint.y();
        const parallelRadius = stdmath.sqrt(parallelRadiusSq);
        const v = worldpoint.z() / parallelRadius;

        if (stdmath.isNan(v)) {
            return GeoCoordinates.fromRadians(0, 0, -self.unit_scale);
        }
        const radius = stdmath.sqrt(parallelRadiusSq + worldpoint.z() * worldpoint.z());
        return GeoCoordinates.fromRadians(stdmath.atan2(worldpoint.y(), worldpoint.x()), stdmath.atan(v), radius - self.unit_scale);
    }
    pub fn unprojectAltitude(_: SphereProjection, worldpoint: Vec3) f64 {
        return worldpoint.length() - earth.EQUATORIAL_RADIUS;
    }
    pub fn groundDistance(self: SphereProjection, worldpoint: Vec3) f64 {
        return worldpoint.length() - self.unit_scale;
    }
    pub fn scalePointToSurface(self: SphereProjection, worldpoint: Vec3) Vec3 {
        var length = worldpoint.length();
        if (length == 0) {
            length = 1.0;
        }
        const scale = self.unit_scale / length;
        return worldpoint.scale(scale);
    }
    pub fn localTagentSpace(self: SphereProjection, geo_point: GeoCoordinates) Mat4 {
        const world_point = self.projectPoint(geo_point);
        const latitude = stdmath.degreesToRadians(geo_point.latitude);
        const longitude = stdmath.degreesToRadians(geo_point.longitude);
        const cosLongitude = stdmath.cos(longitude);
        const sinLongitude = stdmath.sin(longitude);
        const cosLatitude = stdmath.cos(latitude);
        const sinLatitude = stdmath.sin(latitude);
        const slice = [16]f64{0};
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
        slice[11] = world_point.x();
        slice[11] = world_point.y();
        slice[11] = world_point.z();
        slice[11] = 1;
        return Mat4.fromSlice(&slice);
    }
};
pub const sphereProjection = SphereProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.shpere_projection.projectAndunproject" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.longitude, -122.4410209359072);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    const geoPoint2 = sphereProjection.unprojectPoint(worldPoint);
    try testing.expectApproxEqAbs(geoPoint.latitude, geoPoint2.latitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.longitude, geoPoint2.longitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.altitude.?, geoPoint2.altitude.?, epsilon);
}

test "projection.shpere_projection.groundDistance" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(worldPoint), 12, epsilon);
}

test "projection.shpere_projection.scalePointToSurface" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    const worldPoint2 = sphereProjection.scalePointToSurface(worldPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(worldPoint2), 0, epsilon);
}

test "projection.shpere_projection.vector_copy" {
    const ele_4 = @Vector(4, i32);

    // 向量必须拥有编译期已知的长度和类型
    const a = ele_4{ 1, 2, 3, 4 };
    var d: @Vector(4, i32) = a;
    d[0] = 10;
    try testing.expectEqual(d[0], 10);
    try testing.expectEqual(a[0], 1);
}
