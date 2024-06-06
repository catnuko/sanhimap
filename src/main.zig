const std = @import("std");
const print = std.debug.print;
const expectEqual = std.testing.expectEqual;
const lib = @import("lib.zig");
const Vec2 = lib.math.Vec2;
const GeoCoordinates = lib.GeoCoordinates;
pub fn main() !void {
    const a = Vec2.new(1, 2);
    const b = Vec2.new(1, 2);
    const v = Vec2.eql(a, b);
    print("res is {}\n", .{v});

    const point = GeoCoordinates.fromDegrees(10.0, 10.0, 10.0);
    print("point x is {}\n", .{point.longitude});

    const z = std.math.log(f64, std.math.e, 2.0);

    print("cos 2 is {}", .{z});
    print("pi is {}", .{std.math.pi});
}
