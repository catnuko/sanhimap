const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const math = @import("../math/index.zig");
const GeoCoordinates = @import("../lib.zig").coord.GeoCoordinates;
const earth = @import("./earth.zig");
const Box3 = math.Box3;
const Vec3 = math.Vec3;

pub const ProjectionType = enum { Planar, Spherical };
/// convert geo coordinate to world point
pub fn project(geo_point: GeoCoordinates, unit_scale: f64) Vec3 {
    const radius = unit_scale + (geo_point.altitude orelse 0);
    const latitude = stdmath.degreesToRadians(geo_point.latitude);
    const longitude = stdmath.degreesToRadians(geo_point.longitude);
    const cosLatitude = stdmath.cos(latitude);
    return Vec3.new(radius * cosLatitude * stdmath.cos(longitude), radius * cosLatitude * stdmath.sin(longitude), radius * stdmath.sin(latitude));
}
pub const SphereProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) SphereProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn world_extent(
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
    pub fn project_point(self: SphereProjection, geo_point: GeoCoordinates) Vec3 {
        return project(geo_point, self.unit_scale);
    }
    pub fn unproject_point(self: SphereProjection, world_point: Vec3) GeoCoordinates {
        const parallelRadiusSq = world_point.x() * world_point.x() + world_point.y() * world_point.y();
        const parallelRadius = stdmath.sqrt(parallelRadiusSq);
        const v = world_point.z() / parallelRadius;

        if (stdmath.isNan(v)) {
            return GeoCoordinates.fromRadians(0, 0, -self.unit_scale);
        }
        const radius = stdmath.sqrt(parallelRadiusSq + world_point.z * world_point.z);
        return GeoCoordinates.from_radians(stdmath.atan(v), stdmath.atan2(world_point.y(), world_point.x()), radius - self.unit_scale);
    }
    pub fn unproject_altitude(_: SphereProjection, world_point: Vec3) f64 {
        return world_point.length() - earth.EQUATORIAL_RADIUS;
    }
    pub fn ground_distance(self: SphereProjection, world_point: Vec3) f64 {
        return world_point.length() - self.unit_scale;
    }
    pub fn scale_point_to_surface(self: SphereProjection, world_point: Vec3) Vec3 {
        var length = world_point.length();
        if (length == 0) {
            length = 1.0;
        }
        const scale = self.unit_scale / length;
        return world_point.scale(scale);
    }
};
pub const sphereProjection = SphereProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.shpere_projection_0" {
    const geoPoint = GeoCoordinates.new(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.longitude, -122.4410209359072);
    const epsilon = 0.000001;
    const worldPoint = sphereProjection.project_point(geoPoint);
    const geoPoint2 = sphereProjection.unproject_point(worldPoint);
    testing.expectApproxEqAbs(geoPoint.latitude, geoPoint2.latitude, epsilon);
    testing.expectApproxEqAbs(geoPoint.longitude, geoPoint2.longitude, epsilon);
    testing.expectApproxEqAbs(geoPoint.altitude.?, geoPoint2.altitude.?, epsilon);
}
