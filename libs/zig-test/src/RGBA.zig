const std = @import("std");
r: f64,
g: f64,
b: f64,
a: f64,
const Self = @This();
pub fn new(r: f64, g: f64, b: f64, a: f64) Self {
    return Self{ .r = r, .g = g, .b = b, .a = a };
}

pub fn lerp(self: Self, other: Self, t: f64) Self {
    const r = std.math.lerp(self.r, other.r, t);
    const g = std.math.lerp(self.g, other.g, t);
    const b = std.math.lerp(self.b, other.b, t);
    const a = std.math.lerp(self.a, other.a, t);
    return Self{ .r = r, .g = g, .b = b, .a = a };
}

pub fn toString(self: Self, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "rgba({d},{d},{d},{d})\n", .{ self.r, self.g, self.b, self.a }) catch unreachable;
}
