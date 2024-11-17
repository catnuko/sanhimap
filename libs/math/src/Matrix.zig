const testing = @import("testing.zig");
const math = @import("root.zig");
const vec = @import("Vector.zig");
const Quaternion = @import("./Quaternion.zig").Quaternion;
const HeadingPitchRoll = @import("./HeadingPitchRoll.zig").HeadingPitchRoll;
const stdmath = @import("std").math;
const debug = @import("std").debug;

pub fn Matrix2(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vector4{
        ///     vec4( 1,  0,  0,  0),
        ///     vec4( 0,  1,  0,  0),
        ///     vec4( 0,  0,  1,  0),
        ///     vec4(tx, ty, tz, tw),
        /// }
        /// ```
        ///
        /// Use the new() constructor to write code which visually matches the same layout as you'd
        /// see used in scientific / maths communities.
        v: [cols]Vec,

        /// The number of columns, e.g. Mat3x4.cols == 3
        pub const cols = 2;

        /// The number of rows, e.g. Mat3x4.rows == 4
        pub const rows = 2;

        /// The scalar type of this matrix, e.g. Matrix3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Matrix3.Vec == Vector3
        pub const Vec = vec.Vector2(Scalar);

        /// The Vec type corresponding to the number of rows, e.g. Matrix3.RowVec == Vector3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vector4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const identity = Matrix.fromIdentity();
        /// Constructs a 2x2 matrix with the given rows. For example to write a translation
        /// matrix like in the left part of this equation:
        ///
        /// ```
        /// |1 tx| |x  |   |x+y*tx|
        /// |0 ty| |y=1| = |ty    |
        /// ```
        ///
        /// You would write it with the same visual layout:
        ///
        /// ```
        /// const m = Matrix2.new(
        ///     vec3(1, tx),
        ///     vec3(0, ty),
        /// );
        /// ```
        ///
        /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        pub fn new(r0: *const RowVec, r1: *const RowVec) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(r0.x(), r1.x()),
                Vec.new(r0.y(), r1.y()),
            } };
        }

        /// Transposes the matrix.
        pub fn transpose(m: *const Matrix) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(m.v[0].v[0], m.v[1].v[0]),
                Vec.new(m.v[0].v[1], m.v[1].v[1]),
            } };
        }

        // Constructs a 1D matrix which scales each dimension by the given scalar.
        pub fn scaleScalar(t: T) Matrix {
            return new(
                &RowVec.new(t, 0),
                &RowVec.new(0, 1),
            );
        }

        /// Constructs a 1D matrix which translates coordinates by the given scalar.
        pub fn fromTranslationScalar(t: T) Matrix {
            return new(
                &RowVec.new(1, t),
                &RowVec.new(0, 1),
            );
        }

        pub fn fromRotation(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, -s),
                &RowVec.new(s, c),
            );
        }
        pub fn inverse(m: *const Matrix) Matrix {
            const a0 = m.v[0].v[0];
            const a1 = m.v[0].v[1];
            const a2 = m.v[1].v[0];
            const a3 = m.v[1].v[1];

            var det = a0 * a3 - a2 * a1;

            if (math.isNan(det)) {
                unreachable;
            }
            det = 1.0 / det;

            var res: Matrix = undefined;
            res.v[0].v[0] = a3 * det;
            res.v[0].v[1] = -a1 * det;
            res.v[1].v[0] = -a2 * det;
            res.v[1].v[1] = a0 * det;
            return res;
        }
        pub usingnamespace Shared;
    };
}

