const stdmath = @import("std").math;
const math = @import("math");
pub const Vector2 = math.Vector2D;
pub const Vector3 = math.Vector3D;
pub const Vector4 = math.Vector4D;
pub const Mat2 = math.Matrix2D;
pub const Mat3 = math.Matrix3D;
pub const Mat4 = math.Matrix4D;
pub const Quaternion = math.QuaternionD;
pub const HeadingPitchRoll = math.HeadingPitchRollD;
pub const vec2 = math.Vector2D.new;
pub const vec3 = math.Vector3D.new;
pub const vec4 = math.Vector4D.new;
pub const quat = math.QuaternionD.new;
pub const mat2 = math.Matrix2D.new;
pub const mat3 = math.Matrix3D.new;
pub const mat4 = math.Matrix4D.new;
pub const hpr = math.HeadingPitchRollD.new;
pub const vec2FromInt = math.Vector2D.fromInt;
pub const vec3FromInt = math.Vector3D.fromInt;
pub const vec4FromInt = math.Vector4D.fromInt;

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
    if (abs(modv) < epsilon.epsilon14 and abs(angle) > epsilon.epsilon14) {
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
