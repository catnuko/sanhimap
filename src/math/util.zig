const std = @import("std");
const math = std.math;
const expect = @import("std").testing.expect;
pub const F64x2 = @Vector(2, f64);
pub const F64x3 = @Vector(3, f64);
pub const F64x4 = @Vector(4, f64);
pub const F32x2 = @Vector(2, f32);
pub const F32x3 = @Vector(3, f32);
pub const F32x4 = @Vector(4, f32);
pub fn approxEqAbs(v0: anytype, v1: anytype, eps: f32) bool {
    const T = @TypeOf(v0, v1);
    comptime var i: comptime_int = 0;
    inline while (i < veclen(T)) : (i += 1) {
        if (!math.approxEqAbs(f32, v0[i], v1[i], eps)) {
            return false;
        }
    }
    return true;
}

pub inline fn splat(comptime T: type, value: f32) T {
    return @splat(value);
}

pub inline fn veclen(comptime T: type) comptime_int {
    return @typeInfo(T).Vector.len;
}