pub fn Matrix3(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vector4{
        ///     vec4( 1,  0,  0,  0),
        ///     vec4( 0,  1,  0,  0),
        ///     vec4( 0,  0,  1,  0),
        ///     vec4(tx, ty, tz, tw),
        /// }
        /// ```
        ///
        /// Use the new() constructor to write code which visually matches the same layout as you'd
        /// see used in scientific / maths communities.
        v: [cols]Vec,

        /// The number of columns, e.g. Mat3x4.cols == 3
        pub const cols = 3;

        /// The number of rows, e.g. Mat3x4.rows == 4
        pub const rows = 3;

        /// The scalar type of this matrix, e.g. Matrix3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Matrix3.Vec == Vector3
        pub const Vec = vec.Vector3(Scalar);
        pub const Vector2 = vec.Vector2(Scalar);

        /// The Vec type corresponding to the number of rows, e.g. Matrix3.RowVec == Vector3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vector4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const identity = Matrix.fromIdentity();
        /// Constructs a 3x3 matrix with the given rows. For example to write a translation
        /// matrix like in the left part of this equation:
        ///
        /// ```
        /// |1 0 tx| |x  |   |x+z*tx|
        /// |0 1 ty| |y  | = |y+z*ty|
        /// |0 0 tz| |z=1|   |tz    |
        /// ```
        ///
        /// You would write it with the same visual layout:
        ///
        /// ```
        /// const m = Matrix3.new(
        ///     vec3(1, 0, tx),
        ///     vec3(0, 1, ty),
        ///     vec3(0, 0, tz),
        /// );
        /// ```
        ///
        /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        pub fn new(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(r0.x(), r1.x(), r2.x()),
                Vec.new(r0.y(), r1.y(), r2.y()),
                Vec.new(r0.z(), r1.z(), r2.z()),
            } };
        }
        pub fn fromQuaternion(q: *const Quaternion(T)) Matrix {
            const x2 = q.x() * q.x();
            const xy = q.x() * q.y();
            const xz = q.x() * q.z();
            const xw = q.x() * q.w();
            const y2 = q.y() * q.y();
            const yz = q.y() * q.z();
            const yw = q.y() * q.w();
            const z2 = q.z() * q.z();
            const zw = q.z() * q.w();
            const w2 = q.w() * q.w();

            const m00 = x2 - y2 - z2 + w2;
            const m01 = 2.0 * (xy - zw);
            const m02 = 2.0 * (xz + yw);

            const m10 = 2.0 * (xy + zw);
            const m11 = -x2 + y2 - z2 + w2;
            const m12 = 2.0 * (yz - xw);

            const m20 = 2.0 * (xz - yw);
            const m21 = 2.0 * (yz + xw);
            const m22 = -x2 - y2 + z2 + w2;
            var res: Matrix = undefined;
            res.v[0].v[0] = m00;
            res.v[0].v[1] = m10;
            res.v[0].v[2] = m20;
            res.v[1].v[0] = m01;
            res.v[1].v[1] = m11;
            res.v[1].v[2] = m21;
            res.v[2].v[0] = m02;
            res.v[2].v[1] = m12;
            res.v[2].v[2] = m22;
            return res;
        }
        pub fn fromHeadingPitchRoll(hpr: *const HeadingPitchRoll(T)) Matrix {
            const cosTheta = stdmath.cos(-hpr.p());
            const cosPsi = stdmath.cos(-hpr.h());
            const cosPhi = stdmath.cos(hpr.r());
            const sinTheta = stdmath.sin(-hpr.p());
            const sinPsi = stdmath.sin(-hpr.h());
            const sinPhi = stdmath.sin(hpr.r());

            const m00 = cosTheta * cosPsi;
            const m01 = -cosPhi * sinPsi + sinPhi * sinTheta * cosPsi;
            const m02 = sinPhi * sinPsi + cosPhi * sinTheta * cosPsi;

            const m10 = cosTheta * sinPsi;
            const m11 = cosPhi * cosPsi + sinPhi * sinTheta * sinPsi;
            const m12 = -sinPhi * cosPsi + cosPhi * sinTheta * sinPsi;

            const m20 = -sinTheta;
            const m21 = sinPhi * cosTheta;
            const m22 = cosPhi * cosTheta;
            var res: Matrix = undefined;
            res.v[0].v[0] = m00;
            res.v[0].v[1] = m10;
            res.v[0].v[2] = m20;
            res.v[1].v[0] = m01;
            res.v[1].v[1] = m11;
            res.v[1].v[2] = m21;
            res.v[2].v[0] = m02;
            res.v[2].v[1] = m12;
            res.v[2].v[2] = m22;
            return res;
        }
        /// Transposes the matrix.
        pub fn transpose(m: *const Matrix) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0]),
                Vec.new(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1]),
                Vec.new(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2]),
            } };
        }
        /// Constructs a 2D matrix which translates coordinates by the given vector.
        pub fn fromTranslation(t: *const Vector2) Matrix {
            return new(
                &RowVec.new(1, 0, t.x()),
                &RowVec.new(0, 1, t.y()),
                &RowVec.new(0, 0, 1),
            );
        }
        /// Constructs a 2D matrix which translates coordinates by the given scalar.
        pub fn fromTranslationScalar(t: T) Matrix {
            return fromTranslation(&Vector2.splat(t));
        }

        /// Returns the translation component of the matrix.
        pub fn getTranslation(t: *const Matrix) Vector2 {
            return Vector2.new(t.v[2].x(), t.v[2].y());
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn fromRotationX(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(1, 0, 0),
                &RowVec.new(0, c, -s),
                &RowVec.new(0, s, c),
            );
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn fromRotationY(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, 0, s),
                &RowVec.new(0, 1, 0),
                &RowVec.new(-s, 0, c),
            );
        }

        /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
        pub fn fromRotationZ(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, -s, 0),
                &RowVec.new(s, c, 0),
                &RowVec.new(0, 0, 1),
            );
        }
        pub fn inverse(m: *const Matrix) Matrix {
            const a00 = m.v[0].v[0];
            const a01 = m.v[0].v[1];
            const a02 = m.v[0].v[2];

            const a10 = m.v[1].v[0];
            const a11 = m.v[1].v[1];
            const a12 = m.v[1].v[2];

            const a20 = m.v[2].v[0];
            const a21 = m.v[2].v[1];
            const a22 = m.v[2].v[2];

            const b01 = a22 * a11 - a12 * a21;
            const b11 = -a22 * a10 + a12 * a20;
            const b21 = a21 * a10 - a11 * a20;

            // Calculate the determinant
            var det = a00 * b01 + a01 * b11 + a02 * b21;

            if (math.isNan(det)) {
                unreachable;
            }
            det = 1.0 / det;

            var res: Matrix = undefined;

            res.v[0].v[0] = b01 * det;
            res.v[0].v[1] = (-a22 * a01 + a02 * a21) * det;
            res.v[0].v[2] = (a12 * a01 - a02 * a11) * det;
            res.v[1].v[0] = b11 * det;
            res.v[1].v[1] = (a22 * a00 - a02 * a20) * det;
            res.v[1].v[2] = (-a12 * a00 + a02 * a10) * det;
            res.v[2].v[0] = b21 * det;
            res.v[2].v[1] = (-a21 * a00 + a01 * a20) * det;
            res.v[2].v[2] = (a11 * a00 - a01 * a10) * det;
            return res;
        }
        pub fn lookAt(eye: *const Vec, target: *const Vec, updir: *const Vec)Matrix {
            const zAxis = eye.subtract(target).normalize();
            const xAxis = updir.cross(&zAxis).normalize();
            const yAxis = zAxis.cross(&xAxis).normalize();
            var m = Matrix.fromIdentity();
            m.v[0].v[0] = xAxis.x();
            m.v[0].v[1] = yAxis.x();
            m.v[0].v[2] = zAxis.x();

            m.v[1].v[0] = xAxis.y();
            m.v[1].v[1] = yAxis.y();
            m.v[1].v[2] = zAxis.y();

            m.v[2].v[0] = xAxis.z();
            m.v[2].v[1] = yAxis.z();
            m.v[2].v[2] = zAxis.z();
            return m;
        }
        pub usingnamespace Shared;
    };
}

