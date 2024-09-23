const math = @import("math");
const stdmath = @import("std").math;
const Cartographic = @import("Cartographic.zig").Cartographic;
const Rectangle = @import("Rectangle.zig").Rectangle;
pub const Ellipsoid = struct {
    radii: math.Vec3d,
    radiiSquared: math.Vec3d,
    radiiToTheFourth: math.Vec3d,
    oneOverRadii: math.Vec3d,
    oneOverRadiiSquared: math.Vec3d,
    minimumRadius: f64,
    maximumRadius: f64,
    centerToleranceSquared: f64,
    squaredXOverSquaredZ: f64,
    const Self = @This();

    pub const WGS84 = new(6378137.0, 6378137.0, 6356752.3142451793);

    pub const UNIT_SPHERE = new(1, 1, 1);

    pub fn new(x: f64, y: f64, z: f64) Self {
        var ellipsoid: Ellipsoid = undefined;
        const r = math.vec3d(x, y, z);
        const r_sqared = r.mul(&r);
        const r_fourth = r_sqared.mul(&r_sqared);
        const one_over_r = math.vec3d(
            if (x == 0) 0.0 else 1.0 / r.x(),
            if (y == 0) 0.0 else 1.0 / r.y(),
            if (z == 0) 0.0 else 1.0 / r.z(),
        );
        const one_over_r_sqared = math.vec3d(
            if (x == 0) 0.0 else 1.0 / r_sqared.x(),
            if (y == 0) 0.0 else 1.0 / r_sqared.y(),
            if (z == 0) 0.0 else 1.0 / r_sqared.z(),
        );
        const min_r = @min(@min(x, y), z);
        const max_r = @max(@max(x, y), z);
        ellipsoid.radii = r;
        ellipsoid.radiiSquared = r_sqared;
        ellipsoid.radiiToTheFourth = r_fourth;
        ellipsoid.oneOverRadii = one_over_r;
        ellipsoid.oneOverRadiiSquared = one_over_r_sqared;
        ellipsoid.minimumRadius = min_r;
        ellipsoid.maximumRadius = max_r;
        ellipsoid.centerToleranceSquared = math.EPSILON1;
        if (r_sqared.z() != 0) {
            ellipsoid.squaredXOverSquaredZ = r_sqared.x() / r_sqared.z();
        }
        return ellipsoid;
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .radii = self.radii,
            .radiiSquared = self.radiiSquared,
            .radiiToTheFourth = self.radiiToTheFourth,
            .oneOverRadii = self.oneOverRadii,
            .oneOverRadiiSquared = self.oneOverRadiiSquared,
            .minimumRadius = self.minimumRadius,
            .maximumRadius = self.maximumRadius,
            .centerToleranceSquared = self.centerToleranceSquared,
            .squaredXOverSquaredZ = self.squaredXOverSquaredZ,
        };
    }

    pub fn geodeticSurfaceNormalCartographic(_: *const Self, cartographic: *const Cartographic) math.Vec3d {
        const longitude = cartographic.lon;
        const latitude = cartographic.lat;
        const cosLatitude = stdmath.cos(latitude);

        const x = cosLatitude * stdmath.cos(longitude);
        const y = cosLatitude * stdmath.sin(longitude);
        const z = stdmath.sin(latitude);
        return math.vec3d(x, y, z).normalize();
    }

    pub fn geodeticSurfaceNormal(self: *const Self, vec: *const math.Vec3d) ?math.Vec3d {
        if (vec.eqlApprox(&math.Vec3d.ZERO, math.EPSILON14)) {
            return null;
        }
        return vec.mul(&self.oneOverRadiiSquared).normalize();
    }
    pub fn toCartesian(self: *const Self, cartographic: *const Cartographic) math.Vec3d {
        var n = self.geodeticSurfaceNormalCartographic(cartographic);
        var k = self.radiiSquared.mul(&n);
        const gamma = stdmath.sqrt(n.dot(&k));
        k = k.divScalar(gamma);
        n = n.mulScalar(cartographic.height);
        return k.add(&n);
    }
    pub fn scaleToGeodeticSurface(self: *const Self, vec: *const math.Vec3d) ?math.Vec3d {
        const oneOverRadiiSquared = self.oneOverRadiiSquared;
        const v2 = vec.mul(vec).mul(&oneOverRadiiSquared);
        const squaredNorm = v2.x() + v2.y() + v2.z();
        const ratio = stdmath.sqrt(1 / squaredNorm);
        const intersection = vec.mulScalar(ratio);
        if (squaredNorm < self.centerToleranceSquared) {
            return if (!stdmath.isFinite(ratio)) null else intersection;
        }
        const gradient = intersection.mul(&oneOverRadiiSquared.mulScalar(2));
        var lambda = ((1 - ratio) * vec.len()) / (0.5 * gradient.len());
        var correction: f64 = 0.0;
        var func: f64 = math.EPSILON11;
        var denominator: f64 = undefined;

        const one = math.Vec3d.splat(1);
        var m1: math.Vec3d = undefined;
        var m2: math.Vec3d = undefined;
        var m3: math.Vec3d = undefined;
        var mm: math.Vec3d = undefined;
        while (math.abs(func) > math.EPSILON12) {
            lambda -= correction;
            m1 = one.div(&oneOverRadiiSquared.mulScalar(lambda).add(&one));
            m2 = m1.mul(&m1);
            m3 = m2.mul(&m1);
            func = v2.x() * m2.x() + v2.y() * m2.y() + v2.z() * m2.z() - 1.0;
            mm = v2.mul(&m3).mul(&oneOverRadiiSquared);
            denominator = mm.x() + mm.y() + mm.z();
            const derivative = -2.0 * denominator;
            correction = func / derivative;
        }
        return vec.mul(&m1);
    }
    pub fn scaleToGeocentricSurface(self: *const Self, vec: *const math.Vec3d) math.Vec3d {
        const v = vec.mul(vec).mul(&self.oneOverRadiiSquared);
        const beta = 1 / stdmath.sqrt(v.x() + v.y() + v.z());
        return vec.mulScalar(beta);
    }
    pub fn toCartographic(self: *const Self, vec: *const math.Vec3d) ?Cartographic {
        const p = self.scaleToGeodeticSurface(vec) orelse return null;

        const n = self.geodeticSurfaceNormal(&p) orelse unreachable;
        const h = vec.sub(&p);

        const longitude = stdmath.atan2(n.y(), n.x());
        const latitude = stdmath.asin(n.z());
        const altitude = stdmath.sign(h.dot(vec)) * h.len();

        return Cartographic.new(longitude, latitude, altitude);
    }
    pub fn getSurfaceNormalIntersectionWithZAxis(self: *const Self, position: *const math.Vec3d, buffer: f64) ?math.Vec3d {
        const squaredXOverSquaredZ = self.squaredXOverSquaredZ;
        const result = math.vec3d(0, 0, position.z() * (1 - squaredXOverSquaredZ));
        if (math.abs(result.z()) >= self.radii.z() - buffer) {
            return undefined;
        }

        return result;
    }
    pub fn getLocalCurvature(self: *const Self, surfacePosition: *const math.Vec3d) math.Vec2d {
        const primeVerticalEndpoint = self.getSurfaceNormalIntersectionWithZAxis(surfacePosition, 0.0) orelse unreachable;
        const primeVerticalRadius = surfacePosition.dist(&primeVerticalEndpoint);
        // meridional radius = (1 - e^2) * primeVerticalRadius^3 / a^2
        // where 1 - e^2 = b^2 / a^2,
        // so meridional = b^2 * primeVerticalRadius^3 / a^4
        //   = (b * primeVerticalRadius / a^2)^2 * primeVertical
        const radiusRatio = (self.minimumRadius * primeVerticalRadius) / (self.maximumRadius * self.maximumRadius);
        const meridionalRadius = primeVerticalRadius * (radiusRatio * radiusRatio);

        return math.vec2d(1.0 / primeVerticalRadius, 1.0 / meridionalRadius);
    }
    pub fn surfaceArea(self: *const Self, rectangle: *const Rectangle) f64 {
        const minLongitude = rectangle.west;
        var maxLongitude = rectangle.east;
        const minLatitude = rectangle.south;
        const maxLatitude = rectangle.north;

        while (maxLongitude < minLongitude) {
            maxLongitude += math.tau;
        }
        const radiiSquared = self.radiiSquared;
        const a2 = radiiSquared.x();
        const b2 = radiiSquared.y();
        const c2 = radiiSquared.z();
        const a2b2 = a2 * b2;

        const ProcessLon = struct {
            a2b2: f64,
            a2: f64,
            b2: f64,
            c2: f64,
            sinPhi: f64,
            cosPhi: f64,
            fn call(this: @This(), lon: f64) f64 {
                const cosTheta = math.cos(lon);
                const sinTheta = math.sin(lon);
                return math.sqrt(
                    this.a2b2 * this.cosPhi * this.cosPhi +
                        this.c2 *
                        (this.b2 * cosTheta * cosTheta + this.a2 * sinTheta * sinTheta) *
                        this.sinPhi *
                        this.sinPhi,
                );
            }
        };

        const ProcessLat = struct {
            proceeLong: ProcessLon,
            minLongitude: f64,
            maxLongitude: f64,
            const Me = @This();
            fn new(a2b2v: f64, a2v: f64, b2v: f64, c2v: f64, minLongitudev: f64, maxLongitudev: f64) Me {
                const p = ProcessLon{
                    .a2b2 = a2b2v,
                    .a2 = a2v,
                    .b2 = b2v,
                    .c2 = c2v,
                    .sinPhi = 0,
                    .cosPhi = 0,
                };
                return .{
                    .proceeLong = p,
                    .minLongitude = minLongitudev,
                    .maxLongitude = maxLongitudev,
                };
            }

            fn call(me: Me, lat: f64) f64 {
                const sinPhi = stdmath.cos(lat);
                const cosPhi = stdmath.sin(lat);
                var p = me.proceeLong;
                p.sinPhi = sinPhi;
                p.cosPhi = cosPhi;
                return sinPhi * gaussLegendreQuadrature(
                    me.minLongitude,
                    me.maxLongitude,
                    p,
                );
            }
        };

        return gaussLegendreQuadrature(minLatitude, maxLatitude, ProcessLat.new(
            a2b2,
            a2,
            b2,
            c2,
            minLongitude,
            maxLongitude,
        ));
    }
};

