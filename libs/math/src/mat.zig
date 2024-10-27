const testing = @import("testing.zig");
const math = @import("root.zig");
const vec = @import("vec.zig");
const stdmath = @import("std").math;

pub fn Mat2x2(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vec4{
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

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Mat3x3.Vec == Vec3
        pub const Vec = vec.Vec2(Scalar);

        /// The Vec type corresponding to the number of rows, e.g. Mat3x3.RowVec == Vec3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vec4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const ident = Matrix.new(
            &RowVec.new(1, 0),
            &RowVec.new(0, 1),
        );

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
        /// const m = Mat2x2.new(
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
        pub fn translateScalar(t: T) Matrix {
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
        pub const getRow = Shared.getRow;
        pub const getCol = Shared.getCol;
        pub const setRow = Shared.setRow;
        pub const setCol = Shared.setCol;
        pub const fromScale = Shared.fromScale;
        pub const fromUniformScale = Shared.fromUniformScale;
        pub const scale = fromScale;
        pub const setScale = Shared.setScale;
        pub const getScale = Shared.getScale;
        pub const mul = Shared.mul;
        pub const mulVec = Shared.mulVec;
        pub const clone = Shared.clone;
        pub const fromArray = Shared.fromArray;
        pub const toArray = Shared.toArray;
    };
}

pub fn Mat3x3(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vec4{
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

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Mat3x3.Vec == Vec3
        pub const Vec = vec.Vec3(Scalar);
        pub const Vec2 = vec.Vec2(Scalar);

        /// The Vec type corresponding to the number of rows, e.g. Mat3x3.RowVec == Vec3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vec4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const ident = Matrix.new(
            &RowVec.new(1, 0, 0),
            &RowVec.new(0, 1, 0),
            &RowVec.new(0, 0, 1),
        );

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
        /// const m = Mat3x3.new(
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

        /// Transposes the matrix.
        pub fn transpose(m: *const Matrix) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0]),
                Vec.new(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1]),
                Vec.new(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2]),
            } };
        }

        // /// Constructs a 2D matrix which scales each dimension by the given vector.
        pub fn scale(s: Vec2) Matrix {
            return new(
                &RowVec.new(s.x(), 0, 0),
                &RowVec.new(0, s.y(), 0),
                &RowVec.new(0, 0, 1),
            );
        }

        /// Constructs a 2D matrix which scales each dimension by the given scalar.
        pub fn scaleScalar(t: T) Matrix {
            return scale(Vec2.splat(t));
        }

        /// Constructs a 2D matrix which translates coordinates by the given vector.
        pub fn translate(t: Vec2) Matrix {
            return new(
                &RowVec.new(1, 0, t.x()),
                &RowVec.new(0, 1, t.y()),
                &RowVec.new(0, 0, 1),
            );
        }

        /// Constructs a 2D matrix which translates coordinates by the given scalar.
        pub fn translateScalar(t: T) Matrix {
            return translate(Vec2.splat(t));
        }

        /// Returns the translation component of the matrix.
        pub fn translation(t: Matrix) Vec2 {
            return Vec2.new(t.v[2].x(), t.v[2].y());
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn rotateX(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(1, 0, 0),
                &RowVec.new(0, c, -s),
                &RowVec.new(0, s, c),
            );
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn rotateY(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, 0, s),
                &RowVec.new(0, 1, 0),
                &RowVec.new(-s, 0, c),
            );
        }

        /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
        pub fn rotateZ(angle_radians: T) Matrix {
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
        pub const getRow = Shared.getRow;
        pub const getCol = Shared.getCol;
        pub const setRow = Shared.setRow;
        pub const setCol = Shared.setCol;
        pub const fromScale = Shared.fromScale;
        pub const fromUniformScale = Shared.fromUniformScale;
        pub const setScale = Shared.setScale;
        pub const getScale = Shared.getScale;
        pub const mul = Shared.mul;
        pub const mulVec = Shared.mulVec;
        pub const clone = Shared.clone;
        pub const fromArray = Shared.fromArray;
        pub const toArray = Shared.toArray;
    };
}

