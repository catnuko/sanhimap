const std = @import("std");
const testing = std.testing;

const vec = @import("Vector.zig");
const mat = @import("Matrix.zig");
const q = @import("Quaternion.zig");
const ray = @import("Ray3.zig");
const h = @import("HeadingPitchRoll.zig");
pub const epsilon = @import("epsilon.zig");
pub usingnamespace epsilon;

/// Standard f32 precision types
pub const Vector2 = vec.Vector2(f32);
pub const Vector3 = vec.Vector3(f32);
pub const Vector4 = vec.Vector4(f32);
pub const Quaternion = q.Quaternion(f32);
pub const Matrix2 = mat.Matrix2(f32);
pub const Matrix3 = mat.Matrix3(f32);
pub const Matrix4 = mat.Matrix4(f32);
pub const Ray = ray.Ray3(f32);
pub const HeadingPitchRoll = h.HeadingPitchRoll(f32);

/// Double-precision f64 types
pub const Vector2D = vec.Vector2(f64);
pub const Vector3D = vec.Vector3(f64);
pub const Vector4D = vec.Vector4(f64);
pub const QuaternionD = q.Quaternion(f64);
pub const Matrix2D = mat.Matrix2(f64);
pub const Matrix3D = mat.Matrix3(f64);
pub const Matrix4D = mat.Matrix4(f64);
pub const RayD = ray.Ray3(f64);
pub const HeadingPitchRollD = h.HeadingPitchRoll(f64);

/// Standard f32 precision initializers
pub const vec2 = Vector2.new;
pub const vec3 = Vector3.new;
pub const vec4 = Vector4.new;
pub const vec2FromInt = Vector2.fromInt;
pub const vec3FromInt = Vector3.fromInt;
pub const vec4FromInt = Vector4.fromInt;
pub const quat = Quaternion.new;
pub const mat2 = Matrix2.new;
pub const mat3 = Matrix3.new;
pub const mat4 = Matrix4.new;
pub const hpr = HeadingPitchRoll.new;

/// Double-precision f64 initializers
pub const vec2d = Vector2D.new;
pub const vec3d = Vector3D.new;
pub const vec4d = Vector4D.new;
pub const vec2dFromInt = Vector2D.fromInt;
pub const vec3dFromInt = Vector3D.fromInt;
pub const vec4dFromInt = Vector4D.fromInt;
pub const quatd = QuaternionD.new;
pub const mat2d = Matrix2D.new;
pub const mat3d = Matrix3D.new;
pub const mat4d = Matrix4D.new;
pub const hprd = HeadingPitchRollD.new;

test {
    testing.refAllDeclsRecursive(@This());
}

// std.math customizations
pub const eql = std.math.approxEqAbs;
pub const eps = std.math.floatEps;
pub const eps_f16 = std.math.floatEps(f16);
pub const eps_f32 = std.math.floatEps(f32);
pub const eps_f64 = std.math.floatEps(f64);
pub const nan_f16 = std.math.nan(f16);
pub const nan_f32 = std.math.nan(f32);
pub const nan_f64 = std.math.nan(f64);

pub usingnamespace std.math;

pub fn asinClamped(value: anytype) @TypeOf(value) {
    return std.math.asin(std.math.clamp(value, -1.0, 1.0));
}
