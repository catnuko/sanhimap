const lib = @import("../lib.zig");
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector3D = math.Vector3D;
const Mat4 = math.Matrix4D;
const Mat3 = math.Matrix3D;
const QuaternionD = math.QuaternionD;
const HeadingPitchRoll = math.HeadingPitchRoll;

position:Vector3D = Vector3D.fromZero(),
rotation:QuaternionD = QuaternionD.fromZero(),
scale:Vector3D = Vector3D.splat(1),
matrix:Mat4,
matrix_world:Mat4,
const Self = @This();
