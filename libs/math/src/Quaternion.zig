const math = @import("root.zig");
const testing = @import("testing.zig");
const vec = @import("Vector.zig");
const mat = @import("Matrix.zig");
const HeadingPitchRoll = @import("HeadingPitchRoll.zig").HeadingPitchRoll;

pub fn Quaternion(comptime Scalar: type) type {
    return extern struct {
        v: vec.Vector4(Scalar),

        /// The scalar type of this matrix, e.g. Matrix3.T == f32
        pub const T = Vec.T;

        /// The underlying Vec type, e.g. math.Vector4, math.Vec4h, math.Vector4D
        pub const Vec = vec.Vector4(Scalar);

        /// The Vec type used to represent axes, e.g. math.Vector3
        pub const Axis = vec.Vector3(Scalar);

        /// Creates a quaternion from the given x, y, z, and w values
        pub fn new(xv: T, yv: T, zv: T, wv: T) Quaternion(T) {
            return .{ .v = Vec.new(xv, yv, zv, wv) };
        }
        pub inline fn clone(self: *const Quaternion(T)) Quaternion(T) {
            return Quaternion(T).new(self.x(), self.y(), self.z(), self.w());
        }
        pub inline fn fromZero() Quaternion(T) {
            return new(0, 0, 0, 1);
        }
        pub inline fn x(v: *const Quaternion(T)) Scalar {
            return v.v.x();
        }
        pub inline fn y(v: *const Quaternion(T)) Scalar {
            return v.v.y();
        }
        pub inline fn z(v: *const Quaternion(T)) Scalar {
            return v.v.z();
        }
        pub inline fn w(v: *const Quaternion(T)) Scalar {
            return v.v.w();
        }
        /// Returns the fromIdentity quaternion.
        pub inline fn fromIdentity() Quaternion(T) {
            return new(0, 0, 0, 1);
        }

        /// Returns the inverse of the quaternion.
        pub fn inverse(q: *const Quaternion(T)) Quaternion(T) {
            const s = 1 / q.length2();
            return new(-q.v.x() * s, -q.v.y() * s, -q.v.z() * s, q.v.w() * s);
        }

        /// Creates a Quaternion based on the given `axis` and `angle`, and returns it.
        pub fn fromAxisAngle(axis: *const Axis, angle: T) Quaternion(T) {
            const halfAngle = angle * 0.5;
            const s = math.sin(halfAngle);

            return new(s * axis.x(), s * axis.y(), s * axis.z(), math.cos(halfAngle));
        }

        /// Calculates the angle between two given quaternions.
        pub fn angleBetween(a: *const Quaternion(T), b: *const Quaternion(T)) T {
            const d = Vec.dot(&a.v, &b.v);
            return math.acos(2 * d * d - 1);
        }

        /// Multiplies two quaternions
        pub fn multiply(a: *const Quaternion(T), b: *const Quaternion(T)) Quaternion(T) {
            const ax = a.v.x();
            const ay = a.v.y();
            const az = a.v.z();
            const aw = a.v.w();
            const bx = b.v.x();
            const by = b.v.y();
            const bz = b.v.z();
            const bw = b.v.w();

            const xv = aw * bx + ax * bw + ay * bz - az * by;
            const yv = aw * by + ay * bw + az * bx - ax * bz;
            const zv = aw * bz + az * bw + ax * by - ay * bx;
            const wv = aw * bw - ax * bx - ay * by - az * bz;

            return new(xv, yv, zv, wv);
        }

        /// Adds two quaternions
        pub fn add(a: *const Quaternion(T), b: *const Quaternion(T)) Quaternion(T) {
            return new(a.v.x() + b.v.x(), a.v.y() + b.v.y(), a.v.z() + b.v.z(), a.v.w() + b.v.w());
        }

        /// Subtracts two quaternions
        pub fn subtract(a: *const Quaternion(T), b: *const Quaternion(T)) Quaternion(T) {
            return new(a.v.x() - b.v.x(), a.v.y() - b.v.y(), a.v.z() - b.v.z(), a.v.w() - b.v.w());
        }

        /// Multiplies a Quaternion by a scalar
        pub fn multiplyByScalar(q: *const Quaternion(T), s: T) Quaternion(T) {
            return new(q.v.x() * s, q.v.y() * s, q.v.z() * s, q.v.w() * s);
        }

        /// Divides a Quaternion by a scalar
        pub fn divideScalar(q: *const Quaternion(T), s: T) Quaternion(T) {
            return new(q.v.x() / s, q.v.y() / s, q.v.z() / s, q.v.w() / s);
        }

        /// Rotates the give quaternion by the given angle, around the x-axis.
        pub fn rotateX(q: *const Quaternion(T), angle: T) Quaternion(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const bx = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return new(qx * bw + qw * bx, qy * bw + qz * bx, qz * bw - qy * bx, qw * bw - qx * bx);
        }

        /// Rotates the give quaternion by the given angle, around the y-axis.
        pub fn rotateY(q: *const Quaternion(T), angle: T) Quaternion(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const by = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return new(qx * bw - qz * by, qy * bw + qw * by, qz * bw + qx * by, qw * bw - qy * by);
        }

        /// Rotates the give quaternion by the given angle, around the z-axis.
        pub fn rotateZ(q: *const Quaternion(T), angle: T) Quaternion(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const bz = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return new(qx * bw - qy * bz, qy * bw + qx * bz, qz * bw + qw * bz, qw * bw - qz * bz);
        }

        /// Calculates the spherical linear interpolation between two quaternions.
        pub fn slerp(a: *const Quaternion(T), b: *const Quaternion(T), t: T) Quaternion(T) {
            const ax = a.v.x();
            const ay = a.v.y();
            const az = a.v.z();
            const aw = a.v.w();

            var bx = b.v.x();
            var by = b.v.y();
            var bz = b.v.z();
            var bw = b.v.w();

            var cosOmega = ax * bx + ay * by + az * bz + aw * bw;
            if (cosOmega < 0) {
                cosOmega = -cosOmega;
                bx = -bx;
                by = -by;
                bz = -bz;
                bw = -bw;
            }

            var scale0: T = 0.0;
            var scale1: T = 0.0;

            if (1.0 - cosOmega > math.eps(T)) {
                const omega = math.acos(cosOmega);
                const sinOmega = math.sin(omega);
                scale0 = math.sin((1.0 - t) * omega) / sinOmega;
                scale1 = math.sin(t * omega) / sinOmega;
            } else {
                scale0 = 1.0 - t;
                scale1 = t;
            }

            return new(scale0 * ax + scale1 * bx, scale0 * ay + scale1 * by, scale0 * az + scale1 * bz, scale0 * aw + scale1 * bw);
        }

        /// Calculates the conjugate of the given quaternion.
        pub fn conjugate(q: *const Quaternion(T)) Quaternion(T) {
            return new(-q.v.x(), -q.v.y(), -q.v.z(), q.v.w());
        }

        /// Creates a quaternion from the given transformation matrix.
        pub fn fromRotationMatrix(m: *const mat.Matrix3(T)) Quaternion(T) {
            var dst = Quaternion(T).fromIdentity();
            const trace = m.v[0].v[0] + m.v[1].v[1] + m.v[2].v[2];

            if (trace > 0) {
                const root = math.sqrt(trace + 1.0);
                dst.v.v[3] = 0.5 * root;
                const rootInv = 0.5 / root;

                dst.v.v[0] = (m.v[1].v[2] - m.v[2].v[1]) * rootInv;
                dst.v.v[1] = (m.v[2].v[0] - m.v[0].v[2]) * rootInv;
                dst.v.v[2] = (m.v[0].v[1] - m.v[1].v[0]) * rootInv;
            } else {
                var i: usize = 0;

                if (m.v[1].v[1] > m.v[0].v[0]) {
                    i = 1;
                }

                if (m.v[2].v[2] > m.v[i].v[i]) {
                    i = 2;
                }

                const j = (i + 1) % 3;
                const k = (i + 2) % 3;

                var quat = [3]T{ 0, 0, 0 };

                const root = math.sqrt(m.v[i].v[i] - m.v[j].v[j] - m.v[k].v[k] + 1.0);
                quat[i] = 0.5 * root;

                const rootInv = 0.5 / root;

                const ww = (m.v[k].v[j] - m.v[j].v[k]) * rootInv;
                quat[j] = (m.v[j].v[i] - m.v[i].v[j]) * rootInv;
                quat[k] = (m.v[k].v[i] - m.v[i].v[k]) * rootInv;
                dst.v.v[0] = -quat[0];
                dst.v.v[1] = -quat[1];
                dst.v.v[2] = -quat[2];
                dst.v.v[3] = ww;
            }

            return dst;
        }

        /// Creates a quaternion from the given Euler angles.
        pub fn fromEuler(xv: T, yv: T, zv: T) Quaternion(T) {
            const xHalf = xv * 0.5;
            const yHalf = yv * 0.5;
            const zHalf = zv * 0.5;

            const sx = math.sin(xHalf);
            const cx = math.cos(xHalf);
            const sy = math.sin(yHalf);
            const cy = math.cos(yHalf);
            const sz = math.sin(zHalf);
            const cz = math.cos(zHalf);

            const xRet = sx * cy * cz + cx * sy * sz;
            const yRet = cx * sy * cz - sx * cy * sz;
            const zRet = cx * cy * sz + sx * sy * cz;
            const wRet = cx * cy * cz - sx * sy * sz;

            return new(xRet, yRet, zRet, wRet);
        }

        /// Returns the dot product of two quaternions.
        pub fn dot(a: *const Quaternion(T), b: *const Quaternion(T)) T {
            return a.v.x() * b.v.x() + a.v.y() * b.v.y() + a.v.z() * b.v.z() + a.v.w() * b.v.w();
        }

        /// Linearly interpolates between two quaternions.
        pub fn lerp(a: *const Quaternion(T), b: *const Quaternion(T), t: T) Quaternion(T) {
            const xRet = a.v.x() + t * (b.v.x() - a.v.x());
            const yRet = a.v.y() + t * (b.v.y() - a.v.y());
            const zRet = a.v.z() + t * (b.v.z() - a.v.z());
            const wRet = a.v.w() + t * (b.v.w() - a.v.w());

            return new(xRet, yRet, zRet, wRet);
        }

        /// Computes the squared length of a given quaternion.
        pub fn length2(q: *const Quaternion(T)) T {
            return q.v.x() * q.v.x() + q.v.y() * q.v.y() + q.v.z() * q.v.z() + q.v.w() * q.v.w();
        }

        /// Computes the length of a given quaternion.
        pub fn length(q: *const Quaternion(T)) T {
            return math.sqrt(q.v.x() * q.v.x() + q.v.y() * q.v.y() + q.v.z() * q.v.z() + q.v.w() * q.v.w());
        }

        /// Computes the normalized version of a given quaternion.
        pub fn normalize(q: *const Quaternion(T)) Quaternion(T) {
            const q0 = q.v.x();
            const q1 = q.v.y();
            const q2 = q.v.z();
            const q3 = q.v.w();

            const len = math.sqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);

            if (len > 0.00001) {
                return new(q0 / len, q1 / len, q2 / len, q3 / len);
            } else {
                return new(0, 0, 0, 0);
            }
        }
        pub fn fromHeadingPitchRoll(hpr: *const HeadingPitchRoll(T)) Quaternion(T) {
            const rQuat = Quaternion(T).fromAxisAngle(&HeadingPitchRoll(T).Vec.new(1, 0, 0), hpr.r());
            const pQuat = Quaternion(T).fromAxisAngle(&HeadingPitchRoll(T).Vec.new(0, 1, 0), -hpr.p());
            const res = pQuat.multiply(&rQuat);
            const hQuat = Quaternion(T).fromAxisAngle(&HeadingPitchRoll(T).Vec.new(0, 0, 1), -hpr.h());
            return hQuat.multiply(&res);
        }
        pub fn multiplyByPoint(self: *const Quaternion(T), point: *const vec.Vector3(T)) vec.Vector3(T) {
            const vx = point.x();
            const vy = point.y();
            const vz = point.z();
            const qx = self.x();
            const qy = self.y();
            const qz = self.z();
            const qw = self.w();
            const tx = 2 * (qy * vz - qz * vy);
            const ty = 2 * (qz * vx - qx * vz);
            const tz = 2 * (qx * vy - qy * vx);
            const resx = vx + qw * tx + qy * tz - qz * ty;
            const resy = vy + qw * ty + qz * tx - qx * tz;
            const resz = vz + qw * tz + qx * ty - qy * tx;
            return vec.Vector3(T).new(resx, resy, resz);
        }
        pub inline fn eql(a: *const Quaternion(T), b: *const Quaternion(T)) bool {
            return a.v.eql(&b.v);
        }
        pub inline fn eqlApprox(a: *const Quaternion(T), b: *const Quaternion(T), tolerance: T) bool {
            return a.v.eqlApprox(&b.v, tolerance);
        }
        pub inline fn print(a: *const Quaternion(T)) void {
            a.v.print();
        }
        pub fn fromUnitVectors(vFrom: *const vec.Vector3(T), vTo: *const vec.Vector3(T)) Quaternion(T) {
            var xx: T = 0;
            var yy: T = 0;
            var zz: T = 0;
            var ww: T = 0;
            var r = vFrom.dot(vTo) + 1.0;
            if (r < math.floatEps(T)) {
                r = 0;
                if (@abs(vFrom.x()) > @abs(vFrom.z())) {
                    xx = -vFrom.y();
                    yy = vFrom.x();
                    zz = 0;
                    ww = r;
                } else {
                    xx = 0;
                    yy = -vFrom.z();
                    zz = vFrom.y();
                    ww = r;
                }
            } else {
                xx = vFrom.y() * vTo.z() - vFrom.z() * vTo.y();
                yy = vFrom.z() * vTo.x() - vFrom.x() * vTo.z();
                zz = vFrom.x() * vTo.y() - vFrom.y() * vTo.x();
                ww = r;
            }
            const res =  Quaternion(T).new(xx, yy, zz, ww);
            return res.normalize();
        }
    };
}