pub fn Mat4x4(
    comptime Scalar: type,
) type {
    return extern struct {
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vec4{
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

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Scalar;

        /// The underlying Vec type, e.g. Mat3x3.Vec == Vec3
        pub const Vec = vec.Vec4(Scalar);

        /// The Vec type corresponding to the number of rows, e.g. Mat3x3.RowVec == Vec3
        pub const RowVec = Vec;

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vec4
        pub const ColVec = Vec;

        const Matrix = @This();

        const Shared = MatShared(RowVec, ColVec, Matrix);

        /// Identity matrix
        pub const ident = Matrix.new(
            &Vec.new(1, 0, 0, 0),
            &Vec.new(0, 1, 0, 0),
            &Vec.new(0, 0, 1, 0),
            &Vec.new(0, 0, 0, 1),
        );

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
        /// const m = Mat4x4.new(
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

        /// Transposes the matrix.
        pub fn transpose(m: *const Matrix) Matrix {
            return .{ .v = [_]Vec{
                Vec.new(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0], m.v[3].v[0]),
                Vec.new(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1], m.v[3].v[1]),
                Vec.new(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2], m.v[3].v[2]),
                Vec.new(m.v[0].v[3], m.v[1].v[3], m.v[2].v[3], m.v[3].v[3]),
            } };
        }

        /// Constructs a 3D matrix which scales each dimension by the given vector.
        pub fn scale(s: Vec3) Matrix {
            return new(
                &RowVec.new(s.x(), 0, 0, 0),
                &RowVec.new(0, s.y(), 0, 0),
                &RowVec.new(0, 0, s.z(), 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }

        /// Constructs a 3D matrix which scales each dimension by the given scalar.
        pub fn scaleScalar(s: T) Matrix {
            return scale(Vec3.splat(s));
        }

        /// Constructs a 3D matrix which translates coordinates by the given vector.
        pub fn translate(t: Vec3) Matrix {
            return new(
                &RowVec.new(1, 0, 0, t.x()),
                &RowVec.new(0, 1, 0, t.y()),
                &RowVec.new(0, 0, 1, t.z()),
                &RowVec.new(0, 0, 0, 1),
            );
        }

        /// Constructs a 3D matrix which translates coordinates by the given scalar.
        pub fn translateScalar(t: T) Matrix {
            return translate(Vec3.splat(t));
        }

        /// Returns the translation component of the matrix.
        pub fn translation(t: *const Matrix) Vec3 {
            return Vec3.new(t.v[3].x(), t.v[3].y(), t.v[3].z());
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn rotateX(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(1, 0, 0, 0),
                &RowVec.new(0, c, -s, 0),
                &RowVec.new(0, s, c, 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub fn rotateY(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, 0, s, 0),
                &RowVec.new(0, 1, 0, 0),
                &RowVec.new(-s, 0, c, 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }

        /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
        pub fn rotateZ(angle_radians: T) Matrix {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return Matrix.new(
                &RowVec.new(c, -s, 0, 0),
                &RowVec.new(s, c, 0, 0),
                &RowVec.new(0, 0, 1, 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }
        const Vec3 = vec.Vec3(T);
        pub fn fromScale(o: *const Vec3) Matrix {
            return Matrix.new(
                &RowVec.new(o.x(), 0, 0, 0),
                &RowVec.new(0, o.y(), 0, 0),
                &RowVec.new(0, 0, o.z(), 0),
                &RowVec.new(0, 0, 0, 1),
            );
        }
        pub fn fromUniformScale(s: T) Matrix {
            const tempScale = Vec3.splat(s);
            return fromScale(&tempScale);
        }
        pub fn getScale(m: *const Matrix) Vec3 {
            var col: Vec3 = undefined;
            col.v[0] = Vec3.new(m.v[0].v[0], m.v[0].v[1], m.v[0].v[2]).len();
            col.v[1] = Vec3.new(m.v[1].v[0], m.v[1].v[1], m.v[1].v[2]).len();
            col.v[2] = Vec3.new(m.v[2].v[0], m.v[2].v[1], m.v[2].v[2]).len();
            return col;
        }

        pub fn setScale(m: *Matrix, s: *const Vec3) void {
            const existingScale = m.getScale();
            const scaleRatio = s.div(&existingScale);
            var matrix: Matrix = undefined;
            matrix.v[0].v[0] = matrix.v[0].v[0] * scaleRatio.x();
            matrix.v[0].v[1] = matrix.v[0].v[1] * scaleRatio.x();
            matrix.v[0].v[2] = matrix.v[0].v[2] * scaleRatio.x();
            matrix.v[0].v[3] = matrix.v[0].v[3];

            matrix.v[1].v[0] = matrix.v[1].v[0] * scaleRatio.y();
            matrix.v[1].v[1] = matrix.v[1].v[1] * scaleRatio.y();
            matrix.v[1].v[2] = matrix.v[1].v[2] * scaleRatio.y();
            matrix.v[1].v[3] = matrix.v[1].v[3];

            matrix.v[2].v[0] = matrix.v[2].v[0] * scaleRatio.z();
            matrix.v[2].v[1] = matrix.v[2].v[1] * scaleRatio.z();
            matrix.v[2].v[2] = matrix.v[2].v[2] * scaleRatio.z();
            matrix.v[2].v[3] = matrix.v[2].v[3];

            matrix.v[3].v[0] = matrix.v[3].v[0];
            matrix.v[3].v[1] = matrix.v[3].v[1];
            matrix.v[3].v[2] = matrix.v[3].v[2];
            matrix.v[3].v[3] = matrix.v[3].v[3];
        }

        /// Constructs a 2D projection matrix, aka. an orthographic projection matrix.
        ///
        /// First, a cuboid is defined with the parameters:
        ///
        /// * (right - left) defining the distance between the left and right faces of the cube
        /// * (top - bottom) defining the distance between the top and bottom faces of the cube
        /// * (near - far) defining the distance between the back (near) and front (far) faces of the cube
        ///
        /// We then need to construct a projection matrix which converts points in that
        /// cuboid's space into clip space:
        ///
        /// https://machengine.org/engine/math/traversing-coordinate-systems/#view---clip-space
        ///
        /// Normally, in sysgpu/webgpu the depth buffer of floating point values would
        /// have the range [0, 1] representing [near, far], i.e. a pixel very close to the
        /// viewer would have a depth value of 0.0, and a pixel very far from the viewer
        /// would have a depth value of 1.0. But this is an ineffective use of floating
        /// point precision, a better approach is a reversed depth buffer:
        ///
        /// * https://webgpu.github.io/webgpu-samples/samples/reversedZ
        /// * https://developer.nvidia.com/content/depth-precision-visualized
        ///
        /// Mach mandates the use of a reversed depth buffer, so the returned transformation
        /// matrix maps to near=1 and far=0.
        pub fn projection2D(v: struct {
            left: T,
            right: T,
            bottom: T,
            top: T,
            near: T,
            far: T,
        }) Matrix {
            var p = Matrix.ident;
            p = p.mul(&Matrix.translate(Vec3.new(
                (v.right + v.left) / (v.left - v.right), // translate X so that the middle of (left, right) maps to x=0 in clip space
                (v.top + v.bottom) / (v.bottom - v.top), // translate Y so that the middle of (bottom, top) maps to y=0 in clip space
                v.far / (v.far - v.near), // translate Z so that far maps to z=0
            )));
            p = p.mul(&Matrix.scale(Vec3.new(
                2 / (v.right - v.left), // scale X so that [left, right] has a 2 unit range, e.g. [-1, +1]
                2 / (v.top - v.bottom), // scale Y so that [bottom, top] has a 2 unit range, e.g. [-1, +1]
                1 / (v.near - v.far), // scale Z so that [near, far] has a 1 unit range, e.g. [0, -1]
            )));
            return p;
        }
        pub fn lookAt(eye: Vec3, focuspos: Vec3, updir: Vec3) Matrix {
            const zAxis = eye.sub(&focuspos).normalize();
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
        // pub fn perspective(fovy: T, aspect: T, near: T, far: T) Matrix {
        //     const f = stdmath.tan(math.pi * 0.5 - 0.5 * fovy);
        //     const rangeInv = 1 / (near - far);
        //     var res: Matrix = undefined;
        //     res.v[0].v[0] = f / aspect;
        //     res.v[0].v[1] = 0;
        //     res.v[0].v[2] = 0;
        //     res.v[0].v[3] = 0;

        //     res.v[1].v[0] = 0;
        //     res.v[1].v[1] = f;
        //     res.v[1].v[2] = 0;
        //     res.v[1].v[3] = 0;

        //     res.v[2].v[0] = 0;
        //     res.v[2].v[1] = 0;
        //     res.v[2].v[2] = far * rangeInv;
        //     res.v[2].v[3] = -1;

        //     res.v[3].v[0] = 0;
        //     res.v[3].v[1] = 0;
        //     res.v[3].v[2] = far * near * rangeInv;
        //     res.v[3].v[3] = 0;
        //     return res;
        // }

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

        pub const getRow = Shared.getRow;
        pub const getCol = Shared.getCol;
        pub const setRow = Shared.setRow;
        pub const setCol = Shared.setCol;
        pub const mul = Shared.mul;
        pub const mulVec = Shared.mulVec;
        pub const eql = Shared.eql;
        pub const eqlApprox = Shared.eqlApprox;
        pub const clone = Shared.clone;
        pub const fromArray = Shared.fromArray;
        pub const toArray = Shared.toArray;
    };
}

pub fn MatShared(comptime RowVec: type, comptime ColVec: type, comptime Matrix: type) type {
    return struct {
        /// Matrix multiplication a*b
        pub fn mul(a: *const Matrix, b: *const Matrix) Matrix {
            @setEvalBranchQuota(10000);
            var result: Matrix = undefined;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    var sum: RowVec.T = 0.0;
                    inline for (0..RowVec.n) |i| {
                        // Note: we directly access rows/columns below as it is much faster **in
                        // debug builds**, instead of using these helpers:
                        //
                        // sum += a.rowi(rowi).mul(&b.coli(coli)).v[i];
                        sum += a.v[i].v[rowi] * b.v[coli].v[i];
                    }
                    result.v[coli].v[rowi] = sum;
                }
            }
            return result;
        }

        /// Matrix * Vector multiplication
        pub fn mulVec(matrix: *const Matrix, vector: *const ColVec) ColVec {
            var result = [_]ColVec.T{0} ** ColVec.n;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..ColVec.n) |i| {
                    result[i] += matrix.v[rowi].v[i] * vector.v[rowi];
                }
            }
            return ColVec{ .v = result };
        }

        pub fn fromArray(slice: *const [Matrix.cols * Matrix.rows]Matrix.T) Matrix {
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

        pub fn toArray(a: *const Matrix) [Matrix.cols * Matrix.rows]Matrix.T {
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
            var result: Matrix = undefined;
            inline for (0..Matrix.rows) |rowi| {
                inline for (0..Matrix.cols) |coli| {
                    if (rowi == coli) {
                        result.v[coli].v[rowi] = o.v[coli];
                    }
                }
            }
            return result;
        }
        pub fn fromUniformScale(s: Matrix.T) Matrix {
            const tempScale = ColVec.splat(s);
            return fromScale(&tempScale);
        }
        pub fn getScale(m: *const Matrix) ColVec {
            var result = [_]ColVec.T{0} ** ColVec.n;
            inline for (0..Matrix.rows) |rowi| {
                result[rowi] = m.getCol(rowi).len();
            }
            return ColVec{ .v = result };
        }
        pub fn setScale(m: *Matrix, s: *const ColVec) void {
            const existingScale = m.getScale();
            const scaleRatio = s.div(&existingScale);

            inline for (0..Matrix.cols) |coli| {
                m.v[coli] = m.v[coli].mulScalar(scaleRatio.v[coli]);
            }
        }
        pub fn clone(m: *const Matrix) Matrix {
            return Matrix{ .v = m.v };
        }
    };
}

test "Mat4x4_fromArray_toArray" {
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
    const actual = Mat4x4(f64).fromArray(&slice);
    const expect = Mat4x4(f64).new(
        &math.vec4d(1, 5, 9, 13),
        &math.vec4d(2, 6, 10, 14),
        &math.vec4d(3, 7, 11, 15),
        &math.vec4d(4, 8, 12, 16),
    );
    try testing.expect(Mat4x4(f64), expect).eql(actual);
    const actualSlice = actual.toArray();
    try std.testing.expect(std.mem.eql(f64, &slice, &actualSlice));
}

test "gpu_compatibility" {
    // https://www.w3.org/TR/WGSL/#alignment-and-size
    try testing.expect(usize, 16).eql(@sizeOf(math.Mat2x2));
    try testing.expect(usize, 48).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, 64).eql(@sizeOf(math.Mat4x4));

    try testing.expect(usize, 8).eql(@sizeOf(math.Mat2x2h));
    try testing.expect(usize, 24).eql(@sizeOf(math.Mat3x3h));
    try testing.expect(usize, 32).eql(@sizeOf(math.Mat4x4h));

    try testing.expect(usize, 32).eql(@sizeOf(math.Mat2x2d)); // speculative
    try testing.expect(usize, 96).eql(@sizeOf(math.Mat3x3d)); // speculative
    try testing.expect(usize, 128).eql(@sizeOf(math.Mat4x4d)); // speculative
}

test "zero_struct_overhead" {
    // Proof that using e.g. [3]Vec3 is equal to [3]@Vector(3, f32)
    try testing.expect(usize, @alignOf([2]@Vector(2, f32))).eql(@alignOf(math.Mat2x2));
    try testing.expect(usize, @alignOf([3]@Vector(3, f32))).eql(@alignOf(math.Mat3x3));
    try testing.expect(usize, @alignOf([4]@Vector(4, f32))).eql(@alignOf(math.Mat4x4));
    try testing.expect(usize, @sizeOf([2]@Vector(2, f32))).eql(@sizeOf(math.Mat2x2));
    try testing.expect(usize, @sizeOf([3]@Vector(3, f32))).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, @sizeOf([4]@Vector(4, f32))).eql(@sizeOf(math.Mat4x4));
}

test "n" {
    try testing.expect(usize, 3).eql(math.Mat3x3.rows);
    try testing.expect(usize, 3).eql(math.Mat3x3.rows);
    try testing.expect(type, math.Vec3).eql(math.Mat3x3.Vec);
    try testing.expect(usize, 3).eql(math.Mat3x3.Vec.n);
}

test "new" {
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(1, 0, 1337),
        &math.vec3(0, 1, 7331),
        &math.vec3(0, 0, 1),
    )).eql(math.Mat3x3{
        .v = [_]math.Vec3{
            math.Vec3.new(1, 0, 0),
            math.Vec3.new(0, 1, 0),
            math.Vec3.new(1337, 7331, 1),
        },
    });
}

