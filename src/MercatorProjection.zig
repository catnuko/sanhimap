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
    const Self = @This();
    pub fn new(unit_scale: f64) MercatorProjection {
        return .{ .unit_scale = unit_scale };
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
        const y = (self.latitudeClampProject(geopoint.latitude) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unprojectPoint(self: *Self, worldpoint: Vec3) GeoCoordinates {
        return GeoCoordinates.fromRadians(self.unprojectLatitude((worldpoint.y() / self.unit_scale - 0.5) * 2.0), (worldpoint.x() / self.unit_scale) * 2 * math.pi - math.pi, worldpoint.z());
    }
    //static methods
    pub fn surfaceNormal(_: *Self) Vec3 {
        return Vec3.new(0.0, 0.0, -1.0);
    }
    pub fn latitudeClamp(_: *Self, latitude: f64) f64 {
        return math.clamp(latitude, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
    }
    pub fn latitudeProject(_: *Self, latitude: f64) f64 {
        return math.log(f64, math.e, math.tan(math.pi * 0.25 + latitude * 0.5)) / math.pi;
    }
    pub fn unprojectLatitude(_: *Self, y: f64) f64 {
        return 2.0 * math.atan(math.exp(math.pi * y)) - math.pi * 0.5;
    }
    pub fn latitudeClampProject(self: *Self, latitude: f64) f64 {
        return self.latitudeProject(self.latitudeClamp(latitude));
    }
    pub fn unprojectAltitude(_: *Self, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
    pub fn groundDistance(_: *Self, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
    pub fn scalePointToSurface(_: *Self, worldpoint: Vec3) Vec3 {
        return Vec3.new(worldpoint.x(), worldpoint.y(), worldpoint.z());
    }
    pub fn localTagentSpace(self: *Self, geo_point: GeoCoordinates) Mat4 {
        const world_point = self.projectPoint(geo_point);
        var slice = [1]f64{0} ** 16;
        //x axis
        slice[0] = 1;
        slice[1] = 0;
        slice[2] = 0;
        slice[3] = 0;
        //y axis
        slice[4] = 0;
        slice[5] = -1;
        slice[6] = 0;
        slice[7] = 0;
        //z axis
        slice[8] = 0;
        slice[9] = 0;
        slice[10] = -1;
        slice[11] = 0;
        //point
        slice[11] = world_point.x();
        slice[11] = world_point.y();
        slice[11] = world_point.z();
        slice[11] = 1;
        return Mat4.fromSlice(&slice);
    }
    pub fn projectionI(self: *Self) lib.Projection {
        return lib.Projection.init(self);
    }
};
var t = MercatorProjection.new(earth.EQUATORIAL_RADIUS);
pub var mercatorProjection = t.projectionI();
test "Geo.MercatorProjection" {}
