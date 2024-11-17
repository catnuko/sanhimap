const lib = @import("../lib.zig");
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector3 = math.Vector3;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3;
const Quaternion = math.Quaternion;
const HeadingPitchRoll = math.HeadingPitchRoll;

position:Vector3 = Vector3.fromZero(),
rotation:Quaternion = Quaternion.fromZero(),
scale:Vector3 = Vector3.splat(1),
matrix:Mat4,
matrix_world:Mat4,
const Self = @This();