test "Mat2x2_ident" {
    try testing.expect(math.Mat2x2, math.Mat2x2.ident).eql(math.Mat2x2{
        .v = [_]math.Vec2{
            math.Vec2.new(1, 0),
            math.Vec2.new(0, 1),
        },
    });
}

test "Mat3x3_ident" {
    try testing.expect(math.Mat3x3, math.Mat3x3.ident).eql(math.Mat3x3{
        .v = [_]math.Vec3{
            math.Vec3.new(1, 0, 0),
            math.Vec3.new(0, 1, 0),
            math.Vec3.new(0, 0, 1),
        },
    });
}

test "Mat4x4_ident" {
    try testing.expect(math.Mat4x4, math.Mat4x4.ident).eql(math.Mat4x4{
        .v = [_]math.Vec4{
            math.Vec4.new(1, 0, 0, 0),
            math.Vec4.new(0, 1, 0, 0),
            math.Vec4.new(0, 0, 1, 0),
            math.Vec4.new(0, 0, 0, 1),
        },
    });
}

test "Mat2x2_row" {
    const m = math.Mat2x2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vec2, math.vec2(0, 1)).eql(m.getRow(0));
    try testing.expect(math.Vec2, math.vec2(2, 3)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Mat2x2_col" {
    const m = math.Mat2x2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vec2, math.vec2(0, 2)).eql(m.getCol(0));
    try testing.expect(math.Vec2, math.vec2(1, 3)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Mat3x3_row" {
    const m = math.Mat3x3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 1, 2)).eql(m.getRow(0));
    try testing.expect(math.Vec3, math.vec3(3, 4, 5)).eql(m.getRow(1));
    try testing.expect(math.Vec3, math.vec3(6, 7, 8)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Mat3x3_col" {
    const m = math.Mat3x3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 3, 6)).eql(m.getCol(0));
    try testing.expect(math.Vec3, math.vec3(1, 4, 7)).eql(m.getCol(1));
    try testing.expect(math.Vec3, math.vec3(2, 5, 8)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Mat4x4_row" {
    const m = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 1, 2, 3)).eql(m.getRow(0));
    try testing.expect(math.Vec4, math.vec4(4, 5, 6, 7)).eql(m.getRow(1));
    try testing.expect(math.Vec4, math.vec4(8, 9, 10, 11)).eql(m.getRow(2));
    try testing.expect(math.Vec4, math.vec4(12, 13, 14, 15)).eql(m.getRow(@TypeOf(m).rows - 1));
}

