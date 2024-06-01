const std = @import("std");
const Vec3 = @import("../math/index.zig").Vec3;
const math = std.math;

pub const MAX_LATITUDE: i16 = 90;
pub const MIN_LATITUDE: i16 = -90;
pub const MAX_LONGITUDE: i16 = 180;
pub const MIN_LONGITUDE: i16 = -180;
pub const GeoCoordinates = struct {
    const Self = @This();
    longitude: f64,
    latitude: f64,
    altitude: ?f64,
    pub inline fn from_degrees(longitude: f64, latitude: f64, altitude: ?f64) Self {
        return .{ .longitude = longitude, .latitude = latitude, .altitude = altitude };
    }
    pub inline fn from_radians(longitude: f64, latitude: f64, altitude: ?f64) Self {
        return Self.from_degrees(math.radiansToDegrees(longitude), math.radiansToDegrees(latitude), altitude);
    }
    pub inline fn longitude_in_radians(self: Self) f64 {
        return math.degreesToRadians(self.longitude);
    }
    pub inline fn latitude_in_radians(self: Self) f64 {
        return math.degreesToRadians(self.latitude);
    }
    pub inline fn eql(self: Self, other: Self) bool {
        return (self.latitude == other.latitude and
            self.longitude == other.longitude and
            self.altitude == other.altitude);
    }
    pub inline fn copy(self: *Self, other: Self) void {
        self.latitude = other.latitude;
        self.longitude = other.longitude;
        self.altitude = other.altitude;
    }
    pub inline fn clone(self: Self) Self {
        return Self.from_degrees(self.longitude, self.latitude, self.altitude);
    }
    pub fn min_longitude_span_to(self: Self, other: Self) f64 {
        const minLongitude = @min(self.longitude, other.longitude);
        const maxLongitude = @max(self.longitude, other.longitude);
        return @min(maxLongitude - minLongitude, 360 + minLongitude - maxLongitude);
    }
    pub inline fn empty() Self {
        return Self.new(
            0.0,
            0.0,
            0.0,
        );
    }
    pub inline fn from_vec3(vec3: Vec3) Self {
        return Self.new(vec3.x, vec3.y, vec3.z);
    }
    pub inline fn to_vec3(self: Self) Vec3 {
        return Vec3.new(self.longitude, self.latitude, self.altitude);
    }
};

test "coord_geo_coordinates" {
    const point = GeoCoordinates.from_degrees(120, 30, null);
    try std.testing.expectEqual(point.longitude, 120);
    try std.testing.expectEqual(point.latitude, 30);
    try std.testing.expectEqual(point.altitude, null);
}