pub fn Matrix4(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vector4{
        ///     vec4( 1,  0,  0,  0),
        ///     vec4( 0,  1,  0,  0),
        ///     vec4( 0,  0,  1,  0),
        ///     vec4(tx, ty, tz, tw),
        /// }
        /// ```
        ///
        /// Use the new() constructor to write code which visually matches the same layout as you'd
        /// see used in scientific / maths communities.
        v: [cols]Vec,

        /// The number of columns, e.g. Mat3x4.cols == 3
        pub const cols = 4;

        /// The number of rows, e.g. Mat3x4.rows == 4
        pub const rows = 4;

        /// The scalar type of this matrix, e.g. Matrix3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Matrix3.Vec == Vector3
        pub const Vec = vec.Vector4(Scalar);
        pub const Vector3 = vec.Vector3(T);

        /// The Vec type corresponding to the number of rows, e.g. Matrix3.RowVec == Vector3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vector4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const identity = Matrix.fromIdentity();
        /// Constructs a 4x4 matrix with the given rows. For example to write a translation
        /// matrix like in the left part of this equation:
        ///
        /// ```
        /// |1 0 0 tx| |x  |   |x+w*tx|
        /// |0 1 0 ty| |y  | = |y+w*ty|
        /// |0 0 1 tz| |z  |   |z+w*tz|
        /// |0 0 0 tw| |w=1|   |tw    |
        /// ```
        ///
        /// You would write it with the same visual layout:
        ///
        /// ```
        /// const m = Matrix4.new(
        ///     &vec4(1, 0, 0, tx),
        ///     &vec4(0, 1, 0, ty),
        ///     &vec4(0, 0, 1, tz),
        ///     &vec4(0, 0, 0, tw),
        /// );
        /// ```
        ///
        /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        pub fn new(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec, r3: *const RowVec) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(r0.x(), r1.x(), r2.x(), r3.x()),
                Vec.new(r0.y(), r1.y(), r2.y(), r3.y()),
                Vec.new(r0.z(), r1.z(), r2.z(), r3.z()),
                Vec.new(r0.w(), r1.w(), r2.w(), r3.w()),
            } };
        }
        pub inline fn multiplyByPoint(m: *const Matrix, point: *const Vector3) Vector3 {
            const col0 = m.v[0].multiplyByScalar(point.x());
            const col1 = m.v[1].multiplyByScalar(point.y());
            const col2 = m.v[2].multiplyByScalar(point.z());
            const res = col0.add(&col1).add(&col2).add(&m.v[3]);
            return Vector3.new(res.x(), res.y(), res.z());
        }
        pub fn multiplyByPointAsVector(m: *const Matrix, point: *const Vector3) Vector3 {
            const col0 = m.v[0].multiplyByScalar(point.x());
            const col1 = m.v[1].multiplyByScalar(point.y());
            const col2 = m.v[2].multiplyByScalar(point.z());
            const res = col0.add(&col1).add(&col2);
            return Vector3.new(res.x(), res.y(), res.z());
        }
        pub fn multiplyByScale(m: *const Matrix, scale: *const Vector3) Matrix {
            var res: Matrix = undefined;
            res.v[0].v[0] = m.v[0].v[0] * scale.x();
            res.v[0].v[1] = m.v[0].v[1] * scale.x();
            res.v[0].v[2] = m.v[0].v[2] * scale.x();
            res.v[0].v[3] = m.v[0].v[3];

            res.v[1].v[0] = m.v[1].v[0] * scale.y();
            res.v[1].v[1] = m.v[1].v[1] * scale.y();
            res.v[1].v[2] = m.v[1].v[2] * scale.y();
            res.v[1].v[3] = m.v[1].v[3];

            res.v[2].v[0] = m.v[2].v[0] * scale.z();
            res.v[2].v[1] = m.v[2].v[1] * scale.z();
            res.v[2].v[2] = m.v[2].v[2] * scale.z();
            res.v[2].v[3] = m.v[2].v[3];

            res.v[3].v[0] = m.v[3].v[0];
            res.v[3].v[1] = m.v[3].v[1];
            res.v[3].v[2] = m.v[3].v[2];
            res.v[3].v[3] = m.v[3].v[3];
            return res;
        }
        pub inline fn multiplyByUniformScale(m: *const Matrix, scale: T) Matrix {
            return multiplyByScale(m, &Vector3.splat(scale));
        }
        pub fn transformDirection(m: *const Matrix, point: *const Vector3) Vector3 {
            const res = multiplyByPointAsVector(m, point);
            return res.normalize();
        }
        /// Transposes the matrix.
        pub fn transpose(m: *const Matrix) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0], m.v[3].v[0]),
                Vec.new(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1], m.v[3].v[1]),
                Vec.new(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2], m.v[3].v[2]),
                Vec.new(m.v[0].v[3], m.v[1].v[3], m.v[2].v[3], m.v[3].v[3]),
            } };
        }

        pub fn fromTranslation(t: *const Vector3) Matrix {
            return new(
                &RowVec.new(1, 0, 0, t.x()),
                &RowVec.new(0, 1, 0, t.y()),
                &RowVec.new(0, 0, 1, t.z()),
                &RowVec.new(0, 0, 0, 1),
            );
        }
        pub fn fromTranslationScalar(t: T) Matrix {
            return fromTranslation(&Vector3.splat(t));
        }
        pub fn fromRotation(rotation: *const Matrix3(T)) Matrix {
            return new(
                &RowVec.new(rotation.v[0].v[0], rotation.v[1].v[0], rotation.v[2].v[0], 0),
                &RowVec.new(rotation.v[0].v[1], rotation.v[1].v[1], rotation.v[2].v[1], 0),
                &RowVec.new(rotation.v[0].v[2], rotation.v[1].v[2], rotation.v[2].v[2], 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }
        pub fn fromRotationTranslation(rotation: *const Matrix3(T), t: Vector3) Matrix {
            return new(
                &RowVec.new(rotation.v[0].v[0], rotation.v[1].v[0], rotation.v[2].v[0], t.x()),
                &RowVec.new(rotation.v[0].v[1], rotation.v[1].v[1], rotation.v[2].v[1], t.y()),
                &RowVec.new(rotation.v[0].v[2], rotation.v[1].v[2], rotation.v[2].v[2], t.z()),
                &RowVec.new(0, 0, 0, 1),
            );
        }

        /// Returns the translation component of the matrix.
        pub fn getTranslation(t: *const Matrix) Vector3 {
            return Vector3.new(t.v[3].x(), t.v[3].y(), t.v[3].z());
        }
        pub fn getMatrix3(m: *const Matrix) Matrix3(T) {
            var result: Matrix3(T) = undefined;
            result.v[0].v[0] = m.v[0].v[0];
            result.v[0].v[1] = m.v[0].v[1];
            result.v[0].v[2] = m.v[0].v[2];

            result.v[1].v[0] = m.v[1].v[0];
            result.v[1].v[1] = m.v[1].v[1];
            result.v[1].v[2] = m.v[1].v[2];

            result.v[2].v[0] = m.v[2].v[0];
            result.v[2].v[1] = m.v[2].v[1];
            result.v[2].v[2] = m.v[2].v[2];
            return result;
        }
        pub fn getRotation(t: *const Matrix) Matrix3(T) {
            const scale = t.getScale();
            return Matrix3(T).new(
                &Matrix3(T).RowVec.new(t.v[0].v[0] / scale.x(), t.v[1].v[0] / scale.y(), t.v[2].v[0] / scale.z()),
                &Matrix3(T).RowVec.new(t.v[0].v[1] / scale.x(), t.v[1].v[1] / scale.y(), t.v[2].v[1] / scale.z()),
                &Matrix3(T).RowVec.new(t.v[0].v[2] / scale.x(), t.v[1].v[2] / scale.y(), t.v[2].v[2] / scale.z()),
            );
        }
        pub fn setRotation(t: *Matrix, r: *const Matrix3(T)) void {
            const scale = t.getScale();
            t.v[0].v[0] = r.v[0].v[0] * scale.x();
            t.v[0].v[1] = r.v[0].v[1] * scale.x();
            t.v[0].v[2] = r.v[0].v[2] * scale.x();

            t.v[1].v[0] = r.v[1].v[0] * scale.y();
            t.v[1].v[1] = r.v[1].v[1] * scale.y();
            t.v[1].v[2] = r.v[1].v[2] * scale.y();

            t.v[2].v[0] = r.v[2].v[0] * scale.z();
            t.v[2].v[1] = r.v[2].v[1] * scale.z();
            t.v[2].v[2] = r.v[2].v[2] * scale.z();
        }
        pub fn fromScale(s: *const Vector3) Matrix {
            return new(
                &RowVec.new(s.x(), 0, 0, 0),
                &RowVec.new(0, s.y(), 0, 0),
                &RowVec.new(0, 0, s.z(), 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }
        pub inline fn fromScaleScalar(s: T) Matrix {
            return fromScale(&Vector3.splat(s));
        }
        pub fn getScale(m: *const Matrix) Vector3 {
            var col: Vector3 = undefined;
            col.v[0] = Vector3.new(m.v[0].v[0], m.v[0].v[1], m.v[0].v[2]).length();
            col.v[1] = Vector3.new(m.v[1].v[0], m.v[1].v[1], m.v[1].v[2]).length();
            col.v[2] = Vector3.new(m.v[2].v[0], m.v[2].v[1], m.v[2].v[2]).length();
            return col;
        }
        pub inline fn setScaleScalar(m: *Matrix, t: T) void {
            return setScale(m, &Vector3.splat(t));
        }
        pub inline fn setScale(m: *Matrix, s: *const Vector3) void {
            const existingScale = m.getScale();
            const scaleRatio = s.divide(&existingScale);
            m.* = multiplyByScale(m, &scaleRatio);
        }

        pub fn lookAt(eye: *const Vector3, target: *const Vector3, updir: *const Vector3) Matrix {
            const zAxis = eye.subtract(target).normalize();
            const xAxis = updir.cross(&zAxis).normalize();
            const yAxis = zAxis.cross(&xAxis).normalize();
            var res: Matrix = undefined;
            res.v[0].v[0] = xAxis.x();
            res.v[0].v[1] = yAxis.x();
            res.v[0].v[2] = zAxis.x();
            res.v[0].v[3] = 0;
            res.v[1].v[0] = xAxis.y();
            res.v[1].v[1] = yAxis.y();
            res.v[1].v[2] = zAxis.y();
            res.v[1].v[3] = 0;
            res.v[2].v[0] = xAxis.z();
            res.v[2].v[1] = yAxis.z();
            res.v[2].v[2] = zAxis.z();
            res.v[2].v[3] = 0;
            res.v[3].v[0] = -(xAxis.x() * eye.x() + xAxis.y() * eye.y() + xAxis.z() * eye.z());
            res.v[3].v[1] = -(yAxis.x() * eye.x() + yAxis.y() * eye.y() + yAxis.z() * eye.z());
            res.v[3].v[2] = -(zAxis.x() * eye.x() + zAxis.y() * eye.y() + zAxis.z() * eye.z());
            res.v[3].v[3] = 1;
            return res;
        }
        pub fn perspective(fovy: T, aspect: T, near: T, far: T) Matrix {
            const bottom = stdmath.tan(fovy * 0.5);

            const column1Row1 = 1.0 / bottom;
            const column0Row0 = column1Row1 / aspect;
            const column2Row2 = (far + near) / (near - far);
            const column3Row2 = (2.0 * far * near) / (near - far);

            var res: Matrix = undefined;
            res.v[0].v[0] = column0Row0;
            res.v[0].v[1] = 0;
            res.v[0].v[2] = 0;
            res.v[0].v[3] = 0;

            res.v[1].v[0] = 0;
            res.v[1].v[1] = column1Row1;
            res.v[1].v[2] = 0;
            res.v[1].v[3] = 0;

            res.v[2].v[0] = 0;
            res.v[2].v[1] = 0;
            res.v[2].v[2] = column2Row2;
            res.v[2].v[3] = -1;

            res.v[3].v[0] = 0;
            res.v[3].v[1] = 0;
            res.v[3].v[2] = column3Row2;
            res.v[3].v[3] = 0;
            return res;
        }
        pub fn inverse(m: *const Matrix) Matrix {
            const a00 = m.v[0].v[0];
            const a01 = m.v[0].v[1];
            const a02 = m.v[0].v[2];
            const a03 = m.v[0].v[3];

            const a10 = m.v[1].v[0];
            const a11 = m.v[1].v[1];
            const a12 = m.v[1].v[2];
            const a13 = m.v[1].v[3];

            const a20 = m.v[2].v[0];
            const a21 = m.v[2].v[1];
            const a22 = m.v[2].v[2];
            const a23 = m.v[2].v[3];

            const a30 = m.v[3].v[0];
            const a31 = m.v[3].v[1];
            const a32 = m.v[3].v[2];
            const a33 = m.v[3].v[3];
            const b00 = a00 * a11 - a01 * a10;
            const b01 = a00 * a12 - a02 * a10;
            const b02 = a00 * a13 - a03 * a10;
            const b03 = a01 * a12 - a02 * a11;
            const b04 = a01 * a13 - a03 * a11;
            const b05 = a02 * a13 - a03 * a12;
            const b06 = a20 * a31 - a21 * a30;
            const b07 = a20 * a32 - a22 * a30;
            const b08 = a20 * a33 - a23 * a30;
            const b09 = a21 * a32 - a22 * a31;
            const b10 = a21 * a33 - a23 * a31;
            const b11 = a22 * a33 - a23 * a32;

            var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

            if (math.isNan(det)) {
                unreachable;
            }
            det = 1.0 / det;

            var res: Matrix = undefined;

            res.v[0].v[0] = (a11 * b11 - a12 * b10 + a13 * b09) * det;
            res.v[0].v[1] = (a02 * b10 - a01 * b11 - a03 * b09) * det;
            res.v[0].v[2] = (a31 * b05 - a32 * b04 + a33 * b03) * det;
            res.v[0].v[3] = (a22 * b04 - a21 * b05 - a23 * b03) * det;
            res.v[1].v[0] = (a12 * b08 - a10 * b11 - a13 * b07) * det;
            res.v[1].v[1] = (a00 * b11 - a02 * b08 + a03 * b07) * det;
            res.v[1].v[2] = (a32 * b02 - a30 * b05 - a33 * b01) * det;
            res.v[1].v[3] = (a20 * b05 - a22 * b02 + a23 * b01) * det;
            res.v[2].v[0] = (a10 * b10 - a11 * b08 + a13 * b06) * det;
            res.v[2].v[1] = (a01 * b08 - a00 * b10 - a03 * b06) * det;
            res.v[2].v[2] = (a30 * b04 - a31 * b02 + a33 * b00) * det;
            res.v[2].v[3] = (a21 * b02 - a20 * b04 - a23 * b00) * det;
            res.v[3].v[0] = (a11 * b07 - a10 * b09 - a12 * b06) * det;
            res.v[3].v[1] = (a00 * b09 - a01 * b07 + a02 * b06) * det;
            res.v[3].v[2] = (a31 * b01 - a30 * b03 - a32 * b00) * det;
            res.v[3].v[3] = (a20 * b03 - a21 * b01 + a22 * b00) * det;

            return res;
        }
        pub fn fromTranslationQuaternionScale(translationv: *const Vector3, rotation: *const Quaternion(T), scalev: *const Vector3) Matrix {
            const scaleX = scalev.x();
            const scaleY = scalev.y();
            const scaleZ = scalev.z();

            const x2 = rotation.x() * rotation.x();
            const xy = rotation.x() * rotation.y();
            const xz = rotation.x() * rotation.z();
            const xw = rotation.x() * rotation.w();
            const y2 = rotation.y() * rotation.y();
            const yz = rotation.y() * rotation.z();
            const yw = rotation.y() * rotation.w();
            const z2 = rotation.z() * rotation.z();
            const zw = rotation.z() * rotation.w();
            const w2 = rotation.w() * rotation.w();

            const m00 = x2 - y2 - z2 + w2;
            const m01 = 2.0 * (xy - zw);
            const m02 = 2.0 * (xz + yw);

            const m10 = 2.0 * (xy + zw);
            const m11 = -x2 + y2 - z2 + w2;
            const m12 = 2.0 * (yz - xw);

            const m20 = 2.0 * (xz - yw);
            const m21 = 2.0 * (yz + xw);
            const m22 = -x2 - y2 + z2 + w2;

            var res: Matrix = undefined;
            res.v[0].v[0] = m00 * scaleX;
            res.v[0].v[1] = m10 * scaleX;
            res.v[0].v[2] = m20 * scaleX;
            res.v[0].v[3] = 0.0;
            res.v[1].v[0] = m01 * scaleY;
            res.v[1].v[1] = m11 * scaleY;
            res.v[1].v[2] = m21 * scaleY;
            res.v[1].v[3] = 0.0;
            res.v[2].v[0] = m02 * scaleZ;
            res.v[2].v[1] = m12 * scaleZ;
            res.v[2].v[2] = m22 * scaleZ;
            res.v[2].v[3] = 0.0;
            res.v[3].v[0] = translationv.x();
            res.v[3].v[1] = translationv.y();
            res.v[3].v[2] = translationv.z();
            res.v[3].v[3] = 1.0;
            return res;
        }
        pub fn getColVector3(m: *const Matrix, i: usize) Vector3 {
            return Vector3.new(m.v[i].v[0], m.v[i].v[1], m.v[i].v[2]);
        }

        pub const fromIdentity = Shared.fromIdentity;
        pub const getRow = Shared.getRow;
        pub const getCol = Shared.getCol;
        pub const setRow = Shared.setRow;
        pub const setCol = Shared.setCol;
        pub const multiply = Shared.multiply;
        pub const multiplyByVector = Shared.multiplyByVector;
        pub const multiplyByScalar = Shared.multiplyByScalar;
        pub const negate = Shared.negate;
        pub const eql = Shared.eql;
        pub const eqlApprox = Shared.eqlApprox;
        pub const clone = Shared.clone;
        pub const fromColumnMajorArray = Shared.fromColumnMajorArray;
        pub const toColumnMajorArray = Shared.toColumnMajorArray;
        pub const print = Shared.print;
    };
}

pub fn MatShared(comptime RowVec: type, comptime ColVec: type, comptime Matrix: type) type {
    return struct {
        /// Matrix multiplication a*b
        pub fn multiply(a: *const Matrix, b: *const Matrix) Matrix {
            @setEvalBranchQuota(10000);
            var result: Matrix = undefined;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    var sum: RowVec.T = 0.0;
                    inline for (0..RowVec.n) |i| {
                        // Note: we directly access rows/columns below as it is much faster **in
                        // debug builds**, instead of using these helpers:
                        //
                        // sum += a.rowi(rowi).multiply(&b.coli(coli)).v[i];
                        sum += a.v[i].v[rowi] * b.v[coli].v[i];
                    }
                    result.v[coli].v[rowi] = sum;
                }
            }
            return result;
        }

        pub fn fromIdentity() Matrix {
            var result: Matrix = undefined;
            inline for (0..Matrix.cols) |coli| {
                inline for (0..Matrix.rows) |rowi| {
                    result.v[coli].v[rowi] = if (rowi == coli) 1 else 0;
                }
            }
            return result;
        }

        /// Matrix * Vector multiplication
        pub fn multiplyByVector(matrix: *const Matrix, vector: *const ColVec) ColVec {
            var result = [_]ColVec.T{0} ** ColVec.n;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..ColVec.n) |i| {
                    result[i] += matrix.v[rowi].v[i] * vector.v[rowi];
                }
            }
            return ColVec{ .v = result };
        }

        pub fn multiplyByScalar(matrix: *const Matrix, scalar: Matrix.T) Matrix {
            var result: Matrix = undefined;
            inline for (0..Matrix.cols) |coli| {
                inline for (0..Matrix.rows) |rowi| {
                    result.v[coli].v[rowi] = matrix.v[coli].v[rowi] * scalar;
                }
            }
            return result;
        }

        pub fn multiplyByScale(matrix: *const Matrix, scale: *const ColVec) Matrix {
            var result: Matrix = undefined;
            inline for (0..Matrix.cols) |coli| {
                inline for (0..Matrix.rows) |rowi| {
                    result.v[coli].v[rowi] = matrix.v[coli].v[rowi] * scale.v[coli];
                }
            }
            return result;
        }
        pub inline fn multiplyByUniformScale(m: *const Matrix, scale: Matrix.T) Matrix {
            return multiplyByScale(m, &ColVec.splat(scale));
        }
        pub inline fn negate(matrix: *const Matrix) Matrix {
            return multiplyByScalar(matrix, -1);
        }

        pub fn fromColumnMajorArray(slice: *const [Matrix.cols * Matrix.rows]Matrix.T) Matrix {
            var result: Matrix = undefined;
            var i: usize = 0;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    result.v[rowi].v[coli] = slice[i];
                    i += 1;
                }
            }
            return result;
        }

        pub fn toColumnMajorArray(a: *const Matrix) [Matrix.cols * Matrix.rows]Matrix.T {
            var slice = [1]Matrix.T{0} ** (Matrix.cols * Matrix.rows);
            var i: usize = 0;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    slice[i] = a.v[rowi].v[coli];
                    i += 1;
                }
            }
            return slice;
        }

        /// Check if two matrices are approximately equal. Returns true if the absolute difference between
        /// each element in matrix is less than or equal to the specified tolerance.
        pub fn eqlApprox(a: *const Matrix, b: *const Matrix, tolerance: ColVec.T) bool {
            inline for (0..Matrix.rows) |rowi| {
                if (!ColVec.eqlApprox(&a.v[rowi], &b.v[rowi], tolerance)) {
                    return false;
                }
            }
            return true;
        }

        /// Check if two matrices are approximately equal. Returns true if the absolute difference between
        /// each element in matrix is less than or equal to the epsilon tolerance.
        pub fn eql(a: *const Matrix, b: *const Matrix) bool {
            inline for (0..Matrix.rows) |rowi| {
                if (!ColVec.eql(&a.v[rowi], &b.v[rowi])) {
                    return false;
                }
            }
            return true;
        }

        pub fn getRow(m: *const Matrix, i: usize) RowVec {
            var result = [_]RowVec.T{0} ** RowVec.n;
            inline for (0..Matrix.cols) |coli| {
                result[coli] = m.v[coli].v[i];
            }
            return ColVec{ .v = result };
        }

        pub fn getCol(m: *const Matrix, i: usize) RowVec {
            var result = [_]ColVec.T{0} ** ColVec.n;
            inline for (0..Matrix.rows) |rowi| {
                result[rowi] = m.v[i].v[rowi];
            }
            return ColVec{ .v = result };
        }

        pub fn setRow(m: *Matrix, i: usize, o: *const RowVec) void {
            inline for (0..Matrix.cols) |coli| {
                m.v[coli].v[i] = o.v[coli];
            }
        }

        pub fn setCol(m: *Matrix, i: usize, o: *const ColVec) void {
            inline for (0..Matrix.rows) |rowi| {
                m.v[i].v[rowi] = o.v[rowi];
            }
        }

        pub fn fromScale(o: *const ColVec) Matrix {
            var result = Matrix.fromIdentity();
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    if (rowi == coli) {
                        result.v[coli].v[rowi] = o.v[coli];
                    }
                }
            }
            return result;
        }
        pub fn fromScaleScalar(s: Matrix.T) Matrix {
            const tempScale = ColVec.splat(s);
            return fromScale(&tempScale);
        }
        pub fn getScale(m: *const Matrix) ColVec {
            var result = [_]ColVec.T{0} ** ColVec.n;
            inline for (0..Matrix.rows) |rowi| {
                result[rowi] = m.getCol(rowi).length();
            }
            return ColVec{ .v = result };
        }
        pub fn setScale(m: *Matrix, s: *const ColVec) void {
            const existingScale = m.getScale();
            const scaleRatio = s.divide(&existingScale);

            inline for (0..Matrix.cols) |coli| {
                m.v[coli] = m.v[coli].multiplyByScalar(scaleRatio.v[coli]);
            }
        }
        pub fn setScaleScalar(m: *Matrix, s: Matrix.T) void {
            setScale(m, &ColVec.splat(s));
        }
        pub fn clone(m: *const Matrix) Matrix {
            return Matrix{ .v = m.v };
        }
        pub fn print(m: *const Matrix) void {
            debug.print("\n", .{});
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..ColVec.n) |coli| {
                    const colv = m.v[coli].v[rowi];
                    debug.print("{},", .{colv});
                }
                debug.print("\n", .{});
            }
        }
    };
}

