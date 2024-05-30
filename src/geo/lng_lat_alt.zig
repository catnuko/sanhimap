const std = @import("std");
const math = @import("../math/index.zig");
const Vec3 = math.Vec3_f64;
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
        pub fn new(longitude: T, latitude: T, altitude: T) Self {
            return .{ .longitude = longitude, .latitude = latitude, .altitude = altitude };
        }
        pub fn empty() Self {
            return Self.new(
                0.0,
                0.0,
                0.0,
            );
        }
        pub fn from_vec3(vec3: Vec3) Self {
            return Self.new(vec3.x, vec3.y, vec3.z);
        }
    };
}
