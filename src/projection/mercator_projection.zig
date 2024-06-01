const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const math = @import("../math/index.zig");
const coord = @import("../coord/index.zig");
const GeoCoordinates = coord.GeoCoordinates;
const earth = @import("./earth.zig");
const Box3 = math.Box3;
const Vec3 = math.Vec3;
pub const MAXIMUM_LATITUDE: f64 = 1.4844222297453323;
pub const MercatorProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) MercatorProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn world_extent(
        self: MercatorProjection,
        min_elevation: f64,
        max_elevation: f64,
    ) Box3 {
        Box3.new(Vec3.new(
            0,
            0,
            min_elevation,
        ), Vec3.new(
            self.unit_scale,
            self.unit_scale,
            max_elevation,
        ));
    }
    pub fn project_point(self: MercatorProjection, geo_point: GeoCoordinates) Vec3 {
        const x = ((geo_point.longitude + 180) / 360) * self.unit_scale;
        const y = (latitude_clamp_proejct(geo_point.latitude_in_radians) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geo_point.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unproject_point(self: MercatorProjection, world_point: Vec3) GeoCoordinates {
        return GeoCoordinates.from_radians(unproject_latitude((world_point.y / self.unit_scale - 0.5) * 2.0), (world_point.x / self.unit_scale) * 2 * stdmath.pi - stdmath.pi, world_point.z);
    }
    //static methods
    pub fn surface_normal(_: MercatorProjection) Vec3 {
        return Vec3.new(0.0, 0.0, -1.0);
    }
    pub fn latitude_clamp(_: MercatorProjection, latitude: f64) f64 {
        return stdmath.clamp(latitude, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
    }
    pub fn latitude_project(_: MercatorProjection, latitude: f64) f64 {
        return stdmath.log(stdmath.tan(stdmath.PI * 0.25 + latitude * 0.5)) / stdmath.pi;
    }
    pub fn unproject_latitude(_: MercatorProjection, y: f64) f64 {
        return 2.0 * stdmath.atan(stdmath.exp(stdmath.pi * y)) - stdmath.pi * 0.5;
    }
    pub fn latitude_clamp_proejct(_: MercatorProjection, latitude: f64) f64 {
        return latitude_project(latitude_clamp(latitude));
    }
    pub fn unproject_altitude(_: MercatorProjection, world_point: Vec3) f64 {
        return world_point.z;
    }
    pub fn ground_distance(_: MercatorProjection, world_point: Vec3) f64 {
        return world_point.z;
    }
    pub fn scale_point_to_surface(_: MercatorProjection, world_point: *Vec3) Vec3 {
        const z_mut = world_point.zMut();
        z_mut = 0;
        return world_point;
    }
};
pub const mercator_projection = MercatorProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.mercator_projection" {}