test "Matrix4_fromArray_toArray" {
    const std = @import("std");
    var slice = [1]f64{0} ** 16;
    //x axis
    slice[0] = 1;
    slice[1] = 2;
    slice[2] = 3;
    slice[3] = 4;
    //y axis
    slice[4] = 5;
    slice[5] = 6;
    slice[6] = 7;
    slice[7] = 8;
    //z axis
    slice[8] = 9;
    slice[9] = 10;
    slice[10] = 11;
    slice[11] = 12;
    //point
    slice[12] = 13;
    slice[13] = 14;
    slice[14] = 15;
    slice[15] = 16;
    const actual = Matrix4(f64).fromColumnMajorArray(&slice);
    const expect = Matrix4(f64).new(
        &math.vec4d(1, 5, 9, 13),
        &math.vec4d(2, 6, 10, 14),
        &math.vec4d(3, 7, 11, 15),
        &math.vec4d(4, 8, 12, 16),
    );
    try testing.expect(Matrix4(f64), expect).eql(actual);
    const actualSlice = actual.toColumnMajorArray();
    try std.testing.expect(std.mem.eql(f64, &slice, &actualSlice));
}

test "gpu_compatibility" {
    // https://www.w3.org/TR/WGSL/#alignment-and-size
    try testing.expect(usize, 16).eql(@sizeOf(math.Matrix2));
    try testing.expect(usize, 48).eql(@sizeOf(math.Matrix3));
    try testing.expect(usize, 64).eql(@sizeOf(math.Matrix4));

    try testing.expect(usize, 32).eql(@sizeOf(math.Matrix2D)); // speculative
    try testing.expect(usize, 96).eql(@sizeOf(math.Matrix3D)); // speculative
    try testing.expect(usize, 128).eql(@sizeOf(math.Matrix4D)); // speculative
}

