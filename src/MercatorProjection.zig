const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const lib = @import("lib.zig");
const math = lib.math;
const Vec3 = math.Vec3;
const Mat4 = math.Mat4;
const GeoCoordinates = lib.GeoCoordinates;
const earth = lib.earth;
const Box3 = lib.Box3;
pub const MAXIMUM_LATITUDE: f64 = 1.4844222297453323;
pub const MercatorProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) MercatorProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn worldExtent(
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
    pub fn projectPoint(self: MercatorProjection, geopoint: GeoCoordinates) Vec3 {
        const x = ((geopoint.longitude + 180) / 360) * self.unit_scale;
        const y = (latitudeClampProject(geopoint.latitudeInRadians) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unprojectPoint(self: MercatorProjection, worldpoint: Vec3) GeoCoordinates {
        return GeoCoordinates.fromRadians(unprojectLatitude((worldpoint.y / self.unit_scale - 0.5) * 2.0), (worldpoint.x / self.unit_scale) * 2 * math.pi - math.pi, worldpoint.z);
    }
    //static methods
    pub fn surfaceNormal(_: MercatorProjection) Vec3 {
        return Vec3.new(0.0, 0.0, -1.0);
    }
    pub fn latitudeClamp(_: MercatorProjection, latitude: f64) f64 {
        return math.clamp(latitude, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
    }
    pub fn latitudeProject(_: MercatorProjection, latitude: f64) f64 {
        return math.log(math.tan(math.PI * 0.25 + latitude * 0.5)) / math.pi;
    }
    pub fn unprojectLatitude(_: MercatorProjection, y: f64) f64 {
        return 2.0 * math.atan(math.exp(math.pi * y)) - math.pi * 0.5;
    }
    pub fn latitudeClampProject(_: MercatorProjection, latitude: f64) f64 {
        return latitudeProject(latitudeClamp(latitude));
    }
    pub fn unprojectAltitude(_: MercatorProjection, worldpoint: Vec3) f64 {
        return worldpoint.z;
    }
    pub fn groundDistance(_: MercatorProjection, worldpoint: Vec3) f64 {
        return worldpoint.z;
    }
    pub fn scalePointToSurface(_: MercatorProjection, worldpoint: *Vec3) Vec3 {
        const z_mut = worldpoint.zMut();
        z_mut = 0;
        return worldpoint;
    }
};
pub const mercatorProjection = MercatorProjection.new(earth.EQUATORIAL_RADIUS);
test "Geo.MercatorProjection" {}