const abscissas: [6]f64 = .{
    0.14887433898163,
    0.43339539412925,
    0.67940956829902,
    0.86506336668898,
    0.97390652851717,
    0.0,
};
const weights: [6]f64 = .{
    0.29552422471475,
    0.26926671930999,
    0.21908636251598,
    0.14945134915058,
    0.066671344308684,
    0.0,
};
fn gaussLegendreQuadrature(a: f64, b: f64, ctx: anytype) f64 {
    // The range is half of the normal range since the five weights add to one (ten weights add to two).
    // The values of the abscissas are multiplied by two to account for this.
    const xMean = 0.5 * (b + a);
    const xRange = 0.5 * (b - a);

    var sum: f64 = 0.0;
    for (0..5) |i| {
        const dx = xRange * abscissas[i];
        sum += weights[i] * (ctx.call(xMean + dx) + ctx.call(xMean - dx));
    }

    // Scale the sum to the range of x.
    sum *= xRange;
    return sum;
}
test "Ellipsoid.toCartesian" {
    const testing = @import("std").testing;
    const ellipsoid = Ellipsoid.WGS84;
    const spaceCartographic = Cartographic.fromDegrees(-45.0, 15.0, 330000.0);
    const spaceCartesian = math.vec3d(4582719.8827300891, -4582719.8827300882, 1725510.4250797231);
    const returnResult = ellipsoid.toCartesian(&spaceCartographic);
    try testing.expect(returnResult.eqlApprox(&spaceCartesian, math.EPSILON7));

    // const a = Cartographic.fromDegrees(45, 45, 0);
    // const debug = @import("std").debug;
    // const b = ellipsoid.toCartesian(&a);
    // debug.print("{},{},{}", .{ b.x(), b.y(), b.z() });
}
test "Ellipsoid.toCartographic" {
    const testing = @import("std").testing;
    const ellipsoid = Ellipsoid.WGS84;
    const spaceCartographic = Cartographic.fromDegrees(-45.0, 15.0, 330000.0);
    const spaceCartesian = math.vec3d(4582719.8827300891, -4582719.8827300882, 1725510.4250797231);
    const returnResult = ellipsoid.toCartographic(&spaceCartesian) orelse unreachable;
    try testing.expect(returnResult.eqlApprox(&spaceCartographic, math.EPSILON7));
}

