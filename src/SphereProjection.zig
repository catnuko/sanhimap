const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const lib = @import("./lib.zig");
const math = lib.math;
const Box3 = lib.Box3;
const Vec3 = math.Vec3;
const Mat4 = math.Mat4;
const GeoCoordinates = lib.GeoCoordinates;
const earth = lib.earth;

pub const ProjectionType = enum { Planar, Spherical };
/// convert geo coordinate to world point
pub fn project(geopoint: GeoCoordinates, unit_scale: f64) Vec3 {
    const radius = unit_scale + (geopoint.altitude orelse 0);
    const latitude = geopoint.latitude;
    const longitude = geopoint.longitude;
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
        ctx: *anyopaque,
        _: f64,
        max_elevation: f64,
    ) Box3 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        const radius = self.unit_scale + max_elevation;
        return Box3.new(Vec3.new(
            -radius,
            -radius,
            -radius,
        ), Vec3.new(
            radius,
            radius,
            radius,
        ));
    }
    pub fn projectPoint(ctx: *anyopaque, geopoint: GeoCoordinates) Vec3 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return project(geopoint, self.unit_scale);
    }
    pub fn unprojectPoint(ctx: *anyopaque, worldpoint: Vec3) GeoCoordinates {
        const self: *Self = @ptrCast(@alignCast(ctx));
        const parallelRadiusSq = worldpoint.x() * worldpoint.x() + worldpoint.y() * worldpoint.y();
        const parallelRadius = math.sqrt(parallelRadiusSq);
        const v = worldpoint.z() / parallelRadius;

        if (math.isNan(v)) {
            return GeoCoordinates.new(0, 0, -self.unit_scale);
        }
        const radius = math.sqrt(parallelRadiusSq + worldpoint.z() * worldpoint.z());
        return GeoCoordinates.new(math.atan2(worldpoint.y(), worldpoint.x()), math.atan(v), radius - self.unit_scale);
    }
    pub fn unprojectAltitude(ctx: *anyopaque, worldpoint: Vec3) f64 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        return worldpoint.length() - earth.EQUATORIAL_RADIUS;
    }
    pub fn groundDistance(ctx: *anyopaque, worldpoint: Vec3) f64 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return worldpoint.length() - self.unit_scale;
    }
    pub fn scalePointToSurface(ctx: *anyopaque, worldpoint: Vec3) Vec3 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        var length = worldpoint.length();
        if (length == 0) {
            length = 1.0;
        }
        const scale = self.unit_scale / length;
        return worldpoint.scale(scale);
    }
    pub fn localTagentSpace(ctx: *anyopaque, geo_point: GeoCoordinates) Mat4 {
        const world_point = projectPoint(ctx, geo_point);
        const latitude = geo_point.latitude;
        const longitude = geo_point.longitude;
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
        slice[11] = world_point.x();
        slice[11] = world_point.y();
        slice[11] = world_point.z();
        slice[11] = 1;
        return Mat4.fromSlice(&slice);
    }
    pub fn projectionI(self: *Self) lib.Projection {
        return .{ .ptr = self, .vtable = &.{
            .worldExtent = worldExtent,
            .projectPoint = projectPoint,
            .unprojectPoint = unprojectPoint,
            .unprojectAltitude = unprojectAltitude,
            .groundDistance = groundDistance,
            .scalePointToSurface = scalePointToSurface,
            .localTagentSpace = localTagentSpace,
        } };
    }
};
var innerSphereProjection = SphereProjection.new(earth.EQUATORIAL_RADIUS);
pub const sphereProjection = innerSphereProjection.projectionI();
test "SphereProjection.projectAndunproject" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.longitude, std.math.degreesToRadians(-122.4410209359072));
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    const geoPoint2 = sphereProjection.unprojectPoint(worldPoint);
    try testing.expectApproxEqAbs(geoPoint.latitude, geoPoint2.latitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.longitude, geoPoint2.longitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.altitude.?, geoPoint2.altitude.?, epsilon);
}

test "SphereProjection.groundDistance" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(worldPoint), 12, epsilon);
}

test "SphereProjection.scalePointToSurface" {
    const geoPoint = GeoCoordinates.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.projectPoint(geoPoint);
    const worldPoint2 = sphereProjection.scalePointToSurface(worldPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(worldPoint2), 0, epsilon);
}

test "SphereProjection.vectorCopy" {
    const ele_4 = @Vector(4, i32);

    // 向量必须拥有编译期已知的长度和类型
    const a = ele_4{ 1, 2, 3, 4 };
    var d: @Vector(4, i32) = a;
    d[0] = 10;
    try testing.expectEqual(d[0], 10);
    try testing.expectEqual(a[0], 1);
}

test "SphereProjection.worldExtent" {
    const v = sphereProjection.worldExtent(0, 0);
    try testing.expectEqual(v.min.x(), -earth.EQUATORIAL_RADIUS);
}
