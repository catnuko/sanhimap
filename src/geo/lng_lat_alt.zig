const std = @import("std");
const Vec3 = @import("../math/index.zig").Vec3_f64;
const math = std.math;

pub const MAX_LATITUDE: i8 = 90;
pub const MIN_LATITUDE: i8 = -90;
pub const MAX_LONGITUDE: i8 = 180;
pub const MIN_LONGITUDE: i8 = -180;
pub const LngLatAlt = GenericLngLatAlt(f64);
pub fn GenericLngLatAlt(comptime T: type) type {
    if (@typeInfo(T) != .Float and @typeInfo(T) != .Int) {
        @compileError("Vectors not implemented for " ++ @typeName(T));
    }
    return extern struct {
        const Self = @This();
        longitude: T,
        latitude: T,
        altitude: T,
        pub inline fn from_degrees(longitude: T, latitude: T, altitude: ?T) Self {
            return .{ .longitude = longitude, .latitude = latitude, .altitude = if (altitude != null) altitude else 0.0 };
        }
        pub inline fn from_radians(longitude: T, latitude: T, altitude: ?T) Self {
            return Self.from_degrees(math.radiansToDegrees(longitude), math.radiansToDegrees(latitude), altitude);
        }
        pub inline fn lng_in_radians(self: Self) T {
            return math.degreesToRadians(self.longitude);
        }
        pub inline fn lat_in_radians(self: Self) T {
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
        pub fn min_longitude_span_to(self: Self, other: Self) T {
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
}
