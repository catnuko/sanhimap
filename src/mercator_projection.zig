const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const lib = @import("lib.zig");
const math = lib.math;
const GeoCoordinates = lib.GeoCoordinates;
const earth = lib.earth;
const Vec3 = math.Vec3;
const Box3 = lib.Box3;
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
        return Box3.new(Vec3.new(
            0,
            0,
            min_elevation,
        ), Vec3.new(
            self.unit_scale,
            self.unit_scale,
            max_elevation,
        ));
    }
    pub fn project_point(self: MercatorProjection, geopoint: GeoCoordinates) Vec3 {
        const x = ((geopoint.longitude + 180) / 360) * self.unit_scale;
        const y = (latitude_clamp_proejct(geopoint.latitude_in_radians) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unproject_point(self: MercatorProjection, worldpoint: Vec3) GeoCoordinates {
        return GeoCoordinates.from_radians(unproject_latitude((worldpoint.y / self.unit_scale - 0.5) * 2.0), (worldpoint.x / self.unit_scale) * 2 * stdmath.pi - stdmath.pi, worldpoint.z);
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
    pub fn unproject_altitude(_: MercatorProjection, worldpoint: Vec3) f64 {
        return worldpoint.z;
    }
    pub fn ground_distance(_: MercatorProjection, worldpoint: Vec3) f64 {
        return worldpoint.z;
    }
    pub fn scale_point_to_surface(_: MercatorProjection, worldpoint: *Vec3) Vec3 {
        const z_mut = worldpoint.zMut();
        z_mut = 0;
        return worldpoint;
    }
};
pub const mercator_projection = MercatorProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.mercator_projection" {}
