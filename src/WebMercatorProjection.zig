const std = @import("std");

const print = std.debug.print;
const testing = std.testing;
const lib = @import("./lib.zig");
const math = lib.math;
const Mat3 = math.Mat3;
const Vec3 = math.Vec3;
const GeoCoordinates = lib.GeoCoordinates;
const earth = lib;
const MercatorProjection = lib.MercatorProjection;
const Box3 = lib.Box3;
pub const MAXIMUM_LATITUDE: f64 = 1.4844222297453323;
pub const WebMercatorProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) WebMercatorProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn worldExtent(
        self: WebMercatorProjection,
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
    pub fn projectPoint(self: WebMercatorProjection, geopoint: GeoCoordinates) Vec3 {
        const x = ((geopoint.longitude + 180) / 360) * self.unit_scale;
        const sy = math.sin(latitudeClamp(geopoint.latitudeInRadians()));
        const y = (0.5 - math.log((1 + sy) / (1 - sy)) / (4 * math.pi)) * self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unprojectPoint(self: WebMercatorProjection, worldpoint: Vec3) GeoCoordinates {
        const x = worldpoint.x / self.unit_scale - 0.5;
        const y = 0.5 - worldpoint.y / self.unit_scale;
        const longitude = 360 * x;
        const latitude = 90 - (360 * math.atan(math.exp(-y * 2 * math.pi))) / math.pi;
        return GeoCoordinates.fromDegrees(latitude, longitude, worldpoint.z);
    }
    pub fn surfaceNormal() Vec3 {
        return Vec3.new(0.0, 0.0, 1.0);
    }
    pub const latitudeClamp = MercatorProjection.latitudeClamp;
    pub const latitudeProject = MercatorProjection.latitudeProject;
    pub const unprojectLatitude = MercatorProjection.unprojectLatitude;
    pub const latitudeClampProject = MercatorProjection.latitudeClampProject;
    pub const unprojectAltitude = MercatorProjection.unprojectAltitude;
    pub const groundDistance = MercatorProjection.groundDistance;
    pub const scalePointToSurface = MercatorProjection.scalePointToSurface;
};
pub const webMercatorProjection = WebMercatorProjection.new(earth.EQUATORIAL_RADIUS);
test "Geo.WebMercatorProjection" {}
