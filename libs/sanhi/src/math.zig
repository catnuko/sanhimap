const stdmath = @import("std").math;
pub const math = @import("math");
pub const Vec2 = math.Vec2d;
pub const Vec3 = math.Vec3d;
pub const Vec4 = math.Vec4d;
pub const Mat2 = math.Mat2x2d;
pub const Mat3 = math.Mat3x3d;
pub const Mat4 = math.Mat4x4d;
pub const Quat = math.Quatd;
pub const HeadingPitchRoll = math.HeadingPitchRolld;
pub const vec2 = math.Vec2d.new;
pub const vec3 = math.Vec3d.new;
pub const vec4 = math.Vec4d.new;
pub const quat = math.Quatd.new;
pub const mat2x2 = math.Mat2x2d.new;
pub const mat3x3 = math.Mat3x3d.new;
pub const mat4x4 = math.Mat4x4d.new;
pub const hpr = math.HeadingPitchRolld.new;
pub const vec2FromInt = math.Vec2d.fromInt;
pub const vec3FromInt = math.Vec3d.fromInt;
pub const vec4FromInt = math.Vec4d.fromInt;

pub const epsilon = math.epsilon;
pub usingnamespace epsilon;
pub fn abs(v: f64) f64 {
    if (v < 0) {
        return -v;
    } else {
        return v;
    }
}
pub fn zeroToTwoPi(angle: f64) f64 {
    if (angle >= 0 and angle <= stdmath.tau) {
        return angle;
    }
    const modv = stdmath.mod(f64, angle, stdmath.tau) catch unreachable;
    if (abs(modv) < epsilon.EPSILON14 and abs(angle) > epsilon.EPSILON14) {
        return stdmath.tau;
    }
    return modv;
}

pub fn negativePiToPi(angle: f64) f64 {
    if (angle >= -stdmath.pi and angle <= stdmath.pi) {
        return angle;
    }
    return zeroToTwoPi(angle + stdmath.pi) - stdmath.pi;
}

pub fn asinClamped(value: anytype) @TypeOf(value) {
    return stdmath.asin(stdmath.clamp(value, -1.0, 1.0));
}
pub const pi_over_two = stdmath.pi / 2.0;
pub usingnamespace stdmath;