test "Ellipsoid.surfaceArea" {
    const testing = @import("std").testing;
    var ellipsoid = Ellipsoid.new(4, 4, 3);
    var a2 = ellipsoid.radiiSquared.x();
    var c2 = ellipsoid.radiiSquared.z();
    var e = stdmath.sqrt(1.0 - c2 / a2);
    var area = math.tau * a2 + math.pi * (c2 / e) * stdmath.log(f64, stdmath.e, (1.0 + e) / (1.0 - e));
    try testing.expectApproxEqAbs(area, ellipsoid.surfaceArea(&Rectangle.MAX_VALUE), math.EPSILON3);

    ellipsoid = Ellipsoid.new(3, 3, 4);
    a2 = ellipsoid.radiiSquared.x();
    c2 = ellipsoid.radiiSquared.z();
    e = stdmath.sqrt(1.0 - a2 / c2);
    const a = ellipsoid.radii.x();
    const c = ellipsoid.radii.z();
    area =
        math.tau * a2 + math.tau * ((a * c) / e) * stdmath.asin(e);
    try testing.expectApproxEqAbs(area, ellipsoid.surfaceArea(&Rectangle.MAX_VALUE), math.EPSILON3);
}

test "Ellipsoid.getLocalCurvature" {
    const testing = @import("std").testing;
    const ellipsoid = Ellipsoid.WGS84;
    const cartographic = Cartographic.fromDegrees(0, 0, 0);
    const cartesianOnTheSurface = ellipsoid.toCartesian(&cartographic);
    const returedResult = ellipsoid.getLocalCurvature(&cartesianOnTheSurface);
    const expetedResult = math.vec2d(1.0 / ellipsoid.maximumRadius, ellipsoid.maximumRadius /
        (ellipsoid.minimumRadius * ellipsoid.minimumRadius));
    try testing.expect(expetedResult.eqlApprox(&returedResult, math.EPSILON8));
}