test "zero_struct_overhead" {
    // Proof that using e.g. [3]Vector3 is equal to [3]@Vector(3, f32)
    try testing.expect(usize, @alignOf([2]@Vector(2, f32))).eql(@alignOf(math.Matrix2));
    try testing.expect(usize, @alignOf([3]@Vector(3, f32))).eql(@alignOf(math.Matrix3));
    try testing.expect(usize, @alignOf([4]@Vector(4, f32))).eql(@alignOf(math.Matrix4));
    try testing.expect(usize, @sizeOf([2]@Vector(2, f32))).eql(@sizeOf(math.Matrix2));
    try testing.expect(usize, @sizeOf([3]@Vector(3, f32))).eql(@sizeOf(math.Matrix3));
    try testing.expect(usize, @sizeOf([4]@Vector(4, f32))).eql(@sizeOf(math.Matrix4));
}

test "n" {
    try testing.expect(usize, 3).eql(math.Matrix3.rows);
    try testing.expect(usize, 3).eql(math.Matrix3.rows);
    try testing.expect(type, math.Vector3).eql(math.Matrix3.Vec);
    try testing.expect(usize, 3).eql(math.Matrix3.Vec.n);
}

test "new" {
    try testing.expect(math.Matrix3, math.mat3(
        &math.vec3(1, 0, 1337),
        &math.vec3(0, 1, 7331),
        &math.vec3(0, 0, 1),
    )).eql(math.Matrix3{
        .v = [_]math.Vector3{
            math.Vector3.new(1, 0, 0),
            math.Vector3.new(0, 1, 0),
            math.Vector3.new(1337, 7331, 1),
        },
    });
}

