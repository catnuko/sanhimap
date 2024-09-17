const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const Vec3 = @import("lib.zig").math.Vec3;
pub const Box3 = struct {
    min: Vec3,
    max: Vec3,
    pub fn new(min: Vec3, max: Vec3) Box3 {
        return .{ .min = min, .max = max };
    }
};
