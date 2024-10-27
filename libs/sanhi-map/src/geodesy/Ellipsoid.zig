const Cartographic = @import("../Cartographic.zig").Cartographic;
const math = @import("../math.zig");
pub const Ellipsoid = struct {
    a: f64,
    b: f64,
    f: f64,
    pub const WGS84: Ellipsoid = new(6378137, 6356752.314245, 1.0 / 298.257223563);
    pub const Airy1830: Ellipsoid = new(6377563.396, 6356256.909, 1.0 / 299.3249646);
    pub const AiryModified: Ellipsoid = new(6377340.189, 6356034.448, 1.0 / 299.3249646);
    pub const Bessel1841: Ellipsoid = new(6377397.155, 6356078.962822, 1.0 / 299.15281285);
    pub const Clarke1866: Ellipsoid = new(6378206.4, 6356583.8, 1.0 / 294.978698214);
    pub const Clarke1880IGN: Ellipsoid = new(6378249.2, 6356515.0, 1.0 / 293.466021294);
    pub const GRS80: Ellipsoid = new(6378137, 6356752.314140, 1.0 / 298.257222101);
    pub const Intl1924: Ellipsoid = new(6378388, 6356911.946128, 1.0 / 297.0); // aka Hayford
    pub const WGS72: Ellipsoid = new(6378135, 6356750.52, 1.0 / 298.26);
    const Self = @This();
    pub fn new(av: f64, bv: f64, fv: f64) Self {
        return .{ .a = av, .b = bv, .f = fv };
    }
    pub fn toCartesian(self: *const Self, cg: *const Cartographic) math.Vec3 {
        const c = cg.lat;
        const d = cg.lon;
        const h = cg.height;
        // const { a, f } = ellipsoid;
        const a = self.a;
        const f = self.f;

        const sinc = math.sin(c);
        const cosc = math.cos(c);
        const sind = math.sin(d);
        const cosd = math.cos(d);

        const eSq = 2 * f - f * f; // 1st eccentricity squared ≡ (a²-b²)/a²
        const v = a / math.sqrt(1 - eSq * sinc * sinc); // radius of curvature in prime vertical

        const x = (v + h) * cosc * cosd;
        const y = (v + h) * cosc * sind;
        const z = (v * (1 - eSq) + h) * sinc;

        return math.vec3(x, y, z);
    }
    pub fn toCartographic(self: *const Self, vec: *const math.Vec3) Cartographic {
        const x = vec.x();
        const y = vec.y();
        const z = vec.z();
        const a = self.a;
        const b = self.b;
        const f = self.f;

        const e2 = 2 * f - f * f; // 1st eccentricity squared ≡ (a²−b²)/a²
        const ee2 = e2 / (1 - e2); // 2nd eccentricity squared ≡ (a²−b²)/b²
        const p = math.sqrt(x * x + y * y); // distance from minor axis
        const R = math.sqrt(p * p + z * z); // polar radius

        // parametric latitude (Bowring eqn.17, replacing tanb = z·a / p·b)
        const tanb = (b * z) / (a * p) * (1 + ee2 * b / R);
        const sinb = tanb / math.sqrt(1 + tanb * tanb);
        const cosb = sinb / tanb;

        // geodetic latitude (Bowring eqn.18: tang = z+ε²⋅b⋅sin³b / p−e²⋅cos³b)
        const g = if (math.isNan(cosb)) 0 else math.atan2(z + ee2 * b * sinb * sinb * sinb, p - e2 * a * cosb * cosb * cosb);

        // longitude
        const h = math.atan2(y, x);

        // height above ellipsoid (Bowring eqn.7)
        const sing = math.sin(g);
        const cosg = math.cos(g);
        const v = a / math.sqrt(1 - e2 * sing * sing); // length of the normal terminated by the minor axis
        const height = p * cosg + z * sing - (a * a / v);

        return Cartographic.new(g, h, height);
    }
    pub fn distanceTo(self: *const Self, p1: *const Cartographic, p2: *const Cartographic) f64 {
        const res = self.inverse(p1, p2) orelse return math.nan_f64;
        return res.distance;
    }
    pub fn finalBearingTo(self: *const Self, p1: *const Cartographic, p2: *const Cartographic) f64 {
        const res = self.inverse(p1, p2) orelse return math.nan_f64;
        return res.finalBearing;
    }
    pub fn initialBearingTo(self: *const Self, p1: *const Cartographic, p2: *const Cartographic) f64 {
        const res = self.inverse(p1, p2) orelse return math.nan_f64;
        return res.initialBearing;
    }
    pub fn intermediatePointTo(self: *const Self, p1: *const Cartographic, p2: *const Cartographic, fraction: f64) Cartographic {
        if (fraction == 0) return p1.clone();
        if (fraction == 1) return p2.clone();
        const res = self.inverse(p1, p2) orelse unreachable;
        const dist = res.distance;
        const brng = res.initialBearing;
        return if (math.isNan(brng)) p1.clone() else self.destinationPoint(p1, dist * fraction, brng);
    }

    pub fn finalBearingOn(self: *const Self, p: *const Cartographic, distance: f64, initialBearing: f64) f64 {
        return self.direct(p, distance, initialBearing).finalBearing;
    }

    pub fn destinationPoint(self: *const Self, p: *const Cartographic, distance: f64, initialBearing: f64) Cartographic {
        return self.direct(p, distance, initialBearing).point;
    }

    pub const DirectResult = struct {
        point: Cartographic,
        finalBearing: f64,
        iterations: u64,
    };

    pub fn direct(self: *const Self, p: *const Cartographic, distance: f64, initialBearing: f64) DirectResult {
        if (distance == 0) {
            return .{
                .point = p.clone(),
                .finalBearing = math.nan_f64,
                .iterations = 0,
            };
        }
        const lat = p.lat;
        const lon = p.lon;
        const a1 = initialBearing;
        const s = distance;

        // allow alternative ellipsoid to be specified
        const a = self.a;
        const b = self.b;
        const f = self.f;

        const sina1 = math.sin(a1);
        const cosa1 = math.cos(a1);

        const tanU1 = (1 - f) * math.tan(lat);
        const cosU1 = 1 / math.sqrt((1 + tanU1 * tanU1));
        const sinU1 = tanU1 * cosU1;
        const o1 = math.atan2(tanU1, cosa1); // o1 = angular distance on the sphere from the equator to P1
        const sina = cosU1 * sina1; // a = azimuth of the geodesic at the equator
        const cosSqa = 1 - sina * sina;
        const uSq = cosSqa * (a * a - b * b) / (b * b);
        const A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
        const B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));

        var o = s / (b * A);
        var sino: f64 = 0;
        var coso: f64 = 0; // o = angular distance P₁ P₂ on the sphere
        var cos2o: f64 = 0; // oₘ = angular distance on the sphere from the equator to the midpoint of the line
        var oo: f64 = 0;
        var iter: u64 = 0;
        while (math.abs(o - oo) > 1e-12 and iter < 100) : (iter += 1) {
            cos2o = math.cos(2 * o1 + o);
            sino = math.sin(o);
            coso = math.cos(o);
            const do = B * sino * (cos2o + B / 4 * (coso * (-1 + 2 * cos2o * cos2o) - B / 6 * cos2o * (-3 + 4 * sino * sino) * (-3 + 4 * cos2o * cos2o)));
            oo = o;
            o = s / (b * A) + do;
        } // TV: 'iterate until negligible change in l' (≈0.006mm)
        if (iter >= 100) unreachable; // not possible?

        const x = sinU1 * sino - cosU1 * coso * cosa1;
        const phi = math.atan2(sinU1 * coso + cosU1 * sino * cosa1, (1 - f) * math.sqrt(sina * sina + x * x));
        const l = math.atan2(sino * sina1, cosU1 * coso - sinU1 * sino * cosa1);
        const C = f / 16 * cosSqa * (4 + f * (4 - 3 * cosSqa));
        const L = l - (1 - C) * f * sina * (o + C * sino * (cos2o + C * coso * (-1 + 2 * cos2o * cos2o)));
        const l2 = lon + L;

        const a2 = math.atan2(sina, -x);
        return .{
            .point = Cartographic.new(phi, l2, 0),
            .finalBearing = math.zeroToTwoPi(a2),
            .iterations = iter,
        };
    }

    pub const InverseResult = struct {
        distance: f64,
        initialBearing: f64,
        finalBearing: f64,
        iterations: u64,
    };
    pub fn inverse(self: *const Self, p1: *const Cartographic, p2: *const Cartographic) ?InverseResult {
        if (p1.height != 0 or p2.height != 0) {
            return null;
        }
        const lat1 = p1.lat;
        const lon1 = p1.lon;
        const lat2 = p2.lat;
        const lon2 = p2.lon;

        // allow alternative ellipsoid to be specified
        const a = self.a;
        const b = self.b;
        const f = self.f;

        const L = lon2 - lon1; // L = difference in longitude, U = reduced latitude, defined by tan U = (1-f)·tanφ.
        const tanU1 = (1 - f) * math.tan(lat1);
        const cosU1 = 1 / math.sqrt((1 + tanU1 * tanU1));
        const sinU1 = tanU1 * cosU1;
        const tanU2 = (1 - f) * math.tan(lat2);
        const cosU2 = 1 / math.sqrt((1 + tanU2 * tanU2));
        const sinU2 = tanU2 * cosU2;

        const antipodal = math.abs(L) > math.pi / 2.0 or math.abs(lat2 - lat1) > math.pi / 2.0;

        var l = L;
        var sinl: f64 = 0;
        var cosl: f64 = 0; // l = difference in longitude on an auxiliary sphere
        var o: f64 = if (antipodal) math.pi else 0.0;
        var sino: f64 = 0;
        var coso: f64 = if (antipodal) -1 else 1.0;
        var sinSqo: f64 = 0; // o = angular distance P₁ P₂ on the sphere
        var cos2o: f64 = 1; // oₘ = angular distance on the sphere from the equator to the midpoint of the line
        var cosSqo: f64 = 1; // a = azimuth of the geodesic at the equator

        var ll = -math.inf(f64);
        var iter: u64 = 0;
        while (math.abs(l - ll) > 1e-12 and iter < 1000) : (iter += 1) {
            sinl = math.sin(l);
            cosl = math.cos(l);
            sinSqo = math.pow(f64, cosU2 * sinl, 2) + math.pow(f64, cosU1 * sinU2 - sinU1 * cosU2 * cosl, 2);
            if (math.abs(sinSqo) < 1e-24) break; // co-incident/antipodal points (o < ≈0.006mm)
            sino = math.sqrt(sinSqo);
            coso = sinU1 * sinU2 + cosU1 * cosU2 * cosl;
            o = math.atan2(sino, coso);
            const sina = cosU1 * cosU2 * sinl / sino;
            cosSqo = 1 - sina * sina;
            cos2o = if (cosSqo != 0) (coso - 2 * sinU1 * sinU2 / cosSqo) else 0; // on equatorial line cos²a = 0 (§6)
            const C = f / 16 * cosSqo * (4 + f * (4 - 3 * cosSqo));
            ll = l;
            l = L + (1 - C) * f * sina * (o + C * sino * (cos2o + C * coso * (-1 + 2 * cos2o * cos2o)));
            const iterationCheck = if (antipodal) math.abs(l) - math.pi else math.abs(l);

            if (iterationCheck > math.pi) {
                return null;
            }
        }

        if (iter >= 1000) {
            return null;
        }

        const uSq = cosSqo * (a * a - b * b) / (b * b);
        const A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
        const B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
        const ao = B * sino * (cos2o + B / 4 * (coso * (-1 + 2 * cos2o * cos2o) - B / 6 * cos2o * (-3 + 4 * sino * sino) * (-3 + 4 * cos2o * cos2o)));

        const s = b * A * (o - ao); // s = length of the geodesic

        // note special handling of exactly antipodal points where sin²o = 0 (due to discontinuity
        // atan2(0, 0) = 0 but atan2(e, 0) = math.pi/2 / 90°) - in which case bearing is always meridional,
        // due north (or due south!)
        // a = azimuths of the geodesic; a2 the direction P₁ P₂ produced
        const a1 = if (math.abs(sinSqo) < math.eps_f64) 0 else math.atan2(cosU2 * sinl, cosU1 * sinU2 - sinU1 * cosU2 * cosl);
        const a2 = if (math.abs(sinSqo) < math.eps_f64) math.pi else math.atan2(cosU1 * sinl, -sinU1 * cosU2 + cosU1 * sinU2 * cosl);

        return .{
            .distance = s,
            .initialBearing = if (math.abs(s) < math.eps_f64) math.nan_f64 else math.zeroToTwoPi(a1),
            .finalBearing = if (math.abs(s) < math.eps_f64) math.nan_f64 else math.zeroToTwoPi(a2),
            .iterations = iter,
        };
    }
};

// test "geodesic.Ellipsoid.toCartesian" {
//     const p1 = Cartographic.fromDegrees(45, 45, 0);
//     const ellipsoid = Ellipsoid.WGS84;
//     const result = ellipsoid.toCartesian(&p1);
//     const std = @import("std");
// }
