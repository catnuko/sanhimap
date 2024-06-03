const lib = @import("lib.zig");
const Vec3 = lib.Vec3;
const math = lib.math;
pub const MAX_LATITUDE: i16 = 90;
pub const MIN_LATITUDE: i16 = -90;
pub const MAX_LONGITUDE: i16 = 180;
pub const MIN_LONGITUDE: i16 = -180;
pub const GeoCoordinates = struct {
    const Self = @This();
    longitude: f64,
    latitude: f64,
    altitude: ?f64,
    pub const new = fromRadians;
    pub inline fn fromRadians(longitude: f64, latitude: f64, altitude: ?f64) Self {
        return .{ .longitude = longitude, .latitude = latitude, .altitude = altitude };
    }
    pub inline fn fromDegrees(longitude: f64, latitude: f64, altitude: ?f64) Self {
        return Self.fromDegrees(math.degreesToRadians(longitude), math.degreesToRadians(latitude), altitude);
    }
    pub inline fn longitudeInDegrees(self: Self) f64 {
        return math.radiansToDegrees(self.longitude);
    }
    pub inline fn latitudeInDegreees(self: Self) f64 {
        return math.radiansToDegrees(self.latitude);
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
        return Self.new(self.longitude, self.latitude, self.altitude);
    }
    pub fn minLongitudeSpanTo(self: Self, other: Self) f64 {
        const minLongitude = @min(self.longitude, other.longitude);
        const maxLongitude = @max(self.longitude, other.longitude);
        return @min(maxLongitude - minLongitude, lib.pi + minLongitude - maxLongitude);
    }
    pub inline fn empty() Self {
        return Self.new(
            0.0,
            0.0,
            0.0,
        );
    }
    pub inline fn fromVec3(vec3: Vec3) Self {
        return Self.new(vec3.x, vec3.y, vec3.z);
    }
    pub inline fn toVec3(self: Self) Vec3 {
        return Vec3.new(self.longitude, self.latitude, self.altitude);
    }
};

test "Geo.GeoCoordinates" {
    const testing = @import("std").testing;
    const point = GeoCoordinates.fromDegrees(120, 30, null);
    try testing.expectEqual(point.longitude, math.degreesToRadians(120));
    try testing.expectEqual(point.latitude, math.degreesToRadians(30));
    try testing.expectEqual(point.altitude, null);
}
