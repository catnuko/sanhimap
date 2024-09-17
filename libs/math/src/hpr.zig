const math = @import("root.zig");
const stdmath = @import("std").math;
const testing = @import("testing.zig");
const vec = @import("vec.zig");
const mat = @import("mat.zig");
const Quat = @import("quat.zig").Quat;

pub fn HeadingPitchRoll(comptime Scalar: type) type {
    return extern struct {
        pub const Vec = vec.Vec3(Scalar);

        v: Vec,

        pub const T = Vec.T;

        const HeadingPitchRollN = @This();

        pub inline fn init(hv: T, pv: T, rv: T) HeadingPitchRollN {
            return .{ .v = Vec.init(hv, pv, rv) };
        }

        pub inline fn h(a: *const HeadingPitchRollN) T {
            return a.v.x();
        }
        pub inline fn p(a: *const HeadingPitchRollN) T {
            return a.v.y();
        }
        pub inline fn r(a: *const HeadingPitchRollN) T {
            return a.v.z();
        }

        pub inline fn fromQuat(quat: *const Quat(T)) HeadingPitchRollN {
            const x = quat.v.x();
            const y = quat.v.y();
            const z = quat.v.z();
            const w = quat.v.w();
            const testi = 2 * (w * y - z * x);
            const denominatorRoll = 1 - 2 * (x * x + y * y);
            const numeratorRoll = 2 * (w * x + y * z);
            const denominatorHeading = 1 - 2 * (y * y + z * z);
            const numeratorHeading = 2 * (w * z + x * y);

            const hv = -stdmath.atan2(numeratorHeading, denominatorHeading);
            const rv = stdmath.atan2(numeratorRoll, denominatorRoll);
            const pv = -math.asinClamped(testi);
            return init(hv, pv, rv);
        }
        pub inline fn fromDegrees(hv: T, pv: T, rv: T) HeadingPitchRollN {
            return init(hv * math.rad_per_deg, pv * math.rad_per_deg, rv * math.rad_per_deg);
        }
        pub inline fn eql(a: *const HeadingPitchRollN, b: *const HeadingPitchRollN) bool {
            return a.v.eql(&b.v);
        }
        pub inline fn eqlApprox(a: *const HeadingPitchRollN, b: *const HeadingPitchRollN, tolerance: Scalar) bool {
            return a.v.eqlApprox(&b.v, tolerance);
        }
    };
}

test "HeadingPitchRoll_init" {
    const deg2rad = math.deg_per_rad;
    const result = math.hpr(1.0 * deg2rad, 2.0 * deg2rad, 3.0 * deg2rad);
    try testing.expect(f32, 1.0 * deg2rad).eql(result.h());
    try testing.expect(f32, 2.0 * deg2rad).eql(result.p());
    try testing.expect(f32, 3.0 * deg2rad).eql(result.r());
}

test "HeadingPitchRoll_fromQuat" {
    const deg2rad = math.rad_per_deg;
    const testingTab = [9][3]f64{
        .{ 0, 0, 0 },
        .{ 90 * deg2rad, 0, 0 },
        .{ -90 * deg2rad, 0, 0 },
        .{ 0, 89 * deg2rad, 0 },
        .{ 0, -89 * deg2rad, 0 },
        .{ 0, 0, 90 * deg2rad },
        .{ 0, 0, -90 * deg2rad },
        .{ 30 * deg2rad, 30 * deg2rad, 30 * deg2rad },
        .{ -30 * deg2rad, -30 * deg2rad, 45 * deg2rad },
    };
    for (0..9) |i| {
        const h = testingTab[i][0];
        const p = testingTab[i][1];
        const r = testingTab[i][2];
        const hpr = math.hprd(h, p, r);
        const quat = math.Quatd.fromHpr(&hpr);
        const result = math.HeadingPitchRolld.fromQuat(&quat);
        try testing.expect(f64, h).eqlApprox(result.h(), math.EPSILON11);
        try testing.expect(f64, p).eqlApprox(result.p(), math.EPSILON11);
        try testing.expect(f64, r).eqlApprox(result.r(), math.EPSILON11);
    }
}

test "HeadingPitchRoll_fromDegrees" {
    const deg2rad = math.rad_per_deg;
    const testingTab = [9][3]f64{
        .{ 0, 0, 0 },
        .{ 90, 0, 0 },
        .{ -90, 0, 0 },
        .{ 0, 89, 0 },
        .{ 0, -89, 0 },
        .{ 0, 0, 90 },
        .{ 0, 0, -90 },
        .{ 30, 30, 30 },
        .{ -30, -30, 45 },
    };
    for (0..9) |i| {
        const h = testingTab[i][0];
        const p = testingTab[i][1];
        const r = testingTab[i][2];
        const hpr = math.HeadingPitchRolld.fromDegrees(h, p, r);
        try testing.expect(f64, h * deg2rad).eqlApprox(hpr.h(), math.EPSILON11);
        try testing.expect(f64, p * deg2rad).eqlApprox(hpr.p(), math.EPSILON11);
        try testing.expect(f64, r * deg2rad).eqlApprox(hpr.r(), math.EPSILON11);
    }
}

test "HeadingPitchRoll_eql" {
    const hpr = math.hprd(1, 2, 3);
    const hpr2 = math.hprd(1, 2, 3);
    try testing.expect(bool, true).eql(hpr.eql(&hpr2));
}
test "HeadingPitchRoll_eqlApprox" {
    const hpr = math.hprd(1, 2, 3);
    {
        const hpr2 = math.hprd(1, 2, 3);
        try testing.expect(bool, true).eql(hpr.eqlApprox(&hpr2, 0));
    }
    {
        const hpr2 = math.hprd(1, 2, 3);
        try testing.expect(bool, true).eql(hpr.eqlApprox(&hpr2, 1));
    }
    {
        const hpr2 = math.hprd(2, 2, 3);
        try testing.expect(bool, true).eql(hpr.eqlApprox(&hpr2, 1));
    }
    {
        const hpr2 = math.hprd(1, 3, 3);
        try testing.expect(bool, true).eql(hpr.eqlApprox(&hpr2, 1));
    }
    {
        const hpr2 = math.hprd(1, 2, 4);
        try testing.expect(bool, true).eql(hpr.eqlApprox(&hpr2, 1));
    }
}