test "zero_struct_overhead" {
    // Proof that using Quaternion is equal to @Vector(4, f32)
    try testing.expect(usize, @alignOf(@Vector(4, f32))).eql(@alignOf(math.Quaternion));
    try testing.expect(usize, @sizeOf(@Vector(4, f32))).eql(@sizeOf(math.Quaternion));
}

test "new" {
    try testing.expect(math.Quaternion, math.quat(1, 2, 3, 4)).eql(math.Quaternion{
        .v = math.vec4(1, 2, 3, 4),
    });
}

test "inverse" {
    const q = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quaternion.new(-0.1 / 3.0, -0.1 / 3.0 * 2.0, -0.1, 1.0 / 7.5);
    const actual = q.inverse();

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "fromAxisAngle" {
    const expected = math.Quaternion.fromIdentity().rotateX(math.pi / 4.0);
    const actual = math.Quaternion.fromAxisAngle(&math.vec3(1, 0, 0), math.pi / 4.0); // 45 degrees in radians (π/4) around the x-axis

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "angleBetween" {
    const a = math.Quaternion.fromAxisAngle(&math.vec3(1, 0, 0), 1.0);
    const b = math.Quaternion.fromAxisAngle(&math.vec3(1, 0, 0), -1.0);

    try testing.expect(f32, math.Quaternion.angleBetween(&a, &b)).eql(2.0);
}

test "mul" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = a.inverse();
    const expected = math.Quaternion.fromIdentity();
    const actual = math.Quaternion.multiply(&a, &b);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "add" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = math.Quaternion.new(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quaternion.new(6.0, 8.0, 10.0, 12.0);
    const actual = math.Quaternion.add(&a, &b);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "sub" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = math.Quaternion.new(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quaternion.new(-4.0, -4.0, -4.0, -4.0);
    const actual = math.Quaternion.subtract(&a, &b);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "multiplyByScalar" {
    const q = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quaternion.new(2.0, 4.0, 6.0, 8.0);
    const actual = math.Quaternion.multiplyByScalar(&q, 2.0);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "divideScalar" {
    const q = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quaternion.new(0.5, 1.0, 1.5, 2.0);
    const actual = math.Quaternion.divideScalar(&q, 2.0);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "rotateX" {
    const expected = math.Quaternion.fromAxisAngle(&math.vec3(1, 0, 0), math.pi / 4.0);
    const actual = math.Quaternion.fromIdentity().rotateX(math.pi / 4.0);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "rotateY" {
    const expected = math.Quaternion.fromAxisAngle(&math.vec3(0, 1, 0), math.pi / 4.0);
    const actual = math.Quaternion.fromIdentity().rotateY(math.pi / 4.0);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "rotateZ" {
    const expected = math.Quaternion.fromAxisAngle(&math.vec3(0, 0, 1), math.pi / 4.0);
    const actual = math.Quaternion.fromIdentity().rotateZ(math.pi / 4.0);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "slerp" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = math.Quaternion.new(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quaternion.new(3.0, 4.0, 5.0, 6.0);
    const actual = math.Quaternion.slerp(&a, &b, 0.5);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "conjugate" {
    const q = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quaternion.new(-1.0, -2.0, -3.0, 4.0);
    const actual = math.Quaternion.conjugate(&q);
    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "fromRotationMatrix" {
    {
        const qqq = math.QuaternionD.fromAxisAngle(&math.Vector3D.unit_z.clone().negate(), math.pi);
        const rotation = math.Matrix3D.fromColumnMajorArray(&.{ -1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0 }).transpose();
        const actual = math.QuaternionD.fromRotationMatrix(&rotation);
        try testing.expect(bool, true).eql(qqq.eqlApprox(&actual, math.epsilon15));
    }
    {
        const rotation = math.Matrix3D.fromColumnMajorArray(&.{ 0.9639702203483635, 0.26601017702986895, 6.456422901079747e-10, 0.12477198625717335, -0.4521499177166376, 0.8831717858696695, 0.2349326833984488, -0.8513513009480378, -0.46904967396353314 }).transpose();
        const quat = math.QuaternionD.fromRotationMatrix(&rotation);
        const rotation2 = math.Matrix3D.fromQuaternion(&quat);
        try testing.expect(bool, true).eql(rotation.eqlApprox(&rotation2, math.epsilon12));
    }
}
test "fromHeadingPitchRoll" {
    {
        const angle = math.degreesToRadians(20);
        const hpr = math.HeadingPitchRollD.new(0, 0, angle);
        const quat = math.QuaternionD.fromHeadingPitchRoll(&hpr);
        try testing.expect(bool, true).eql(math.Matrix3D.fromQuaternion(&quat).eqlApprox(&math.Matrix3D.fromRotationX(angle), math.epsilon11));
    }
    {
        const heading = math.degreesToRadians(180);
        const pitch = math.degreesToRadians(-45);
        const roll = math.degreesToRadians(45);
        const hpr = math.HeadingPitchRollD.new(heading, pitch, roll);
        const quat = math.QuaternionD.fromHeadingPitchRoll(&hpr);
        const mat1 = math.Matrix3D.fromRotationX(roll);
        const mat2 = math.Matrix3D.fromRotationY(-pitch);
        const mat3 = math.Matrix3D.fromRotationZ(-heading);
        const matres = mat3.multiply(&mat2).multiply(&mat1);
        const expected = math.Matrix3D.fromQuaternion(&quat);
        try testing.expect(bool, true).eql(matres.eqlApprox(&expected, math.epsilon11));
    }
}

test "dot" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = math.Quaternion.new(5.0, 6.0, 7.0, 8.0);
    const expected = 70.0;
    const actual = math.Quaternion.dot(&a, &b);

    try testing.expect(f32, actual).eql(expected);
}

test "lerp" {
    const a = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const b = math.Quaternion.new(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quaternion.new(3.0, 4.0, 5.0, 6.0);
    const actual = math.Quaternion.lerp(&a, &b, 0.5);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}

test "length2" {
    const q = math.Quaternion.new(1.0, 2.0, 3.0, 4.0);
    const expected = 30.0;
    const actual = math.Quaternion.length2(&q);

    try testing.expect(f32, actual).eql(expected);
}

test "len" {
    const q = math.Quaternion.new(0.0, 0.0, 3.0, 4.0);
    const expected = 5.0;
    const actual = math.Quaternion.length(&q);

    try testing.expect(f32, actual).eql(expected);
}

test "normalize" {
    const q = math.Quaternion.new(0.0, 0.0, 3.0, 4.0);
    const expected = math.Quaternion.new(0.0, 0.0, 0.6, 0.8);
    const actual = math.Quaternion.normalize(&q);

    try testing.expect(math.Vector4, expected.v).eql(actual.v);
}