test "Matrix2_ident" {
    try testing.expect(math.Matrix2, math.Matrix2.identity).eql(math.Matrix2{
        .v = [_]math.Vector2{
            math.Vector2.new(1, 0),
            math.Vector2.new(0, 1),
        },
    });
}

test "Matrix3_ident" {
    try testing.expect(math.Matrix3, math.Matrix3.identity).eql(math.Matrix3{
        .v = [_]math.Vector3{
            math.Vector3.new(1, 0, 0),
            math.Vector3.new(0, 1, 0),
            math.Vector3.new(0, 0, 1),
        },
    });
}

test "Matrix4_ident" {
    try testing.expect(math.Matrix4, math.Matrix4.identity).eql(math.Matrix4{
        .v = [_]math.Vector4{
            math.Vector4.new(1, 0, 0, 0),
            math.Vector4.new(0, 1, 0, 0),
            math.Vector4.new(0, 0, 1, 0),
            math.Vector4.new(0, 0, 0, 1),
        },
    });
}

test "Matrix2_row" {
    const m = math.Matrix2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vector2, math.vec2(0, 1)).eql(m.getRow(0));
    try testing.expect(math.Vector2, math.vec2(2, 3)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Matrix2_col" {
    const m = math.Matrix2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vector2, math.vec2(0, 2)).eql(m.getCol(0));
    try testing.expect(math.Vector2, math.vec2(1, 3)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Matrix3_row" {
    const m = math.Matrix3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vector3, math.vec3(0, 1, 2)).eql(m.getRow(0));
    try testing.expect(math.Vector3, math.vec3(3, 4, 5)).eql(m.getRow(1));
    try testing.expect(math.Vector3, math.vec3(6, 7, 8)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Matrix3_col" {
    const m = math.Matrix3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vector3, math.vec3(0, 3, 6)).eql(m.getCol(0));
    try testing.expect(math.Vector3, math.vec3(1, 4, 7)).eql(m.getCol(1));
    try testing.expect(math.Vector3, math.vec3(2, 5, 8)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Matrix4_row" {
    const m = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vector4, math.vec4(0, 1, 2, 3)).eql(m.getRow(0));
    try testing.expect(math.Vector4, math.vec4(4, 5, 6, 7)).eql(m.getRow(1));
    try testing.expect(math.Vector4, math.vec4(8, 9, 10, 11)).eql(m.getRow(2));
    try testing.expect(math.Vector4, math.vec4(12, 13, 14, 15)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Matrix4_col" {
    const m = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vector4, math.vec4(0, 4, 8, 12)).eql(m.getCol(0));
    try testing.expect(math.Vector4, math.vec4(1, 5, 9, 13)).eql(m.getCol(1));
    try testing.expect(math.Vector4, math.vec4(2, 6, 10, 14)).eql(m.getCol(2));
    try testing.expect(math.Vector4, math.vec4(3, 7, 11, 15)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Matrix2_transpose" {
    const m = math.Matrix2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Matrix2, math.Matrix2.new(
        &math.vec2(0, 2),
        &math.vec2(1, 3),
    )).eql(m.transpose());
}

