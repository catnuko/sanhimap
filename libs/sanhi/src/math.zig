const std = @import("std");
const math = @import("math");
pub const Vec3f = math.Vector3;
pub const Vec2f = math.Vector2;
pub const Vec4f = math.Vector4;

pub const Mat2f = math.Matrix2;
pub const Mat3f = math.Matrix3;
pub const Mat4f = math.Matrix4;

pub const Quatf = math.Quaternion;

pub const Hprf = math.HeadingPitchRoll;

pub const vec2f = math.vec2;
pub const vec3f = math.vec3;
pub const vec4f = math.vec4;

pub const mat2f = math.mat2;
pub const mat3f = math.mat3;
pub const mat4f = math.mat4;

pub const quatf = math.quat;
pub const hprf = math.hpr;

pub const Vec3 = math.Vector3D;
pub const Vec2 = math.Vector2D;
pub const Vec4 = math.Vector4D;

pub const Mat2 = math.Matrix2D;
pub const Mat3 = math.Matrix3D;
pub const Mat4 = math.Matrix4D;

pub const Quat = math.QuaternionD;

pub const Hpr = math.HeadingPitchRollD;

pub const vec2 = math.vec2d;
pub const vec3 = math.vec3d;
pub const vec4 = math.vec4d;

pub const mat2 = math.mat2d;
pub const mat3 = math.mat3d;
pub const mat4 = math.mat4d;

pub const quat = math.quatd;
pub const hpr = math.hprd;

pub const EncodedVec3 = struct {
    high: Vec3 = Vec3.zero.clone(),
    low: Vec3 = Vec3.zero.clone(),

    pub fn fromVec3(vec3v: Vec3) EncodedVec3 {
        var result = EncodedVec3{};

        var scratchEncode = EncodedF64{};
        scratchEncode = EncodedVec3.encode(vec3v.x);
        result.high.x = scratchEncode.high;
        result.low.x = scratchEncode.low;

        scratchEncode = EncodedVec3.encode(vec3v.y);
        result.high.y = scratchEncode.high;
        result.low.y = scratchEncode.low;

        scratchEncode = EncodedVec3.encode(vec3v.z);
        result.high.z = scratchEncode.high;
        result.low.z = scratchEncode.low;

        return result;
    }
    const EncodedF64 = struct { high: f64 = 0, low: f64 = 0 };
    pub fn enocde(value: f64) EncodedF64 {
        var result = EncodedF64{};
        var doubleHigh: f64 = 0;
        if (value >= 0.0) {
            doubleHigh = std.math.floor(value / 65536.0) * 65536.0;
            result.high = doubleHigh;
            result.low = value - doubleHigh;
        } else {
            doubleHigh = std.math.floor(-value / 65536.0) * 65536.0;
            result.high = -doubleHigh;
            result.low = value + doubleHigh;
        }
        return result;
    }
};

pub fn toVecNf(comptime T: type, comptime O: type) *const fn (a: *const T) O {
    const res = struct {
        pub fn call(a: *const T) O {
            const v: @Vector(T.n, f32) = @floatCast(a.v);
            return .{ .v = v };
        }
    };
    return res.call;
}
pub fn toMatNf(comptime T: type, comptime O: type) *const fn (a: *const T) O {
    const res = struct {
        pub fn call(a: *const T) O {
            var result: O = undefined;
            inline for (0..T.cols) |coli| {
                const v: @Vector(T.rows, f32) = @floatCast(a.v[coli].v);
                result.v[coli].v = v;
            }
            return result;
        }
    };
    return res.call;
}
pub const toVec2f = toVecNf(Vec2, Vec2f);
pub const toVec3f = toVecNf(Vec3, Vec3f);
pub const toVec4f = toVecNf(Vec4, Vec4f);
pub const toMat2f = toMatNf(Mat2, Mat2f);
pub const toMat3f = toMatNf(Mat3, Mat3f);
pub const toMat4f = toMatNf(Mat4, Mat4f);

test "toVecNf" {
    const v = vec2(1, 2);
    const v1 = toVec2f(&v);
    const v2 = vec2f(1, 2);
    std.testing.expect(math.Vector2.eql(&v1, &v2));
}

test "toMatNf" {
    const v = Mat4.identity();
    const v1 = toMat4f(&v);
    const v2 = Mat4f.identity();
    std.testing.expect(math.Vector2.eql(&v1, &v2));
}