test "Mat4x4_col" {
    const m = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 4, 8, 12)).eql(m.getCol(0));
    try testing.expect(math.Vec4, math.vec4(1, 5, 9, 13)).eql(m.getCol(1));
    try testing.expect(math.Vec4, math.vec4(2, 6, 10, 14)).eql(m.getCol(2));
    try testing.expect(math.Vec4, math.vec4(3, 7, 11, 15)).eql(m.getCol(@TypeOf(m).cols - 1));
}

test "Mat2x2_transpose" {
    const m = math.Mat2x2.new(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Mat2x2, math.Mat2x2.new(
        &math.vec2(0, 2),
        &math.vec2(1, 3),
    )).eql(m.transpose());
}

test "Mat3x3_transpose" {
    const m = math.Mat3x3.new(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Mat3x3, math.Mat3x3.new(
        &math.vec3(0, 3, 6),
        &math.vec3(1, 4, 7),
        &math.vec3(2, 5, 8),
    )).eql(m.transpose());
}

test "Mat4x4_transpose" {
    const m = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Mat4x4, math.Mat4x4.new(
        &math.vec4(0, 4, 8, 12),
        &math.vec4(1, 5, 9, 13),
        &math.vec4(2, 6, 10, 14),
        &math.vec4(3, 7, 11, 15),
    )).eql(m.transpose());
}