test "Matrix3_transpose" {
    const m = math.Matrix3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Matrix3, math.Matrix3.new(
        &math.vec3(0, 3, 6),
        &math.vec3(1, 4, 7),
        &math.vec3(2, 5, 8),
    )).eql(m.transpose());
}

test "Matrix4_transpose" {
    const m = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Matrix4, math.Matrix4.new(
        &math.vec4(0, 4, 8, 12),
        &math.vec4(1, 5, 9, 13),
        &math.vec4(2, 6, 10, 14),
        &math.vec4(3, 7, 11, 15),
    )).eql(m.transpose());
}

test "Matrix2_fromScaleScalar" {
    const m = math.Matrix2.fromScaleScalar(2);
    try testing.expect(math.Matrix2, math.Matrix2.new(
        &math.vec2(2, 0),
        &math.vec2(0, 2),
    )).eql(m);
}

test "Matrix3_fromScale" {
    const m = math.Matrix3.fromScale(&math.vec3(2, 3, 1));
    try testing.expect(math.Matrix3, math.Matrix3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 3, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Matrix3_fromScaleScalar" {
    const m = math.Matrix3.fromScaleScalar(2);
    try testing.expect(math.Matrix3, math.Matrix3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 2),
    )).eql(m);
}

test "Matrix4_fromScale" {
    const m = math.Matrix4.fromScale(&math.vec3(2, 3, 4));
    try testing.expect(math.Matrix4, math.Matrix4.new(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 3, 0, 0),
        &math.vec4(0, 0, 4, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Matrix4_fromScaleScalar" {
    const m = math.Matrix4.fromScaleScalar(2);
    try testing.expect(math.Matrix4, math.Matrix4.new(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 2, 0, 0),
        &math.vec4(0, 0, 2, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Matrix3_fromTranslation" {
    const m = math.Matrix3.fromTranslation(&math.vec2(2, 3));
    try testing.expect(math.Matrix3, math.Matrix3.new(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 3),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Matrix4_fromTranslation" {
    const m = math.Matrix4.fromTranslation(&math.vec3(2, 3, 4));
    try testing.expect(math.Matrix4, math.Matrix4.new(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 3),
        &math.vec4(0, 0, 1, 4),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Matrix3_fromTranslationScalar" {
    const m = math.Matrix3.fromTranslationScalar(2);
    try testing.expect(math.Matrix3, math.Matrix3.new(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 2),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Matrix2_fromTranslationScalar" {
    const m = math.Matrix2.fromTranslationScalar(2);
    try testing.expect(math.Matrix2, math.Matrix2.new(
        &math.vec2(1, 2),
        &math.vec2(0, 1),
    )).eql(m);
}

test "Matrix4_fromTranslationScalar" {
    const m = math.Matrix4.fromTranslationScalar(2);
    try testing.expect(math.Matrix4, math.Matrix4.new(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 2),
        &math.vec4(0, 0, 1, 2),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Matrix3_getTranslation" {
    const m = math.Matrix3.fromTranslation(&math.vec2(2, 3));
    try testing.expect(math.Vector2, math.vec2(2, 3)).eql(m.getTranslation());
}

test "Matrix4_getTranslation" {
    const m = math.Matrix4.fromTranslation(&math.vec3(2, 3, 4));
    try testing.expect(math.Vector3, math.vec3(2, 3, 4)).eql(m.getTranslation());
}

test "Matrix2_mulVec_vec2_ident" {
    const v = math.Vector2.splat(1);
    const identity = math.Matrix2.identity;
    const expected = v;
    const m = math.Matrix2.multiplyByVector(&identity, &v);

    try testing.expect(math.Vector2, expected).eql(m);
}

test "Matrix2_mulVec_vec2" {
    const v = math.Vector2.splat(1);
    const mat = math.Matrix2.new(
        &math.vec2(2, 0),
        &math.vec2(0, 2),
    );

    const m = math.Matrix2.multiplyByVector(&mat, &v);
    const expected = math.vec2(2, 2);
    try testing.expect(math.Vector2, expected).eql(m);
}

test "Matrix3_mulVec_vec3_ident" {
    const v = math.Vector3.splat(1);
    const identity = math.Matrix3.identity;
    const expected = v;
    const m = math.Matrix3.multiplyByVector(&identity, &v);

    try testing.expect(math.Vector3, expected).eql(m);
}

test "Matrix3_mulVec_vec3" {
    const v = math.Vector3.splat(1);
    const mat = math.Matrix3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 3),
    );

    const m = math.Matrix3.multiplyByVector(&mat, &v);
    const expected = math.vec3(2, 2, 3);
    try testing.expect(math.Vector3, expected).eql(m);
}

test "Matrix4_mulVec_vec4" {
    const v = math.vec4(2, 5, 1, 8);
    const mat = math.Matrix4.new(
        &math.vec4(1, 0, 2, 0),
        &math.vec4(0, 3, 0, 4),
        &math.vec4(0, 0, 5, 0),
        &math.vec4(6, 0, 0, 7),
    );

    const m = math.Matrix4.multiplyByVector(&mat, &v);
    const expected = math.vec4(4, 47, 5, 68);
    try testing.expect(math.Vector4, expected).eql(m);
}

test "Matrix2_multiply" {
    const a = math.Matrix2.new(
        &math.vec2(4, 2),
        &math.vec2(7, 9),
    );
    const b = math.Matrix2.new(
        &math.vec2(5, -7),
        &math.vec2(6, -3),
    );
    const c = math.Matrix2.multiply(&a, &b);

    const expected = math.Matrix2.new(
        &math.vec2(32, -34),
        &math.vec2(89, -76),
    );
    try testing.expect(math.Matrix2, expected).eql(c);
}

test "Matrix3_multiply" {
    const a = math.Matrix3.new(
        &math.vec3(4, 2, -3),
        &math.vec3(7, 9, -8),
        &math.vec3(-1, 8, -8),
    );
    const b = math.Matrix3.new(
        &math.vec3(5, -7, -8),
        &math.vec3(6, -3, 2),
        &math.vec3(-3, -4, 4),
    );
    const c = math.Matrix3.multiply(&a, &b);

    const expected = math.Matrix3.new(
        &math.vec3(41, -22, -40),
        &math.vec3(113, -44, -70),
        &math.vec3(67, 15, -8),
    );
    try testing.expect(math.Matrix3, expected).eql(c);
}

test "Matrix4_multiply" {
    const a = math.Matrix4.new(
        &math.vec4(10, -5, 6, -2),
        &math.vec4(0, -1, 0, 9),
        &math.vec4(-1, 6, -4, 8),
        &math.vec4(9, -8, -6, -10),
    );
    const b = math.Matrix4.new(
        &math.vec4(7, -7, -3, -8),
        &math.vec4(1, -1, -7, -2),
        &math.vec4(-10, 2, 2, -2),
        &math.vec4(10, -7, 7, 1),
    );
    const c = math.Matrix4.multiply(&a, &b);

    const expected = math.Matrix4.new(
        &math.vec4(-15, -39, 3, -84),
        &math.vec4(89, -62, 70, 11),
        &math.vec4(119, -63, 9, 12),
        &math.vec4(15, 3, -53, -54),
    );
    try testing.expect(math.Matrix4, expected).eql(c);
}

test "Matrix4_eql_not_ident" {
    const m1 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.5, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Matrix4.eql(&m1, &m2)).eql(false);
}

test "Matrix4_eql_ident" {
    const m1 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Matrix4.eql(&m1, &m2)).eql(true);
}

test "Matrix4_eqlApprox_not_ident" {
    const m1 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.11, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Matrix4.eqlApprox(&m1, &m2, 0.1)).eql(false);
}

test "Matrix4_eqlApprox_ident" {
    const m1 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Matrix4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.09, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Matrix4.eqlApprox(&m1, &m2, 0.1)).eql(true);
}

test "Matrix2_setScale" {
    const oldScale = math.Vector2.new(2, 3);
    const newScale = math.Vector2.new(4, 5);
    var matrix = math.Matrix2.fromScale(&oldScale);
    try testing.expect(math.Vector2, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vector2, newScale).eql(matrix.getScale());
}

test "Matrix3_setScale" {
    const oldScale = math.Vector3.new(2, 3, 4);
    const newScale = math.Vector3.new(5, 6, 7);
    var matrix = math.Matrix3.fromScale(&oldScale);
    try testing.expect(math.Vector3, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vector3, newScale).eql(matrix.getScale());
}

test "Matrix4_setScale" {
    const oldScale = math.Vector3.new(2, 3, 4);
    const newScale = math.Vector3.new(5, 6, 7);
    var matrix = math.Matrix3.fromScale(&oldScale);
    try testing.expect(math.Vector3, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vector3, newScale).eql(matrix.getScale());
}

test "Matrix4_multiplyByPoint" {
    const array = [_]f64{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const left = math.Matrix4D.fromColumnMajorArray(&array).transpose();
    const right = math.vec3d(17, 18, 19);
    const expected = math.vec3d(114, 334, 554);
    try testing.expect(math.Vector3D, expected).eql(left.multiplyByPoint(&right));
}

test "Matrix4_multiplyByPointAsVector" {
    const array = [_]f64{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const left = math.Matrix4D.fromColumnMajorArray(&array).transpose();
    const right = math.vec3d(17, 18, 19);
    const expected = math.vec3d(110, 326, 542);
    try testing.expect(math.Vector3D, expected).eql(left.multiplyByPointAsVector(&right));
}

test "Matrix4_multiplyByScalar" {
    const array = [_]f64{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const left = math.Matrix4D.fromColumnMajorArray(&array).transpose();
    const array2 = [_]f64{ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32 };
    const expected = math.Matrix4D.fromColumnMajorArray(&array2).transpose();
    try testing.expect(math.Matrix4D, expected).eql(left.multiplyByScalar(2));
}

test "Matrix4_negate" {
    const array = [_]f64{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const left = math.Matrix4D.fromColumnMajorArray(&array).transpose();
    const array2 = [_]f64{ -1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, -9.0, -10.0, -11.0, -12.0, -13.0, -14.0, -15.0, -16.0 };
    const expected = math.Matrix4D.fromColumnMajorArray(&array2).transpose();
    try testing.expect(math.Matrix4D, expected).eql(left.negate());
}

test "Matrix4_multiplyByScale" {
    {
        const left = math.Matrix4D.fromColumnMajorArray(&.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0, 0, 0, 1 }).transpose();
        const scale = math.vec3d(1, 1, 1);
        const expected = left.multiply(&math.Matrix4D.fromScale(&scale));
        try testing.expect(math.Matrix4D, expected).eql(left.multiplyByScale(&scale));
    }
    {
        const left = math.Matrix4D.fromColumnMajorArray(&.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0, 0, 0, 1 }).transpose();
        const scale = math.vec3d(2, 3, 4);
        const expected = left.multiply(&math.Matrix4D.fromScale(&scale));
        try testing.expect(math.Matrix4D, expected).eql(left.multiplyByScale(&scale));
    }
}

test "Matrix4_multiplyByUniformScale" {
    const left = math.Matrix4D.fromColumnMajorArray(&.{ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }).transpose();
    const scale: f64 = 2;
    const expected = math.Matrix4D.fromColumnMajorArray(&.{ 2 * scale, 3 * scale, 4 * scale, 5, 6 * scale, 7 * scale, 8 * scale, 9, 10 * scale, 11 * scale, 12 * scale, 13, 14, 15, 16, 17 }).transpose();
    try testing.expect(math.Matrix4D, expected).eql(left.multiplyByUniformScale(scale));
}

test "Matrix4_inverse" {
    const left = math.Matrix4D.fromColumnMajorArray(&.{ 0.72, 0.7, 0.0, 0.0, -0.4, 0.41, 0.82, 0.0, 0.57, -0.59, 0.57, -3.86, 0.0, 0.0, 0.0, 1.0 }).transpose();
    const expected = math.Matrix4D.fromColumnMajorArray(&.{ 0.7150830193944467, -0.3976559229803265, 0.5720664155155574, 2.2081763638900513, 0.6930574657657118, 0.40901752077976433, -0.5884111702445733, -2.271267117144053, 0.0022922521876059163, 0.8210249357172755, 0.5732623731786561, 2.2127927604696125, 0.0, 0.0, 0.0, 1.0 }).transpose();
    try testing.expect(math.Matrix4D, expected).eql(left.inverse());
}

test "Matrix4_fromTranslationQuaternionScale" {
    const expected = math.Matrix4D.fromColumnMajorArray(&.{ 7.0, 0.0, 0.0, 1.0, 0.0, 0.0, 9.0, 2.0, 0.0, -8.0, 0.0, 3.0, 0.0, 0.0, 0.0, 1.0 }).transpose();
    const returnedResult = math.Matrix4D.fromTranslationQuaternionScale(
        &math.vec3d(1.0, 2.0, 3.0), // translation
        &math.QuaternionD.fromAxisAngle(&math.Vector3D.unit_x, math.degreesToRadians(-90.0)), // rotation
        &math.vec3d(7.0, 8.0, 9.0),
    ); // scale
    try testing.expect(bool, true).eql(expected.eqlApprox(&returnedResult, math.epsilon14));
}

test "Matrix4_lookAt" {
    const position = math.vec3d(0.13089289583616875, 0.6058574068283575, 2.7756337072375956);
    const target = math.Vector3D.fromZero();
    const up = math.Vector3D.unit_y.clone();
    const m = math.Matrix3D.lookAt(&position, &target, &up);
    const mm = math.Matrix4D.fromRotation(&m);
    const expect = math.Matrix4D.fromColumnMajorArray(&.{ 0.9988899201242548, 0, -0.04710549303594798, 0, -0.010034882991636218, 0.9770456595353209, -0.2127935156590389, 0, 0.04602421751104426, 0.21302999597049582, 0.9759610608109867, 0, 0, 0, 0, 1 }).transpose();
    try testing.expect(bool,true).eql(expect.eqlApprox(&mm, math.epsilon11));
}
