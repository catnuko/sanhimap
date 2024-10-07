const std = @import("std");
const math = @import("math");
const Vec3 = math.Vec3d;
const Mat4 = math.Mat4x4d;
const Mat3 = math.Mat3x3d;
const Cartographic = @import("../Cartographic.zig").Cartographic;
const earth = @import("./Earth.zig");
const ProjectionImpl = @import("./ProjectionImpl.zig").ProjectionImpl;
const ProjectionType = @import("./ProjectionType.zig").ProjectionType;
const webMercatorProjection = @import("./WebMercatorProjection.zig").webMercatorProjection;
const mercatorProjection = @import("./MercatorProjection.zig").mercatorProjection;
const AABB = @import("../AABB.zig").AABB;
const OBB = @import("../OBB.zig").OBB;
const GeoBox = @import("../GeoBox.zig").GeoBox;

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
        return Box3.new(
            Vec3.new(0, 0, min_elevation),
            Vec3.new(self.unit_scale, self.unit_scale, max_elevation),
        );
    }
    pub fn project(self: *Self, geopoint: GeoCoordinates) Vec3 {
        const x = geopoint.longitude * self.unit_scale;
        const y = (self.latitudeClampProject(geopoint.latitude) * 0.5 + 0.5) *
            self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unproject(self: *Self, worldpoint: Vec3) GeoCoordinates {
        return GeoCoordinates.fromRadians(self.unprojectLatitude((worldpoint.y() / self.unit_scale - 0.5) * 2.0), (worldpoint.x() / self.unit_scale) * 2 * math.pi - math.pi, worldpoint.z());
    }
    pub fn reproject(self: *const Self, comptime P: type, sourceProjection: *const P, worldPoint: *const Vec3) Vec3 {}
    pub fn projectBox(self: *const Self, geoBox: *const GeoBox, comptime ResultBoxType: type) ResultBoxType {}
    pub fn unprojectBox(_: *const Self, _: *const OBB) GeoBox {}
    pub fn unprojectLatitude(_: *Self, y: f64) f64 {
        return 2.0 * math.atan(math.exp(math.pi * y)) - math.pi * 0.5;
    }
    pub fn getScaleFactor(_: *const Self, _: *const Vec3) f64 {}
    pub fn surfaceNormal(_: *Self) Vec3 {
        return Vec3.new(0.0, 0.0, -1.0);
    }
    pub fn groundDistance(_: *Self, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
    pub fn scalePointToSurface(_: *Self, worldpoint: Vec3) Vec3 {
        return Vec3.new(worldpoint.x(), worldpoint.y(), worldpoint.z());
    }
    pub fn localTagentSpace(self: *Self, geo_point: GeoCoordinates) Mat4 {
        const world_point = self.project(geo_point);
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

    pub fn latitudeClamp(_: *Self, latitude: f64) f64 {
        return math.clamp(latitude, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
    }
    pub fn latitudeProject(_: *Self, latitude: f64) f64 {
        return math.log(f64, math.e, math.tan(math.pi * 0.25 + latitude * 0.5)) / math.pi;
    }
    pub fn latitudeClampProject(self: *Self, latitude: f64) f64 {
        return self.latitudeProject(self.latitudeClamp(latitude));
    }
    pub fn unprojectAltitude(_: *Self, worldpoint: Vec3) f64 {
        return worldpoint.z();
    }
};
var t = ProjectionImpl(MercatorProjection).new(earth.EQUATORIAL_RADIUS);
pub var mercatorProjection = t.projectionI();
test "Geo.MercatorProjection" {}
