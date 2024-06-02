const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const math = @import("./math/index.zig");
const GeoCoordinates = @import("./geo_coordinates.zig").GeoCoordinates;
const earth = @import("./earth.zig");
const MercatorProjection = @import("./mercator_projection.zig").MercatorProjection;
const Box3 = math.Box3;
const Vec3 = math.Vec3;
pub const MAXIMUM_LATITUDE: f64 = 1.4844222297453323;
pub const WebMercatorProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) WebMercatorProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn world_extent(
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
    pub fn project_point(self: WebMercatorProjection, geopoint: GeoCoordinates) Vec3 {
        const x = ((geopoint.longitude + 180) / 360) * self.unit_scale;
        const sy = stdmath.sin(latitude_clamp(geopoint.latitude_in_radians()));
        const y = (0.5 - stdmath.log((1 + sy) / (1 - sy)) / (4 * stdmath.pi)) * self.unit_scale;
        const z = geopoint.altitude orelse 0;
        return Vec3.new(x, y, z);
    }
    pub fn unproject_point(self: WebMercatorProjection, worldpoint: Vec3) GeoCoordinates {
        const x = worldpoint.x / self.unit_scale - 0.5;
        const y = 0.5 - worldpoint.y / self.unit_scale;
        const longitude = 360 * x;
        const latitude = 90 - (360 * stdmath.atan(stdmath.exp(-y * 2 * stdmath.pi))) / stdmath.pi;
        return GeoCoordinates.from_degrees(latitude, longitude, worldpoint.z);
    }
    pub fn surface_normal() Vec3 {
        return Vec3.new(0.0, 0.0, 1.0);
    }
    pub const latitude_clamp = MercatorProjection.latitude_clamp;
    pub const latitude_project = MercatorProjection.latitude_project;
    pub const unproject_latitude = MercatorProjection.unproject_latitude;
    pub const latitude_clamp_proejct = MercatorProjection.latitude_clamp_proejct;
    pub const unproject_altitude = MercatorProjection.unproject_altitude;
    pub const ground_distance = MercatorProjection.ground_distance;
    pub const scale_point_to_surface = MercatorProjection.scale_point_to_surface;
};
pub const web_mercator_projection = WebMercatorProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.web_mercator_projection" {}