test "Mat2x2_scaleScalar" {
    const m = math.Mat2x2.scaleScalar(2);
    try testing.expect(math.Mat2x2, math.Mat2x2.new(
        &math.vec2(2, 0),
        &math.vec2(0, 1),
    )).eql(m);
}

test "Mat3x3_scale" {
    const m = math.Mat3x3.scale(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.Mat3x3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 3, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat3x3_scaleScalar" {
    const m = math.Mat3x3.scaleScalar(2);
    try testing.expect(math.Mat3x3, math.Mat3x3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scale" {
    const m = math.Mat4x4.scale(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.Mat4x4.new(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 3, 0, 0),
        &math.vec4(0, 0, 4, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scaleScalar" {
    const m = math.Mat4x4.scaleScalar(2);
    try testing.expect(math.Mat4x4, math.Mat4x4.new(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 2, 0, 0),
        &math.vec4(0, 0, 2, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translate" {
    const m = math.Mat3x3.translate(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.Mat3x3.new(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 3),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_translate" {
    const m = math.Mat4x4.translate(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.Mat4x4.new(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 3),
        &math.vec4(0, 0, 1, 4),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translateScalar" {
    const m = math.Mat3x3.translateScalar(2);
    try testing.expect(math.Mat3x3, math.Mat3x3.new(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 2),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat2x2_translateScalar" {
    const m = math.Mat2x2.translateScalar(2);
    try testing.expect(math.Mat2x2, math.Mat2x2.new(
        &math.vec2(1, 2),
        &math.vec2(0, 1),
    )).eql(m);
}

test "Mat4x4_translateScalar" {
    const m = math.Mat4x4.translateScalar(2);
    try testing.expect(math.Mat4x4, math.Mat4x4.new(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 2),
        &math.vec4(0, 0, 1, 2),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translation" {
    const m = math.Mat3x3.translate(math.vec2(2, 3));
    try testing.expect(math.Vec2, math.vec2(2, 3)).eql(m.translation());
}

test "Mat4x4_translation" {
    const m = math.Mat4x4.translate(math.vec3(2, 3, 4));
    try testing.expect(math.Vec3, math.vec3(2, 3, 4)).eql(m.translation());
}

test "Mat2x2_mulVec_vec2_ident" {
    const v = math.Vec2.splat(1);
    const ident = math.Mat2x2.ident;
    const expected = v;
    const m = math.Mat2x2.mulVec(&ident, &v);

    try testing.expect(math.Vec2, expected).eql(m);
}

test "Mat2x2_mulVec_vec2" {
    const v = math.Vec2.splat(1);
    const mat = math.Mat2x2.new(
        &math.vec2(2, 0),
        &math.vec2(0, 2),
    );

    const m = math.Mat2x2.mulVec(&mat, &v);
    const expected = math.vec2(2, 2);
    try testing.expect(math.Vec2, expected).eql(m);
}

test "Mat3x3_mulVec_vec3_ident" {
    const v = math.Vec3.splat(1);
    const ident = math.Mat3x3.ident;
    const expected = v;
    const m = math.Mat3x3.mulVec(&ident, &v);

    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat3x3_mulVec_vec3" {
    const v = math.Vec3.splat(1);
    const mat = math.Mat3x3.new(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 3),
    );

    const m = math.Mat3x3.mulVec(&mat, &v);
    const expected = math.vec3(2, 2, 3);
    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat4x4_mulVec_vec4" {
    const v = math.vec4(2, 5, 1, 8);
    const mat = math.Mat4x4.new(
        &math.vec4(1, 0, 2, 0),
        &math.vec4(0, 3, 0, 4),
        &math.vec4(0, 0, 5, 0),
        &math.vec4(6, 0, 0, 7),
    );

    const m = math.Mat4x4.mulVec(&mat, &v);
    const expected = math.vec4(4, 47, 5, 68);
    try testing.expect(math.Vec4, expected).eql(m);
}

test "Mat2x2_mul" {
    const a = math.Mat2x2.new(
        &math.vec2(4, 2),
        &math.vec2(7, 9),
    );
    const b = math.Mat2x2.new(
        &math.vec2(5, -7),
        &math.vec2(6, -3),
    );
    const c = math.Mat2x2.mul(&a, &b);

    const expected = math.Mat2x2.new(
        &math.vec2(32, -34),
        &math.vec2(89, -76),
    );
    try testing.expect(math.Mat2x2, expected).eql(c);
}

test "Mat3x3_mul" {
    const a = math.Mat3x3.new(
        &math.vec3(4, 2, -3),
        &math.vec3(7, 9, -8),
        &math.vec3(-1, 8, -8),
    );
    const b = math.Mat3x3.new(
        &math.vec3(5, -7, -8),
        &math.vec3(6, -3, 2),
        &math.vec3(-3, -4, 4),
    );
    const c = math.Mat3x3.mul(&a, &b);

    const expected = math.Mat3x3.new(
        &math.vec3(41, -22, -40),
        &math.vec3(113, -44, -70),
        &math.vec3(67, 15, -8),
    );
    try testing.expect(math.Mat3x3, expected).eql(c);
}

test "Mat4x4_mul" {
    const a = math.Mat4x4.new(
        &math.vec4(10, -5, 6, -2),
        &math.vec4(0, -1, 0, 9),
        &math.vec4(-1, 6, -4, 8),
        &math.vec4(9, -8, -6, -10),
    );
    const b = math.Mat4x4.new(
        &math.vec4(7, -7, -3, -8),
        &math.vec4(1, -1, -7, -2),
        &math.vec4(-10, 2, 2, -2),
        &math.vec4(10, -7, 7, 1),
    );
    const c = math.Mat4x4.mul(&a, &b);

    const expected = math.Mat4x4.new(
        &math.vec4(-15, -39, 3, -84),
        &math.vec4(89, -62, 70, 11),
        &math.vec4(119, -63, 9, 12),
        &math.vec4(15, 3, -53, -54),
    );
    try testing.expect(math.Mat4x4, expected).eql(c);
}

test "Mat4x4_eql_not_ident" {
    const m1 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.5, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eql(&m1, &m2)).eql(false);
}

test "Mat4x4_eql_ident" {
    const m1 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eql(&m1, &m2)).eql(true);
}

test "Mat4x4_eqlApprox_not_ident" {
    const m1 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.11, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eqlApprox(&m1, &m2, 0.1)).eql(false);
}

test "Mat4x4_eqlApprox_ident" {
    const m1 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.Mat4x4.new(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.09, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eqlApprox(&m1, &m2, 0.1)).eql(true);
}

test "projection2D_xy_centered" {
    const v = .{
        .left = -400,
        .right = 400,
        .bottom = -200,
        .top = 200,
        .near = 0,
        .far = 100,
    };
    const m = math.Mat4x4.projection2D(v);

    // Calculate some reference points
    const width = v.right - v.left;
    const height = v.top - v.bottom;
    const width_mid = v.left + (width / 2.0);
    const height_mid = v.bottom + (height / 2.0);
    try testing.expect(f32, 800).eql(width);
    try testing.expect(f32, 400).eql(height);
    try testing.expect(f32, 0).eql(width_mid);
    try testing.expect(f32, 0).eql(height_mid);

    // Probe some points on the X axis from beyond the left face, all the way to beyond the right face.
    try testing.expect(math.Vec4, math.vec4(-2, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left - (width / 2), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-1, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left + (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right - (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(2, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right + (width / 2), height_mid, 0, 1)));

    // Probe some points on the Y axis from beyond the bottom face, all the way to beyond the top face.
    try testing.expect(math.Vec4, math.vec4(0, -2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom - (height / 2), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom + (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top - (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top + (height / 2), 0, 1)));
}

test "projection2D_xy_offcenter" {
    const v = .{
        .left = 100,
        .right = 500,
        .bottom = 100,
        .top = 500,
        .near = 0,
        .far = 100,
    };
    const m = math.Mat4x4.projection2D(v);

    // Calculate some reference points
    const width = v.right - v.left;
    const height = v.top - v.bottom;
    const width_mid = v.left + (width / 2.0);
    const height_mid = v.bottom + (height / 2.0);
    try testing.expect(f32, 400).eql(width);
    try testing.expect(f32, 400).eql(height);
    try testing.expect(f32, 300).eql(width_mid);
    try testing.expect(f32, 300).eql(height_mid);

    // Probe some points on the X axis from beyond the left face, all the way to beyond the right face.
    try testing.expect(math.Vec4, math.vec4(-2, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left - (width / 2), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-1, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.left + (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right - (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(2, 0, 1, 1)).eql(m.mulVec(&math.vec4(v.right + (width / 2), height_mid, 0, 1)));

    // Probe some points on the Y axis from beyond the bottom face, all the way to beyond the top face.
    try testing.expect(math.Vec4, math.vec4(0, -2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom - (height / 2), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.bottom + (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top - (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, v.top + (height / 2), 0, 1)));
}

test "projection2D_z" {
    const m = math.Mat4x4.projection2D(.{
        // Set x=0 and y=0 as centers, so we can specify 0 centers in our testing.expects below
        .left = -400,
        .right = 400,
        .bottom = -200,
        .top = 200,

        // Choose some near/far plane values that we can easily test against
        // We'll have [near, far] == [-100, 100] == [1, 0]
        .near = -100,
        .far = 100,
    });

    // Probe some points on the Z axis from the near plane, all the way to the far plane.
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(0, 0, -100, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.75, 1)).eql(m.mulVec(&math.vec4(0, 0, -50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(m.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.25, 1)).eql(m.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0, 1)).eql(m.mulVec(&math.vec4(0, 0, 100, 1)));

    // Probe some points outside the near/far planes
    try testing.expect(math.Vec4, math.vec4(0, 0, 2, 1)).eql(m.mulVec(&math.vec4(0, 0, -100 - 200, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, -1, 1)).eql(m.mulVec(&math.vec4(0, 0, 100 + 200, 1)));
}

test "projection2D_z_positive" {
    const m = math.Mat4x4.projection2D(.{
        // Set x=0 and y=0 as centers, so we can specify 0 centers in our testing.expects below
        .left = -400,
        .right = 400,
        .bottom = -200,
        .top = 200,

        // Choose some near/far plane values that we can easily test against
        // We'll have [near, far] == [0, 100] == [1, 0]
        .near = 0,
        .far = 100,
    });

    // Probe some points on the Z axis from the near plane, all the way to the far plane.
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.75, 1)).eql(m.mulVec(&math.vec4(0, 0, 25, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(m.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.25, 1)).eql(m.mulVec(&math.vec4(0, 0, 75, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0, 1)).eql(m.mulVec(&math.vec4(0, 0, 100, 1)));

    // Probe some points outside the near/far planes
    try testing.expect(math.Vec4, math.vec4(0, 0, 2, 1)).eql(m.mulVec(&math.vec4(0, 0, 0 - 100, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, -1, 1)).eql(m.mulVec(&math.vec4(0, 0, 100 + 100, 1)));
}

test "projection2D_model_to_clip_space" {
    const model = math.Mat4x4.ident;
    const view = math.Mat4x4.ident;
    const proj = math.Mat4x4.projection2D(.{
        .left = -50,
        .right = 50,
        .bottom = -50,
        .top = 50,
        .near = 0,
        .far = 100,
    });
    const mvp = model.mul(&view).mul(&proj);

    try testing.expect(math.Vec4, math.vec4(0, 0, 1.0, 1)).eql(mvp.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(mvp.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(mvp.mul(&math.Mat4x4.rotateX(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(mvp.mul(&math.Mat4x4.rotateY(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(mvp.mul(&math.Mat4x4.rotateZ(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
}

test "Mat2x2_setScale" {
    const oldScale = math.Vec2.new(2, 3);
    const newScale = math.Vec2.new(4, 5);
    var matrix = math.Mat2x2.fromScale(&oldScale);
    try testing.expect(math.Vec2, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vec2, newScale).eql(matrix.getScale());
}

test "Mat3x3_setScale" {
    const oldScale = math.Vec3.new(2, 3, 4);
    const newScale = math.Vec3.new(5, 6, 7);
    var matrix = math.Mat3x3.fromScale(&oldScale);
    try testing.expect(math.Vec3, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vec3, newScale).eql(matrix.getScale());
}

test "Mat4x4_setScale" {
    const oldScale = math.Vec3.new(2, 3, 4);
    const newScale = math.Vec3.new(5, 6, 7);
    var matrix = math.Mat3x3.fromScale(&oldScale);
    try testing.expect(math.Vec3, oldScale).eql(matrix.getScale());
    matrix.setScale(&newScale);
    try testing.expect(math.Vec3, newScale).eql(matrix.getScale());
}
