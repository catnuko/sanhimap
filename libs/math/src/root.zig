const std = @import("std");
const testing = std.testing;

const vec = @import("vec.zig");
const mat = @import("mat.zig");
const q = @import("quat.zig");
const ray = @import("ray.zig");
const h = @import("hpr.zig");
pub const epsilon = @import("epsilon.zig");
pub usingnamespace epsilon;

/// Public namespaces
pub const collision = @import("collision.zig");

/// Standard f32 precision types
pub const Vec2 = vec.Vec2(f32);
pub const Vec3 = vec.Vec3(f32);
pub const Vec4 = vec.Vec4(f32);
pub const Quat = q.Quat(f32);
pub const Mat2x2 = mat.Mat2x2(f32);
pub const Mat3x3 = mat.Mat3x3(f32);
pub const Mat4x4 = mat.Mat4x4(f32);
pub const Ray = ray.Ray3(f32);
pub const HeadingPitchRoll = h.HeadingPitchRoll(f32);

/// Half-precision f16 types
pub const Vec2h = vec.Vec2(f16);
pub const Vec3h = vec.Vec3(f16);
pub const Vec4h = vec.Vec4(f16);
pub const Mat2x2h = mat.Mat2x2(f16);
pub const Mat3x3h = mat.Mat3x3(f16);
pub const Mat4x4h = mat.Mat4x4(f16);
pub const Rayh = ray.Ray3(f16);

/// Double-precision f64 types
pub const Vec2d = vec.Vec2(f64);
pub const Vec3d = vec.Vec3(f64);
pub const Vec4d = vec.Vec4(f64);
pub const Quatd = q.Quat(f64);
pub const Mat2x2d = mat.Mat2x2(f64);
pub const Mat3x3d = mat.Mat3x3(f64);
pub const Mat4x4d = mat.Mat4x4(f64);
pub const Rayd = ray.Ray3(f64);
pub const HeadingPitchRolld = h.HeadingPitchRoll(f64);

/// Standard f32 precision initializers
pub const vec2 = Vec2.new;
pub const vec3 = Vec3.new;
pub const vec4 = Vec4.new;
pub const vec2FromInt = Vec2.fromInt;
pub const vec3FromInt = Vec3.fromInt;
pub const vec4FromInt = Vec4.fromInt;
pub const quat = Quat.new;
pub const mat2x2 = Mat2x2.new;
pub const mat3x3 = Mat3x3.new;
pub const mat4x4 = Mat4x4.new;
pub const hpr = HeadingPitchRoll.new;

/// Half-precision f16 initializers
pub const vec2h = Vec2h.new;
pub const vec3h = Vec3h.new;
pub const vec4h = Vec4h.new;
pub const vec2hFromInt = Vec2h.fromInt;
pub const vec3hFromInt = Vec3h.fromInt;
pub const vec4hFromInt = Vec4h.fromInt;
pub const mat2x2h = Mat2x2h.new;
pub const mat3x3h = Mat3x3h.new;
pub const mat4x4h = Mat4x4h.new;

/// Double-precision f64 initializers
pub const vec2d = Vec2d.new;
pub const vec3d = Vec3d.new;
pub const vec4d = Vec4d.new;
pub const vec2dFromInt = Vec2d.fromInt;
pub const vec3dFromInt = Vec3d.fromInt;
pub const vec4dFromInt = Vec4d.fromInt;
pub const quatd = Quatd.new;
pub const mat2x2d = Mat2x2d.new;
pub const mat3x3d = Mat3x3d.new;
pub const mat4x4d = Mat4x4d.new;
pub const hprd = HeadingPitchRolld.new;

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
