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
    mercatorProjection: MercatorProjection,
    const Self = @This();
    pub fn new(unit_scale: f64) WebMercatorProjection {
        return .{
            .unit_scale = unit_scale,
            .mercatorProjection = MercatorProjection.new(unit_scale),
        };
    }
    pub fn worldExtent(
        self: *Self,
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
    pub fn projectPoint(self: *Self, geopoint: GeoCoordinates) Vec3 {
        const x = geopoint.longitude * self.unit_scale;
        const sy = math.sin(self.latitudeClamp(geopoint.latitude));
        const y = (0.5 - math.log(f64, math.e, (1 + sy) / (1 - sy)) / (4 * math.pi)) * self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unprojectPoint(self: *Self, worldpoint: Vec3) GeoCoordinates {
        const x = worldpoint.x() / self.unit_scale - 0.5;
        const y = 0.5 - worldpoint.y() / self.unit_scale;
        const longitude = math.tow_pi * x;
        const latitude = math.pi_over_two - (std.math.tau * math.atan(math.exp(-y * 2 * math.pi))) / math.pi;
        return GeoCoordinates.fromRadians(latitude, longitude, worldpoint.z());
    }
    pub fn surfaceNormal() Vec3 {
        return Vec3.new(0.0, 0.0, 1.0);
    }
    pub inline fn latitudeClamp(self: *Self, latitude: f64) f64 {
        return self.mercatorProjection.latitudeClamp(latitude);
    }
    pub inline fn latitudeProject(self: *Self, latitude: f64) f64 {
        return self.mercatorProjection.latitudeProject(latitude);
    }
    pub inline fn unprojectLatitude(self: *Self, y: f64) f64 {
        return self.mercatorProjection.unprojectLatitude(y);
    }
    pub inline fn latitudeClampProject(self: *Self, latitude: f64) f64 {
        return self.mercatorProjection.latitudeClampProject(latitude);
    }
    pub inline fn unprojectAltitude(self: *Self, worldpoint: Vec3) f64 {
        return self.mercatorProjection.unprojectAltitude(worldpoint);
    }
    pub inline fn groundDistance(self: *Self, worldpoint: Vec3) f64 {
        return self.mercatorProjection.groundDistance(worldpoint);
    }
    pub inline fn scalePointToSurface(self: *Self, worldpoint: Vec3) Vec3 {
        return self.mercatorProjection.scalePointToSurface(worldpoint);
    }
    pub fn localTagentSpace(self: *Self, geoPoint: GeoCoordinates) lib.math.Mat4 {
        return self.mercatorProjection.localTagentSpace(geoPoint);
    }
    pub fn projectionI(self: *Self) lib.Projection {
        return lib.Projection.init(self);
    }
};
var t = WebMercatorProjection.new(lib.earth.EQUATORIAL_RADIUS);
pub const webMercatorProjection = t.projectionI();
test "WebMercatorProjection" {}
