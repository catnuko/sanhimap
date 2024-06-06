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
        ctx: *anyopaque,
        min_elevation: f64,
        max_elevation: f64,
    ) Box3 {
        const self: *Self = @ptrCast(@alignCast(ctx));
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
    pub fn projectPoint(ctx: *anyopaque, geopoint: GeoCoordinates) Vec3 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        const x = geopoint.longitude * self.unit_scale;
        const y = (latitudeClampProject(ctx, geopoint.latitude) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unprojectPoint(ctx: *anyopaque, worldpoint: Vec3) GeoCoordinates {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return GeoCoordinates.fromRadians(unprojectLatitude(ctx, (worldpoint.y() / self.unit_scale - 0.5) * 2.0), (worldpoint.x() / self.unit_scale) * 2 * math.pi - math.pi, worldpoint.z());
    }
    //static methods
    pub fn surfaceNormal(_: *anyopaque) Vec3 {
        return Vec3.new(0.0, 0.0, -1.0);
    }
    pub fn latitudeClamp(_: *anyopaque, latitude: f64) f64 {
        return math.clamp(latitude, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
    }
    pub fn latitudeProject(_: *anyopaque, latitude: f64) f64 {
        return math.log(f64, math.e, math.tan(math.pi * 0.25 + latitude * 0.5)) / math.pi;
    }
    pub fn unprojectLatitude(_: *anyopaque, y: f64) f64 {
        return 2.0 * math.atan(math.exp(math.pi * y)) - math.pi * 0.5;
    }
    pub fn latitudeClampProject(ctx: *anyopaque, latitude: f64) f64 {
        return latitudeProject(ctx, latitudeClamp(ctx, latitude));
    }
    pub fn unprojectAltitude(_: *anyopaque, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
    pub fn groundDistance(_: *anyopaque, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
    pub fn scalePointToSurface(_: *anyopaque, worldpoint: Vec3) Vec3 {
        return Vec3.new(worldpoint.x(), worldpoint.y(), worldpoint.z());
    }
    pub fn localTagentSpace(ctx: *anyopaque, geo_point: GeoCoordinates) Mat4 {
        // const self: *Self = @ptrCast(@alignCast(ctx));
        const world_point = projectPoint(ctx, geo_point);
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
var t = MercatorProjection.new(earth.EQUATORIAL_RADIUS);
pub var mercatorProjection = t.projectionI();
test "Geo.MercatorProjection" {}
